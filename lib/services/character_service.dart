import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/character.dart';
import '../models/skill.dart';

class CharacterService {
  final FirebaseFirestore _firestore;
  final String _collection = 'characters';

  CharacterService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Create a new character
  Future<void> createCharacter(Character character) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(character.id)
          .set(character.toJson());
    } catch (e) {
      throw Exception('Failed to create character: $e');
    }
  }

  /// Read a character by ID
  Future<Character?> getCharacter(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists && doc.data() != null) {
        return Character.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch character: $e');
    }
  }

  /// Update an existing character
  Future<void> updateCharacter(Character character) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(character.id)
          .update(character.toJson());
    } catch (e) {
      throw Exception('Failed to update character: $e');
    }
  }

  /// Delete a character
  Future<void> deleteCharacter(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete character: $e');
    }
  }

  /// Fetch characters by creatorId
  Future<List<Character>> getCharactersByCreator(String creatorId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('creatorId', isEqualTo: creatorId)
          .get();
      return querySnapshot.docs
          .map((doc) => Character.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch characters by creator: $e');
    }
  }

  /// Update a character's state (health, mood, location, inventory, metadata)
  Future<void> updateCharacterState(
    String characterId, {
    double? health,
    String? mood,
    String? location,
    List<String>? inventory,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      if (health != null) updates['health'] = health;
      if (mood != null) updates['mood'] = mood;
      if (location != null) updates['location'] = location;
      if (inventory != null) updates['inventory'] = inventory;
      if (metadata != null) updates['metadata'] = metadata;

      if (updates.isNotEmpty) {
        await _firestore
            .collection(_collection)
            .doc(characterId)
            .update(updates);
      }
    } catch (e) {
      throw Exception('Failed to update character state: $e');
    }
  }

  /// Update a character's skills
  Future<void> updateCharacterSkills(
    String characterId,
    List<Skill> skills,
  ) async {
    try {
      await _firestore.collection(_collection).doc(characterId).update({
        'skills': skills.map((s) => s.toJson()).toList(),
      });
    } catch (e) {
      throw Exception('Failed to update character skills: $e');
    }
  }
}
