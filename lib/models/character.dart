import 'skill.dart';

class Character {
  final String id;
  final String name;
  final int age;
  final String gender;
  final String race;
  final String occupation;
  final String personality;
  final String story;
  final String appearance;
  final List<Skill> skills;
  final String creatorId;
  final DateTime createdAt;

  // Dynamic state fields
  final double health;
  final String mood;
  final String location;
  final List<String> inventory;
  final Map<String, dynamic> metadata;

  Character({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.race,
    required this.occupation,
    required this.personality,
    required this.story,
    required this.appearance,
    required this.skills,
    required this.creatorId,
    required this.createdAt,
    this.health = 1.0,
    this.mood = 'Neutral',
    this.location = 'Unknown',
    this.inventory = const [],
    this.metadata = const {},
  });

  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      id: json['id'] as String,
      name: json['name'] as String,
      age: json['age'] as int,
      gender: json['gender'] as String,
      race: json['race'] as String,
      occupation: json['occupation'] as String,
      personality: json['personality'] as String,
      story: json['story'] as String,
      appearance: json['appearance'] as String,
      skills: (json['skills'] as List<dynamic>)
          .map((e) => Skill.fromJson(e as Map<String, dynamic>))
          .toList(),
      creatorId: json['creatorId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      health: (json['health'] as num?)?.toDouble() ?? 1.0,
      mood: json['mood'] as String? ?? 'Neutral',
      location: json['location'] as String? ?? 'Unknown',
      inventory: (json['inventory'] as List<dynamic>?)?.cast<String>() ?? [],
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'gender': gender,
      'race': race,
      'occupation': occupation,
      'personality': personality,
      'story': story,
      'appearance': appearance,
      'skills': skills.map((e) => e.toJson()).toList(),
      'creatorId': creatorId,
      'createdAt': createdAt.toIso8601String(),
      'health': health,
      'mood': mood,
      'location': location,
      'inventory': inventory,
      'metadata': metadata,
    };
  }
}
