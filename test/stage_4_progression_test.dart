import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:loreweaver/models/skill.dart';
import 'package:loreweaver/models/character.dart';
import 'package:loreweaver/models/story.dart';
import 'package:loreweaver/services/skill_service.dart';
import 'package:loreweaver/services/character_service.dart';
import 'package:loreweaver/services/relationship_service.dart';
import 'package:loreweaver/services/story_service.dart';
import 'package:loreweaver/services/story_management_service.dart';

import 'stage_4_progression_test.mocks.dart';

@GenerateMocks([
  FirebaseFirestore,
  FirebaseFunctions,
  HttpsCallable,
  HttpsCallableResult,
  CharacterService,
  RelationshipService,
  StoryManagementService,
  CollectionReference,
  DocumentReference,
  DocumentSnapshot,
])
void main() {
  group('SkillService Tests', () {
    late SkillService skillService;
    late Skill testSkill;

    setUp(() {
      skillService = SkillService();
      testSkill = Skill(
        id: 'skill_1',
        name: 'Swordplay',
        category: 'Combat',
        currentLevel: 5,
        maxPotential: 100,
        proficiencyTier: ProficiencyTier.nullTier,
        experience: 0,
        xpToNextLevel: 100,
      );
    });

    test(
      'addExperience should increase experience and level up when threshold reached',
      () {
        final updatedSkill = skillService.addExperience(testSkill, 150);

        expect(updatedSkill.currentLevel, 6);
        expect(updatedSkill.experience, 50);
        expect(updatedSkill.xpToNextLevel, 150); // 100 * 1.5
      },
    );

    test('addExperience should handle multiple level ups', () {
      final updatedSkill = skillService.addExperience(testSkill, 300);

      expect(updatedSkill.currentLevel, 7);
      expect(updatedSkill.experience, 50);
    });

    test('calculateProficiencyTier should return correct tiers', () {
      expect(
        skillService.calculateProficiencyTier(5),
        ProficiencyTier.nullTier,
      );
      expect(skillService.calculateProficiencyTier(15), ProficiencyTier.novice);
      expect(
        skillService.calculateProficiencyTier(35),
        ProficiencyTier.apprentice,
      );
      expect(
        skillService.calculateProficiencyTier(55),
        ProficiencyTier.skilled,
      );
      expect(skillService.calculateProficiencyTier(75), ProficiencyTier.expert);
      expect(skillService.calculateProficiencyTier(90), ProficiencyTier.master);
      expect(skillService.calculateProficiencyTier(98), ProficiencyTier.divine);
    });

    test('progressSkill should increment level and update tier', () {
      final skillAt9 = Skill(
        id: 'skill_2',
        name: 'Magic',
        category: 'Arcane',
        currentLevel: 9,
        maxPotential: 100,
        proficiencyTier: ProficiencyTier.nullTier,
      );

      final updatedSkill = skillService.progressSkill(skillAt9);

      expect(updatedSkill.currentLevel, 10);
      expect(updatedSkill.proficiencyTier, ProficiencyTier.novice);
    });
  });

  group('StoryService Progression Tests', () {
    late StoryService storyService;
    late MockFirebaseFirestore mockFirestore;
    late MockFirebaseFunctions mockFunctions;
    late MockCharacterService mockCharacterService;
    late MockRelationshipService mockRelationshipService;
    late MockStoryManagementService mockStoryManagementService;
    late MockHttpsCallable mockHttpsCallable;

    final testCharacter = Character(
      id: 'char_1',
      name: 'Eldrin',
      age: 30,
      gender: 'Male',
      race: 'Elf',
      occupation: 'Ranger',
      personality: 'Stoic',
      story: 'A forest protector.',
      appearance: 'Tall and lean.',
      skills: [
        Skill(
          id: 'skill_1',
          name: 'Archery',
          category: 'Combat',
          currentLevel: 10,
          maxPotential: 100,
          proficiencyTier: ProficiencyTier.novice,
        ),
      ],
      creatorId: 'user_1',
      createdAt: DateTime.now(),
      health: 0.8,
      mood: 'Neutral',
      location: 'Forest',
    );

    final testStory = Story(
      id: 'story_1',
      title: 'The Lost Woods',
      description: 'A journey through magic.',
      creatorId: 'user_1',
      characterIds: ['char_1'],
      visibility: 'public',
      tags: ['fantasy'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockFunctions = MockFirebaseFunctions();
      mockCharacterService = MockCharacterService();
      mockRelationshipService = MockRelationshipService();
      mockStoryManagementService = MockStoryManagementService();
      mockHttpsCallable = MockHttpsCallable();

      storyService = StoryService(
        firestore: mockFirestore,
        functions: mockFunctions,
        characterService: mockCharacterService,
        relationshipService: mockRelationshipService,
        storyManagementService: mockStoryManagementService,
      );

      when(
        mockStoryManagementService.getStory('story_1'),
      ).thenAnswer((_) async => testStory);
      when(
        mockCharacterService.getCharacter('char_1'),
      ).thenAnswer((_) async => testCharacter);
      when(
        mockFunctions.httpsCallable('processStorySegment'),
      ).thenReturn(mockHttpsCallable);
    });

    test('processSegment should apply character state updates', () async {
      final mockResponse = MockHttpsCallableResult();
      when(mockResponse.data).thenReturn({
        'stateUpdates': {
          'health_change': -0.1,
          'mood_change': 'Tired',
          'location_change': 'Cave',
        },
      });
      when(mockHttpsCallable.call(any)).thenAnswer((_) async => mockResponse);

      await storyService.processSegment(
        storyId: 'story_1',
        userPrompt: 'I enter the cave.',
      );

      verify(
        mockCharacterService.updateCharacterState(
          'char_1',
          health: argThat(closeTo(0.7, 0.0001), named: 'health'),
          mood: 'Tired',
          location: 'Cave',
          inventory: anyNamed('inventory'),
          metadata: anyNamed('metadata'),
        ),
      ).called(1);
    });

    test('processSegment should apply skill XP gain', () async {
      final mockResponse = MockHttpsCallableResult();
      when(mockResponse.data).thenReturn({
        'stateUpdates': {
          'skill_usage': ['Archery'],
        },
      });
      when(mockHttpsCallable.call(any)).thenAnswer((_) async => mockResponse);

      await storyService.processSegment(
        storyId: 'story_1',
        userPrompt: 'I shoot an arrow.',
      );

      final capturedSkills =
          verify(
                mockCharacterService.updateCharacterSkills(
                  'char_1',
                  captureAny,
                ),
              ).captured.first
              as List<Skill>;

      expect(capturedSkills.first.name, 'Archery');
      expect(capturedSkills.first.experience, 20);
    });

    test('processSegment should apply relationship updates', () async {
      final mockResponse = MockHttpsCallableResult();
      when(mockResponse.data).thenReturn({
        'stateUpdates': {
          'relationship_change': {'target_id': 'char_2', 'affinity_delta': 5},
        },
      });
      when(mockHttpsCallable.call(any)).thenAnswer((_) async => mockResponse);

      await storyService.processSegment(
        storyId: 'story_1',
        userPrompt: 'I help the stranger.',
      );

      verify(
        mockRelationshipService.updateRelationship(
          'char_1',
          'char_2',
          5,
          'Interaction in story segment',
        ),
      ).called(1);
    });

    test(
      'processSegment should include character states in RAG context',
      () async {
        final mockResponse = MockHttpsCallableResult();
        when(mockResponse.data).thenReturn({'stateUpdates': null});
        when(mockHttpsCallable.call(any)).thenAnswer((_) async => mockResponse);

        await storyService.processSegment(
          storyId: 'story_1',
          userPrompt: 'What is my status?',
        );

        final capturedArgs =
            verify(mockHttpsCallable.call(captureAny)).captured.first
                as Map<String, dynamic>;

        expect(capturedArgs['context']['characterStates'], isNotEmpty);
        expect(capturedArgs['context']['characterStates'][0]['name'], 'Eldrin');
        expect(capturedArgs['context']['characterStates'][0]['health'], 0.8);
      },
    );
  });
}
