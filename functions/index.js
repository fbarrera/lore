const { onCall } = require("firebase-functions/v2/https");
const { setGlobalOptions } = require("firebase-functions");
const logger = require("firebase-functions/logger");
const { GoogleGenerativeAI } = require("@google/generative-ai");
const { Pinecone } = require("@pinecone-database/pinecone");
const admin = require("firebase-admin");
require("dotenv").config();

admin.initializeApp();

setGlobalOptions({ maxInstances: 10 });

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY || "");
const pc = new Pinecone({
    apiKey: process.env.PINECONE_API_KEY || "",
});
const index = pc.index(process.env.PINECONE_INDEX_NAME || "");

/**
 * Helper to generate embeddings using Gemini
 * @param {string} text
 * @return {Promise<number[]>}
 */
async function generateEmbedding(text) {
    const model = genAI.getGenerativeModel({ model: "text-embedding-004" });
    const result = await model.embedContent(text);
    return result.embedding.values;
}

/**
 * Helper to retrieve relevant context from Pinecone
 * @param {string} storyId
 * @param {string} query
 * @param {number} k
 * @return {Promise<string>}
 */
async function retrieveContext(storyId, query, k = 5) {
    try {
        const embedding = await generateEmbedding(query);
        const queryResponse = await index.namespace(storyId).query({
            vector: embedding,
            topK: k,
            includeMetadata: true,
        });

        return queryResponse.matches
            .map((match) => `[${match.metadata.type || "Memory"}]: ${match.metadata.text}`)
            .join("\n\n---\n\n");
    } catch (error) {
        logger.error("Error retrieving context from Pinecone", error);
        return ""; // Return empty context on error to allow story to continue
    }
}

/**
 * Helper to upsert to Pinecone
 * @param {string} storyId
 * @param {string} id
 * @param {number[]} embedding
 * @param {object} metadata
 */
async function upsertToPinecone(storyId, id, embedding, metadata) {
    try {
        await index.namespace(storyId).upsert([{
            id: id,
            values: embedding,
            metadata: metadata,
        }]);
        logger.info("Upserted to Pinecone", { id, storyId });
    } catch (error) {
        logger.error("Error upserting to Pinecone", error, { id, storyId });
    }
}

/**
 * Cloud Function to index world lore (Knowledge Nuggets)
 */
exports.indexLore = onCall(async (request) => {
    const { storyId, loreId, text, title, tags } = request.data;
    if (!storyId || !loreId || !text) {
        throw new Error("Missing storyId, loreId, or text");
    }

    try {
        const embedding = await generateEmbedding(`Lore: ${title || ""}\nTags: ${(tags || []).join(", ")}\n${text}`);
        await upsertToPinecone(storyId, `lore_${loreId}`, embedding, {
            text,
            title: title || "",
            tags: tags || [],
            type: "Lore",
            timestamp: new Date().toISOString(),
        });
        return { success: true };
    } catch (error) {
        logger.error("Error indexing lore", error);
        throw new Error("Failed to index lore");
    }
});

/**
 * Cloud Function to index character profiles
 */
exports.indexCharacter = onCall(async (request) => {
    const { storyId, characterId, name, profileText, traits } = request.data;
    if (!storyId || !characterId || !profileText) {
        throw new Error("Missing storyId, characterId, or profileText");
    }

    try {
        const embedding = await generateEmbedding(`Character: ${name}\nTraits: ${(traits || []).join(", ")}\n${profileText}`);
        await upsertToPinecone(storyId, `character_${characterId}`, embedding, {
            text: profileText,
            name: name || "",
            traits: traits || [],
            type: "Character",
            timestamp: new Date().toISOString(),
        });
        return { success: true };
    } catch (error) {
        logger.error("Error indexing character", error);
        throw new Error("Failed to index character");
    }
});

/**
 * Helper to extract entities using Gemini
 * @param {string} text
 * @return {Promise<string[]>}
 */
