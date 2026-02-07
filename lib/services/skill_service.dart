import '../models/skill.dart';

class SkillService {
  /// Increments a skill's currentLevel while ensuring it doesn't exceed maxPotential.
  /// Also updates the proficiencyTier based on the new currentLevel.
  Skill progressSkill(Skill skill) {
    if (skill.currentLevel >= skill.maxPotential) {
      return skill;
    }

    final newLevel = skill.currentLevel + 1;
    final newTier = calculateProficiencyTier(newLevel);

    return Skill(
      id: skill.id,
      name: skill.name,
      category: skill.category,
      currentLevel: newLevel,
      maxPotential: skill.maxPotential,
      proficiencyTier: newTier,
      experience: 0, // Reset XP on level up
      xpToNextLevel: (skill.xpToNextLevel * 1.5).toInt(),
      lastUsedAt: DateTime.now(),
    );
  }

  /// Adds experience to a skill and handles level up logic.
  Skill addExperience(Skill skill, int amount) {
    int newExperience = skill.experience + amount;
    int newLevel = skill.currentLevel;
    int newXpToNextLevel = skill.xpToNextLevel;

    while (newExperience >= newXpToNextLevel && newLevel < skill.maxPotential) {
      newExperience -= newXpToNextLevel;
      newLevel++;
      newXpToNextLevel = (newXpToNextLevel * 1.5).toInt();
    }

    return Skill(
      id: skill.id,
      name: skill.name,
      category: skill.category,
      currentLevel: newLevel,
      maxPotential: skill.maxPotential,
      proficiencyTier: calculateProficiencyTier(newLevel),
      experience: newExperience,
      xpToNextLevel: newXpToNextLevel,
      lastUsedAt: DateTime.now(),
    );
  }

  /// Logic to update the proficiencyTier based on the currentLevel
  /// (0: Null, 1: Novice, 2: Apprentice, 3: Skilled, 4: Expert, 5: Master, 6: Divine).
  ProficiencyTier calculateProficiencyTier(int level) {
    if (level < 10) return ProficiencyTier.nullTier;
    if (level < 30) return ProficiencyTier.novice;
    if (level < 50) return ProficiencyTier.apprentice;
    if (level < 70) return ProficiencyTier.skilled;
    if (level < 85) return ProficiencyTier.expert;
    if (level < 95) return ProficiencyTier.master;
    return ProficiencyTier.divine;
  }
}
