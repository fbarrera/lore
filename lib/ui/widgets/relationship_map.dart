import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/models/character.dart';
import '../theme/lore_theme.dart';

/// Visual relationship map showing character connections and affinity levels.
/// Renders as a radial graph with the main character at center.
class RelationshipMap extends StatefulWidget {
  final Character character;
  final Map<String, String> characterNames; // id -> name mapping
  final void Function(String characterId)? onCharacterTap;

  const RelationshipMap({
    super.key,
    required this.character,
    this.characterNames = const {},
    this.onCharacterTap,
  });

  @override
  State<RelationshipMap> createState() => _RelationshipMapState();
}

class _RelationshipMapState extends State<RelationshipMap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _affinityColor(int affinity) {
    if (affinity > 50) return LoreTheme.affinityPositive;
    if (affinity > 20) return LoreTheme.affinityPositive.withOpacity(0.7);
    if (affinity > -20) return LoreTheme.affinityNeutral;
    if (affinity > -50) return LoreTheme.affinityNegative.withOpacity(0.7);
    return LoreTheme.affinityNegative;
  }

  String _affinityLabel(int affinity) {
    if (affinity > 75) return 'Devoted';
    if (affinity > 50) return 'Allied';
    if (affinity > 20) return 'Friendly';
    if (affinity > -20) return 'Neutral';
    if (affinity > -50) return 'Hostile';
    if (affinity > -75) return 'Rival';
    return 'Nemesis';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.character.relationships.isEmpty) {
      return Semantics(
        label: 'No relationships formed yet',
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: LoreTheme.glassmorphism(),
          child: Column(
            children: [
              Icon(
                Icons.people_outline,
                size: 48,
                color: LoreTheme.warmBrown.withOpacity(0.4),
              ),
              const SizedBox(height: 12),
              Text(
                'No significant bonds formed yet.',
                style: TextStyle(
                  color: LoreTheme.warmBrown.withOpacity(0.6),
                  fontStyle: FontStyle.italic,
                  fontFamily: LoreTheme.serifFont,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Relationships will develop through story interactions.',
                style: TextStyle(
                  color: LoreTheme.warmBrown.withOpacity(0.4),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      builder: (context, _) {
        return Column(
          children: [
            // Radial visualization
            SizedBox(
              height: 220,
              child: CustomPaint(
                painter: _RelationshipPainter(
                  character: widget.character,
                  characterNames: widget.characterNames,
                  progress: _controller.value,
                ),
                size: const Size(double.infinity, 220),
              ),
            ),
            const SizedBox(height: 16),
            // List view of relationships
            ...widget.character.relationships.entries.map((entry) {
              final name = widget.characterNames[entry.key] ?? entry.key;
              final affinity = entry.value;
              final color = _affinityColor(affinity);
              final label = _affinityLabel(affinity);

              return Semantics(
                label: '$name: $label, affinity $affinity',
                child: GestureDetector(
                  onTap: widget.onCharacterTap != null
                      ? () => widget.onCharacterTap!(entry.key)
                      : null,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: color.withOpacity(0.2),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Avatar
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: color.withOpacity(0.2),
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontFamily: LoreTheme.serifFont,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Name and label
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  color: LoreTheme.parchment,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: LoreTheme.serifFont,
                                ),
                              ),
                              Text(
                                label,
                                style: TextStyle(
                                  color: color.withOpacity(0.8),
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Affinity bar
                        SizedBox(
                          width: 80,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${affinity > 0 ? "+" : ""}$affinity',
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: SizedBox(
                                  height: 4,
                                  child: LinearProgressIndicator(
                                    value: (affinity + 100) / 200,
                                    backgroundColor: LoreTheme.deepBrown
                                        .withOpacity(0.5),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      color,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

/// Animated builder helper.
class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;

  const AnimatedBuilder({
    super.key,
    required Animation<double> animation,
    required this.builder,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, null);
  }
}

/// Custom painter for the radial relationship visualization.
class _RelationshipPainter extends CustomPainter {
  final Character character;
  final Map<String, String> characterNames;
  final double progress;

  _RelationshipPainter({
    required this.character,
    required this.characterNames,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 30;

    // Draw center character
    final centerPaint = Paint()
      ..color = LoreTheme.goldAccent.withOpacity(0.3 * progress)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 24 * progress, centerPaint);

    final centerBorderPaint = Paint()
      ..color = LoreTheme.goldAccent.withOpacity(0.6 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, 24 * progress, centerBorderPaint);

    // Draw center label
    final centerTextPainter = TextPainter(
      text: TextSpan(
        text: character.name.isNotEmpty ? character.name[0].toUpperCase() : '?',
        style: TextStyle(
          color: LoreTheme.goldAccent.withOpacity(progress),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    centerTextPainter.paint(
      canvas,
      center -
          Offset(centerTextPainter.width / 2, centerTextPainter.height / 2),
    );

    // Draw relationship nodes
    final entries = character.relationships.entries.toList();
    for (int i = 0; i < entries.length; i++) {
      final angle = (2 * math.pi * i / entries.length) - math.pi / 2;
      final affinity = entries[i].value;
      final name = characterNames[entries[i].key] ?? entries[i].key;

      // Distance based on affinity (closer = higher affinity)
      final distance = radius * (1 - (affinity + 100) / 400) * progress;
      final nodeCenter = Offset(
        center.dx + math.cos(angle) * distance,
        center.dy + math.sin(angle) * distance,
      );

      // Connection line
      Color lineColor;
      if (affinity > 20) {
        lineColor = LoreTheme.affinityPositive;
      } else if (affinity < -20) {
        lineColor = LoreTheme.affinityNegative;
      } else {
        lineColor = LoreTheme.affinityNeutral;
      }

      final linePaint = Paint()
        ..color = lineColor.withOpacity(0.3 * progress)
        ..strokeWidth = (affinity.abs() / 50).clamp(0.5, 3.0)
        ..style = PaintingStyle.stroke;
      canvas.drawLine(center, nodeCenter, linePaint);

      // Node circle
      final nodePaint = Paint()
        ..color = lineColor.withOpacity(0.2 * progress)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(nodeCenter, 16 * progress, nodePaint);

      final nodeBorderPaint = Paint()
        ..color = lineColor.withOpacity(0.5 * progress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(nodeCenter, 16 * progress, nodeBorderPaint);

      // Node label
      final textPainter = TextPainter(
        text: TextSpan(
          text: name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            color: lineColor.withOpacity(progress),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        nodeCenter - Offset(textPainter.width / 2, textPainter.height / 2),
      );

      // Name label below node
      final namePainter = TextPainter(
        text: TextSpan(
          text: name.length > 8 ? '${name.substring(0, 8)}...' : name,
          style: TextStyle(
            color: LoreTheme.lightBrown.withOpacity(0.7 * progress),
            fontSize: 9,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      namePainter.paint(
        canvas,
        Offset(
          nodeCenter.dx - namePainter.width / 2,
          nodeCenter.dy + 20 * progress,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RelationshipPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.character != character;
  }
}
