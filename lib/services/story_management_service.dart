import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/story.dart';

class StoryManagementService {
  final FirebaseFirestore _firestore;
  final String _collection = 'stories';

  StoryManagementService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Create a new story
  Future<void> createStory(Story story) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(story.id)
          .set(story.toJson());
    } catch (e) {
      throw Exception('Failed to create story: $e');
    }
  }

  /// Read a story by ID
  Future<Story?> getStory(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists && doc.data() != null) {
        return Story.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch story: $e');
    }
  }

  /// Update an existing story
  Future<void> updateStory(Story story) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(story.id)
          .update(story.toJson());
    } catch (e) {
      throw Exception('Failed to update story: $e');
    }
  }

  /// Delete a story
  Future<void> deleteStory(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete story: $e');
    }
  }

  /// Fetch stories by creatorId
  Future<List<Story>> getStoriesByCreator(String creatorId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('creatorId', isEqualTo: creatorId)
          .get();
      return querySnapshot.docs
          .map((doc) => Story.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch stories by creator: $e');
    }
  }

  /// Assign characters to a story
  Future<void> assignCharactersToStory(
    String storyId,
    List<String> characterIds,
  ) async {
    try {
      await _firestore.collection(_collection).doc(storyId).update({
        'characterIds': characterIds,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to assign characters to story: $e');
    }
  }

  /// Update story bookmark and progress
  Future<void> updateBookmark(
    String storyId,
    String segmentId,
    int chapter,
  ) async {
    try {
      await _firestore.collection(_collection).doc(storyId).update({
        'lastSegmentId': segmentId,
        'currentChapter': chapter,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update bookmark: $e');
    }
  }
}
