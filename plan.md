# AI Storytelling App - Master Plan & Tracker

## Overview
This master plan outlines the development of an AI-powered storytelling app with creator tools, character progression, and immersive RAG-based memory systems. The project is divided into 5 implementation stages for systematic development and testing.

## Core Objectives
- **Persistent Memory:** Utilize RAG to recall story beats across long sessions.
- **Customizable Persona:** Dedicated slots for Narration Style, System Lore, and User Character.
- **Efficiency:** Offload heavy computation to the cloud to preserve phone battery.
- **Modern UI:** High-fidelity interface using the Flutter AI Toolkit.
- **Creator Tools:** Enable users to build and manage stories with detailed characters.
- **Character Progression:** Organic skill advancement through story interactions.

## Tech Stack (Cloud-Centric & Free Tiers)
- **Frontend:** Flutter (Cross-platform performance & AI Toolkit support).
- **AI Model:** Gemini 3 Flash / Pro (High reasoning, 2M context window).
- **Backend:** Firebase Spark Plan (Auth, Firestore).
- **Vector Search:** Firestore Vector Search (Built-in; handles similarity search).
- **Embeddings:** text-embedding-004 (Converts text to searchable vectors).

## Implementation Stages

### [Stage 1: Foundation & Setup](stage-1-foundation.md)
**Status:** Completed
**Focus:** Cloud services, authentication, basic data storage
**Dependencies:** None
**Estimated Effort:** 8-12 hours

### [Stage 2: Core AI Engine & Basic RAG](stage-2-core-engine.md)
**Status:** Completed
**Focus:** AI integration, tri-part system instructions, basic memory
**Dependencies:** Stage 1
**Estimated Effort:** 18-26 hours

### [Stage 3: Creator Tools & Character Management](stage-3-creator-tools.md)
**Status:** Completed
**Focus:** Character creation, skills system, story authoring
**Dependencies:** Stage 1, Stage 2
**Estimated Effort:** 30-40 hours

### [Stage 4: Advanced RAG & Character Progression](stage-4-rag-progression.md)
**Status:** Completed
**Focus:** Skill advancement, relationship tracking, state synchronization
**Dependencies:** Stage 2, Stage 3
**Estimated Effort:** 28-38 hours

### [Stage 5: UI/UX Implementation & Polish](stage-5-ui-ux.md)
**Status:** Completed
**Focus:** Complete interface, accessibility, responsive design
**Dependencies:** Stage 1, Stage 2, Stage 3, Stage 4
**Estimated Effort:** 32-42 hours

## System Architecture
The app follows a "Thick Client" model to stay within the Firebase Spark Plan (Free Tier) by performing embedding computation and RAG logic directly on the device.

### Tri-Part System Instruction Framework
1. **Narration Slot:** Literary style (e.g., "Gritty Noir")
2. **World Notes Slot:** Fixed lore rules (e.g., "Magic is radioactive")
3. **User Persona Slot:** Player identity (e.g., "A rogue pilot")

### Client-Side RAG Workflow
1. **Story Segment:** App generates embeddings locally using Gemini API
2. **Data Storage:** App stores segment and embedding in Firestore
3. **Context Retrieval:** App uses Firestore Vector Search to retrieve relevant past events
4. **AI Generation:** App injects context into Gemini prompt for story continuation

## Data Schema (Firestore)
See individual stage files for detailed schema implementations.

## Total Estimated Effort: 116-158 hours
## Recommended Development Order: 1 → 2 → 3 → 4 → 5

---

*This master plan serves as the central tracking document. Each stage contains detailed implementation guides, dependencies, and success criteria. Update stage statuses as development progresses.*