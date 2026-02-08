import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import '../models/character.dart';

class ProgressionResult {
  final Map<String, int> skillChanges; // skillName -> xpGained
  final Map<String, int> relationshipChanges; // characterId -> affinityChange
  final String summary;

  ProgressionResult({
    required this.skillChanges,
    required this.relationshipChanges,
    required this.summary,
  });

  factory ProgressionResult.fromJson(Map<String, dynamic> json) {
    return ProgressionResult(
      skillChanges: Map<String, int>.from(json['skillChanges'] ?? {}),
      relationshipChanges: Map<String, int>.from(
        json['relationshipChanges'] ?? {},
      ),
      summary: json['summary'] ?? '',
    );
  }
}

class AIService {
  late final GenerativeModel _model;
  late final GenerativeModel _embeddingModel;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  AIService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
    _embeddingModel = GenerativeModel(
      model: 'text-embedding-004',
      apiKey: apiKey,
    );
  }

  Future<String> processStorySegment({
    required String text,
    required String storyId,
    required String narrationStyle,
    required String worldNotes,
    required String userPersona,
    List<String> characterIds = const [],
  }) async {
    // 1. Generate embedding
    final embedding = await generateEmbedding(text);

    // 2. Store in Firestore
    final segmentRef = _db
        .collection('stories')
        .doc(storyId)
        .collection('segments')
        .doc();
    await segmentRef.set({
      'text': text,
      'embedding': VectorValue(embedding),
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 3. Retrieve context (Story Segments)
    List<String> contextTexts = [];
    try {
      final query = _db
          .collection('stories')
          .doc(storyId)
          .collection('segments');

      // Fallback: Get last 5 segments chronologically
      final lastSegments = await query
          .orderBy('timestamp', descending: true)
          .limit(6)
          .get();

      contextTexts = lastSegments.docs
          .where((doc) => doc.id != segmentRef.id)
          .map((doc) => doc.data()['text'] as String)
          .toList();
    } catch (e) {
      print("Vector search failed, using chronological fallback: $e");
    }

    // 4. Retrieve Character Memories (Advanced RAG)
    List<String> memoryTexts = [];
    if (characterIds.isNotEmpty) {
      try {
        for (String charId in characterIds) {
          // In a real scenario with vector search enabled:
          /*
          final memoryQuery = _db
              .collection('stories')
              .doc(storyId)
              .collection('characters')
              .doc(charId)
              .collection('memories');
              
          final relevantMemories = await memoryQuery.findNearest(
            vectorField: 'embedding',
            queryVector: VectorValue(embedding),
            limit: 2,
            distanceMeasure: DistanceMeasure.cosine,
          ).get();
          
          memoryTexts.addAll(relevantMemories.docs.map((d) => "Memory of $charId: ${d.data()['text']}"));
          */

          // Fallback: Get recent memories
          final recentMemories = await _db
              .collection('stories')
              .doc(storyId)
              .collection('characters')
              .doc(charId)
              .collection('memories')
              .orderBy('timestamp', descending: true)
              .limit(2)
              .get();

          memoryTexts.addAll(
            recentMemories.docs.map((d) => "[Memory] ${d.data()['text']}"),
          );
        }
      } catch (e) {
        print("Failed to retrieve character memories: $e");
      }
    }

    // 5. Generate AI Response
    final prompt =
        '''
System Instructions:
1. Narration Style: $narrationStyle
2. World Lore: $worldNotes
3. User Persona: $userPersona

Context from Story:
${contextTexts.reversed.join('\n')}

Relevant Character Memories:
${memoryTexts.join('\n')}

Current Story Beat:
$text
''';

    final content = [Content.text(prompt)];
    final response = await _model.generateContent(content);
    final responseText = response.text ?? 'Error generating story.';

    return responseText;
  }

  Future<ProgressionResult?> analyzeProgression({
    required String storyContext,
    required String lastInteraction,
    required List<Character> characters,
  }) async {
    final characterData = characters
        .map(
          (c) => {
            'name': c.name,
            'skills': c.skills.map(
              (k, v) =>
                  MapEntry(k, {'level': v.currentLevel, 'xp': v.experience}),
            ),
            'relationships': c.relationships,
          },
        )
        .toList();

    final prompt =
        '''
System Instructions:
Analyze the following story interaction for character development.
Focus on:
1. **Skill Usage**: Did a character use a specific skill? Was it successful?
   - Award 5-15 XP for significant usage.
   - Award 20-30 XP for critical success or major plot impact.
   - Award 1-5 XP for minor usage or practice.
2. **Relationship Evolution**: Did characters interact meaningfully?
   - +5 to +15 affinity for positive bonding, shared hardship, or agreement.
   - -5 to -15 affinity for betrayal, argument, or conflict.
   - 0 for neutral interactions.

Return a JSON object with:
- skillChanges: Map of skill names to XP gained (e.g., {"Swordsmanship": 15})
- relationshipChanges: Map of character names/IDs to affinity change (e.g., {"Marcus": 10})
- summary: A concise narrative summary of *why* these changes occurred (e.g., "Elara used her stealth to bypass the guards, gaining experience. She bonded with Marcus over the shared danger.").

Characters:
${jsonEncode(characterData)}

Story Context:
$storyContext

Last Interaction:
$lastInteraction
''';

    final content = [Content.text(prompt)];
    final response = await _model.generateContent(content);
    final text = response.text;
    if (text == null) return null;

    try {
      // Extract JSON from response (handling potential markdown blocks)
      final jsonString = text.contains('```json')
          ? text.split('```json')[1].split('```')[0]
          : text;
      return ProgressionResult.fromJson(jsonDecode(jsonString));
    } catch (e) {
      print("Failed to parse progression: $e");
      return null;
    }
  }

  Future<void> storeCharacterMemory({
    required String storyId,
    required String characterId,
    required String memoryText,
    required Map<String, dynamic> stateSnapshot,
  }) async {
    final embedding = await generateEmbedding(memoryText);

    await _db
        .collection('stories')
        .doc(storyId)
        .collection('characters')
        .doc(characterId)
        .collection('memories')
        .add({
          'text': memoryText,
          'embedding': VectorValue(embedding),
          'stateSnapshot': stateSnapshot,
          'timestamp': FieldValue.serverTimestamp(),
        });
  }

  Future<String> generateCharacterDetails(String prompt) async {
    final fullPrompt =
        '''
System Instructions:
You are the "Oracle", a gritty noir storyteller. Generate character details in JSON format based on the user's prompt.
The JSON should have the following fields:
- name: String
- race: String
- occupation: String
- personality: String
- backstory: String
- skills: A map of skill names to an object with {currentLevel: int (0-6), maxPotential: int (0-6)}

User Prompt: $prompt
''';

    final content = [Content.text(fullPrompt)];
    final response = await _model.generateContent(content);
    return response.text ?? '{}';
  }

  Future<List<double>> generateEmbedding(String text) async {
    final content = Content.text(text);
    final result = await _embeddingModel.embedContent(content);
    return result.embedding.values;
  }
}
