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
    begin: 0.90,
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
      child: ColoredBox(
        color: AppColors.bg,
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
                        // Helle Fassung: das "Studio" der Wortmarke ist im
                        // Original dunkelblau und auf dieser Flaeche unlesbar.
                        'assets/wordmark_light.png',
                        width: _markWidth(context),
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.medium,
                      ),
                    ),
                  ),
                  const SizedBox(height: 34),
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
                    color: AppColors.textSecondary.withValues(alpha: 0.45),
                    letterSpacing: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Die Wortmarke ist breit; auf schmalen Fenstern skaliert sie mit statt
  /// an den Rand zu stossen.
  double _markWidth(BuildContext context) {
    final available = MediaQuery.sizeOf(context).width;
    return (available * 0.55).clamp(200.0, 360.0);
  }

  Widget _progressBar() {
    return SizedBox(
      width: 132,
      height: 2,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(1),
        child: Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(
                color: AppColors.textSecondary.withValues(alpha: 0.10),
              ),
            ),
            AnimatedBuilder(
              animation: Listenable.merge([_progress, StartupWarmup.instance]),
              builder: (context, _) => FractionallySizedBox(
                key: const Key('splash-progress-fill'),
                alignment: Alignment.centerLeft,
                widthFactor: _barProgress(),
                child: ColoredBox(color: AppColors.accent),
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
