class Story {
  final String id;
  final String title;
  final String description;
  final String creatorId;
  final List<String> characterIds;
  final String visibility;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? lastSegmentId;
  final int currentChapter;

  Story({
    required this.id,
    required this.title,
    required this.description,
    required this.creatorId,
    required this.characterIds,
    required this.visibility,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
    this.lastSegmentId,
    this.currentChapter = 1,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      creatorId: json['creatorId'] as String,
      characterIds: List<String>.from(json['characterIds'] as List),
      visibility: json['visibility'] as String,
      tags: List<String>.from(json['tags'] as List),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      lastSegmentId: json['lastSegmentId'] as String?,
      currentChapter: json['currentChapter'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'creatorId': creatorId,
      'characterIds': characterIds,
      'visibility': visibility,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastSegmentId': lastSegmentId,
      'currentChapter': currentChapter,
    };
  }
}
