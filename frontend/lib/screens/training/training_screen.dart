import 'package:flutter/material.dart';
import '../../l10n/app_strings.dart';
import '../../widgets/phase_lock.dart';

// Das Training ist fuer Phase 3 geplant und daher hinter PhaseLockOverlay
// gesperrt. Das Backend-Stub-Modul wurde entfernt; dieser Screen ist eine reine
// statische Design-Vorschau ohne Backend-Anbindung, bis das Feature echt
// gebaut wird. Kein Polling, keine API-Aufrufe.
class TrainingScreen extends StatefulWidget {
  const TrainingScreen({super.key});

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  final _modelIdController = TextEditingController(text: 'llama-3-8b');
  final _datasetController = TextEditingController(
    text: 'data/datasets/philosophy_qa.json',
  );
  final _hyperparamsController = TextEditingController(
    text:
        '{\n  "learning_rate": "2e-4",\n  "epochs": "3",\n  "batch_size": "4",\n  "lora_rank": "16"\n}',
  );

  @override
  void dispose() {
    _modelIdController.dispose();
    _datasetController.dispose();
    _hyperparamsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PhaseLockOverlay(
        phase: 3,
        feature: tr('sidebar.training'),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left side: start configuration
            Expanded(
              flex: 3,
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(right: 12),
                child: _buildStartCard(),
              ),
            ),
            // Right side: active runs
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.only(left: 12),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: Colors.white.withValues(alpha: 0.04)),
                  ),
                ),
                child: _buildJobsQueueCard(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF16161D),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            tr('training.title'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            tr('training.baseModelId'),
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _modelIdController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF0F0F12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            tr('training.datasetPath'),
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _datasetController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF0F0F12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            tr('training.hyperparams'),
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _hyperparamsController,
            maxLines: 8,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontFamily: 'monospace',
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF0F0F12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC9A24A),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              tr('training.start'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobsQueueCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF16161D),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            tr('training.queueTitle'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Center(
              child: Text(
                tr('training.emptyJobs'),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.25),
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
