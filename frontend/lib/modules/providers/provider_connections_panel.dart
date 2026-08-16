import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/api_service.dart';
import '../../core/culpeo_grid.dart';
import '../../core/design_tokens.dart';
import '../nodes/node_add_dialog.dart';
import '../nodes/nodes_screen.dart';
import '../settings/settings_widgets.dart';
import 'marketplace_providers_section.dart';
import 'provider_api.dart';
import 'provider_connections_controller.dart';
import 'provider_visuals.dart';

/// Settings panel for user-owned hosted AI connections.
///
/// The panel deliberately receives only public connection metadata.  The API
/// key field exists inside the add/edit dialog for the duration of one save
/// request, then is cleared and disposed; it is never copied into Flutter
/// state, preferences, connection cards, or logs.
class ProviderConnectionsPanel extends StatefulWidget {
  const ProviderConnectionsPanel({
    super.key,
    this.api,
    this.onActiveModelsChanged,
  });

  final ProviderApi? api;

  /// Lets the host refresh its chat-model picker immediately after a model is
  /// enabled or disabled.  It is optional to keep this settings module free of
  /// a direct dependency on the global chat state.
  final FutureOr<void> Function()? onActiveModelsChanged;

  @override
  State<ProviderConnectionsPanel> createState() =>
      _ProviderConnectionsPanelState();
}

/// The one preset with no fixed brand: any other OpenAI-compatible HTTPS
/// endpoint. It gets its own "Nodes" category instead of a card among named
/// vendors, since it is a shape, not an identity.
const _customPresetId = 'custom_openai_compatible';

enum _ProviderCategory { vendors, nodes }

class _ProviderConnectionsPanelState extends State<ProviderConnectionsPanel> {
  late final ProviderConnectionsController _controller;
  _ProviderCategory _category = _ProviderCategory.vendors;

  /// Only for the count on the category segment. The node view manages its own
  /// list; this is the one number the toggle needs before it is opened.
  int _nodeCount = 0;

