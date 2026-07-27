import 'dart:ui';

import 'package:flutter/material.dart';

import '../l10n/remaining_ui_strings.dart';

/// The rollout phase the platform is currently in. Modules that belong to a
/// later phase are locked with a [PhaseLockOverlay] so users cannot use a
/// feature that is not part of the current phase yet.
const int kCurrentPhase = 1;

const Color _kGold = Color(0xFFC9A24A);

/// Wraps a module's UI and makes the whole screen unusable: the real content is
/// kept mounted only as a blurred, dimmed preview that cannot be clicked, typed
/// into, or tab-focused, and a full-cover barrier explains that the feature is
/// reserved for a later rollout phase.
class PhaseLockOverlay extends StatelessWidget {
  const PhaseLockOverlay({
    super.key,
    required this.phase,
    required this.feature,
    required this.child,
  });

  /// The rollout phase this module is planned for (e.g. 3 or 4).
  final int phase;

  /// Human-readable subject of the sentence, e.g. 'Das Training'.
  final String feature;

  /// The original, interactive screen content – shown only as a locked preview.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Real UI as an unreachable preview: removed from pointer AND focus
        // handling so nothing on it can be clicked, typed into, or tabbed to.
        Positioned.fill(
          child: ExcludeFocus(
            child: IgnorePointer(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Opacity(opacity: 0.4, child: child),
              ),
            ),
          ),
        ),
        // Full-cover barrier that swallows every gesture.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
            child: Container(
              color: Colors.black.withValues(alpha: 0.55),
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _lockCard(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _lockCard() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 440),
      padding: const EdgeInsets.fromLTRB(28, 30, 28, 28),
      decoration: BoxDecoration(
        color: const Color(0xFF16161D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kGold.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _kGold.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              color: _kGold,
              size: 30,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _kGold.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              remainingUiText('phaseLock.badge', {'phase': '$phase'}),
              style: const TextStyle(
                color: _kGold,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            remainingUiText('phaseLock.title'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            remainingUiText('phaseLock.description', {
              'feature': feature,
              'phase': '$phase',
              'currentPhase': '$kCurrentPhase',
            }),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.62),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
