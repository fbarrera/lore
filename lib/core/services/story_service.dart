import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/story.dart';

class StoryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createStory(String userId, Story story) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('stories')
        .doc(story.id)
        .set(story.toMap());
  }

  Future<List<Story>> getStories(String userId) async {
    final snapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('stories')
        .orderBy('lastUpdated', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Story.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<void> updateStory(String userId, Story story) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('stories')
        .doc(story.id)
        .update(story.toMap());
  }

  Future<void> deleteStory(String userId, String storyId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('stories')
        .doc(storyId)
        .delete();
  }
}
