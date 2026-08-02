import 'package:flutter/material.dart';
import '../../l10n/app_strings.dart';
import '../../widgets/phase_lock.dart';

class QuantizationScreen extends StatefulWidget {
  const QuantizationScreen({super.key});

  @override
  State<QuantizationScreen> createState() => _QuantizationScreenState();
}

class _QuantizationScreenState extends State<QuantizationScreen> {
  final _modelPathController = TextEditingController(
    text: 'data/models/llama-3-8b.safetensors',
  );
  final _outputPathController = TextEditingController(
    text: 'data/models/llama-3-8b-Q4_K_M.gguf',
  );
  String _selectedType = 'Q4_K_M';
  final List<String> _types = ['Q4_0', 'Q4_1', 'Q4_K_M', 'Q8_0', 'F16'];

  @override
  void dispose() {
    _modelPathController.dispose();
    _outputPathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PhaseLockOverlay(
        phase: 3,
        feature: tr('sidebar.quantization'),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(right: 12),
                child: _buildStartQuantCard(),
              ),
            ),

            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.only(left: 12),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: Colors.white.withValues(alpha: 0.04),
                    ),
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

  Widget _buildStartQuantCard() {
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
            tr('quantization.title'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            tr('quantization.sourcePath'),
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _modelPathController,
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
            tr('quantization.targetType'),
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF0F0F12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedType,
                dropdownColor: const Color(0xFF16161D),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white60,
                ),
                isExpanded: true,
                items: _types
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) {
                  setState(() => _selectedType = val!);
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            tr('quantization.outputPath'),
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _outputPathController,
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
              tr('quantization.start'),
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
            tr('quantization.queueTitle'),
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
                tr('quantization.emptyJobs'),
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
