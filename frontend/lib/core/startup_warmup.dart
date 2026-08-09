import 'dart:async';

import 'package:flutter/foundation.dart';

import 'api_service.dart';

/// Warmt beim Programmstart die Daten fuer Marketplace, News und Benchmark
/// vor, waehrend der Splash noch sichtbar ist.
///
/// Die Prefetch-Ergebnisse landen in einem TTL-basierten In-Memory-Cache, den
/// die Screens beim ersten Aufbau per [take] konsumieren: Sie rendern damit
/// sofort ihre Inhalte und lassen danach im Hintergrund frisch nachladen.
/// Fehlgeschlagene Prefetches sind bewusst folgenlos - die Screens fallen auf
/// ihren normalen Netzwerkpfad zurueck.
///
/// Der Fortschritt [value] liegt in [0, 1] und speist die Fortschrittsanzeige
/// des Splash, damit die Startanimation ehrlich laedt statt auf Zeit zu
/// spielen.
class StartupWarmup extends ValueNotifier<double> {
  StartupWarmup._() : super(0);

  static final StartupWarmup instance = StartupWarmup._();

  /// Die Suchergebnisse der Standardansicht (1. Seite, alle Provider).
  static const Duration marketplaceSearchTtl = Duration(minutes: 5);

  static const Duration marketplaceHardwareTtl = Duration(minutes: 10);

  static const Duration marketplaceJobsTtl = Duration(minutes: 1);

  static const Duration newsTtl = Duration(minutes: 5);

  static const Duration savedNewsTtl = Duration(minutes: 5);

  static const Duration benchmarkTtl = Duration(minutes: 10);

  bool _started = false;
  int _pending = 0;
  int _done = 0;
  final Map<String, _Entry> _cache = {};

  /// True, solange noch Prefetch-Aufgaben laufen.
  bool get isRunning => _pending > 0;

  /// Startet die Prefetches genau einmal im Hintergrund.
  ///
  /// Vor dem Login gibt es keinen Token, der Aufruf waere ohnehin
  /// ungueltig - dann ist der Start ein No-op.
  void start() {
    if (_started || ApiService().token == null) return;
    _started = true;
    unawaited(
      _runWith([
        _warmMarketplaceSearch,
        _warmMarketplaceHardware,
        _warmMarketplaceJobs,
        _warmNews,
        _warmSavedNews,
        _warmBenchmark,
      ]),
    );
  }

  /// Entnimmt einen zwischengespeicherten Wert und konsumiert ihn: Nur der
  /// erste Aufrufer bekommt ihn, danach faellt die Anzeige auf das
  /// normale Nachladen zurueck.
  ///
  /// Mit [ttl] verfaellt ein Eintrag, der aelter als die angegebene Dauer
  /// ist - News und Preise altern, also nie unbegrenzt aus dem Cache malen.
  T? take<T extends Object>(String key, {Duration? ttl}) {
    final entry = _cache.remove(key);
    if (entry == null) return null;
    if (ttl != null && DateTime.now().difference(entry.storedAt) > ttl) {
      return null;
    }
    final value = entry.value;
    return value is T ? value : null;
  }

  /// Entfernt alle Reste, z.B. beim Logout.
  void clear() => _cache.clear();

  Future<void> _runWith(List<Future<void> Function()> tasks) async {
    _pending = tasks.length;
    _done = 0;
    await Future.wait(
      tasks.map((task) async {
        try {
          await task();
        } catch (_) {
          // Best effort: Ein fehlgeschlagener Prefetch blockiert nie den
          // Start, der Screens faellt auf seinen Netzwerkpfad zurueck.
        } finally {
          _done++;
          value = _done / _pending;
        }
      }),
    );
    _pending = 0;
  }

  Future<void> _warmMarketplaceSearch() async {
    final res = await ApiService().marketplace.search(page: 1, limit: 24);
    if (res.containsKey('error') || res['models'] is! List) return;
    _store('marketplace.search', res);
  }

  Future<void> _warmMarketplaceHardware() async {
    final res = await ApiService().marketplace.getHardwareProfile();
    if (res.containsKey('error')) return;
    _store('marketplace.hardware', res);
  }

  Future<void> _warmMarketplaceJobs() async {
    final res = await ApiService().marketplace.listDownloadJobs();
    if (res.containsKey('error') || res['jobs'] is! List) return;
    _store('marketplace.jobs', res);
  }

  Future<void> _warmNews() async {
    final list = await ApiService().news.getNews();
    _store('news.list', list);
  }

  Future<void> _warmSavedNews() async {
    final list = await ApiService().news.getSavedNews();
    _store('news.saved', list);
  }

  Future<void> _warmBenchmark() async {
    final boardsRes = await ApiService().benchmark.getBoards();
    final rawBoards = boardsRes['boards'];
    if (rawBoards is! List || rawBoards.isEmpty) return;
    final fallback = boardsRes['default'];
    var key = fallback is String && fallback.isNotEmpty ? fallback : '';
    if (key.isEmpty && rawBoards.first is Map) {
      key = (rawBoards.first as Map)['key']?.toString() ?? '';
    }
    if (key.isEmpty) return;

    final status = await ApiService().benchmark.getStatus(board: key);
    final bundle = <String, dynamic>{
      'boards': rawBoards,
      'default': fallback is String ? fallback : key,
      'status': status,
    };
    if ('${status['state']}' == 'ready') {
      bundle['overview'] = await ApiService().benchmark.getOverview(board: key);
    }
    _store('benchmark.bootstrap', bundle);
  }

  void _store(String key, Object value) {
    _cache[key] = _Entry(value);
  }

  @visibleForTesting
  void debugReset() {
    _cache.clear();
    _started = false;
    _pending = 0;
    _done = 0;
    value = 0;
  }

  @visibleForTesting
  void debugSeed(String key, Object value, {DateTime? storedAt}) {
    _cache[key] = _Entry(value, storedAt: storedAt);
  }

  @visibleForTesting
  void debugSetProgress(double progress) {
    value = progress.clamp(0.0, 1.0);
  }

  @visibleForTesting
  Future<void> debugRun(List<Future<void> Function()> tasks) => _runWith(tasks);
}

class _Entry {
  _Entry(this.value, {DateTime? storedAt})
    : storedAt = storedAt ?? DateTime.now();

  final Object value;
  final DateTime storedAt;
}