  /// The connection editor's fields. They belong to this State because a
  /// dialog route keeps rebuilding after showDialog's future resolves; a
  /// controller disposed at that point is still read by the exit animation.
  /// [_editorKeyController] holds a secret only while its dialog is open and
  /// is cleared as soon as it closes.
  final TextEditingController _editorNameController = TextEditingController();
  final TextEditingController _editorBaseUrlController =
      TextEditingController();
  final TextEditingController _editorKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = ProviderConnectionsController(
      widget.api ?? ApiService().providers,
    )..load();
    _loadNodeCount();
  }

  Future<void> _loadNodeCount() async {
    try {
      final nodes = await ApiService().nodes.listNodes();
      if (!mounted) return;
      setState(() => _nodeCount = nodes.length);
    } catch (_) {
      // Nodes are optional; a panel that cannot count them still works.
      if (!mounted) return;
      setState(() => _nodeCount = 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _editorKeyController.clear();
    _editorKeyController.dispose();
    _editorNameController.dispose();
    _editorBaseUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return settingsGlassCard(
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final hasHeight = constraints.hasBoundedHeight;
          return SizedBox(
            height: hasHeight ? null : 600,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(context),
                    if (_controller.loadError != null) ...[
                      const SizedBox(height: 10),
                      _buildFailureBanner(context, _controller.loadError!),
                    ],
                    const SizedBox(height: 12),
                    Expanded(child: _buildContent(context)),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 31,
          decoration: BoxDecoration(
            color: CulpeoColors.action,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'KI-Anbieter & API-Modelle',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: SettingsPalette.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Anbieter verbinden, aktuelle Modellkataloge synchronisieren und Modelle gezielt für den Chat aktivieren.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: SettingsPalette.textFaint,
                  fontSize: 11.5,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: _controller.isLoading ? null : _controller.load,
          tooltip: 'Anbieter und Verbindungen neu laden',
          color: SettingsPalette.textSecondary,
          icon: _controller.isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh_rounded),
        ),
        const SizedBox(width: 4),
        ElevatedButton.icon(
          onPressed: _controller.presets.isEmpty
              ? null
              : () => _showAddChooser(context),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Hinzufügen'),
          style: ElevatedButton.styleFrom(
            backgroundColor: CulpeoColors.action,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFailureBanner(BuildContext context, String error) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: CulpeoColors.danger.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: CulpeoColors.danger.withValues(alpha: 0.32)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: CulpeoColors.danger,
            size: 17,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'Provider-Dienst nicht erreichbar: $error',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: SettingsPalette.textSecondary,
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ),
          TextButton(
            onPressed: _controller.isLoading ? null : _controller.load,
            child: const Text('Erneut versuchen'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_controller.isLoading &&
        _controller.presets.isEmpty &&
        _controller.connections.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCategoryToggle(),
        const SizedBox(height: 18),
        Expanded(
          child: _category == _ProviderCategory.vendors
              ? _buildVendorsView(context)
              : _buildNodesView(context),
        ),
      ],
    );
  }

  /// The main navigational choice in this panel now that the catalogue lives
  /// behind "Hinzufügen" rather than filling the page: two generous halves
  /// instead of a cramped pill, since there is height to spend once the
  /// always-visible catalogue grid is gone.
  Widget _buildCategoryToggle() {
    // Two kinds of connection, counted separately: an Anbieter is a hosted API
    // this Studio calls, a Node is a machine it runs models on.
    final vendorCount = _controller.connections.length;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: CulpeoColors.inset,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildCategorySegment(
              _ProviderCategory.vendors,
              label: 'Anbieter',
              subtitle: 'Gehostete Cloud-Modelle',
              icon: Icons.hub_rounded,
              count: vendorCount,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildCategorySegment(
              _ProviderCategory.nodes,
              label: 'Nodes',
              subtitle: 'Eigene Server',
              icon: Icons.dns_rounded,
              count: _nodeCount,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySegment(
    _ProviderCategory value, {
    required String label,
    required String subtitle,
    required IconData icon,
    required int count,
  }) {
    final selected = _category == value;
    final onTint = selected ? Colors.white : SettingsPalette.textSecondary;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: selected ? null : () => setState(() => _category = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: selected ? CulpeoColors.action : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: onTint),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: selected ? Colors.white : CulpeoColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected
                          ? Colors.white.withValues(alpha: 0.82)
                          : SettingsPalette.textFaint,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (count > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.2)
                      : CulpeoColors.metric.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: selected ? Colors.white : CulpeoColors.metricBright,
                    fontWeight: FontWeight.w800,
                    fontSize: 11.5,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVendorsView(BuildContext context) {
    // The custom OpenAI-compatible preset lives here too: it is still a
    // provider connection, just an unbranded one. "Nodes" is a different,
    // not-yet-built feature (see _buildNodesView), not a home for it.
    final connected = _controller.connections.toList(growable: false);
    return ListView(
      key: const PageStorageKey('provider-connections-vendors-scroll'),
      padding: const EdgeInsets.only(bottom: 4),
      children: [
        // Built in, so it opens above the connections rather than replacing
        // them: these vendors exist whether or not anything is connected.
        const MarketplaceProvidersSection(),
        const SizedBox(height: 20),
        _buildSectionLabel(
          icon: Icons.hub_outlined,
          title: 'Eigene Verbindungen',
          subtitle:
              'Cloud-Anbieter mit deinem eigenen API-Schlüssel. Ihre Modelle wählst du direkt hier aus.',
        ),
        const SizedBox(height: 11),
        if (connected.isEmpty && _controller.presets.isEmpty)
          _buildOfflineNotice(context)
        else if (connected.isEmpty)
          _buildNoConnectionsHint(context)
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: culpeoGridDelegate(extent: 204, maxTileWidth: 360),
            itemCount: connected.length,
            itemBuilder: (context, index) =>
                _buildConnectionCard(context, connected[index]),
          ),
      ],
    );
  }

  Widget _buildSectionLabel({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: CulpeoColors.metricBright),
            const SizedBox(width: 7),
            Text(
              title,
              style: const TextStyle(
                color: SettingsPalette.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: SettingsPalette.textMuted,
            fontSize: 11,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _buildNoConnectionsHint(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: CulpeoColors.inset,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Noch kein eigener Anbieter verbunden. Verbinde OpenAI, Anthropic, Gemini und weitere mit deinem eigenen API-Schlüssel.',
              style: TextStyle(
                color: SettingsPalette.textMuted,
                fontSize: 11.5,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => _showVendorPickerDialog(context),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Hinzufügen'),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: CulpeoColors.action,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Nodes are the other machines this Studio downloads models to and runs
  /// them on — an infrastructure category of its own, not the custom
  /// OpenAI-compatible preset, which is an Anbieter.
  ///
  /// The screen manages its own list, tunnels and add flow, so it is embedded
  /// whole rather than reimplemented here.
  Widget _buildNodesView(BuildContext context) {
    return NodesScreen(onNodesChanged: _loadNodeCount);
  }

  /// The entry point for both categories: pressing "Hinzufügen" no longer
  /// silently guesses from the active tab. It asks once, then routes straight
  /// into the right flow.
  Future<void> _showAddChooser(BuildContext context) async {
    final choice = await showModalBottomSheet<_ProviderCategory>(
      context: context,
      backgroundColor: const Color(0xFF17171E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text(
                  'Was möchtest du hinzufügen?',
                  style: TextStyle(
                    color: SettingsPalette.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 14),
                _buildChooserOption(
                  icon: Icons.hub_rounded,
                  title: 'Anbieter',
                  subtitle:
                      'OpenAI, Anthropic, Gemini und weitere Cloud-Anbieter',
                  onTap: () =>
                      Navigator.pop(sheetContext, _ProviderCategory.vendors),
                ),
                const SizedBox(height: 10),
                _buildChooserOption(
                  icon: Icons.dns_rounded,
                  title: 'Node',
                  subtitle: 'Eigener Server, der Modelle laedt und ausfuehrt',
                  onTap: () =>
                      Navigator.pop(sheetContext, _ProviderCategory.nodes),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (choice == null || !context.mounted) return;
    setState(() => _category = choice);
    // A node is not picked from a catalogue of vendors: it is paired with a
    // join code its own setup printed.
    if (choice == _ProviderCategory.nodes) {
      final added = await showNodeAddDialog(context);
      if (added != null) await _loadNodeCount();
      return;
    }
    await _showVendorPickerDialog(context);
  }

  Widget _buildChooserOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: CulpeoColors.action.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: CulpeoColors.action.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Icon(icon, color: CulpeoColors.actionHover, size: 21),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: SettingsPalette.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: SettingsPalette.textMuted,
                          fontSize: 11.5,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                if (enabled)
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: SettingsPalette.textFaint,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The vendor catalogue used to sit permanently in the main view. It now
  /// only appears here, reached deliberately through "Hinzufügen", so the
  /// main view can stay limited to what is actually connected.
  Future<void> _showVendorPickerDialog(BuildContext context) async {
    // The custom OpenAI-compatible preset is included: it is an Anbieter,
    // just an unbranded one, so it belongs in this catalogue too.
    final presets = _controller.presets;
    final selected = await showDialog<ProviderPreset>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: const Color(0xFF17171E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 660, maxHeight: 580),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 14, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Anbieter auswählen',
                        style: TextStyle(
                          color: SettingsPalette.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: SettingsPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: culpeoGridDelegate(
                      extent: 200,
                      maxTileWidth: 320,
                    ),
                    itemCount: presets.length,
                    itemBuilder: (context, index) => _buildPresetCard(
                      context,
                      presets[index],
                      onSelected: () =>
                          Navigator.pop(dialogContext, presets[index]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (selected == null || !context.mounted) return;
    await _showConnectionEditor(context, initialPreset: selected);
  }

  /// Only the connection half depends on the provider service. The built-in
  /// Marketplace vendors above keep working from the settings service, so this
  /// stays an inline notice rather than taking over the panel.
  Widget _buildOfflineNotice(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: CulpeoColors.inset,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.settings_ethernet_rounded,
            size: 22,
            color: SettingsPalette.textFaint.withValues(alpha: 0.65),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Der sichere Provider-Dienst ist nicht verfügbar.',
                  style: TextStyle(
                    color: SettingsPalette.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Starte oder aktualisiere das Culpeo-Backend und lade diese Ansicht erneut. API-Schlüssel werden bewusst nicht lokal zwischengespeichert.',
                  style: TextStyle(
                    color: SettingsPalette.textMuted,
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: _controller.load,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Erneut versuchen'),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionCard(
    BuildContext context,
    ProviderConnection connection,
  ) {
    final stateColor = _connectionStateColor(connection);
    final isBusy = _controller.syncingConnectionIds.contains(connection.id);
    final testing = _controller.testingConnectionIds.contains(connection.id);
    return CulpeoGridTile(
      semanticLabel: '${connection.name}, ${connection.modelCount} Modelle',
      selected: connection.enabled && connection.lastSyncError.isEmpty,
      onTap: () => _showModelsDialog(context, connection),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProviderLogo(
                icon: providerIconFor(connection.presetId),
                color: providerColorFor(connection.presetId),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  connection.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: CulpeoColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              ProviderStatusDot(color: stateColor),
              PopupMenuButton<_ConnectionAction>(
                tooltip: 'Verbindung verwalten',
                padding: EdgeInsets.zero,
                iconSize: 18,
                color: CulpeoColors.panel,
                onSelected: (action) =>
                    _handleConnectionAction(context, connection, action),
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _ConnectionAction.test,
                    child: Text('Verbindung testen'),
                  ),
                  PopupMenuItem(
                    value: _ConnectionAction.edit,
                    child: Text('Bearbeiten'),
                  ),
                  PopupMenuDivider(),
                  PopupMenuItem(
                    value: _ConnectionAction.delete,
                    child: Text('Verbindung entfernen'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 9),
          CulpeoCardSlot(
            height: 18,
            child: Text(
              connection.baseUrl,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: CulpeoColors.textMuted, fontSize: 10.5),
            ),
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 7,
            runSpacing: 5,
            children: [
              CulpeoStatPill(
                icon: Icons.model_training_outlined,
                label: '${connection.modelCount} Modelle',
                color: CulpeoColors.metric,
              ),
              CulpeoStatPill(
                icon: connection.apiKeySet
                    ? Icons.lock_rounded
                    : Icons.lock_open_rounded,
                label: connection.apiKeySet
                    ? 'Schlüssel gesetzt'
                    : 'Ohne Schlüssel',
                color: connection.apiKeySet
                    ? CulpeoColors.success
                    : CulpeoColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 8),
          CulpeoCardSlot(
            height: 19,
            child: Text(
              _connectionDetail(connection),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: connection.lastSyncError.isNotEmpty
                    ? CulpeoColors.warning
                    : CulpeoColors.textMuted,
                fontSize: 10.5,
              ),
            ),
          ),
          const Spacer(),
          Row(
            children: [
              TextButton.icon(
                onPressed: connection.enabled
                    ? () => _showModelsDialog(context, connection)
                    : null,
                icon: const Icon(Icons.tune_rounded, size: 15),
                label: const Text('Modelle'),
                style: TextButton.styleFrom(
                  foregroundColor: CulpeoColors.metricBright,
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const Spacer(),
              Tooltip(
                message: 'Modellkatalog aktualisieren',
                child: IconButton(
                  onPressed: !connection.enabled || isBusy
                      ? null
                      : () => _syncConnection(context, connection),
                  icon: isBusy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync_rounded, size: 18),
                  color: CulpeoColors.info,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              Tooltip(
                message: 'Verbindung testen',
                child: IconButton(
                  onPressed: testing
                      ? null
                      : () => _testConnection(context, connection),
                  icon: testing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.network_ping_rounded, size: 18),
                  color: SettingsPalette.textSecondary,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPresetCard(
    BuildContext context,
    ProviderPreset preset, {
    VoidCallback? onSelected,
  }) {
    final color = providerColorFor(preset.id);
    final select =
        onSelected ??
        () => _showConnectionEditor(context, initialPreset: preset);
    return CulpeoGridTile(
      semanticLabel: preset.name,
      onTap: preset.available
          ? select
          : () => _showUnavailablePreset(context, preset),
      child: Opacity(
        opacity: preset.available ? 1 : 0.58,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProviderLogo(
                  icon: providerIconFor(preset.id),
                  color: color,
                  size: 40,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        preset.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: CulpeoColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        preset.protocol.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: color,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (preset.localOnly)
                  const CulpeoBadge(
                    label: 'Lokal',
                    color: CulpeoColors.info,
                    icon: Icons.home_outlined,
                  ),
                if (!preset.available)
                  const CulpeoBadge(
                    label: 'Info',
                    color: CulpeoColors.warning,
                    icon: Icons.info_outline_rounded,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Text(
                preset.available
                    ? preset.description
                    : preset.unavailableReason,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: CulpeoColors.textSecondary,
                  fontSize: 11,
                  height: 1.32,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: preset.available
                        ? select
                        : () => _showUnavailablePreset(context, preset),
                    icon: Icon(
                      preset.available
                          ? Icons.add_link_rounded
                          : Icons.info_outline_rounded,
                      size: 15,
                    ),
                    label: Text(preset.available ? 'Verbinden' : 'Hinweis'),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor:
                          (preset.available ? color : CulpeoColors.warning)
                              .withValues(alpha: 0.16),
                      foregroundColor: preset.available
                          ? color
                          : CulpeoColors.warning,
                      side: BorderSide(
                        color: (preset.available ? color : CulpeoColors.warning)
                            .withValues(alpha: 0.4),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
                if (preset.documentationUrl.isNotEmpty) ...[
                  const SizedBox(width: 5),
                  IconButton(
                    onPressed: () =>
                        _openExternalLink(context, preset.documentationUrl),
                    tooltip: 'Anbieter-Dokumentation öffnen',
                    icon: const Icon(Icons.open_in_new_rounded, size: 17),
                    color: SettingsPalette.textSecondary,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleConnectionAction(
    BuildContext context,
    ProviderConnection connection,
    _ConnectionAction action,
  ) async {
    switch (action) {
      case _ConnectionAction.test:
        await _testConnection(context, connection);
      case _ConnectionAction.edit:
        await _showConnectionEditor(context, existing: connection);
      case _ConnectionAction.delete:
        await _confirmDeleteConnection(context, connection);
    }
  }

  Future<void> _testConnection(
    BuildContext context,
    ProviderConnection connection,
  ) async {
    final result = await _controller.testConnection(connection.id);
    if (!context.mounted) return;
    if (result == null) {
      _showError(
        context,
        _controller.lastActionError ?? 'Verbindungstest fehlgeschlagen.',
      );
      return;
    }
    final color = result.reachable
        ? CulpeoColors.success
        : CulpeoColors.warning;
    _showMessage(
      context,
      result.message.isEmpty
          ? (result.reachable
                ? '${connection.name} ist erreichbar (${result.discoveredModelCount} Modelle).'
                : '${connection.name} ist nicht erreichbar.')
          : result.message,
      color,
    );
  }

  Future<void> _syncConnection(
    BuildContext context,
    ProviderConnection connection,
  ) async {
    final result = await _controller.syncConnection(connection.id);
    if (!context.mounted) return;
    if (result == null) {
      _showError(
        context,
        _controller.lastActionError ??
            'Der Modellkatalog konnte nicht aktualisiert werden.',
      );
      return;
    }
    _showMessage(
      context,
      '${result.models.length} aktuelle Modelle von ${connection.name} geladen.',
      CulpeoColors.success,
    );
  }

  Future<void> _showConnectionEditor(
    BuildContext context, {
    ProviderPreset? initialPreset,
    ProviderConnection? existing,
  }) async {
    final availablePresets = _controller.presets
        .where((preset) => preset.available)
        .toList(growable: false);
    if (availablePresets.isEmpty) {
      _showError(context, 'Die Anbieter-Presets konnten nicht geladen werden.');
      return;
    }

    ProviderPreset selectedPreset =
        initialPreset ??
        _presetForId(existing?.presetId) ??
        availablePresets.first;
    if (!selectedPreset.available) {
      selectedPreset = availablePresets.first;
    }

    // Owned by this State rather than by this method: showDialog's future
    // resolves while the route is still animating out and rebuilding once
    // more, so disposing here would leave the fields on dead controllers.
    final nameController = _editorNameController
      ..text = existing?.name ?? selectedPreset.name;
    final baseUrlController = _editorBaseUrlController
      ..text = existing?.baseUrl ?? selectedPreset.defaultBaseUrl;
    final keyController = _editorKeyController..clear();
    var selectedProtocol = existing?.protocol ?? selectedPreset.protocol;
    var enabled = existing?.enabled ?? true;
    var clearApiKey = false;
    var obscureKey = true;
    var isSaving = false;
    var error = '';

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              final isCustom = selectedPreset.id == _customPresetId;
              final color = providerColorFor(selectedPreset.id);
              final apiKeyUrl = providerApiKeyUrlFor(selectedPreset.id);
              return AlertDialog(
                backgroundColor: const Color(0xFF17171E),
                surfaceTintColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
                titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 4),
                title: Row(
                  children: [
                    ProviderLogo(
                      icon: providerIconFor(selectedPreset.id),
                      color: color,
                      size: 40,
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            existing == null
                                ? 'Anbieter verbinden'
                                : 'Verbindung bearbeiten',
                            style: const TextStyle(
                              color: SettingsPalette.textFaint,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            existing?.name ?? selectedPreset.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                content: SizedBox(
                  width: 490,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        providerDialogLabel('ANBIETER'),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<ProviderPreset>(
                          initialValue: selectedPreset,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF202027),
                          decoration: providerDialogInputDecoration(),
                          items: availablePresets
                              .map(
                                (preset) => DropdownMenuItem(
                                  value: preset,
                                  child: Row(
                                    children: [
                                      ProviderLogo(
                                        icon: providerIconFor(preset.id),
                                        color: providerColorFor(preset.id),
                                        size: 22,
                                      ),
                                      const SizedBox(width: 9),
                                      Expanded(
                                        child: Text(
                                          preset.name,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: existing != null
                              ? null
                              : (preset) {
                                  if (preset == null) return;
                                  setDialogState(() {
                                    selectedPreset = preset;
                                    selectedProtocol = preset.protocol;
                                    if (nameController.text.trim().isEmpty ||
                                        nameController.text ==
                                            selectedPreset.name) {
                                      nameController.text = preset.name;
                                    }
                                    baseUrlController.text =
                                        preset.defaultBaseUrl;
                                  });
                                },
                        ),
                        const SizedBox(height: 6),
                        Text(
                          selectedPreset.description,
                          style: const TextStyle(
                            color: SettingsPalette.textMuted,
                            fontSize: 11.5,
                            height: 1.35,
                          ),
                        ),
                        if (selectedPreset.documentationUrl.isNotEmpty)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () => _openExternalLink(
                                dialogContext,
                                selectedPreset.documentationUrl,
                              ),
                              icon: const Icon(
                                Icons.open_in_new_rounded,
                                size: 14,
                              ),
                              label: const Text('API-Dokumentation'),
                              style: TextButton.styleFrom(
                                foregroundColor: CulpeoColors.metricBright,
                                padding: const EdgeInsets.only(
                                  top: 5,
                                  bottom: 5,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                        providerDialogLabel('BEZEICHNUNG'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: nameController,
                          maxLength: 80,
                          style: const TextStyle(
                            color: SettingsPalette.textPrimary,
                          ),
                          decoration: providerDialogInputDecoration(
                            hintText: 'z. B. Firmenkonto oder Privat',
                          ),
                        ),
                        const SizedBox(height: 8),
                        providerDialogLabel('API-BASIS-URL'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: baseUrlController,
                          keyboardType: TextInputType.url,
                          autocorrect: false,
                          enableSuggestions: false,
                          style: const TextStyle(
                            color: SettingsPalette.textPrimary,
                          ),
                          decoration: providerDialogInputDecoration(
                            hintText: selectedPreset.defaultBaseUrl.isEmpty
                                ? 'https://api.example.com/v1'
                                : selectedPreset.defaultBaseUrl,
                          ),
                        ),
                        if (isCustom) ...[
                          const SizedBox(height: 12),
                          providerDialogLabel('PROTOKOLL'),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<ProviderConnectionProtocol>(
                            initialValue: selectedProtocol,
                            dropdownColor: const Color(0xFF202027),
                            decoration: providerDialogInputDecoration(),
                            items: ProviderConnectionProtocol.values
                                .map(
                                  (protocol) => DropdownMenuItem(
                                    value: protocol,
                                    child: Text(protocol.label),
                                  ),
                                )
                                .toList(growable: false),
                            onChanged: (protocol) {
                              if (protocol == null) return;
                              setDialogState(() => selectedProtocol = protocol);
                            },
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            providerDialogLabel(
                              existing == null
                                  ? 'API-SCHLÜSSEL'
                                  : 'NEUEN API-SCHLÜSSEL SETZEN (OPTIONAL)',
                            ),
                            if (selectedPreset.apiKeyRequired &&
                                apiKeyUrl != null) ...[
                              const Spacer(),
                              InkWell(
                                onTap: () =>
                                    _openExternalLink(dialogContext, apiKeyUrl),
                                borderRadius: BorderRadius.circular(4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Schlüssel erstellen',
                                      style: TextStyle(
                                        color: color,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(width: 3),
                                    Icon(
                                      Icons.open_in_new_rounded,
                                      size: 12,
                                      color: color,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: keyController,
                          obscureText: obscureKey,
                          autocorrect: false,
                          enableSuggestions: false,
                          style: const TextStyle(
                            color: SettingsPalette.textPrimary,
                          ),
                          decoration: providerDialogInputDecoration(
                            hintText: selectedPreset.apiKeyRequired
                                ? 'Wird nur einmalig sicher gespeichert'
                                : 'Optional',
                            suffixIcon: IconButton(
                              tooltip: obscureKey
                                  ? 'Schlüssel anzeigen'
                                  : 'Schlüssel verbergen',
                              onPressed: () => setDialogState(
                                () => obscureKey = !obscureKey,
                              ),
                              icon: Icon(
                                obscureKey
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: SettingsPalette.textFaint,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Wird verschlüsselt im Backend gespeichert, damit du ihn nicht bei jeder Sitzung neu eingeben musst. Aus diesem Feld heraus wird er danach nie wieder im Klartext angezeigt.',
                          style: TextStyle(
                            color: SettingsPalette.textFaint,
                            fontSize: 10.5,
                            height: 1.3,
                          ),
                        ),
                        if (existing != null && existing.apiKeySet) ...[
                          const SizedBox(height: 8),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: clearApiKey,
                            dense: true,
                            controlAffinity: ListTileControlAffinity.leading,
                            activeColor: CulpeoColors.danger,
                            title: const Text(
                              'Gespeicherten Schlüssel entfernen',
                              style: TextStyle(
                                color: SettingsPalette.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            onChanged: (value) => setDialogState(
                              () => clearApiKey = value ?? false,
                            ),
                          ),
                        ],
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: enabled,
                          activeThumbColor: CulpeoColors.success,
                          title: const Text(
                            'Verbindung für den Chat aktivieren',
                            style: TextStyle(
                              color: SettingsPalette.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          subtitle: const Text(
                            'Einzelne Modelle werden später separat im Chat-Picker freigegeben.',
                            style: TextStyle(
                              color: SettingsPalette.textFaint,
                              fontSize: 10.5,
                            ),
                          ),
                          onChanged: (value) =>
                              setDialogState(() => enabled = value),
                        ),
                        if (error.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            error,
                            style: const TextStyle(
                              color: CulpeoColors.danger,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isSaving
                        ? null
                        : () => Navigator.pop(dialogContext),
                    child: const Text('Abbrechen'),
                  ),
                  FilledButton.icon(
                    onPressed: isSaving
                        ? null
                        : () async {
                            final name = nameController.text.trim();
                            final baseUrl = baseUrlController.text.trim();
                            final apiKey = keyController.text.trim();
                            if (name.isEmpty || baseUrl.isEmpty) {
                              setDialogState(() {
                                error =
                                    'Bezeichnung und API-Basis-URL sind erforderlich.';
                              });
                              return;
                            }
                            if (selectedPreset.apiKeyRequired &&
                                existing == null &&
                                apiKey.isEmpty) {
                              setDialogState(() {
                                error =
                                    'Für diesen Anbieter wird ein API-Schlüssel benötigt.';
                              });
                              return;
                            }
                            setDialogState(() {
                              isSaving = true;
                              error = '';
                            });
                            // Copy the value only into this in-flight request,
                            // then clear the text controller before awaiting.
                            final writeOnlyKey = apiKey.isEmpty ? null : apiKey;
                            keyController.clear();
                            final result = await _controller.saveConnection(
                              id: existing?.id ?? '',
                              presetId: selectedPreset.id,
                              name: name,
                              protocol: selectedProtocol,
                              baseUrl: baseUrl,
                              apiKey: writeOnlyKey,
                              clearApiKey: clearApiKey,
                              enabled: enabled,
                              syncModels: true,
                            );
                            if (!dialogContext.mounted) return;
                            if (result == null) {
                              setDialogState(() {
                                isSaving = false;
                                error =
                                    _controller.lastActionError ??
                                    'Die Verbindung konnte nicht gespeichert werden.';
                              });
                              return;
                            }
                            Navigator.pop(dialogContext);
                            if (!mounted) return;
                            if (result.syncError.isNotEmpty) {
                              _showMessage(
                                context,
                                'Verbindung gespeichert. Modellabgleich ausstehend: ${result.syncError}',
                                CulpeoColors.warning,
                              );
                            } else {
                              _showMessage(
                                context,
                                'Verbindung gespeichert und ${result.models.length} Modelle aktualisiert.',
                                CulpeoColors.success,
                              );
                            }
                          },
                    icon: isSaving
                        ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined, size: 17),
                    label: Text(isSaving ? 'Speichern …' : 'Sicher speichern'),
                    style: FilledButton.styleFrom(
                      backgroundColor: CulpeoColors.action,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      // The text controller can contain a secret while the dialog is open.
      // Clear it as soon as the dialog is gone, however it was dismissed.
      // Disposal happens with this State, see the controllers' declaration.
      keyController.clear();
    }
  }

  Future<void> _showModelsDialog(
    BuildContext context,
    ProviderConnection initialConnection,
  ) async {
    var loaded = await _controller.loadModels(initialConnection.id);
    if (!context.mounted) return;
    if (loaded == null) {
      _showError(
        context,
        _controller.lastActionError ?? 'Modelle konnten nicht geladen werden.',
      );
      return;
    }
    var connection = loaded.connection;
    var models = loaded.models;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final height = MediaQuery.sizeOf(dialogContext).height * 0.65;
            final syncing = _controller.syncingConnectionIds.contains(
              connection.id,
            );
            return AlertDialog(
              backgroundColor: const Color(0xFF17171E),
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
              titlePadding: const EdgeInsets.fromLTRB(24, 20, 14, 8),
              title: Row(
                children: [
                  ProviderLogo(
                    icon: providerIconFor(connection.presetId),
                    color: providerColorFor(connection.presetId),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${connection.name}: Modelle',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 17),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${models.length} im zuletzt abgerufenen Katalog · aktiviere nur die Modelle, die im Chat erscheinen sollen',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: SettingsPalette.textFaint,
                            fontSize: 10.5,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Modellkatalog aktualisieren',
                    onPressed: syncing
                        ? null
                        : () async {
                            final result = await _controller.syncConnection(
                              connection.id,
                            );
                            if (result == null || !dialogContext.mounted) {
                              return;
                            }
                            setDialogState(() {
                              connection = result.connection;
                              models = result.models;
                            });
                          },
                    icon: syncing
                        ? const SizedBox(
                            width: 17,
                            height: 17,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync_rounded),
                  ),
                ],
              ),
              content: SizedBox(
                width: 720,
                height: height.clamp(280, 520).toDouble(),
                child: models.isEmpty
                    ? const Center(
                        child: Text(
                          'Noch keine Modelle erkannt. Aktualisiere den Katalog oder prüfe den API-Schlüssel.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: SettingsPalette.textMuted),
                        ),
                      )
                    : ListView.separated(
                        itemCount: models.length,
                        separatorBuilder: (context, index) => Divider(
                          color: Colors.white.withValues(alpha: 0.07),
                          height: 1,
                        ),
                        itemBuilder: (context, index) => _buildModelRow(
                          dialogContext,
                          connection,
                          models[index],
                          onChanged: () => setDialogState(() {}),
                        ),
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Schließen'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildModelRow(
    BuildContext dialogContext,
    ProviderConnection connection,
    ProviderModel model, {
    required VoidCallback onChanged,
  }) {
    final active = _controller.activeModelFor(
      connectionId: connection.id,
      modelId: model.id,
    );
    final activating = _controller.isActivating(connection.id, model.id);
    final canActivate =
        connection.enabled && model.chatSupported && !model.deprecated;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            model.chatSupported
                ? Icons.chat_bubble_outline_rounded
                : Icons.info_outline_rounded,
            size: 18,
            color: model.chatSupported
                ? CulpeoColors.info
                : CulpeoColors.textMuted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  model.displayName.isEmpty ? model.id : model.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: model.deprecated
                        ? CulpeoColors.textMuted
                        : CulpeoColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  model.id,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: CulpeoColors.textMuted,
                    fontFamily: 'monospace',
                    fontSize: 10.5,
                  ),
                ),
                if (model.description.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    model.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: SettingsPalette.textFaint,
                      fontSize: 10.5,
                      height: 1.25,
                    ),
                  ),
                ],
                if (model.deprecated || !model.chatSupported) ...[
                  const SizedBox(height: 4),
                  Text(
                    model.deprecated
                        ? 'Vom Anbieter als veraltet markiert'
                        : 'Nicht als Chat-Modell freigegeben',
                    style: const TextStyle(
                      color: CulpeoColors.warning,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (active != null)
            TextButton.icon(
              onPressed: () async {
                final didDeactivate = await _controller.deactivateModel(
                  active.modelRef,
                );
                if (!dialogContext.mounted) return;
                if (!didDeactivate) {
                  _showError(
                    dialogContext,
                    _controller.lastActionError ??
                        'Modell konnte nicht deaktiviert werden.',
                  );
                  return;
                }
                await _notifyActiveModelsChanged();
                onChanged();
              },
              icon: const Icon(Icons.check_circle_rounded, size: 16),
              label: const Text('Im Chat'),
              style: TextButton.styleFrom(
                foregroundColor: CulpeoColors.success,
              ),
            )
          else
            OutlinedButton(
              onPressed: !canActivate || activating
                  ? null
                  : () async {
                      final result = await _controller.activateModel(
                        connectionId: connection.id,
                        model: model,
                      );
                      if (!dialogContext.mounted) return;
                      if (result == null) {
                        _showError(
                          dialogContext,
                          _controller.lastActionError ??
                              'Modell konnte nicht aktiviert werden.',
                        );
                        return;
                      }
                      await _notifyActiveModelsChanged();
                      onChanged();
                    },
              style: OutlinedButton.styleFrom(
                foregroundColor: CulpeoColors.metricBright,
                side: BorderSide(
                  color: CulpeoColors.metric.withValues(alpha: 0.5),
                ),
              ),
              child: activating
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Aktivieren'),
            ),
        ],
      ),
    );
  }

  Future<void> _notifyActiveModelsChanged() async {
    final callback = widget.onActiveModelsChanged;
    if (callback != null) await callback();
  }

  Future<void> _confirmDeleteConnection(
    BuildContext context,
    ProviderConnection connection,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF17171E),
        title: const Text('Verbindung entfernen?'),
        content: Text(
          '${connection.name} wird samt verschlüsseltem Schlüssel, Modellkatalog und Chat-Aktivierungen entfernt. Diese Aktion kann nicht rückgängig gemacht werden.',
          style: const TextStyle(
            color: SettingsPalette.textSecondary,
            height: 1.35,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: CulpeoColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Entfernen'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final deleted = await _controller.deleteConnection(connection.id);
    if (!context.mounted) return;
    if (!deleted) {
      _showError(
        context,
        _controller.lastActionError ??
            'Verbindung konnte nicht entfernt werden.',
      );
      return;
    }
    await _notifyActiveModelsChanged();
    if (!context.mounted) return;
    _showMessage(
      context,
      '${connection.name} wurde entfernt.',
      CulpeoColors.success,
    );
  }

  Future<void> _showUnavailablePreset(
    BuildContext context,
    ProviderPreset preset,
  ) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF17171E),
        title: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: CulpeoColors.warning),
            const SizedBox(width: 10),
            Expanded(child: Text(preset.name)),
          ],
        ),
        content: Text(
          preset.unavailableReason.isNotEmpty
              ? preset.unavailableReason
              : preset.description,
          style: const TextStyle(
            color: SettingsPalette.textSecondary,
            height: 1.4,
          ),
        ),
        actions: [
          if (preset.documentationUrl.isNotEmpty)
            TextButton.icon(
              onPressed: () =>
                  _openExternalLink(dialogContext, preset.documentationUrl),
              icon: const Icon(Icons.open_in_new_rounded, size: 15),
              label: const Text('Dokumentation'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }

  Future<void> _openExternalLink(BuildContext context, String rawUrl) async {
    final error = await openProviderLink(rawUrl);
    if (error != null && context.mounted) _showError(context, error);
  }

  ProviderPreset? _presetForId(String? id) {
    if (id == null) return null;
    for (final preset in _controller.presets) {
      if (preset.id == id) return preset;
    }
    return null;
  }

  String _connectionDetail(ProviderConnection connection) {
    if (connection.lastSyncError.isNotEmpty) {
      return 'Synchronisierung: ${connection.lastSyncError}';
    }
    if (!connection.enabled) return 'Für Chat deaktiviert';
    if (connection.stale) return 'Katalog muss aktualisiert werden';
    final at = connection.lastSyncedAt;
    if (at == null) return 'Noch nicht synchronisiert';
    return 'Zuletzt synchronisiert: ${_shortDate(at)}';
  }

  String _shortDate(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day.$month.${local.year} $hour:$minute';
  }

  Color _connectionStateColor(ProviderConnection connection) {
    if (connection.lastSyncError.isNotEmpty) return CulpeoColors.warning;
    if (!connection.enabled) return CulpeoColors.textMuted;
    if (connection.stale) return CulpeoColors.warning;
    return CulpeoColors.success;
  }

  void _showError(BuildContext context, String message) =>
      _showMessage(context, message, CulpeoColors.danger);

  void _showMessage(BuildContext context, String message, Color color) =>
      showProviderMessage(context, message, color);
}

enum _ConnectionAction { test, edit, delete }
