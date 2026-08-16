import 'dart:async';

import 'package:flutter/material.dart';

import './app_strings.dart';
import './app_theme.dart';
import './design_tokens.dart';

/// A recovery route offered alongside a notification.
///
/// [actionLabel]/[onAction] stay the shorthand for the common single-button
/// case. This is for the notifications that have to offer a real choice - a
/// failed model start can be retried, handed to another model, or rebound -
/// which get their own row so three buttons never squeeze the message out.
class TopNotificationAction {
  const TopNotificationAction({
    required this.label,
    required this.onPressed,
    this.primary = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool primary;
}

void showTopNotification(
  BuildContext context,
  String message, {
  Color? color,
  String? actionLabel,
  VoidCallback? onAction,
  List<TopNotificationAction> actions = const <TopNotificationAction>[],
  Duration duration = const Duration(seconds: 4),
}) {
  if (!context.mounted) return;

  final overlay = Overlay.of(context, rootOverlay: true);
  _active?.remove();
  _active = null;

  late final _ActiveNotification active;
  final entry = OverlayEntry(
    builder: (context) => _TopNotificationCard(
      message: message,
      accentColor: color,
      actionLabel: actionLabel,
      onAction: onAction,
      actions: actions,
      duration: duration,
      onDismissed: () {
        active.remove();
        if (identical(_active, active)) _active = null;
      },
    ),
  );
  active = _ActiveNotification(entry);

  _active = active;
  overlay.insert(entry);
}

_ActiveNotification? _active;

/// Owns one overlay entry and guarantees it is removed exactly once.
///
/// Two notifications in quick succession used to collide: showing the second
/// removed the first entry directly, and when the first card's dismiss timer
/// then finished its exit animation it removed the same entry again.
/// `OverlayEntry.mounted` is no guard against that - a removed entry can stay
/// mounted until the overlay rebuilds - so the state is tracked here.
class _ActiveNotification {
  _ActiveNotification(this.entry);

  final OverlayEntry entry;
  var _removed = false;

  void remove() {
    if (_removed) return;
    _removed = true;
    entry.remove();
  }
}

class _TopNotificationCard extends StatefulWidget {
  const _TopNotificationCard({
    required this.message,
    required this.accentColor,
    required this.duration,
    required this.onDismissed,
    this.actionLabel,
    this.onAction,
    this.actions = const <TopNotificationAction>[],
  });

  final String message;
  final Color? accentColor;
  final String? actionLabel;
  final VoidCallback? onAction;
  final List<TopNotificationAction> actions;
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

  /// Callers pass whatever colour is handy (`Colors.redAccent`,
  /// `Colors.green`, a one-off hex) as a rough "what kind of thing is this"
  /// hint. Painting that raw next to the muted rust/sand palette is what made
  /// the card read as a loud, off-brand alert box - so the hue is only used to
  /// classify the notification, and the actual paint always comes from the
  /// design tokens.
  Color _semanticAccent(Color? hint) {
    if (hint == null) return AppColors.accent;
    final r = hint.r, g = hint.g, b = hint.b;
    if (g > r * 1.05 && g > b * 1.05) return CulpeoColors.success;
    if (r > b * 1.6 && g > b * 1.3 && r > g * 1.05) return CulpeoColors.warning;
    if (r > g * 1.15 && r > b * 1.15) return CulpeoColors.danger;
    return AppColors.accent;
  }

  Widget _actionButton(TopNotificationAction action) {
    void run() {
      action.onPressed();
      _dismiss();
    }

    return action.primary
        ? FilledButton.tonal(onPressed: run, child: Text(action.label))
        : TextButton(onPressed: run, child: Text(action.label));
  }

  @override
  Widget build(BuildContext context) {
    final accent = _semanticAccent(widget.accentColor);
    final background = AppColors.surface;
    final foreground = AppColors.textPrimary;
    final isError = accent == CulpeoColors.danger;
    final isSuccess = accent == CulpeoColors.success;
    final isWarning = accent == CulpeoColors.warning;
    final icon = isError
        ? Icons.error_outline_rounded
        : isSuccess
        ? Icons.check_circle_outline_rounded
        : isWarning
        ? Icons.warning_amber_rounded
        : Icons.info_outline_rounded;

    // No IgnorePointer here. An overlay entry is laid out at full screen size,
    // and an ancestor IgnorePointer(ignoring: true) aborts the hit test before
    // it ever reaches the card - a nested IgnorePointer(ignoring: false) cannot
    // undo that, which is what left the action and close buttons dead. SafeArea
    // and Align do not absorb hits themselves, so clicks beside the card still
    // reach the app while the card stays interactive.
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        heightFactor: 1.0,
        child: SlideTransition(
          position: _slide,
          child: FadeTransition(
            opacity: _controller,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 560),
              margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: CulpeoColors.hairlineStrong),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Material(
                  color: Colors.transparent,
                  child: IntrinsicHeight(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(width: 3, color: accent),
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(13, 12, 8, 12),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 26,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        color: accent.withValues(alpha: 0.14),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        icon,
                                        color: accent,
                                        size: 15,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Flexible(
                                      child: Text(
                                        widget.message,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: foreground,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                    if (widget.actionLabel != null &&
                                        widget.onAction != null)
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
                                      icon: Icon(
                                        Icons.close_rounded,
                                        color: foreground.withValues(
                                          alpha: 0.7,
                                        ),
                                      ),
                                      iconSize: 18,
                                    ),
                                  ],
                                ),
                                if (widget.actions.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 38,
                                      top: 4,
                                    ),
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        for (final action in widget.actions)
                                          _actionButton(action),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
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
