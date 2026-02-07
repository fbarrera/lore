import 'package:cloud_firestore/cloud_firestore.dart';

class StorySegment {
  final String id;
  final String text;
  final String? imageUrl;
  final DateTime createdAt;
  final String? userPrompt;
  final Map<String, dynamic>? stateUpdates;
  final List<String>? choices;

  StorySegment({
    required this.id,
    required this.text,
    this.imageUrl,
    required this.createdAt,
    this.userPrompt,
    this.stateUpdates,
    this.choices,
  });

  factory StorySegment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StorySegment(
      id: doc.id,
      text: data['text'] ?? '',
      imageUrl: data['imageUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      userPrompt: data['userPrompt'],
      stateUpdates: data['stateUpdates'] as Map<String, dynamic>?,
      choices: data['choices'] != null
          ? List<String>.from(data['choices'])
          : null,
    );
  }
}
