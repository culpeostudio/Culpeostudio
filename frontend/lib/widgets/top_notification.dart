import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';

/// Shows a compact, automatically dismissing notification at the top of the
/// app. A new notification replaces the previous one, so rapid actions do not
/// leave a stack of stale messages on screen.
void showTopNotification(
  BuildContext context,
  String message, {
  Color? color,
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 4),
}) {
  if (!context.mounted) return;

  final overlay = Overlay.of(context, rootOverlay: true);
  _activeEntry?.remove();

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => _TopNotificationCard(
      message: message,
      accentColor: color,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
      onDismissed: () {
        if (entry.mounted) entry.remove();
        if (identical(_activeEntry, entry)) _activeEntry = null;
      },
    ),
  );

  _activeEntry = entry;
  overlay.insert(entry);
}

OverlayEntry? _activeEntry;

class _TopNotificationCard extends StatefulWidget {
  const _TopNotificationCard({
    required this.message,
    required this.accentColor,
    required this.duration,
    required this.onDismissed,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final Color? accentColor;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Duration duration;
  final VoidCallback onDismissed;

  @override
  State<_TopNotificationCard> createState() => _TopNotificationCardState();
}

class _TopNotificationCardState extends State<_TopNotificationCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  Timer? _dismissTimer;
  var _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.22),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
    _dismissTimer = Timer(widget.duration, _dismiss);
  }

  Future<void> _dismiss() async {
    if (_isDismissing) return;
    _isDismissing = true;
    _dismissTimer?.cancel();
    await _controller.reverse();
    if (mounted) widget.onDismissed();
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor ?? AppColors.accent(Brightness.dark);
    final background = AppColors.surface(Brightness.dark);
    final foreground = AppColors.textPrimary(Brightness.dark);
    final isError = accent.r > accent.g * 1.18;
    final isSuccess = accent.g > accent.r * 1.12;
    final icon = isError
        ? Icons.error_outline_rounded
        : isSuccess
        ? Icons.check_circle_outline_rounded
        : Icons.info_outline_rounded;

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: SlideTransition(
          position: _slide,
          child: FadeTransition(
            opacity: _controller,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 560),
              margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: accent.withValues(alpha: 0.48)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.32),
                    blurRadius: 26,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 13, 8, 13),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: accent, size: 22),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          widget.message,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: foreground,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      if (widget.actionLabel != null && widget.onAction != null)
                        TextButton(
                          onPressed: () {
                            widget.onAction!();
                            _dismiss();
                          },
                          child: Text(widget.actionLabel!),
                        ),
                      IconButton(
                        tooltip: tr('common.close'),
                        onPressed: _dismiss,
                        icon: Icon(Icons.close_rounded, color: foreground),
                        iconSize: 19,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
