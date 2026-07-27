import 'package:flutter/material.dart';
import '../../l10n/app_strings.dart';
import '../../l10n/remaining_ui_strings.dart';
import '../../widgets/phase_lock.dart';

// Das Gen Studio (Bild- und Videogenerierung) ist fuer Phase 4 geplant und
// daher hinter PhaseLockOverlay gesperrt. Die Backend-Stub-Module wurden
// entfernt; dieser Screen ist eine reine statische Design-Vorschau ohne
// Backend-Anbindung, bis das Feature echt gebaut wird. Kein Polling, keine
// API-Aufrufe.
class GenStudioScreen extends StatefulWidget {
  const GenStudioScreen({super.key});

  @override
  State<GenStudioScreen> createState() => _GenStudioScreenState();
}

class _GenStudioScreenState extends State<GenStudioScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.04)),
            ),
          ),
          child: IgnorePointer(
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFFC9A24A),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white38,
              tabs: [
                Tab(text: tr('genstudio.imageGenTab')),
                Tab(text: tr('genstudio.videoGenTab')),
              ],
            ),
          ),
        ),
      ),
      body: PhaseLockOverlay(
        phase: 4,
        feature: tr('sidebar.generative'),
        child: TabBarView(
          controller: _tabController,
          children: [
            _GenTab(
              title: tr('genstudio.imageTitle'),
              promptLabel: tr('genstudio.promptLabel'),
              promptText: tr('genstudio.promptPlaceholderImage'),
              modelText: 'sdxl-turbo',
              showSteps: true,
              submitLabel: tr('genstudio.submitImage'),
            ),
            _GenTab(
              title: tr('genstudio.videoTitle'),
              promptLabel: tr('genstudio.promptLabel'),
              promptText: tr('genstudio.promptPlaceholderVideo'),
              modelText: 'stable-video-diffusion',
              showSteps: false,
              submitLabel: tr('genstudio.submitVideo'),
            ),
          ],
        ),
      ),
    );
  }
}

// _GenTab ist die statische Vorschau eines Generierungs-Tabs (Bild oder Video).
// Die Eingabefelder zeigen Beispielwerte; der Absende-Button ist deaktiviert,
// solange das Feature gesperrt ist.
class _GenTab extends StatefulWidget {
  const _GenTab({
    required this.title,
    required this.promptLabel,
    required this.promptText,
    required this.modelText,
    required this.showSteps,
    required this.submitLabel,
  });

  final String title;
  final String promptLabel;
  final String promptText;
  final String modelText;
  final bool showSteps;
  final String submitLabel;

  @override
  State<_GenTab> createState() => _GenTabState();
}

class _GenTabState extends State<_GenTab> {
  late final TextEditingController _promptController;
  late final TextEditingController _modelController;
  final _stepsController = TextEditingController(text: '20');

  @override
  void initState() {
    super.initState();
    _promptController = TextEditingController(text: widget.promptText);
    _modelController = TextEditingController(text: widget.modelText);
  }

  @override
  void dispose() {
    _promptController.dispose();
    _modelController.dispose();
    _stepsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _buildCreateCard(),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: Colors.white.withValues(alpha: 0.04)),
                ),
              ),
              child: _buildJobsCard(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateCard() {
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
            widget.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.promptLabel,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _promptController,
            maxLines: 4,
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      remainingUiText('genStudio.modelId'),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _modelController,
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
                  ],
                ),
              ),
              if (widget.showSteps) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        remainingUiText('genStudio.steps'),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _stepsController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFF0F0F12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
              ],
            ],
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
              widget.submitLabel,
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

  Widget _buildJobsCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          remainingUiText('genStudio.activeRenderings'),
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
              remainingUiText('genStudio.noActiveRenderJobs'),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.25),
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
