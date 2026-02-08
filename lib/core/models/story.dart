import 'package:cloud_firestore/cloud_firestore.dart';

class Story {
  final String id;
  final String title;
  final String description;
  final String introMessage;
  final String genre;
  final String narrationStyle;
  final String worldNotes;
  final bool isPublic;
  final DateTime lastUpdated;
  final List<String> characterIds;

  Story({
    required this.id,
    required this.title,
    required this.description,
    this.introMessage = '',
    required this.genre,
    required this.narrationStyle,
    required this.worldNotes,
    this.isPublic = false,
    required this.lastUpdated,
    this.characterIds = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'introMessage': introMessage,
      'genre': genre,
      'narrationStyle': narrationStyle,
      'worldNotes': worldNotes,
      'isPublic': isPublic,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'characterIds': characterIds,
    };
  }

  factory Story.fromMap(String id, Map<String, dynamic> map) {
    return Story(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      introMessage: map['introMessage'] ?? '',
      genre: map['genre'] ?? '',
      narrationStyle: map['narrationStyle'] ?? '',
      worldNotes: map['worldNotes'] ?? '',
      isPublic: map['isPublic'] ?? false,
      lastUpdated:
          (map['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      characterIds: List<String>.from(map['characterIds'] ?? []),
    );
  }
}
