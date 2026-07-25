import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myphilostudio/screens/chat/model_warmup.dart';

void main() {
  test('real engine phases use monotonic anchors below ready', () {
    const expected = <String, double>{
      'queued': 0.12,
      'admission': 0.12,
      'preparing_runtime': 0.22,
      'runtime_ready': 0.30,
      'refreshing_plan': 0.36,
      'lru_evicting': 0.40,
      'starting_instances': 0.48,
      'launching_worker': 0.66,
      'loading_model': 0.78,
      'worker_initializing': 0.86,
      'worker_ready': 0.92,
      'verifying_worker': 0.98,
      'instance_verified': 0.99,
      'ready': 1.0,
    };

    var previous = 0.0;
    for (final entry in expected.entries) {
      final ceiling = ModelWarmupProgress.phaseCeilingForPhase(entry.key);
      expect(ceiling, entry.value, reason: entry.key);
      expect(ceiling, greaterThanOrEqualTo(previous), reason: entry.key);
      if (entry.key != 'ready') {
        expect(ceiling, lessThan(1), reason: entry.key);
      }
      previous = ceiling;
    }
  });

  testWidgets('renders every real engine phase and reaches 100 only at ready', (
    tester,
  ) async {
    final progress = ModelWarmupProgress(
      tickInterval: const Duration(milliseconds: 20),
    );
    addTearDown(progress.dispose);
    progress.begin(instanceId: 'local-1', modelName: 'Lokales Modell');

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(body: ModelWarmupPanel(progress: progress)),
      ),
    );

    const phases = <(String, String, double)>[
      ('queued', 'Wartet auf sichere Ressourcen', 0.01),
      ('admission', 'Ressourcenfreigabe wird geprüft', 0.02),
      ('preparing_runtime', 'Laufzeit wird vorbereitet', 0.05),
      ('runtime_ready', 'Laufzeit ist bereit', 0.30),
      ('refreshing_plan', 'Speicherplan wird erneut geprüft', 0.32),
      ('lru_evicting', 'Ungenutztes Modell wird entladen', 0.34),
      ('starting_instances', 'Modellstart wird koordiniert', 0.40),
      ('launching_worker', 'Modellprozess wird gestartet', 0.62),
      ('loading_model', 'Modellgewichte werden geladen', 0.70),
      ('worker_initializing', 'Healthcheck: Modellserver startet', 0.76),
      ('worker_ready', 'Healthcheck erfolgreich', 0.82),
      ('verifying_worker', 'Mini-Inferenz wird geprüft', 0.86),
      ('instance_verified', 'Mini-Inferenz erfolgreich', 0.95),
    ];

    var previous = progress.displayProgress;
    for (final (phase, label, realProgress) in phases) {
      progress.updateFromJson({
        'status': 'running',
        'phase': phase,
        'progress': realProgress,
      });
      await tester.pump(const Duration(milliseconds: 40));
      expect(find.text(label), findsOneWidget, reason: phase);
      expect(
        progress.displayProgress,
        greaterThanOrEqualTo(previous),
        reason: phase,
      );
      expect(progress.displayProgress, lessThan(1), reason: phase);
      previous = progress.displayProgress;
    }

    progress.updateFromJson(const {
      'status': 'running',
      'phase': 'ready',
      'progress': 1,
    });
    await tester.pump();
    expect(find.text('Modell ist bereit'), findsOneWidget);
    expect(progress.displayProgress, lessThan(1));
    expect(find.text('100 %'), findsNothing);

    progress.updateFromJson(const {
      'status': 'ready',
      'phase': 'ready',
      'progress': 1,
    });
    await tester.pump();
    expect(progress.displayProgress, 1);
    expect(find.text('100 %'), findsOneWidget);
  });

  testWidgets(
    'visual warmup progress is monotonic and stays below 100 until ready',
    (tester) async {
      final progress = ModelWarmupProgress(
        tickInterval: const Duration(milliseconds: 20),
      );
      addTearDown(progress.dispose);
      progress.begin(
        instanceId: 'local-1',
        modelName: 'Lokales Modell',
        placement: 'hybrid',
      );
      progress.updateFromJson(const {
        'status': 'running',
        'phase': 'loading_weights',
        'progress': 0.42,
        'queue_position': 2,
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(body: ModelWarmupPanel(progress: progress)),
        ),
      );
      final first = progress.displayProgress;
      await tester.pump(const Duration(milliseconds: 400));
      final interpolated = progress.displayProgress;
      expect(interpolated, greaterThan(first));
      expect(interpolated, lessThan(0.78));
      expect(interpolated, lessThan(1));
      expect(find.text('Bitte kurz warten – Modell läuft warm'), findsWidgets);
      expect(find.text('Modellgewichte werden geladen'), findsOneWidget);
      expect(find.text('Warteschlange: 2'), findsOneWidget);

      progress.updateFromJson(const {
        'status': 'running',
        'phase': 'queued',
        'progress': 0.05,
      });
      await tester.pump();
      expect(progress.displayProgress, greaterThanOrEqualTo(interpolated));
      expect(progress.displayProgress, lessThan(1));

      progress.updateFromJson(const {
        'status': 'ready',
        'phase': 'ready',
        'progress': 1,
      });
      await tester.pump();
      expect(progress.displayProgress, 1);
      expect(find.text('100 %'), findsOneWidget);
    },
  );

  test('warmup retry reuses the existing user bubble exactly once', () {
    final messages = <Map<String, dynamic>>[
      {'role': 'user', 'content': 'Erkläre Kant'},
    ];

    prepareWarmupRetryMessages(messages, 'Erkläre Kant');
    prepareWarmupRetryMessages(messages, 'Erkläre Kant');

    expect(
      messages.where((message) => message['role'] == 'user'),
      hasLength(1),
    );
    expect(
      messages.where((message) => message['role'] == 'assistant'),
      hasLength(1),
    );
  });

  testWidgets('failed warmup exposes retry and binding recovery actions', (
    tester,
  ) async {
    final progress = ModelWarmupProgress();
    addTearDown(progress.dispose);
    progress.begin(instanceId: 'local-1', modelName: 'Lokales Modell');
    progress.fail(
      message: 'Ressourcenschutz hat den Start abgelehnt.',
      code: 'resource_guard_rejected',
    );
    var retried = false;
    var changedBinding = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: ModelWarmupPanel(
            progress: progress,
            onRetry: () => retried = true,
            onChangeBinding: () => changedBinding = true,
            onChooseAnother: () {},
          ),
        ),
      ),
    );

    expect(find.text('Erneut versuchen'), findsOneWidget);
    expect(find.text('Bindung ändern'), findsOneWidget);
    expect(find.text('Anderes Modell wählen'), findsOneWidget);
    await tester.tap(find.text('Erneut versuchen'));
    await tester.tap(find.text('Bindung ändern'));
    expect(retried, isTrue);
    expect(changedBinding, isTrue);
  });
}
