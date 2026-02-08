import 'package:flutter/material.dart';
import '../../core/models/character.dart';
import '../theme/lore_theme.dart';
import '../theme/responsive.dart';
import '../widgets/skill_progression_tile.dart';
import '../widgets/relationship_map.dart';
import 'character_builder.dart';

/// Full character progression screen with skill displays,
/// relationship maps, and backstory. Responsive and accessible.
class CharacterProgressionScreen extends StatefulWidget {
  final Character character;
  final Map<String, String> characterNames;

  const CharacterProgressionScreen({
    super.key,
    required this.character,
    this.characterNames = const {},
  });

  @override
  State<CharacterProgressionScreen> createState() =>
      _CharacterProgressionScreenState();
}

class _CharacterProgressionScreenState
    extends State<CharacterProgressionScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Semantics(
          header: true,
          child: Text(
            '${widget.character.name.toUpperCase()} — PROGRESSION',
            style: const TextStyle(
              fontFamily: LoreTheme.serifFont,
              letterSpacing: 1.5,
              fontSize: 16,
            ),
          ),
        ),
        actions: [
          // Edit button
          Semantics(
            button: true,
            label: 'Edit ${widget.character.name}',
            child: IconButton(
              icon: Icon(
                Icons.edit_outlined,
                color: LoreTheme.goldAccent.withOpacity(0.8),
              ),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        CharacterBuilderScreen(character: widget.character),
                  ),
                );
                if (result == true && mounted) {
                  Navigator.pop(context, true);
                }
              },
              tooltip: 'Edit character',
            ),
          ),
        ],
      ),
      body: Container(
        decoration: LoreTheme.backgroundGradient,
        child: SafeArea(
          child: ContentConstraint(
            child: SingleChildScrollView(
              padding: Responsive.contentPadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Character header card
                  _buildCharacterHeader(context),
                  const SizedBox(height: 24),

                  // Skills section
                  _buildSectionTitle('PROWESS & SKILLS'),
                  const SizedBox(height: 12),
                  _buildSkillsSection(context),
                  const SizedBox(height: 32),

                  // Relationships section
                  _buildSectionTitle('BONDS & RIVALRIES'),
                  const SizedBox(height: 12),
                  RelationshipMap(
                    character: widget.character,
                    characterNames: widget.characterNames,
                  ),
                  const SizedBox(height: 32),

                  // Backstory section
                  _buildSectionTitle('BACKSTORY & ESSENCE'),
                  const SizedBox(height: 12),
                  _buildBackstorySection(),
                  const SizedBox(height: 32),

                  // Stats summary
                  _buildStatsSummary(context),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCharacterHeader(BuildContext context) {
    final totalSkillLevels = widget.character.skills.values.fold<int>(
      0,
      (sum, s) => sum + s.currentLevel,
    );
    final maxSkillLevels = widget.character.skills.values.fold<int>(
      0,
      (sum, s) => sum + s.maxPotential,
    );

    return Semantics(
      label:
          '${widget.character.name}, ${widget.character.race} ${widget.character.occupation}. '
          'Overall power: $totalSkillLevels of $maxSkillLevels',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: LoreTheme.glassmorphism(),
        child: Row(
          children: [
            // Avatar
            Hero(
              tag: 'character_${widget.character.id}',
              child: CircleAvatar(
                radius: 36,
                backgroundColor: LoreTheme.deepBrown,
                child: Text(
                  widget.character.name.isNotEmpty
                      ? widget.character.name[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: LoreTheme.goldAccent,
                    fontSize: 28,
                    fontFamily: LoreTheme.serifFont,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.character.name,
                    style: const TextStyle(
                      color: LoreTheme.parchment,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: LoreTheme.serifFont,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.character.race} • ${widget.character.occupation}',
                    style: TextStyle(
                      color: LoreTheme.lightBrown.withOpacity(0.7),
                      fontSize: 14,
                      fontFamily: LoreTheme.serifFont,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Overall power bar
                  Row(
                    children: [
                      Text(
                        'POWER',
                        style: TextStyle(
                          color: LoreTheme.warmBrown.withOpacity(0.6),
                          fontSize: 10,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: maxSkillLevels > 0
                                ? totalSkillLevels / maxSkillLevels
                                : 0,
                            backgroundColor: LoreTheme.deepBrown.withOpacity(
                              0.5,
                            ),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              LoreTheme.goldAccent,
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$totalSkillLevels/$maxSkillLevels',
                        style: TextStyle(
                          color: LoreTheme.goldAccent.withOpacity(0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillsSection(BuildContext context) {
    if (widget.character.skills.isEmpty) {
      return Text(
        'No skills defined yet.',
        style: TextStyle(
          color: LoreTheme.warmBrown.withOpacity(0.5),
          fontStyle: FontStyle.italic,
        ),
      );
    }

    // Sort skills by level descending
    final sortedSkills = widget.character.skills.values.toList()
      ..sort((a, b) => b.currentLevel.compareTo(a.currentLevel));

    return Column(
      children: sortedSkills
          .map((skill) => SkillProgressionTile(skill: skill))
          .toList(),
    );
  }

  Widget _buildBackstorySection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LoreTheme.narratorBg.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LoreTheme.warmBrown.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.character.personality.isNotEmpty) ...[
            Text('PERSONALITY', style: LoreTheme.labelStyle(fontSize: 10)),
            const SizedBox(height: 6),
            Text(
              widget.character.personality,
              style: TextStyle(
                color: LoreTheme.parchment.withOpacity(0.8),
                fontFamily: LoreTheme.serifFont,
                height: 1.5,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text('BACKSTORY', style: LoreTheme.labelStyle(fontSize: 10)),
          const SizedBox(height: 6),
          Text(
            widget.character.backstory.isNotEmpty
                ? widget.character.backstory
                : 'Their story has yet to be written...',
            style: TextStyle(
              color: widget.character.backstory.isNotEmpty
                  ? LoreTheme.parchment.withOpacity(0.8)
                  : LoreTheme.warmBrown.withOpacity(0.5),
              fontFamily: LoreTheme.serifFont,
              height: 1.6,
              fontSize: 14,
              fontStyle: widget.character.backstory.isEmpty
                  ? FontStyle.italic
                  : FontStyle.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSummary(BuildContext context) {
    final totalXP = widget.character.skills.values.fold<int>(
      0,
      (sum, s) => sum + s.experience,
    );
    final relationshipCount = widget.character.relationships.length;
    final avgAffinity = widget.character.relationships.isNotEmpty
        ? widget.character.relationships.values.fold<int>(0, (s, v) => s + v) ~/
              widget.character.relationships.length
        : 0;

    return Semantics(
      label: 'Character statistics summary',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: LoreTheme.glassmorphism(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('TOTAL XP', totalXP.toString(), Icons.star),
            _buildStatItem('BONDS', relationshipCount.toString(), Icons.people),
            _buildStatItem(
              'AVG AFFINITY',
              '${avgAffinity > 0 ? "+" : ""}$avgAffinity',
              Icons.favorite,
            ),
            _buildStatItem(
              'SKILLS',
              widget.character.skills.length.toString(),
              Icons.auto_awesome,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: LoreTheme.goldAccent.withOpacity(0.6), size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: LoreTheme.parchment,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: LoreTheme.serifFont,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: LoreTheme.warmBrown.withOpacity(0.5),
            fontSize: 9,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Semantics(
      header: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: LoreTheme.sectionTitle(fontSize: 16)),
          Divider(color: LoreTheme.warmBrown.withOpacity(0.2)),
        ],
      ),
    );
  }
}
