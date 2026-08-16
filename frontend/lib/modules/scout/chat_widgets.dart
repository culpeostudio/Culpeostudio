import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/design_tokens.dart';

class HoverIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final double size;
  final Color? color;

  const HoverIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size = 18,
    this.color,
  });

  @override
  State<HoverIconButton> createState() => _HoverIconButtonState();
}

class _HoverIconButtonState extends State<HoverIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: IconButton(
        icon: Icon(
          widget.icon,
          color: _isHovered
              ? CulpeoColors.metric
              : (widget.color ?? Colors.white70),
          size: widget.size,
        ),
        tooltip: widget.tooltip,
        onPressed: widget.onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }
}

class ChatBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color themeColor;

  const ChatBadge({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          margin: const EdgeInsets.only(left: 6),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: themeColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: themeColor.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: themeColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.close, size: 10, color: Colors.white30),
            ],
          ),
        ),
      ),
    );
  }
}

/// Spark on its own switch, sitting left of the thinking pill. It used to be
/// the sixth segment of [ThinkingModeSliderButton], which read as "think this
/// hard" when what it actually changes is who answers: the agent loop, with
/// tools and file access. The thinking bar stays live next to it, because
/// Spark drives the same model and how hard that model thinks is still the
/// user's call.
///
/// On is rust like every other engaged control; off is the same quiet outline
/// the thinking bar wears, so the two read as one row of controls rather than
/// a switch bolted onto a bar.
class SparkModeButton extends StatefulWidget {
  const SparkModeButton({
    super.key,
    required this.active,
    required this.label,
    required this.tooltip,
    required this.themeColor,
    required this.onChanged,
    this.compact = false,
  });

  final bool active;
  final String label;
  final String tooltip;
  final Color themeColor;
  final ValueChanged<bool> onChanged;

  /// Icon-only, for panes too narrow to carry the label as well.
  final bool compact;

  static const double height = ThinkingModeSliderButton.barHeight;

  @override
  State<SparkModeButton> createState() => _SparkModeButtonState();
}

