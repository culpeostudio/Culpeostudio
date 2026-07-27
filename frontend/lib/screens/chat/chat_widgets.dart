import 'dart:ui';
import 'package:flutter/material.dart';

import '../../l10n/chat_aux_strings.dart';
import '../../theme/app_theme.dart';

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
              ? const Color(0xFFC9A24A)
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

class ThinkingModeOption {
  final String value;
  final String label;
  final IconData icon;

  /// When false the option is shown but cannot be selected ("In Entwicklung").
  /// Dragging or tapping onto it previews the option but snaps back to the last
  /// enabled option, and [ThinkingModeSliderButton.onChanged] never fires for it.
  final bool enabled;

  const ThinkingModeOption({
    required this.value,
    required this.label,
    required this.icon,
    this.enabled = true,
  });
}

class ThinkingModeSliderButton extends StatefulWidget {
  final String value;
  final List<ThinkingModeOption> options;
  final Color themeColor;
  final ValueChanged<String> onChanged;
  final Key? triggerKey;
  final Key? popupKey;
  final Key? sliderKey;

  const ThinkingModeSliderButton({
    super.key,
    required this.value,
    required this.options,
    required this.themeColor,
    required this.onChanged,
    this.triggerKey,
    this.popupKey,
    this.sliderKey,
  });

  @override
  State<ThinkingModeSliderButton> createState() =>
      _ThinkingModeSliderButtonState();
}

