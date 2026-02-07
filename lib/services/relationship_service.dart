import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/relationship.dart';

class RelationshipService {
  final FirebaseFirestore _firestore;
  final String _collection = 'relationships';

  RelationshipService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Fetch a relationship between two characters
  Future<Relationship?> getRelationship(String charAId, String charBId) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('characterAId', whereIn: [charAId, charBId])
          .get();

      for (var doc in query.docs) {
        final data = doc.data();
        if ((data['characterAId'] == charAId &&
                data['characterBId'] == charBId) ||
            (data['characterAId'] == charBId &&
                data['characterBId'] == charAId)) {
          return Relationship.fromJson({...data, 'id': doc.id});
        }
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch relationship: $e');
    }
  }

  /// Fetch all relationships for a character
  Future<List<Relationship>> getRelationshipsForCharacter(
    String characterId,
  ) async {
    try {
      final queryA = await _firestore
          .collection(_collection)
          .where('characterAId', isEqualTo: characterId)
          .get();
      final queryB = await _firestore
          .collection(_collection)
          .where('characterBId', isEqualTo: characterId)
          .get();

      final List<Relationship> relationships = [];
      for (var doc in queryA.docs) {
        relationships.add(Relationship.fromJson({...doc.data(), 'id': doc.id}));
      }
      for (var doc in queryB.docs) {
        relationships.add(Relationship.fromJson({...doc.data(), 'id': doc.id}));
      }
      return relationships;
    } catch (e) {
      throw Exception('Failed to fetch relationships: $e');
    }
  }

  /// Update or create a relationship
  Future<void> updateRelationship(
    String charAId,
    String charBId,
    int affinityDelta,
    String historyEntry,
  ) async {
    try {
      Relationship? existing = await getRelationship(charAId, charBId);

      if (existing != null) {
        await _firestore.collection(_collection).doc(existing.id).update({
          'affinity': existing.affinity + affinityDelta,
          'history': FieldValue.arrayUnion([historyEntry]),
        });
      } else {
        final newId = _firestore.collection(_collection).doc().id;
        final newRel = Relationship(
          id: newId,
          characterAId: charAId,
          characterBId: charBId,
          affinity: affinityDelta,
          history: [historyEntry],
          tags: [],
        );
        await _firestore
            .collection(_collection)
            .doc(newId)
            .set(newRel.toJson());
      }
    } catch (e) {
      throw Exception('Failed to update relationship: $e');
    }
  }
}
