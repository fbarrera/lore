import 'package:flutter/material.dart';
import '../theme/lore_theme.dart';

/// Custom overlay notification that bypasses ScaffoldMessenger/SnackBar
/// to avoid the Windows accessibility_plugin viewId error.
class LoreNotification {
  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(context);
    late final OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _LoreNotificationWidget(
        message: message,
        isError: isError,
        duration: duration,
        onDismiss: () => entry.remove(),
      ),
    );

    overlay.insert(entry);
  }
}

class _LoreNotificationWidget extends StatefulWidget {
  final String message;
  final bool isError;
  final Duration duration;
  final VoidCallback onDismiss;

  const _LoreNotificationWidget({
    required this.message,
    required this.isError,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_LoreNotificationWidget> createState() =>
      _LoreNotificationWidgetState();
}

class _LoreNotificationWidgetState extends State<_LoreNotificationWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
    Future.delayed(widget.duration, _dismiss);
  }

  void _dismiss() {
    if (!mounted) return;
    _controller.reverse().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 24,
      left: 24,
      right: 24,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: ExcludeSemantics(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: widget.isError
                      ? const Color(0xFF3D1515)
                      : LoreTheme.deepBrown,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.isError
                        ? Colors.red.withOpacity(0.4)
                        : LoreTheme.goldAccent.withOpacity(0.4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.isError ? Icons.error_outline : Icons.check_circle,
                      color: widget.isError
                          ? Colors.red.shade300
                          : LoreTheme.goldAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: TextStyle(
                          color: LoreTheme.parchment,
                          fontFamily: LoreTheme.serifFont,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _dismiss,
                      child: Icon(
                        Icons.close,
                        color: LoreTheme.warmBrown.withOpacity(0.6),
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
