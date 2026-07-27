import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import 'settings_widgets.dart';

// Karte eines API-Providers in den Einstellungen (Hover-Zustand inklusive).

class ProviderCardWidget extends StatefulWidget {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final String emoji;
  final bool isKeySet;
  final Color accentColor;
  final List<Color> gradientColors;
  final VoidCallback onTap;
  final bool isCustom;
  final Widget Function(
    String id,
    String title,
    Color accentColor,
    String emoji,
    IconData icon,
  )
  logoBuilder;
  final String health;
  final String healthMsg;

  const ProviderCardWidget({
    super.key,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.emoji,
    required this.isKeySet,
    required this.accentColor,
    required this.gradientColors,
    required this.onTap,
    required this.logoBuilder,
    required this.health,
    required this.healthMsg,
    this.isCustom = false,
  });

  @override
  State<ProviderCardWidget> createState() => _ProviderCardWidgetState();
}

class _ProviderCardWidgetState extends State<ProviderCardWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final healthColor = widget.health == 'ok'
        ? Colors.greenAccent
        : (widget.health == 'checking' ? Colors.white30 : Colors.redAccent);

    final isInteractive = widget.id != 'backend';

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: isInteractive
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: isInteractive ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          transform: Matrix4.identity()
            ..translateByDouble(0.0, _isHovered ? -3.0 : 0.0, 0.0, 1.0),
          width: 240,
          height: 170,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _isHovered
                ? SettingsPalette.glassHover
                : SettingsPalette.glassIdle,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.accentColor.withValues(
                alpha: _isHovered ? 0.45 : 0.18,
              ), // glow border on hover
              width: _isHovered ? 1.5 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? widget.accentColor.withValues(
                        alpha: 0.15,
                      ) // brand glow shadow on hover
                    : Colors.black.withValues(alpha: 0.2),
                blurRadius: _isHovered ? 14 : 10,
                spreadRadius: _isHovered ? 1 : 0,
                offset: Offset(0, _isHovered ? 6 : 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo + Title
              Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: widget.accentColor.withValues(
                        alpha: _isHovered ? 0.14 : 0.08,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: widget.accentColor.withValues(
                          alpha: _isHovered ? 0.35 : 0.20,
                        ),
                        width: 1.0,
                      ),
                    ),
                    padding: const EdgeInsets.all(5),
                    child: widget.logoBuilder(
                      widget.id,
                      widget.title,
                      widget.accentColor,
                      widget.emoji,
                      widget.icon,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              // Details
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 11,
                      letterSpacing: 0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Key Status Badge
                  Row(
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.isKeySet
                              ? Colors.greenAccent
                              : Colors.amberAccent,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (widget.isKeySet
                                          ? Colors.greenAccent
                                          : Colors.amberAccent)
                                      .withValues(alpha: 0.4),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.id == 'backend'
                            ? tr('settings.provider.enabled')
                            : (widget.isKeySet
                                  ? tr('settings.provider.keySet')
                                  : tr('settings.provider.keyMissing')),
                        style: TextStyle(
                          color: widget.id == 'backend'
                              ? Colors.greenAccent
                              : (widget.isKeySet
                                    ? Colors.greenAccent
                                    : Colors.amberAccent),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Reachability Status badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.03),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.health == 'checking')
                      const SizedBox(
                        width: 8,
                        height: 8,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor: AlwaysStoppedAnimation(Colors.white30),
                        ),
                      )
                    else
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: healthColor,
                          boxShadow: [
                            BoxShadow(
                              color: healthColor.withValues(alpha: 0.5),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        widget.health == 'checking'
                            ? tr('settings.provider.checking')
                            : widget.healthMsg,
                        style: TextStyle(
                          color: healthColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
  }
}
