# Stage 4 Design: Advanced Character State & Progression

This document outlines the architecture for dynamic character states, skill progression, relationship tracking, and enhanced RAG integration for Stage 4.

## 1. Data Model Changes

### 1.1 Character Model ([`lib/models/character.dart`](lib/models/character.dart))
Add dynamic state fields to track the character's current condition within a story session.

| Field | Type | Description |
|-------|------|-------------|
| `health` | `double` | 0.0 to 1.0 (Current physical condition). |
| `mood` | `String` | Current emotional state (e.g., Happy, Anxious, Enraged). |
| `location` | `String` | Current position in the world. |
| `inventory` | `List<String>` | Items currently held by the character. |
| `metadata` | `Map<String, dynamic>` | Flexible storage for world-specific attributes. |

### 1.2 Skill Model ([`lib/models/skill.dart`](lib/models/skill.dart))
Add experience tracking for automatic advancement.

| Field | Type | Description |
|-------|------|-------------|
| `experience` | `int` | Current XP in the skill. |
| `xpToNextLevel` | `int` | XP required to reach the next level. |
| `lastUsedAt` | `DateTime?` | Timestamp of the last successful usage. |

### 1.3 Relationship Model (New: `lib/models/relationship.dart`)
Tracks the bond between two characters.

| Field | Type | Description |
|-------|------|-------------|
| `id` | `String` | Unique identifier. |
| `characterAId` | `String` | ID of the first character. |
| `characterBId` | `String` | ID of the second character. |
| `affinity` | `int` | -100 to 100 (Hostile to Soulmates). |
| `history` | `List<String>` | Key events shared between them. |
| `tags` | `List<String>` | Relationship types (e.g., Rival, Mentor, Family). |

---

## 2. State Management

### 2.1 Session-Based State
Character states (health, mood, etc.) are tied to a specific `Story` session. 
- **Persistence**: States are saved to a `character_states` sub-collection under the `Story` document in Firestore.
- **Synchronization**: The `StoryService` will fetch and merge the base `Character` profile with the session-specific `CharacterState` before passing it to the AI.

### 2.2 State Update Flow
1. AI generates a story segment.
2. AI returns structured metadata (JSON) indicating state changes (e.g., "Character took 10 damage").
3. `StoryManagementService` parses the metadata and updates the Firestore state.
4. UI reflects changes via a `StreamBuilder` or `Provider`.

---

## 3. Progression Logic

### 3.1 Skill Advancement Algorithm
Skills advance based on "Meaningful Usage".
- **Detection**: The AI identifies when a skill was used successfully in the narrative.
- **XP Gain**: `XP = (Base_XP * Difficulty_Multiplier) / Current_Level`.
- **Level Up**: When `experience >= xpToNextLevel`, `currentLevel` increments, and `xpToNextLevel` scales (e.g., `previous * 1.5`).
- **Cap**: Advancement stops at `maxPotential`.

### 3.2 Relationship Evolution
- **Affinity Shifts**: Triggered by dialogue choices or shared combat/events.
- **Thresholds**: Reaching affinity milestones (e.g., 50, 80, -50) unlocks new interaction types or dialogue options in the AI prompt.

---

## 4. RAG Enhancement

### 4.1 Lore Indexing
- **Character Profiles**: Indexed as high-priority context.
- **World Lore**: Segmented into "Knowledge Nuggets" (e.g., "The Fall of Eldoria").
- **Retrieval**: 
    - **Vector Search**: Based on the current story segment's keywords.
    - **Entity Extraction**: If "Eldoria" is mentioned, the RAG system prioritizes Eldoria-related lore.

### 4.2 Context Window Management
The prompt will be structured as:
1. **System Instructions**: Core AI behavior.
2. **Dynamic State**: Current health, mood, location of active characters.
3. **Retrieved Lore**: Relevant world/character history from RAG.
4. **Recent History**: Last 5-10 story segments.

---

## 5. AI Prompt Engineering

### 5.1 State Injection Template
```text
Current Character State:
- Name: {{char.name}}
- Health: {{char.health * 100}}%
- Mood: {{char.mood}}
- Location: {{char.location}}
- Skills: {{char.skills_summary}}
- Relationships: {{char.relationships_summary}}

Lore Context:
{{rag_results}}

Task: Continue the story based on the user's prompt, ensuring character actions are consistent with their current state and skills.
```

### 5.2 Structured Output Requirement
The AI must append a hidden JSON block to its response for state updates:
```json
{
  "state_updates": {
    "health_change": -0.1,
    "mood_change": "Determined",
    "skill_usage": ["Swordsmanship"],
    "relationship_change": {"target_id": "npc_1", "affinity_delta": 5}
  }
}
```
