import 'package:flutter/material.dart';
import '../../providers/provider_connections_panel.dart';
import '../../../core/app_state.dart';

/// AnbieterSection encapsulates the Provider / Custom API / Presets settings component
/// within the settings module under the 'anbieter' subfolder.
class AnbieterSection extends StatelessWidget {
  final VoidCallback? onActiveModelsChanged;

  const AnbieterSection({
    super.key,
    this.onActiveModelsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final appState = AppState();
    return ProviderConnectionsPanel(
      onActiveModelsChanged: onActiveModelsChanged ?? appState.refreshActiveApiModels,
    );
  }
}
