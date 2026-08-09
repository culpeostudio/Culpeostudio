import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// A card in the adaptive grid.
///
/// The height is fixed by the grid delegate rather than by the content, so
/// every card in a row ends on the same line. Content that varies in length
/// therefore has to be given a slot instead of being allowed to push: see
/// [CulpeoCardSlot].
class CulpeoGridTile extends StatelessWidget {
  const CulpeoGridTile({
    super.key,
    required this.child,
    this.onTap,
    this.selected = false,
    this.padding = const EdgeInsets.all(CulpeoLayout.cardPadding),
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool selected;
  final EdgeInsets padding;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final surface = Container(
      padding: padding,
      decoration: culpeoPanelDecoration(selected: selected),
      child: child,
    );
    if (onTap == null) {
      return Semantics(label: semanticLabel, child: surface);
    }
    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(CulpeoLayout.cardRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(CulpeoLayout.cardRadius),
          hoverColor: CulpeoColors.action.withValues(alpha: 0.06),
          child: surface,
        ),
      ),
    );
  }
}

/// Reserves a fixed height for a piece of card content.
///
/// Without this a card whose title wraps to two lines would push its pills out
/// of the fixed tile height and clip them. Giving each region a slot keeps the
/// rows of a grid visually aligned.
class CulpeoCardSlot extends StatelessWidget {
  const CulpeoCardSlot({super.key, required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Align(alignment: Alignment.centerLeft, child: child),
    );
  }
}

/// One reading, with an icon and a colour that says what kind of reading it is.
class CulpeoStatPill extends StatelessWidget {
  const CulpeoStatPill({
    super.key,
    required this.icon,
    required this.label,
    this.color,
    this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback? onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final tone = color ?? CulpeoColors.metric;
    Widget pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: culpeoPillDecoration(tone),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: tone, size: 13),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: tone,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    if (tooltip != null) pill = Tooltip(message: tooltip!, child: pill);
    if (onTap == null) return pill;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(CulpeoLayout.pillRadius),
      child: pill,
    );
  }
}

/// Small uppercase marker for a fixed fact, such as which prebuilt binary is
/// running. Deliberately quieter than a stat pill: it is an attribute, not a
/// measurement.
class CulpeoBadge extends StatelessWidget {
  const CulpeoBadge({
    super.key,
    required this.label,
    this.color,
    this.icon,
    this.tooltip,
  });

  final String label;
  final Color? color;
  final IconData? icon;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final tone = color ?? CulpeoColors.textMuted;
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: tone.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: tone),
            const SizedBox(width: 4),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: tone,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
    return tooltip == null ? badge : Tooltip(message: tooltip!, child: badge);
  }
}

/// One segment of a [CulpeoSplitBar].
class CulpeoSplitSegment {
  const CulpeoSplitSegment({
    required this.bytes,
    required this.color,
    required this.label,
  });

  final int bytes;
  final Color color;
  final String label;
}

/// Shows how a total is divided, as one bar rather than a set of numbers.
///
/// This exists for memory placement: whether a model sits in VRAM or spills
/// into system RAM is the difference between fast and slow, and the user is
/// asked to decide it. A row of figures makes that decision abstract; a bar
/// makes the proportion immediate.
class CulpeoSplitBar extends StatelessWidget {
  const CulpeoSplitBar({
    super.key,
    required this.segments,
    this.height = 8,
    this.showLegend = true,
  });

  final List<CulpeoSplitSegment> segments;
  final double height;
  final bool showLegend;

  @override
  Widget build(BuildContext context) {
    final visible = segments.where((s) => s.bytes > 0).toList();
    final total = visible.fold<int>(0, (sum, s) => sum + s.bytes);
    if (total <= 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: SizedBox(
            height: height,
            child: Row(
              children: [
                for (final segment in visible)
                  Expanded(
                    flex: segment.bytes,
                    child: Tooltip(
                      message: segment.label,
                      child: ColoredBox(color: segment.color),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (showLegend) ...[
          const SizedBox(height: 7),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              for (final segment in visible)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: segment.color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      segment.label,
                      style: TextStyle(
                        color: CulpeoColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ],
    );
  }
}