class _SparkModeButtonState extends State<SparkModeButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.active;
    final foreground = active
        ? Colors.white
        : (_hovered ? Colors.white : Colors.white60);

    return Tooltip(
      key: const Key('spark-mode-toggle'),
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => widget.onChanged(!active),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            height: SparkModeButton.height,
            padding: EdgeInsets.symmetric(horizontal: widget.compact ? 7 : 10),
            decoration: BoxDecoration(
              color: active
                  ? widget.themeColor.withValues(alpha: 0.16)
                  : Colors.white.withValues(alpha: _hovered ? 0.07 : 0.04),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: active
                    ? widget.themeColor.withValues(alpha: 0.75)
                    : Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.electric_bolt,
                  size: widget.compact ? 15 : 13,
                  color: foreground,
                ),
                if (!widget.compact) ...[
                  const SizedBox(width: 6),
                  // Gives way rather than blowing the row open if the label
                  // runs long in some language.
                  Flexible(
                    child: Text(
                      widget.label,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ThinkingModeOption {
  final String value;
  final String label;
  final IconData icon;

  final bool enabled;

  const ThinkingModeOption({
    required this.value,
    required this.label,
    required this.icon,
    this.enabled = true,
  });
}

/// A segmented pill, styled like the sidebar's module/chat/model switcher:
/// every option sits on the bar and a tap commits it directly, no popup.
/// Icon-only with a tooltip per segment - the composer doesn't have room to
/// spell out all five modes at once, so a ring around the active icon
/// carries the selection instead of a label. Agentic modes (agentic/agents)
/// keep the same violet accent the old popup used to flag them as a different
/// kind of option; Spark left the bar for [SparkModeButton], so it is no
/// longer one of them. The bar stays live while Spark runs - the level it
/// carries is the effort Spark's own turns are sent with.
///
/// Switching segments doesn't cross-fade the ring: the highlight is a
/// droplet that travels to the new segment, and while it's in flight the
/// remainder of the old one trails behind and is pulled back into it. See
/// [_DropletPainter] for the shape itself.
class ThinkingModeSliderButton extends StatefulWidget {
  const ThinkingModeSliderButton({
    super.key,
    required this.value,
    required this.options,
    required this.themeColor,
    required this.onChanged,
  });

  final String value;
  final List<ThinkingModeOption> options;
  final Color themeColor;
  final ValueChanged<String> onChanged;

  /// Fixed per-segment footprint (24px dot + 1px margin either side), which
  /// [_DropletPainter] shares so the highlight's centre lines up with its
  /// segment without measuring the render tree, plus the bar's own padding
  /// and height.
  static const double segmentWidth = 26;
  static const double barPadding = 3;
  static const double barHeight = 30;

  @override
  State<ThinkingModeSliderButton> createState() =>
      _ThinkingModeSliderButtonState();
}

class _ThinkingModeSliderButtonState extends State<ThinkingModeSliderButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _transition = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
    value: 1,
  );
  late String _previousValue = widget.value;

  int _indexOf(String value) {
    final index = widget.options.indexWhere((o) => o.value == value);
    return index < 0 ? 0 : index;
  }

  @override
  void didUpdateWidget(covariant ThinkingModeSliderButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _previousValue = oldWidget.value;
      _transition
        ..value = 0
        ..forward();
    }
  }

  @override
  void dispose() {
    _transition.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('thinking-mode-switcher'),
      height: ThinkingModeSliderButton.barHeight,
      padding: const EdgeInsets.symmetric(
        horizontal: ThinkingModeSliderButton.barPadding,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _transition,
              builder: (context, _) => CustomPaint(
                painter: _DropletPainter(
                  fromIndex: _indexOf(_previousValue),
                  toIndex: _indexOf(widget.value),
                  progress: _transition.value,
                  color: widget.themeColor,
                ),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final option in widget.options)
                _ThinkingSegment(
                  key: ValueKey('thinking-option-${option.value}'),
                  option: option,
                  selected: option.value == widget.value,
                  themeColor: widget.themeColor,
                  onTap: option.enabled
                      ? () => widget.onChanged(option.value)
                      : null,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Draws the selection highlight: an outlined droplet, resting on the
/// selected segment and travelling to the next one on a change.
///
/// At rest it's a single ring around the active icon - an outline plus a
/// whisper of fill, not a solid disc, so it marks the icon without
/// repainting it.
///
/// In flight ([fromIndex] != [toIndex], [progress] between 0 and 1) it's two
/// circles: the leading one runs ahead and grows, the trailing remnant
/// starts late, catches up and shrinks away. [_fuse] joins them into a
/// single outline whenever they're close enough to hold a neck, so the
/// remnant visibly stretches into the leader and is absorbed instead of one
/// blob fading out while another fades in. Past that reach the neck snaps -
/// which is what a real droplet does too, and it only happens on jumps of
/// more than one segment.
class _DropletPainter extends CustomPainter {
  const _DropletPainter({
    required this.fromIndex,
    required this.toIndex,
    required this.progress,
    required this.color,
  });

  final int fromIndex;
  final int toIndex;
  final double progress;
  final Color color;

  static const double _radius = 12;
  static const double _stroke = 1.4;

  /// Bezier handle length for the neck, and how far past the circles'
  /// intersection the neck grips them. Both are the usual values from the
  /// classic two-circle metaball construction.
  static const double _handleRate = 2.4;
  static const double _grip = 0.5;

  /// How far apart the two droplets can be, as a multiple of their radii,
  /// before a neck can no longer span them.
  static const double _bridgeReach = 1.3;

  /// Centre of [index]'s icon, in the painter's own coordinates. Those
  /// start inside the bar's padding - the same box the segment [Row] is
  /// laid out in - so the padding must not be counted again here.
  double _centerX(int index) =>
      index * ThinkingModeSliderButton.segmentWidth +
      ThinkingModeSliderButton.segmentWidth / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final shape = _shape(centerY);
    canvas.drawPath(shape, Paint()..color = color.withValues(alpha: 0.10));
    canvas.drawPath(
      shape,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke,
    );
  }

  Path _shape(double centerY) {
    final settled = fromIndex == toIndex || progress <= 0 || progress >= 1;
    if (settled) {
      final index = progress <= 0 ? fromIndex : toIndex;
      return Path()..addOval(
        Rect.fromCircle(
          center: Offset(_centerX(index), centerY),
          radius: _radius,
        ),
      );
    }

    // The leader leaves first and settles early, the remnant hangs back and
    // then rushes after it.
    final from = _centerX(fromIndex);
    final to = _centerX(toIndex);
    var leadX = from + (to - from) * Curves.easeOutCubic.transform(progress);
    var trailX = from + (to - from) * Curves.easeInCubic.transform(progress);
    final leadRadius = _radius * Curves.easeOut.transform(progress);
    final trailRadius = _radius * (1 - Curves.easeIn.transform(progress));

    if (leadRadius < 0.5) {
      return Path()..addOval(
        Rect.fromCircle(center: Offset(trailX, centerY), radius: trailRadius),
      );
    }
    if (trailRadius < 0.5) {
      return Path()..addOval(
        Rect.fromCircle(center: Offset(leadX, centerY), radius: leadRadius),
      );
    }

    // Over more than one segment those curves alone would pull the two so
    // far apart that no neck could span them, and the highlight would read
    // as one dot fading out beside another. Reeling them back in keeps it a
    // single stretched body all the way across: the remnant is dragged
    // along behind the leader and swallowed at the end.
    // A hair inside the reach, so rounding can't drop the neck for a frame.
    final reach = (leadRadius + trailRadius) * _bridgeReach * 0.99;
    final excess = (leadX - trailX).abs() - reach;
    if (excess > 0) {
      final step = (leadX > trailX ? -1 : 1) * excess / 2;
      leadX += step;
      trailX -= step;
    }

    final lead = Offset(leadX, centerY);
    final trail = Offset(trailX, centerY);
    return _fuse(lead, leadRadius, trail, trailRadius) ??
        (Path()
          ..addOval(Rect.fromCircle(center: lead, radius: leadRadius))
          ..addOval(Rect.fromCircle(center: trail, radius: trailRadius)));
  }

  /// The outline around two circles fused into one body: an arc of each
  /// circle joined by two curved necks. Returns null when they're too far
  /// apart to hold a neck - the caller then draws them as two separate
  /// droplets.
  Path? _fuse(Offset c1, double r1, Offset c2, double r2) {
    final span = (c2 - c1).distance;
    if (span > (r1 + r2) * _bridgeReach) return null;
    // One already swallowed the other: only the bigger one is visible.
    if (span <= (r1 - r2).abs()) {
      return Path()..addOval(
        Rect.fromCircle(center: r1 >= r2 ? c1 : c2, radius: math.max(r1, r2)),
      );
    }

    // Half-angle from the centre line to where the circles cross, zero once
    // they've pulled apart and only the neck still connects them.
    final overlapping = span < r1 + r2;
    final cross1 = overlapping ? _angle(r1, span, r2) : 0.0;
    final cross2 = overlapping ? _angle(r2, span, r1) : 0.0;
    final axis = math.atan2(c2.dy - c1.dy, c2.dx - c1.dx);
    final spread = math.acos(((r1 - r2) / span).clamp(-1.0, 1.0));

    final a1 = axis + cross1 + (spread - cross1) * _grip;
    final b1 = axis - cross1 - (spread - cross1) * _grip;
    final a2 = axis + math.pi - cross2 - (math.pi - cross2 - spread) * _grip;
    final b2 = axis - math.pi + cross2 + (math.pi - cross2 - spread) * _grip;

    final p1a = c1 + _dir(a1) * r1;
    final p1b = c1 + _dir(b1) * r1;
    final p2a = c2 + _dir(a2) * r2;
    final p2b = c2 + _dir(b2) * r2;

    // Necks thin out as the droplets separate, and stay short while they're
    // still mostly one blob.
    var pull = math.min(_grip * _handleRate, (p1a - p2a).distance / (r1 + r2));
    pull *= math.min(1.0, span * 2 / (r1 + r2));
    final h1 = r1 * pull;
    final h2 = r2 * pull;

    final path = Path()..moveTo(p1a.dx, p1a.dy);
    _neck(path, p1a, a1, h1, p2a, a2, h2);
    // Around the far side of c2, from the near neck to the other one.
    path.arcTo(Rect.fromCircle(center: c2, radius: r2), a2, b2 - a2, false);
    _neck(path, p2b, b2, h2, p1b, b1, h1);
    // ...and the long way back around c1, closing the outline.
    path.arcTo(
      Rect.fromCircle(center: c1, radius: r1),
      b1,
      a1 - b1 - 2 * math.pi,
      false,
    );
    return path..close();
  }

  /// One side of the neck between two droplets: it leaves [from] along that
  /// circle's tangent and arrives at [to] along the other's, so the outline
  /// pinches inward instead of cornering.
  void _neck(
    Path path,
    Offset from,
    double fromAngle,
    double fromHandle,
    Offset to,
    double toAngle,
    double toHandle,
  ) {
    final c1 = from + _dir(fromAngle - math.pi / 2) * fromHandle;
    final c2 = to + _dir(toAngle + math.pi / 2) * toHandle;
    path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, to.dx, to.dy);
  }

  /// Half-angle at the centre of the circle with radius [r], in a triangle
  /// whose other sides are [span] and [other].
  double _angle(double r, double span, double other) => math.acos(
    ((r * r + span * span - other * other) / (2 * r * span)).clamp(-1.0, 1.0),
  );

  Offset _dir(double angle) => Offset(math.cos(angle), math.sin(angle));

  @override
  bool shouldRepaint(_DropletPainter old) =>
      old.fromIndex != fromIndex ||
      old.toIndex != toIndex ||
      old.progress != progress ||
      old.color != color;
}

class _ThinkingSegment extends StatefulWidget {
  const _ThinkingSegment({
    super.key,
    required this.option,
    required this.selected,
    required this.themeColor,
    required this.onTap,
  });

  final ThinkingModeOption option;
  final bool selected;
  final Color themeColor;
  final VoidCallback? onTap;

  @override
  State<_ThinkingSegment> createState() => _ThinkingSegmentState();
}

class _ThinkingSegmentState extends State<_ThinkingSegment> {
  static const Color _agenticAccent = Color(0xFFA78BFA);
  static const Set<String> _agenticValues = {'agentic', 'agents'};

  bool _hovered = false;

  bool get _isAgentic => _agenticValues.contains(widget.option.value);

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onTap == null;
    final active = widget.selected && !disabled;
    final color = disabled
        ? Colors.white24
        : active
        ? Colors.white
        : _isAgentic
        ? _agenticAccent
        : (_hovered ? Colors.white : Colors.white60);

    return Tooltip(
      message: widget.option.label,
      child: MouseRegion(
        cursor: disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          // 24px + 1px either side == ThinkingModeSliderButton.segmentWidth,
          // which is what the gooey blob layer uses to find this segment's
          // centre without measuring the render tree.
          child: Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            alignment: Alignment.center,
            child: Icon(widget.option.icon, size: 15, color: color),
          ),
        ),
      ),
    );
  }
}

class FileChip extends StatefulWidget {
  final Map<String, String> file;
  final Color themeColor;
  final VoidCallback onDelete;
  final ValueChanged<String> onOpen;

  const FileChip({
    super.key,
    required this.file,
    required this.themeColor,
    required this.onDelete,
    required this.onOpen,
  });

  @override
  State<FileChip> createState() => _FileChipState();
}

class _FileChipState extends State<FileChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8, right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => widget.onOpen(widget.file['path']!),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) => setState(() => _isHovered = true),
              onExit: (_) => setState(() => _isHovered = false),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.description, size: 14, color: widget.themeColor),
                  const SizedBox(width: 8),
                  Text(
                    widget.file['name']!,
                    style: TextStyle(
                      color: _isHovered ? widget.themeColor : Colors.white70,
                      fontSize: 11,
                      decoration: _isHovered
                          ? TextDecoration.underline
                          : TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: widget.onDelete,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: const Icon(Icons.close, size: 12, color: Colors.white38),
            ),
          ),
        ],
      ),
    );
  }
}