async function extractEntities(text) {
    try {
        const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });
        const prompt = `Extract key entities (characters, locations, items, events) from the following text. Return them as a comma-separated list. If none, return "none": "${text}"`;
        const result = await model.generateContent(prompt);
        const entitiesText = result.response.text().trim();
        if (entitiesText.toLowerCase() === "none") return [];
        return entitiesText.split(",").map((e) => e.trim());
    } catch (error) {
        logger.error("Error extracting entities", error);
        return [];
    }
}

/**
 * Cloud Function to process a story segment
 */
exports.processStorySegment = onCall(async (request) => {
    const { storyId, userPrompt, context } = request.data;
    const { narration, worldNotes, userPersona, characterStates } = context;

    if (!storyId || !userPrompt) {
        throw new Error("Missing storyId or userPrompt");
    }

    try {
        // 1. Extract entities for better retrieval
        const entities = await extractEntities(userPrompt);
        const retrievalQuery = entities.length > 0 ?
            `${userPrompt} Entities: ${entities.join(", ")}` :
            userPrompt;

        // 2. Retrieve relevant past context (RAG)
        const pastContext = await retrieveContext(storyId, retrievalQuery);

        // 3. Prepare Character State Summary
        const charStateSummary = (characterStates || []).map((char) => `
- Name: ${char.name}
- Health: ${Math.round((char.health || 1.0) * 100)}%
- Mood: ${char.mood || "Neutral"}
- Location: ${char.location || "Unknown"}
- Skills: ${char.skills_summary || "None"}
- Relationships: ${char.relationships_summary || "None"}
        `).join("\n");

        // 4. Prepare System Instruction
        const systemInstruction = `
      You are an expert storyteller and dungeon master.
      
      NARRATION STYLE:
      ${narration || "Standard third-person narrative, descriptive and engaging."}
      
      WORLD NOTES:
      ${worldNotes || "A generic fantasy world."}
      
      USER PERSONA:
      ${userPersona || "An adventurer seeking glory."}

      CURRENT CHARACTER STATES:
      ${charStateSummary || "No active characters."}

      RELEVANT LORE & MEMORIES:
      ${pastContext || "No relevant lore found."}
      
      INSTRUCTIONS:
      - Continue the story based on the user's input.
      - Maintain consistency with the world notes, persona, character states, and lore.
      - Keep the response concise but evocative.
      - You MUST return your response in JSON format with the following structure:
        {
          "text": "Your narrative response here",
          "state_updates": {
            "health_change": number (e.g., -0.1 for damage, 0.1 for healing),
            "mood_change": "string (new mood)",
            "location_change": "string (new location name)",
            "skill_usage": ["string (skill names used)"],
            "relationship_change": {"target_id": "string", "affinity_delta": number}
          }
        }
      - If no state updates are needed, provide null or empty values for those fields.
    `;

        // 5. Call Gemini to generate the next segment
        const model = genAI.getGenerativeModel({
            model: "gemini-1.5-flash",
            systemInstruction: systemInstruction,
            generationConfig: {
                responseMimeType: "application/json",
            },
        });

        const result = await model.generateContent(userPrompt);
        const responseText = result.response.text();
        const responseJson = JSON.parse(responseText);
        const generatedText = responseJson.text;

        // 6. Generate embedding for the new segment
        const embedding = await generateEmbedding(generatedText);

        // 7. Store in Firestore
        const segmentData = {
            storyId,
            text: generatedText,
            userPrompt,
            stateUpdates: responseJson.state_updates,
            entities: entities,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
        };

        const docRef = await admin.firestore()
            .collection("stories")
            .doc(storyId)
            .collection("segments")
            .add(segmentData);

        // 8. Upsert to Pinecone
        await upsertToPinecone(storyId, docRef.id, embedding, {
            text: generatedText,
            userPrompt: userPrompt,
            type: "Memory",
            timestamp: new Date().toISOString(),
        });

        logger.info("Segment processed and stored", { segmentId: docRef.id });

        return {
            segmentId: docRef.id,
            text: generatedText,
            stateUpdates: responseJson.state_updates,
        };
    } catch (error) {
        logger.error("Error processing story segment", error);
        throw new Error("Failed to process story segment: " + error.message);
    }
});
