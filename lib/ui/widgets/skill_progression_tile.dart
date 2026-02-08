import 'package:flutter/material.dart';
import '../../core/models/character.dart';
import '../theme/lore_theme.dart';

/// Enhanced skill progression tile with animated XP bar,
/// tier name display, and accessibility support.
class SkillProgressionTile extends StatefulWidget {
  final Skill skill;
  final bool animate;

  const SkillProgressionTile({
    super.key,
    required this.skill,
    this.animate = true,
  });

  @override
  State<SkillProgressionTile> createState() => _SkillProgressionTileState();
}

class _SkillProgressionTileState extends State<SkillProgressionTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    final targetProgress = (widget.skill.experience % 100) / 100.0;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _progressAnimation = Tween<double>(
      begin: 0,
      end: targetProgress,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(SkillProgressionTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.skill.experience != widget.skill.experience) {
      final newProgress = (widget.skill.experience % 100) / 100.0;
      _progressAnimation =
          Tween<double>(
            begin: _progressAnimation.value,
            end: newProgress,
          ).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
          );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getTierName(int level) {
    const tiers = [
      'Null',
      'Novice',
      'Apprentice',
      'Skilled',
      'Expert',
      'Master',
      'Divine',
    ];
    if (level >= 0 && level < tiers.length) return tiers[level];
    return 'Unknown';
  }

  Color _getTierColor(int level) {
    const colors = [
      Color(0xFF616161), // Null - grey
      Color(0xFF8D6E63), // Novice - brown
      Color(0xFF66BB6A), // Apprentice - green
      Color(0xFF42A5F5), // Skilled - blue
      Color(0xFFAB47BC), // Expert - purple
      Color(0xFFFFB300), // Master - gold
      Color(0xFFE040FB), // Divine - magenta
    ];
    if (level >= 0 && level < colors.length) return colors[level];
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final tierName = _getTierName(widget.skill.currentLevel);
    final tierColor = _getTierColor(widget.skill.currentLevel);
    final isMaxLevel = widget.skill.currentLevel >= widget.skill.maxPotential;

    return Semantics(
      label:
          '${widget.skill.name}: $tierName, level ${widget.skill.currentLevel} '
          'of ${widget.skill.maxPotential}, '
          '${widget.skill.experience % 100} of 100 experience points',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Skill name
                Expanded(
                  child: Text(
                    widget.skill.name,
                    style: const TextStyle(
                      color: LoreTheme.parchment,
                      fontFamily: LoreTheme.serifFont,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                // Tier badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: tierColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: tierColor.withOpacity(0.4),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    tierName,
                    style: TextStyle(
                      color: tierColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      fontFamily: LoreTheme.serifFont,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Level indicator
                Text(
                  '${widget.skill.currentLevel}/${widget.skill.maxPotential}',
                  style: TextStyle(
                    color: LoreTheme.lightBrown.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Animated progress bar
            AnimatedBuilder(
              listenable: _progressAnimation,
              builder: (context, _) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(
                    children: [
                      // Background
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: LoreTheme.deepBrown.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      // Progress fill
                      FractionallySizedBox(
                        widthFactor: isMaxLevel
                            ? 1.0
                            : _progressAnimation.value,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [tierColor.withOpacity(0.6), tierColor],
                            ),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: tierColor.withOpacity(0.3),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            // XP text
            Text(
              isMaxLevel
                  ? 'MAX POTENTIAL REACHED'
                  : 'XP: ${widget.skill.experience % 100} / 100',
              style: TextStyle(
                color: isMaxLevel
                    ? LoreTheme.goldAccent.withOpacity(0.8)
                    : LoreTheme.warmBrown.withOpacity(0.6),
                fontSize: 10,
                fontFamily: LoreTheme.serifFont,
                fontStyle: isMaxLevel ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reusable animated builder (same as in story_chat_view).
class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;

  const AnimatedBuilder({
    super.key,
    required Animation<double> listenable,
    required this.builder,
  }) : super(listenable: listenable);

  @override
  Widget build(BuildContext context) {
    return builder(context, null);
  }
}
