import 'package:flutter_test/flutter_test.dart';

import 'package:culpeo_studio/core/startup_warmup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(StartupWarmup.instance.debugReset);
  tearDown(StartupWarmup.instance.debugReset);

  group('take', () {
    test('liefert einen gespeicherten Wert genau einmal', () {
      StartupWarmup.instance.debugSeed('k', {'a': 1});

      final first = StartupWarmup.instance.take<Map<String, dynamic>>('k');
      final second = StartupWarmup.instance.take<Map<String, dynamic>>('k');

      expect(first, {'a': 1});
      expect(second, isNull);
    });

    test('konsumiert Eintraege auch bei falschem Typ', () {
      StartupWarmup.instance.debugSeed('k', {'a': 1});

      expect(StartupWarmup.instance.take<List<dynamic>>('k'), isNull);
      expect(StartupWarmup.instance.take<Map<String, dynamic>>('k'), isNull);
    });

    test('verfaellt Eintraege ueber der TTL', () {
      final ttl = StartupWarmup.newsTtl;
      StartupWarmup.instance.debugSeed(
        'alt',
        'wert',
        storedAt: DateTime.now().subtract(ttl * 2),
      );

      expect(StartupWarmup.instance.take<String>('alt', ttl: ttl), isNull);
    });

    test('haelt Eintraege innerhalb der TTL', () {
      final ttl = StartupWarmup.newsTtl;
      StartupWarmup.instance.debugSeed('frisch', 'wert');

      expect(StartupWarmup.instance.take<String>('frisch', ttl: ttl), 'wert');
    });

    test('liefert Eintraege auch ohne ttl-Angabe ungeprueft', () {
      StartupWarmup.instance.debugSeed(
        'uralt',
        'wert',
        storedAt: DateTime.now().subtract(const Duration(days: 1)),
      );

      expect(StartupWarmup.instance.take<String>('uralt'), 'wert');
    });
  });

  test('clear entfernt alle Eintraege', () {
    StartupWarmup.instance.debugSeed('k', 'wert');
    StartupWarmup.instance.clear();

    expect(StartupWarmup.instance.take<String>('k'), isNull);
  });

  test('start ist ohne Login ein No-op', () {
    StartupWarmup.instance.start();
    expect(StartupWarmup.instance.isRunning, isFalse);
  });

  test('debugRun meldet Fortschritt und schluckt Fehler', () async {
    final values = <double>[];
    void listener() => values.add(StartupWarmup.instance.value);
    StartupWarmup.instance.addListener(listener);
    addTearDown(() => StartupWarmup.instance.removeListener(listener));

    await StartupWarmup.instance.debugRun([
      () async {
        StartupWarmup.instance.debugSeed('a', {'ok': true});
      },
      () async => throw Exception('kaputt'),
      () async {
        await Future<void>.delayed(Duration.zero);
        StartupWarmup.instance.debugSeed('b', 2);
      },
    ]);

    expect(StartupWarmup.instance.isRunning, isFalse);
    expect(StartupWarmup.instance.value, 1.0);
    expect(values, isNotEmpty);
    expect(values.last, 1.0);
    expect(StartupWarmup.instance.take<Map<String, dynamic>>('a'), {
      'ok': true,
    });
    expect(StartupWarmup.instance.take<int>('b'), 2);
  });
}
