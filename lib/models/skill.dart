enum ProficiencyTier {
  nullTier(0),
  novice(1),
  apprentice(2),
  skilled(3),
  expert(4),
  master(5),
  divine(6);

  final int value;
  const ProficiencyTier(this.value);

  static ProficiencyTier fromInt(int value) {
    return ProficiencyTier.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ProficiencyTier.nullTier,
    );
  }
}

class Skill {
  final String id;
  final String name;
  final String category;
  final int currentLevel;
  final int maxPotential;
  final ProficiencyTier proficiencyTier;
  final int experience;
  final int xpToNextLevel;
  final DateTime? lastUsedAt;

  Skill({
    required this.id,
    required this.name,
    required this.category,
    required this.currentLevel,
    required this.maxPotential,
    required this.proficiencyTier,
    this.experience = 0,
    this.xpToNextLevel = 100,
    this.lastUsedAt,
  });

  factory Skill.fromJson(Map<String, dynamic> json) {
    return Skill(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      currentLevel: json['currentLevel'] as int,
      maxPotential: json['maxPotential'] as int,
      proficiencyTier: ProficiencyTier.fromInt(json['proficiencyTier'] as int),
      experience: json['experience'] as int? ?? 0,
      xpToNextLevel: json['xpToNextLevel'] as int? ?? 100,
      lastUsedAt: json['lastUsedAt'] != null
          ? DateTime.parse(json['lastUsedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'currentLevel': currentLevel,
      'maxPotential': maxPotential,
      'proficiencyTier': proficiencyTier.value,
      'experience': experience,
      'xpToNextLevel': xpToNextLevel,
      'lastUsedAt': lastUsedAt?.toIso8601String(),
    };
  }
}
