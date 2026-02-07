import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/character.dart';
import '../models/skill.dart';

class AICharacterService with ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  late final GenerativeModel _model;

  AICharacterService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null) {
      throw Exception('GEMINI_API_KEY not found in .env');
    }
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
    );
  }

  /// Generates a Character object based on a user prompt.
  Future<Character> generateCharacter(
    String prompt, {
    String? creatorId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      const systemPrompt = '''
You are an expert character creator for a fantasy role-playing game.
Generate a detailed character based on the user's prompt.
The response must be a valid JSON object matching this structure:
{
  "name": "Character Name",
  "age": 25,
  "gender": "Gender",
  "race": "Race",
  "occupation": "Occupation",
  "personality": "Personality description",
  "story": "Backstory",
  "appearance": "Physical description",
  "skills": [
    {
      "name": "Skill Name",
      "category": "Skill Category",
      "currentLevel": 1,
      "maxPotential": 10,
      "proficiencyTier": 1
    }
  ]
}
Proficiency tiers are: 0 (Null), 1 (Novice), 2 (Apprentice), 3 (Skilled), 4 (Expert), 5 (Master), 6 (Divine).
Ensure the skills are relevant to the character's occupation and story.
''';

      final content = [
        Content.text(systemPrompt),
        Content.text('User prompt: $prompt'),
      ];

      final response = await _model.generateContent(content);
      final text = response.text;
      if (text == null) {
        throw Exception('AI returned an empty response');
      }

      final Map<String, dynamic> data = jsonDecode(text);

      // Add required fields for the Character model that AI doesn't provide
      data['id'] = FirebaseFirestore.instance.collection('characters').doc().id;
      data['creatorId'] = creatorId ?? 'ai-generated';
      data['createdAt'] = DateTime.now().toIso8601String();

      // Add IDs to skills if missing
      if (data['skills'] != null && data['skills'] is List) {
        for (var skill in data['skills']) {
          if (skill is Map && skill['id'] == null) {
            skill['id'] = FirebaseFirestore.instance
                .collection('characters')
                .doc()
                .id;
          }
        }
      }

      return Character.fromJson(data);
    } catch (e) {
      debugPrint('Error generating character: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refines an existing character based on user feedback.
  Future<Character> refineCharacter(
    Character character,
    String feedback,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      const systemPrompt = '''
You are an expert character creator. You will be given an existing character and user feedback.
Update the character based on the feedback while maintaining consistency where appropriate.
The response must be a valid JSON object matching the same structure as the input character.
''';

      final characterJson = jsonEncode(character.toJson());
      final content = [
        Content.text(systemPrompt),
        Content.text('Current Character: $characterJson'),
        Content.text('User Feedback: $feedback'),
      ];

      final response = await _model.generateContent(content);
      final text = response.text;
      if (text == null) {
        throw Exception('AI returned an empty response');
      }

      final Map<String, dynamic> data = jsonDecode(text);

      // Preserve fields from the original character
      data['id'] = character.id;
      data['creatorId'] = character.creatorId;
      data['createdAt'] = character.createdAt.toIso8601String();

      // Add IDs to skills if missing (e.g. for newly generated skills)
      if (data['skills'] != null && data['skills'] is List) {
        for (var skill in data['skills']) {
          if (skill is Map && skill['id'] == null) {
            skill['id'] = FirebaseFirestore.instance
                .collection('characters')
                .doc()
                .id;
          }
        }
      }

      return Character.fromJson(data);
    } catch (e) {
      debugPrint('Error refining character: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
