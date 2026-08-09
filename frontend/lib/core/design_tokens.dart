import 'package:flutter/material.dart';

import 'dark_theme.dart';

/// The one place colour, surface, spacing and grid geometry are decided.
///
/// Before this existed the same values were spelled out as hex literals in each
/// screen, which is how the app ended up with two identities at once: the theme
/// declared Culpeo Rust while every screen hardcoded a gold. Anything visual
/// belongs here so there is one answer rather than one per file.
///
/// The split that matters: **rust acts, gold measures.** Rust marks what the
/// user can do — primary buttons, the selected card, focus. Gold marks what the
/// machine reports — context lengths, memory figures, quantisation. Keeping
/// them apart means a number never looks like a button.
class CulpeoColors {
  CulpeoColors._();

  // --- Identity: rust acts -------------------------------------------------

  /// Primary action. Buttons, selected state, focus rings.
  static const Color action = DarkColors.primary; // #C1440E
  /// Hover and glow on top of [action].
  static const Color actionHover = DarkColors.hoverGlow; // #F2762E
  /// Quiet identity tint for large fills that must not shout.
  static Color get actionMuted => DarkColors.primary.withValues(alpha: 0.14);
  static Color get actionBorder => DarkColors.primary.withValues(alpha: 0.45);

  // --- Measurement: gold reports ------------------------------------------

  /// Readings the engine produced: context, tokens, throughput.
  static const Color metric = Color(0xFFC9A24A);

  /// Emphasised reading, and the sand-toned text on metric surfaces.
  static const Color metricBright = Color(0xFFDFC077);

  /// Palest gold, for metric text on dark panels.
  static const Color metricSoft = Color(0xFFEBD9A8);

  // --- Semantics ------------------------------------------------------------

  static const Color success = Color(0xFF76C893);
  static const Color warning = Color(0xFFFF7043);
  static const Color danger = Color(0xFFEF5350);
  static const Color info = Color(0xFF4DD0E1);

  /// Memory placement. These two read as a pair on the split bar, so they are
  /// deliberately far apart in hue: VRAM is the fast home, RAM the slow one.
  static const Color vram = Color(0xFF76C893);
  static const Color ram = Color(0xFFDFC077);

  // --- Surfaces -------------------------------------------------------------

  static Color get background => DarkColors.bg; // #0D0D0E
  /// Card and panel fill.
  static const Color panel = Color(0xFF16161D);

  /// Recessed fill inside a panel.
  static const Color inset = Color(0xFF0F0F12);

  static Color get textPrimary => DarkColors.textPrimary;
  static Color get textSecondary => DarkColors.textSecondary;
  static Color textMuted = const Color(0xFFFAF7F2).withValues(alpha: 0.45);
  static Color textFaint = const Color(0xFFFAF7F2).withValues(alpha: 0.28);

  static Color get hairline => const Color(0xFFFAF7F2).withValues(alpha: 0.06);
  static Color get hairlineStrong =>
      const Color(0xFFFAF7F2).withValues(alpha: 0.12);
}

/// Spacing, radii and the grid geometry the card screens share.
class CulpeoLayout {
  CulpeoLayout._();

  /// Widest a card may get before the grid adds a column. Marketplace and news
  /// both settled on this; the engine now matches so the three read as one app.
  static const double tileMaxWidth = 360;
  static const double gridGap = 12;

  static const double cardRadius = 12;
  static const double pillRadius = 8;

  static const double cardPadding = 14;

  /// Left inset that lines page headers up across screens.
  static const double headerInset = 38;
}

/// The adaptive grid every card surface uses.
///
/// Columns follow the available width instead of a breakpoint table, which is
/// what keeps a narrow window from overflowing: the tile shrinks until a column
/// drops. [extent] is the fixed card height, so rows stay aligned even when one
/// card's text is shorter than its neighbour's.
SliverGridDelegateWithMaxCrossAxisExtent culpeoGridDelegate({
  required double extent,
  double maxTileWidth = CulpeoLayout.tileMaxWidth,
  double gap = CulpeoLayout.gridGap,
}) {
  return SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: maxTileWidth,
    mainAxisExtent: extent,
    crossAxisSpacing: gap,
    mainAxisSpacing: gap,
  );
}

/// Standard card surface: flat fill, hairline border, no shadow.
BoxDecoration culpeoPanelDecoration({bool selected = false}) {
  return BoxDecoration(
    color: CulpeoColors.panel,
    borderRadius: BorderRadius.circular(CulpeoLayout.cardRadius),
    border: Border.all(
      color: selected ? CulpeoColors.actionBorder : CulpeoColors.hairline,
      width: selected ? 1.4 : 1,
    ),
  );
}

/// Tinted chip used for a single reading or state.
BoxDecoration culpeoPillDecoration(Color color) {
  return BoxDecoration(
    color: color.withValues(alpha: 0.12),
    borderRadius: BorderRadius.circular(CulpeoLayout.pillRadius),
    border: Border.all(color: color.withValues(alpha: 0.34)),
  );
}
