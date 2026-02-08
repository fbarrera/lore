class Character {
  final String id;
  final String name;
  final String race;
  final String occupation;
  final String personality;
  final String backstory;
  final Map<String, Skill> skills;
  final Map<String, int>
  relationships; // characterId -> affinity level (-100 to 100)

  Character({
    required this.id,
    required this.name,
    required this.race,
    required this.occupation,
    required this.personality,
    required this.backstory,
    required this.skills,
    this.relationships = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'race': race,
      'occupation': occupation,
      'personality': personality,
      'backstory': backstory,
      'skills': skills.map((k, v) => MapEntry(k, v.toMap())),
      'relationships': relationships,
    };
  }

  factory Character.fromMap(String id, Map<String, dynamic> map) {
    return Character(
      id: id,
      name: map['name'] ?? '',
      race: map['race'] ?? '',
      occupation: map['occupation'] ?? '',
      personality: map['personality'] ?? '',
      backstory: map['backstory'] ?? '',
      skills:
          (map['skills'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, Skill.fromMap(v as Map<String, dynamic>)),
          ) ??
          {},
      relationships: Map<String, int>.from(map['relationships'] ?? {}),
    );
  }

  Character copyWith({
    String? name,
    String? race,
    String? occupation,
    String? personality,
    String? backstory,
    Map<String, Skill>? skills,
    Map<String, int>? relationships,
  }) {
    return Character(
      id: id,
      name: name ?? this.name,
      race: race ?? this.race,
      occupation: occupation ?? this.occupation,
      personality: personality ?? this.personality,
      backstory: backstory ?? this.backstory,
      skills: skills ?? this.skills,
      relationships: relationships ?? this.relationships,
    );
  }
}

class Skill {
  final String name;
  final int currentLevel;
  final int maxPotential;
  final int experience; // Added for progression

  Skill({
    required this.name,
    required this.currentLevel,
    required this.maxPotential,
    this.experience = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'currentLevel': currentLevel,
      'maxPotential': maxPotential,
      'experience': experience,
    };
  }

  factory Skill.fromMap(Map<String, dynamic> map) {
    return Skill(
      name: map['name'] ?? '',
      currentLevel: map['currentLevel'] ?? 0,
      maxPotential: map['maxPotential'] ?? 0,
      experience: map['experience'] ?? 0,
    );
  }

  Skill copyWith({int? currentLevel, int? maxPotential, int? experience}) {
    return Skill(
      name: name,
      currentLevel: currentLevel ?? this.currentLevel,
      maxPotential: maxPotential ?? this.maxPotential,
      experience: experience ?? this.experience,
    );
  }
}
