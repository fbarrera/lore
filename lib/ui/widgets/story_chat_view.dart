import 'package:flutter/material.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import '../../core/services/ai_service.dart';
import '../../core/models/story.dart';
import '../../core/services/lore_llm_provider.dart';
import '../theme/lore_theme.dart';

/// Enhanced chat view integrating Flutter AI Toolkit's [LlmChatView]
/// with custom narrator/user bubble styling, typing indicators,
/// and accessibility support.
class StoryChatView extends StatefulWidget {
  final Story story;
  final AIService aiService;
  final Function(String) onMessageSent;

  const StoryChatView({
    super.key,
    required this.story,
    required this.aiService,
    required this.onMessageSent,
  });

  @override
  State<StoryChatView> createState() => _StoryChatViewState();
}

class _StoryChatViewState extends State<StoryChatView>
    with SingleTickerProviderStateMixin {
  late final LoreLlmProvider _provider;
  late final AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _provider = LoreLlmProvider(widget.aiService, widget.story);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeController,
      child: Semantics(
        label: 'Story chat interface for ${widget.story.title}',
        child: LlmChatView(
          provider: _provider,
          style: LlmChatViewStyle(
            backgroundColor: Colors.transparent,
            progressIndicatorColor: LoreTheme.goldAccent,
            userMessageStyle: UserMessageStyle(
              textStyle: LoreTheme.userText(),
              decoration: LoreTheme.userBubble(),
            ),
            llmMessageStyle: LlmMessageStyle(
              icon: Icons.auto_stories,
              iconColor: LoreTheme.goldAccent,
              iconDecoration: BoxDecoration(
                color: LoreTheme.deepBrown,
                shape: BoxShape.circle,
                border: Border.all(
                  color: LoreTheme.goldAccent.withOpacity(0.3),
                ),
              ),
              decoration: LoreTheme.narratorBubble(),
            ),
            chatInputStyle: ChatInputStyle(
              textStyle: LoreTheme.userText(fontSize: 14),
              hintText: 'What do you do next?',
              hintStyle: TextStyle(
                color: LoreTheme.warmBrown.withOpacity(0.5),
                fontFamily: LoreTheme.serifFont,
                fontStyle: FontStyle.italic,
              ),
              backgroundColor: LoreTheme.inkBlack,
              decoration: BoxDecoration(
                color: LoreTheme.inkBlack.withOpacity(0.8),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: LoreTheme.warmBrown.withOpacity(0.3)),
              ),
            ),
            submitButtonStyle: ActionButtonStyle(
              icon: Icons.send_rounded,
              iconColor: LoreTheme.goldAccent,
              iconDecoration: BoxDecoration(
                color: LoreTheme.deepBrown,
                shape: BoxShape.circle,
                border: Border.all(
                  color: LoreTheme.goldAccent.withOpacity(0.3),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A standalone typing indicator widget with animated dots.
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      ),
    );
    _animations = _controllers.map((c) {
      return Tween<double>(
        begin: 0,
        end: -8,
      ).animate(CurvedAnimation(parent: c, curve: Curves.easeInOut));
    }).toList();

    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'The narrator is composing a response',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: LoreTheme.narratorBubble(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_stories,
              size: 14,
              color: LoreTheme.goldAccent.withOpacity(0.6),
            ),
            const SizedBox(width: 8),
            ...List.generate(3, (i) {
              return AnimatedBuilder(
                listenable: _animations[i],
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _animations[i].value),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: LoreTheme.goldAccent.withOpacity(0.7),
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// Animated builder helper for typing indicator dots.
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

/// A loading shimmer effect for story content.
class StoryLoadingShimmer extends StatefulWidget {
  const StoryLoadingShimmer({super.key});

  @override
  State<StoryLoadingShimmer> createState() => _StoryLoadingShimmerState();
}

class _StoryLoadingShimmerState extends State<StoryLoadingShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: LoreTheme.narratorBubble(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(3, (i) {
              final widthFactor = [0.9, 0.7, 0.5][i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  height: 12,
                  width: 200 * widthFactor,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: LinearGradient(
                      colors: [
                        LoreTheme.warmBrown.withOpacity(0.1),
                        LoreTheme.warmBrown.withOpacity(0.3),
                        LoreTheme.warmBrown.withOpacity(0.1),
                      ],
                      stops: [
                        (_controller.value - 0.3).clamp(0.0, 1.0),
                        _controller.value,
                        (_controller.value + 0.3).clamp(0.0, 1.0),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
