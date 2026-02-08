import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/character.dart';
import 'ai_service.dart';
import 'character_service.dart';

class ProgressionService {
  final CharacterService _characterService = CharacterService();
  final AIService _aiService = AIService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const int xpPerLevel = 100;

  Future<void> processProgression({
    required String userId,
    required String storyId,
    required String lastInteraction,
    required List<Character> characters,
  }) async {
    final result = await _aiService.analyzeProgression(
      storyContext: "Story ID: $storyId", // Could be more detailed
      lastInteraction: lastInteraction,
      characters: characters,
    );

    if (result == null) return;

    for (var character in characters) {
      bool updated = false;
      var updatedCharacter = character;

      // Update Skills
      Map<String, Skill> newSkills = Map.from(character.skills);
      result.skillChanges.forEach((skillName, xpGained) {
        if (newSkills.containsKey(skillName)) {
          var skill = newSkills[skillName]!;
          int newXp = skill.experience + xpGained;
          int newLevel = skill.currentLevel;

          if (newXp >= xpPerLevel) {
            if (newLevel < skill.maxPotential) {
              newLevel++;
              newXp -= xpPerLevel;
            } else {
              newXp = xpPerLevel; // Cap at max XP if at max potential
            }
          }

          newSkills[skillName] = skill.copyWith(
            experience: newXp,
            currentLevel: newLevel,
          );
          updated = true;
        }
      });

      // Update Relationships
      Map<String, int> newRelationships = Map.from(character.relationships);
      result.relationshipChanges.forEach((targetId, affinityChange) {
        // Note: targetId might be a name or ID depending on AI output
        // For simplicity, we'll assume the AI uses IDs if we provide them,
        // or we'd need a mapping.
        int currentAffinity = newRelationships[targetId] ?? 0;
        newRelationships[targetId] = (currentAffinity + affinityChange).clamp(
          -100,
          100,
        );
        updated = true;
      });

      if (updated) {
        updatedCharacter = updatedCharacter.copyWith(
          skills: newSkills,
          relationships: newRelationships,
        );
        await _characterService.updateCharacter(userId, updatedCharacter);

        // Store memory for RAG
        await _aiService.storeCharacterMemory(
          storyId: storyId,
          characterId: character.id,
          memoryText: result.summary,
          stateSnapshot: updatedCharacter.toMap(),
        );
      }
    }
  }
}
