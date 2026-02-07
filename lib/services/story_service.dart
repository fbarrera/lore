import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import '../models/story_segment.dart';
import '../models/character.dart';
import '../models/skill.dart';
import '../models/story.dart';
import 'character_service.dart';
import 'skill_service.dart';
import 'relationship_service.dart';
import 'story_management_service.dart';

class StoryService with ChangeNotifier {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final CharacterService _characterService;
  final SkillService _skillService;
  final RelationshipService _relationshipService;
  final StoryManagementService _storyManagementService;

  StoryService({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    CharacterService? characterService,
    SkillService? skillService,
    RelationshipService? relationshipService,
    StoryManagementService? storyManagementService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _functions = functions ?? FirebaseFunctions.instance,
       _characterService = characterService ?? CharacterService(),
       _skillService = skillService ?? SkillService(),
       _relationshipService = relationshipService ?? RelationshipService(),
       _storyManagementService =
           storyManagementService ?? StoryManagementService();

  List<StorySegment> _segments = [];
  List<StorySegment> get segments => _segments;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Stream<List<StorySegment>> getStorySegments(String storyId) {
    return _firestore
        .collection('stories')
        .doc(storyId)
        .collection('segments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => StorySegment.fromFirestore(doc))
              .toList();
        });
  }

  Future<Map<String, dynamic>> processSegment({
    required String storyId,
    required String userPrompt,
    String narrationSlot = 'default',
    String worldNotesSlot = 'default',
    String userPersonaSlot = 'default',
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Fetch Story and Characters for context
      final story = await _storyManagementService.getStory(storyId);
      if (story == null) throw Exception('Story not found');

      List<Map<String, dynamic>> characterStates = [];
      for (String charId in story.characterIds) {
        final char = await _characterService.getCharacter(charId);
        if (char != null) {
          characterStates.add({
            'id': char.id,
            'name': char.name,
            'health': char.health,
            'mood': char.mood,
            'location': char.location,
            'skills_summary': char.skills
                .map((s) => '${s.name} (Lvl ${s.currentLevel})')
                .join(', '),
            // Relationships summary could be added here if needed
          });
        }
      }

      // 2. Call Cloud Function
      final HttpsCallable callable = _functions.httpsCallable(
        'processStorySegment',
      );

      final response = await callable.call({
        'storyId': storyId,
        'userPrompt': userPrompt,
        'context': {
          'narration':
              narrationSlot, // In a real app, you'd fetch the actual content for these slots
          'worldNotes': worldNotesSlot,
          'userPersona': userPersonaSlot,
          'characterStates': characterStates,
        },
      });

      final data = Map<String, dynamic>.from(response.data);
      final stateUpdates = data['stateUpdates'];
      final choices = data['choices'] as List<dynamic>?;

      if (stateUpdates != null) {
        await _applyStateUpdates(story.characterIds.first, stateUpdates);
      }

      // Update story progress if a new segment was created
      if (data['segmentId'] != null) {
        await _storyManagementService.updateBookmark(
          storyId,
          data['segmentId'],
          data['isNewChapter'] == true
              ? story.currentChapter + 1
              : story.currentChapter,
        );
      }

      return data;
    } catch (e) {
      debugPrint('Error processing story segment: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _applyStateUpdates(
    String primaryCharacterId,
    Map<dynamic, dynamic> updates,
  ) async {
    debugPrint('Applying state updates: $updates');

    // 1. Update Character Basic State
    double? healthChange = (updates['health_change'] as num?)?.toDouble();
    String? moodChange = updates['mood_change'] as String?;
    String? locationChange = updates['location_change'] as String?;

    if (healthChange != null || moodChange != null || locationChange != null) {
      final character = await _characterService.getCharacter(
        primaryCharacterId,
      );
      if (character != null) {
        double newHealth = (character.health + (healthChange ?? 0.0)).clamp(
          0.0,
          1.0,
        );
        await _characterService.updateCharacterState(
          primaryCharacterId,
          health: newHealth,
          mood: moodChange ?? character.mood,
          location: locationChange ?? character.location,
        );
        debugPrint(
          'Updated character $primaryCharacterId: health=$newHealth, mood=${moodChange ?? character.mood}, location=${locationChange ?? character.location}',
        );
      }
    }

    // 2. Update Skills
    List<dynamic>? skillUsage = updates['skill_usage'] as List<dynamic>?;
    if (skillUsage != null && skillUsage.isNotEmpty) {
      final character = await _characterService.getCharacter(
        primaryCharacterId,
      );
      if (character != null) {
        List<Skill> updatedSkills = List.from(character.skills);
        bool changed = false;

        for (var skillName in skillUsage) {
          int index = updatedSkills.indexWhere(
            (s) => s.name.toLowerCase() == skillName.toString().toLowerCase(),
          );
          if (index != -1) {
            updatedSkills[index] = _skillService.addExperience(
              updatedSkills[index],
              20,
            ); // Default 20 XP
            changed = true;
            debugPrint(
              'Skill progressed: ${updatedSkills[index].name} to level ${updatedSkills[index].currentLevel}',
            );
          }
        }

        if (changed) {
          await _characterService.updateCharacterSkills(
            primaryCharacterId,
            updatedSkills,
          );
        }
      }
    }

    // 3. Update Relationships
    Map<dynamic, dynamic>? relChange =
        updates['relationship_change'] as Map<dynamic, dynamic>?;
    if (relChange != null) {
      String? targetId = relChange['target_id'] as String?;
      int? affinityDelta = (relChange['affinity_delta'] as num?)?.toInt();

      if (targetId != null && affinityDelta != null) {
        await _relationshipService.updateRelationship(
          primaryCharacterId,
          targetId,
          affinityDelta,
          'Interaction in story segment',
        );
        debugPrint(
          'Relationship updated between $primaryCharacterId and $targetId: delta=$affinityDelta',
        );
      }
    }
  }
}
