import 'dart:async';
import 'package:flutter/material.dart';

import '../../core/app_info.dart';
import '../../core/app_theme.dart';
import '../../core/startup_warmup.dart';

/// Zeigt beim Programmstart kurz das Culpeo-Zeichen und blendet dann [child] ein.
///
/// Der Splash liegt als Overlay ueber [child], damit die eigentliche Oberflaeche
/// waehrend der Animation bereits aufbaut. Ist die Systemeinstellung fuer
/// reduzierte Bewegung aktiv, entfaellt die Animation vollstaendig.
///
/// Der Fortschrittsbalken folgt dem [StartupWarmup]: Sind die Prefetches fuer
/// Marketplace, News und Benchmark frueher fertig, steigt er schneller - der
/// Start wirkt geladen statt nur auf Zeit zu spielen. Die Animation hat
/// weiterhin eine feste Gesamtdauer von fuenf Sekunden.
class SplashGate extends StatefulWidget {
  const SplashGate({super.key, required this.child});

  final Widget child;

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate>
    with SingleTickerProviderStateMixin {
  static const Duration _duration = Duration(milliseconds: 5000);

  // Der Controller wird bewusst in initState erzeugt: bei reduzierter Bewegung
  // startet die Animation nie, und ein spaet erzeugter Ticker wuerde erst in
  // dispose() auf einen bereits abgebauten Elementbaum zugreifen.
  late final AnimationController _controller;

  bool _finished = false;
  bool _started = false;

  // Die Anteile sind auf die Gesamtdauer bezogen. Wortmarke und Fusszeile
  // stehen frueh, damit das Bild bei fuenf Sekunden nicht traege aufbaut; die
  // Zeit dazwischen traegt der Fortschrittsbalken.
  late final Animation<double> _markFade = _curve(0.0, 0.12, Curves.easeOut);
  late final Animation<double> _markScale = Tween<double>(
    begin: 0.95,
    end: 1.0,
  ).animate(_curve(0.0, 0.20, Curves.easeOutCubic));
  late final Animation<double> _progress = _curve(
    0.06,
    0.86,
    Curves.easeInOutCubic,
  );
  late final Animation<double> _footerFade = _curve(0.10, 0.22, Curves.easeOut);
  late final Animation<double> _overlayFade = Tween<double>(
    begin: 1.0,
    end: 0.0,
  ).animate(_curve(0.90, 1.0, Curves.easeIn));

  Animation<double> _curve(double begin, double end, Curve curve) {
    return CurvedAnimation(
      parent: _controller,
      curve: Interval(begin, end, curve: curve),
    );
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _finished = true);
        }
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _finished = true;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_finished) return widget.child;

    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: FadeTransition(opacity: _overlayFade, child: _splash(context)),
        ),
      ],
    );
  }

  Widget _splash(BuildContext context) {
    return Semantics(
      label: '${AppInfo.name} wird gestartet',
      child: Material(
        type: MaterialType.transparency,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.1),
              radius: 0.8,
              colors: [AppColors.surface, AppColors.bg],
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FadeTransition(
                      opacity: _markFade,
                      child: ScaleTransition(
                        scale: _markScale,
                        child: Image.asset(
                          'assets/wordmark_light.png',
                          width: _markWidth(context),
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ),
                    const SizedBox(height: 50),
                    AnimatedBuilder(
                      animation: Listenable.merge([_progress, StartupWarmup.instance]),
                      builder: (context, _) => _TypingConsole(progress: _barProgress()),
                    ),
                    const SizedBox(height: 24),
                    _progressBar(),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 40,
                child: FadeTransition(
                  opacity: _footerFade,
                  child: Text(
                    AppInfo.versionLine,
                    textAlign: TextAlign.center,
                    style: AppFonts.mono(
                      fontSize: 10,
                      color: AppColors.textSecondary.withValues(alpha: 0.2),
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Das Logo wurde um 50% vergrössert, um präsenter zu wirken.
  double _markWidth(BuildContext context) {
    final available = MediaQuery.sizeOf(context).width;
    return (available * 0.75).clamp(300.0, 540.0);
  }

  Widget _progressBar() {
    return SizedBox(
      width: 180,
      height: 2,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(1),
        child: Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(
                color: AppColors.textSecondary.withValues(alpha: 0.05),
              ),
            ),
            AnimatedBuilder(
              animation: Listenable.merge([_progress, StartupWarmup.instance]),
              builder: (context, _) => FractionallySizedBox(
                key: const Key('splash-progress-fill'),
                alignment: Alignment.centerLeft,
                widthFactor: _barProgress(),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.hoverGlow, AppColors.accent],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Der Balken laeuft mindestens mit der Animation, darf aber hinter dem
  /// Warmup-Fortschritt nicht zurueckbleiben: Er erreicht frueh
  /// 86 % (dasselbe Ziel wie die Ladeanimation), der Rest gehoert dem
  /// Ueberblenden.
  double _barProgress() {
    final animated = _progress.value;
    final warmFactor = StartupWarmup.instance.value.clamp(0.0, 1.0) * 0.86;
    return animated > warmFactor ? animated : warmFactor;
  }
}

/// A professional developer-console typing effect widget.
class _TypingConsole extends StatefulWidget {
  final double progress;
  const _TypingConsole({required this.progress});

  @override
  State<_TypingConsole> createState() => _TypingConsoleState();
}

class _TypingConsoleState extends State<_TypingConsole> with SingleTickerProviderStateMixin {
  late final AnimationController _cursorController;
  Timer? _typeTimer;
  String _currentText = "";
  String _previousTarget = "";

  String get _targetText {
    if (widget.progress >= 0.99) return "Workspace Ready.";
    if (widget.progress >= 0.80) return "Establishing secure port hooks...";
    if (widget.progress >= 0.60) return "Loading AI model weights...";
    if (widget.progress >= 0.40) return "Mounting local filesystem...";
    if (widget.progress >= 0.20) return "Allocating workspace memory...";
    return "Initializing local neural engine...";
  }

  @override
  void initState() {
    super.initState();
    _cursorController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..repeat(reverse: true);
    _previousTarget = _targetText;
    _startTyping();
  }

  @override
  void didUpdateWidget(_TypingConsole oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_targetText != _previousTarget) {
      _previousTarget = _targetText;
      _startTyping();
    }
  }

  void _startTyping() {
    _typeTimer?.cancel();
    _currentText = "";
    int index = 0;
    final target = _previousTarget;
    _typeTimer = Timer.periodic(const Duration(milliseconds: 15), (timer) {
      if (index < target.length) {
        if (mounted) {
          setState(() {
            _currentText += target[index];
            index++;
          });
        }
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _typeTimer?.cancel();
    _cursorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDone = widget.progress >= 0.99;
    return SizedBox(
      height: 20, // Keep height stable
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text("> ", style: AppFonts.mono(fontSize: 11, color: isDone ? AppColors.accent : AppColors.hoverGlow)),
          Text(
            _currentText, 
            style: AppFonts.mono(
              fontSize: 11, 
              color: AppColors.textSecondary.withValues(alpha: 0.4),
              letterSpacing: 0.5,
            ),
          ),
          if (!isDone)
            FadeTransition(
              opacity: _cursorController,
              child: Container(
                width: 6,
                height: 12,
                margin: const EdgeInsets.only(left: 4),
                color: AppColors.accent,
              ),
            ),
        ],
      ),
    );
  }
}