class _ThinkingModeSliderButtonState extends State<ThinkingModeSliderButton>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isOpen = false;
  late int _selectedIndex;
  late final AnimationController _agenticController;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.options.indexWhere(
      (option) => option.value == widget.value,
    );
    if (_selectedIndex < 0 || !widget.options[_selectedIndex].enabled) {
      _selectedIndex = _firstEnabledIndex();
    }
    _agenticController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _syncAgenticAnimation();
  }

  @override
  void didUpdateWidget(covariant ThinkingModeSliderButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newIndex = widget.options.indexWhere(
      (option) => option.value == widget.value,
    );
    if (newIndex >= 0 && newIndex != _selectedIndex) {
      setState(() => _selectedIndex = newIndex);
      _syncAgenticAnimation();
    }
  }

  int _firstEnabledIndex() {
    final index = widget.options.indexWhere((option) => option.enabled);
    return index < 0 ? 0 : index;
  }

  ThinkingModeOption get _currentOption => widget.options[_selectedIndex];
  bool get _isAgentic =>
      _currentOption.value == 'agent' ||
      _currentOption.value == 'agentic' ||
      _currentOption.value == 'agents';

  void _syncAgenticAnimation() {
    if (_isAgentic) {
      _agenticController.repeat(reverse: true);
    } else {
      _agenticController.stop();
      _agenticController.value = 0;
    }
  }

  void _toggleMenu() {
    if (_isOpen) {
      _hideMenu();
    } else {
      _showMenu();
    }
  }

  void _showMenu() {
    if (!mounted || _overlayEntry != null) {
      if (mounted) setState(() => _isOpen = true);
      return;
    }
    final overlay = Overlay.of(context, rootOverlay: true);
    _overlayEntry = OverlayEntry(builder: (ctx) => _buildOverlayContent());
    overlay.insert(_overlayEntry!);
    if (mounted) setState(() => _isOpen = true);
  }

  void _hideMenu({bool notify = true}) {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (notify && mounted) {
      setState(() => _isOpen = false);
    }
  }

  void _onSelected(int index) {
    if (index < 0 || index >= widget.options.length) return;
    if (!widget.options[index].enabled) return;
    if (index != _selectedIndex) {
      setState(() => _selectedIndex = index);
      _syncAgenticAnimation();
      widget.onChanged(widget.options[index].value);
    }
    _hideMenu();
  }

  void _onSliderChanged(int index) {
    if (index < 0 || index >= widget.options.length) return;
    if (!widget.options[index].enabled) return;
    if (index != _selectedIndex) {
      setState(() => _selectedIndex = index);
      _syncAgenticAnimation();
      widget.onChanged(widget.options[index].value);
    }
  }

  @override
  void deactivate() {
    _hideMenu(notify: false);
    super.deactivate();
  }

  @override
  void dispose() {
    _hideMenu(notify: false);
    _agenticController.dispose();
    super.dispose();
  }

  Widget _buildOverlayContent() {
    const popupGap = 12.0;
    return Stack(
      children: <Widget>[
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _hideMenu(),
          child: const SizedBox.expand(),
        ),
        CompositedTransformFollower(
          link: _layerLink,
          targetAnchor: Alignment.topRight,
          followerAnchor: Alignment.bottomRight,
          offset: const Offset(0, -popupGap),
          child: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: 280,
              child: _ThinkingModePopupCard(
                key: widget.popupKey,
                sliderKey: widget.sliderKey,
                options: widget.options,
                selectedIndex: _selectedIndex,
                themeColor: widget.themeColor,
                onSelected: _onSelected,
                onSliderChanged: _onSliderChanged,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final active = _isHovered || _isOpen;
    final textPrimary = AppColors.textPrimary(brightness);
    final textSecondary = AppColors.textSecondary(brightness);
    return SelectionContainer.disabled(
      child: CompositedTransformTarget(
        link: _layerLink,
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            key: widget.triggerKey,
            behavior: HitTestBehavior.opaque,
            onTap: _toggleMenu,
            child: SizedBox(
              width: 118,
              height: 30,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _agenticController,
                    builder: (context, child) => Transform.scale(
                      scale: _isAgentic
                          ? 1 + _agenticController.value * 0.16
                          : 1,
                      child: Transform.rotate(
                        angle: _isAgentic ? _agenticController.value * 0.12 : 0,
                        child: child,
                      ),
                    ),
                    child: Icon(
                      _currentOption.icon,
                      size: 18,
                      color: _isAgentic
                          ? const Color(0xFFA78BFA)
                          : (active ? widget.themeColor : textSecondary),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _currentOption.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _isAgentic
                            ? textPrimary
                            : (active ? textPrimary : textSecondary),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _isOpen
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 12,
                    color: _isAgentic
                        ? const Color(0xFFA78BFA)
                        : (active ? widget.themeColor : textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThinkingModePopupCard extends StatefulWidget {
  final List<ThinkingModeOption> options;
  final int selectedIndex;
  final Color themeColor;
  final ValueChanged<int> onSelected;
  final ValueChanged<int> onSliderChanged;
  final Key? sliderKey;

  const _ThinkingModePopupCard({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.themeColor,
    required this.onSelected,
    required this.onSliderChanged,
    this.sliderKey,
  });

  @override
  State<_ThinkingModePopupCard> createState() => _ThinkingModePopupCardState();
}

class _ThinkingModePopupCardState extends State<_ThinkingModePopupCard> {
  late int _localIndex = widget.selectedIndex;
  // The last option the user actually committed to. Disabled ("In Entwicklung")
  // options preview under the thumb but snap back here on release.
  late int _lastEnabledIndex = _resolveEnabled(widget.selectedIndex);

  int _resolveEnabled(int index) {
    if (index >= 0 &&
        index < widget.options.length &&
        widget.options[index].enabled) {
      return index;
    }
    final fallback = widget.options.indexWhere((option) => option.enabled);
    return fallback < 0 ? 0 : fallback;
  }

  @override
  void didUpdateWidget(covariant _ThinkingModePopupCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _localIndex = widget.selectedIndex;
      _lastEnabledIndex = _resolveEnabled(widget.selectedIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final optionCount = widget.options.length;
    final sliderValue = _localIndex.toDouble().clamp(
      0.0,
      (optionCount - 1).toDouble(),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: MouseRegion(
          cursor: SystemMouseCursors.basic,
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1B1B1B).withValues(alpha: 0.98),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.42),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: _SlimThinkingSlider(
              key: widget.sliderKey,
              value: sliderValue,
              min: 0,
              max: (optionCount - 1).toDouble(),
              divisions: optionCount > 1 ? optionCount - 1 : null,
              label: widget.options[_localIndex].label,
              markers: widget.options.map((option) => option.label).toList(),
              enabledFlags: widget.options
                  .map((option) => option.enabled)
                  .toList(),
              themeColor: widget.themeColor,
              onChanged: (value) {
                final nextIndex = value.round().clamp(0, optionCount - 1);
                if (nextIndex != _localIndex) {
                  setState(() => _localIndex = nextIndex);
                  // Only commit enabled options; disabled ones preview only.
                  if (widget.options[nextIndex].enabled) {
                    _lastEnabledIndex = nextIndex;
                    widget.onSliderChanged(nextIndex);
                  }
                }
              },
              onChangeEnd: () {
                // Snap a preview of a disabled option back to the last committed
                // enabled option once the interaction ends.
                if (!widget.options[_localIndex].enabled) {
                  setState(() => _localIndex = _lastEnabledIndex);
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _SlimThinkingSlider extends StatefulWidget {
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String label;
  final List<String> markers;
  final List<bool> enabledFlags;
  final Color themeColor;
  final ValueChanged<double> onChanged;
  final VoidCallback? onChangeEnd;

  const _SlimThinkingSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    required this.label,
    required this.markers,
    required this.enabledFlags,
    required this.themeColor,
    required this.onChanged,
    this.onChangeEnd,
  });

  @override
  State<_SlimThinkingSlider> createState() => _SlimThinkingSliderState();
}

class _SlimThinkingSliderState extends State<_SlimThinkingSlider>
    with SingleTickerProviderStateMixin {
  static const double _trackHeight = 20.0;
  static const double _thumbRadius = 10.0;
  static const double _hoverRingRadius = 14.0;
  static const double _sliderHeight = 62.0;
  static const Color _thinkingAccent = Color(0xFFA78BFA);

  final GlobalKey _trackKey = GlobalKey();
  late final AnimationController _matrixController;
  bool _isHover = false;
  bool _isDragging = false;

  bool get _isEnhanced => widget.value > widget.min;

  int get _currentIndex =>
      widget.value.round().clamp(0, widget.markers.length - 1);

  bool _optionEnabled(int index) =>
      index < 0 || index >= widget.enabledFlags.length
      ? true
      : widget.enabledFlags[index];

  bool get _currentDisabled => !_optionEnabled(_currentIndex);

  @override
  void initState() {
    super.initState();
    _matrixController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _syncMatrixAnimation();
  }

  @override
  void didUpdateWidget(covariant _SlimThinkingSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMatrixAnimation();
  }

  void _syncMatrixAnimation() {
    if (_isEnhanced) {
      _matrixController.repeat();
    } else {
      _matrixController.stop();
      _matrixController.value = 0;
    }
  }

  @override
  void dispose() {
    _matrixController.dispose();
    super.dispose();
  }

  double _normalize(double v) {
    final span = widget.max - widget.min;
    if (span <= 0) return 0;
    return ((v - widget.min) / span).clamp(0.0, 1.0);
  }

  double _denormalize(double t) {
    final span = widget.max - widget.min;
    if (span <= 0) return widget.min;
    if (widget.divisions != null && widget.divisions! > 0) {
      final step = span / widget.divisions!;
      return widget.min + (t * span / step).round() * step;
    }
    return widget.min + t * span;
  }

  void _updateFromGlobal(Offset globalPosition) {
    final ctx = _trackKey.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return;
    final size = box.size;
    if (size.width <= 0) return;
    final local = box.globalToLocal(globalPosition);
    final t = (local.dx / size.width).clamp(0.0, 1.0);
    final newVal = _denormalize(t);
    if ((newVal - widget.value).abs() > 1e-9) {
      widget.onChanged(newVal);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _normalize(widget.value);
    final enhanced = _isEnhanced;
    final active = _isHover || _isDragging;
    final matrixActive = active || enhanced;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHover = true),
      onExit: (_) => setState(() => _isHover = false),
      cursor: SystemMouseCursors.click,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final trackWidth = constraints.maxWidth;
          final thumbX =
              _thumbRadius +
              t * (trackWidth - _thumbRadius * 2).clamp(0.0, trackWidth);
          final activeWidth = thumbX.clamp(_thumbRadius, trackWidth);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: (_) => setState(() => _isDragging = true),
            onHorizontalDragUpdate: (details) =>
                _updateFromGlobal(details.globalPosition),
            onHorizontalDragEnd: (_) {
              setState(() => _isDragging = false);
              widget.onChangeEnd?.call();
            },
            onHorizontalDragCancel: () {
              setState(() => _isDragging = false);
              widget.onChangeEnd?.call();
            },
            onTapDown: (details) => _updateFromGlobal(details.globalPosition),
            onTapUp: (_) => widget.onChangeEnd?.call(),
            onTapCancel: () => widget.onChangeEnd?.call(),
            child: SizedBox(
              height: _sliderHeight,
              width: trackWidth,
              child: Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  Positioned(
                    left: 0,
                    top: 0,
                    child: Text(
                      tr('chat.thinkingSlider.faster'),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Text(
                      tr('chat.thinkingSlider.smarter'),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  if (_currentDisabled)
                    Positioned(
                      left: 0,
                      right: 0,
                      top: -1,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.18),
                            ),
                          ),
                          child: Text(
                            tr('chat.thinkingSlider.inDevelopment'),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    key: _trackKey,
                    left: 0,
                    right: 0,
                    top: 22,
                    child: SizedBox(
                      height: _trackHeight,
                      width: trackWidth,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.centerLeft,
                        children: <Widget>[
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              height: _trackHeight,
                              width: trackWidth,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 140),
                              height: _trackHeight,
                              width: matrixActive ? activeWidth : 0,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    _thinkingAccent.withValues(alpha: 0.16),
                                    _thinkingAccent.withValues(alpha: 0.52),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ),
                          if (matrixActive)
                            Positioned(
                              left: 0,
                              top: 0,
                              width: activeWidth,
                              height: _trackHeight,
                              child: IgnorePointer(
                                child: AnimatedBuilder(
                                  animation: _matrixController,
                                  builder: (context, _) => CustomPaint(
                                    painter: _MatrixTrackPainter(
                                      color: _thinkingAccent,
                                      phase: _matrixController.value,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: List.generate(7, (index) {
                              final position = index / 6;
                              final reached = position <= t;
                              return Container(
                                width: 3,
                                height: 3,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: index == 6
                                      ? _thinkingAccent
                                      : reached
                                      ? _thinkingAccent.withValues(alpha: 0.76)
                                      : Colors.white.withValues(alpha: 0.28),
                                ),
                              );
                            }),
                          ),
                          ...List.generate(widget.markers.length, (index) {
                            final isMiddle =
                                index > 0 && index < widget.markers.length - 1;
                            if (!isMiddle) return const SizedBox.shrink();
                            final position =
                                index / (widget.markers.length - 1);
                            return Positioned(
                              left: position * trackWidth - 0.5,
                              top: 4,
                              child: Container(
                                width: 1,
                                height: 12,
                                color: index == widget.value.round()
                                    ? _thinkingAccent
                                    : Colors.white.withValues(alpha: 0.34),
                              ),
                            );
                          }),
                          if (active)
                            Positioned(
                              left: thumbX - _hoverRingRadius,
                              top: _trackHeight / 2 - _hoverRingRadius,
                              child: Container(
                                width: _hoverRingRadius * 2,
                                height: _hoverRingRadius * 2,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _thinkingAccent.withValues(
                                    alpha: 0.16,
                                  ),
                                ),
                              ),
                            ),
                          // Thumb
                          Positioned(
                            left: thumbX - _thumbRadius,
                            top: 0,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 140),
                              curve: Curves.easeOut,
                              width: _thumbRadius * 2,
                              height: _thumbRadius * 2,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFE7E7E4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.35),
                                    blurRadius: _isDragging ? 10 : 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ...List.generate(widget.markers.length, (index) {
                    final isMiddle =
                        index > 0 && index < widget.markers.length - 1;
                    if (!isMiddle) return const SizedBox.shrink();
                    final position = index / (widget.markers.length - 1);
                    final isSelected = index == widget.value.round();
                    final enabled = _optionEnabled(index);
                    return Positioned(
                      left: (position * trackWidth - 24).clamp(
                        0.0,
                        trackWidth - 48,
                      ),
                      top: 47,
                      width: 48,
                      child: Text(
                        widget.markers[index].toUpperCase(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: !enabled
                              ? Colors.white.withValues(alpha: 0.32)
                              : isSelected
                              ? _thinkingAccent
                              : Colors.white.withValues(alpha: 0.62),
                          fontSize: 8,
                          fontWeight: isSelected && enabled
                              ? FontWeight.w800
                              : FontWeight.w600,
                          letterSpacing: 0.45,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A stable, low-key grid of pixels for the maximum Thinking level.
class _MatrixTrackPainter extends CustomPainter {
  final Color color;
  final double phase;

  const _MatrixTrackPainter({required this.color, required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 5.0;
    const dotSize = 2.25;
    final columns = (size.width / spacing).ceil();
    final rows = (size.height / spacing).ceil();
    final paint = Paint()..isAntiAlias = false;

    for (var row = 0; row < rows; row++) {
      for (var column = 0; column < columns; column++) {
        // Deterministic pixels keep the effect calm instead of flickering.
        final phaseStep = (phase * 12).floor();
        final seed = (column * 17 + row * 11 + phaseStep) % 9;
        if (seed > 6) continue;
        paint.color = color.withValues(alpha: 0.24 + seed * 0.065);
        canvas.drawRect(
          Rect.fromLTWH(
            column * spacing + 1,
            row * spacing + 1,
            dotSize,
            dotSize,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MatrixTrackPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.phase != phase;
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
