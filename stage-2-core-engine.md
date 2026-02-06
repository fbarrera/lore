# Stage 2: Core AI Engine & Basic RAG

## Overview
Build the core AI engine with Gemini 3 Flash/Pro integration, implement the tri-part system instruction framework for dynamic storytelling, and establish basic Retrieval-Augmented Generation (RAG) using Pinecone for memory retrieval. This stage depends on the foundation established in Stage 1.

## Objectives
- Integrate Gemini 3 Flash/Pro AI model for story generation
- Implement tri-part system instruction framework (Narration Slot, World Notes Slot, User Persona Slot)
- Set up basic RAG system with Pinecone for memory retrieval
- Develop Cloud Functions for processing story segments and generating embeddings
- Update data schemas for storing story segments and embeddings

## Deliverables
- Gemini AI integration module with API client
- Tri-part system instruction framework implementation
- Basic RAG pipeline with Pinecone vector search
- Cloud Functions for story segment processing and embedding generation
- Updated Firestore schemas for story segments and embeddings
- Integration tests for AI engine and RAG functionality

## Tech Stack Setup
- **AI Model:** Gemini 3 Flash/Pro via Google AI API
- **Vector Database:** Pinecone for embedding storage and retrieval
- **Backend Processing:** Firebase Cloud Functions for server-side AI processing
- **Data Storage:** Firestore collections for story segments and embeddings
- **Frontend Integration:** Flutter AI Toolkit for client-side AI interactions

## Implementation Steps
1. Set up Gemini 3 Flash/Pro API client in Cloud Functions
2. Implement tri-part system instruction framework:
   - Narration Slot: Dynamic story narration prompts
   - World Notes Slot: Contextual world-building information
   - User Persona Slot: User-specific preferences and characteristics
3. Configure Pinecone index for story embeddings
4. Develop Cloud Function for generating embeddings from story segments
5. Create Cloud Function for story segment processing and AI generation
6. Update Firestore data schemas:
   - Add story_segments collection with embedding vectors
   - Modify stories collection to reference segments
   - Add embedding metadata fields
7. Implement basic RAG retrieval logic in Cloud Functions
8. Integrate RAG pipeline with Gemini AI for context-aware story generation
9. Add error handling and rate limiting for AI API calls
10. Create unit tests for AI engine components

## Dependencies
- Stage 1: Foundation & Setup (Firebase, Pinecone, basic Flutter app)

## Estimated Effort
- Gemini API integration: 3-4 hours
- Tri-part system instruction framework: 4-5 hours
- Pinecone RAG setup: 2-3 hours
- Cloud Functions development: 6-8 hours
- Data schema updates: 2-3 hours
- Integration and testing: 3-4 hours

## Success Criteria
- Gemini 3 Flash/Pro successfully generates coherent story segments
- Tri-part system instructions dynamically adapt story output
- RAG system retrieves relevant story context from Pinecone
- Cloud Functions process story segments and generate embeddings without errors
- Updated data schemas support efficient storage and retrieval of story data
- End-to-end AI pipeline works for basic story generation with memory