import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/character.dart';

class CharacterService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createCharacter(String userId, Character character) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('characters')
        .doc(character.id)
        .set(character.toMap());
  }

  Future<List<Character>> getCharacters(String userId) async {
    final snapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('characters')
        .get();

    return snapshot.docs
        .map((doc) => Character.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<void> updateCharacter(String userId, Character character) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('characters')
        .doc(character.id)
        .update(character.toMap());
  }

  Future<void> deleteCharacter(String userId, String characterId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('characters')
        .doc(characterId)
        .delete();
  }

  Future<Character?> getCharacter(String userId, String characterId) async {
    final doc = await _db
        .collection('users')
        .doc(userId)
        .collection('characters')
        .doc(characterId)
        .get();

    if (!doc.exists) return null;
    return Character.fromMap(doc.id, doc.data()!);
  }
}
