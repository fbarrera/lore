class Relationship {
  final String id;
  final String characterAId;
  final String characterBId;
  final int affinity;
  final List<String> history;
  final List<String> tags;

  Relationship({
    required this.id,
    required this.characterAId,
    required this.characterBId,
    required this.affinity,
    required this.history,
    required this.tags,
  });

  factory Relationship.fromJson(Map<String, dynamic> json) {
    return Relationship(
      id: json['id'] as String,
      characterAId: json['characterAId'] as String,
      characterBId: json['characterBId'] as String,
      affinity: json['affinity'] as int,
      history: (json['history'] as List<dynamic>).cast<String>(),
      tags: (json['tags'] as List<dynamic>).cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'characterAId': characterAId,
      'characterBId': characterBId,
      'affinity': affinity,
      'history': history,
      'tags': tags,
    };
  }
}
