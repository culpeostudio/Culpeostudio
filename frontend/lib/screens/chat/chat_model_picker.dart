import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../../engine/models.dart';

enum ChatModelSource { cloud, local }

class ChatModelChoice {
  final ChatModelSource source;
  final String stableKey;
  final String modelRef;
  final String provider;
  final String modelId;
  final String? instanceId;
  final String label;
  final String subtitle;
  final bool selectable;
  final String state;
  final String placement;

  const ChatModelChoice({
    required this.source,
    required this.stableKey,
    required this.modelRef,
    required this.provider,
    required this.modelId,
    required this.label,
    required this.subtitle,
    this.instanceId,
    this.selectable = true,
    this.state = 'ready',
    this.placement = 'unknown',
  });

  bool get isLocal => source == ChatModelSource.local;
  bool get isReady => !isLocal || state == 'ready';
  bool get requiresWarmup => isLocal && !isReady && selectable;
  String get placementLabel {
    final label = switch (placement) {
      'gpu' => 'GPU',
      'ram' => 'RAM',
      'hybrid' => 'GPU + RAM',
      _ => '',
    };
    if (label.isEmpty) return '';
    return isReady ? label : 'Geplant: $label';
  }

  factory ChatModelChoice.cloud(ActiveApiModel model) {
    return ChatModelChoice(
      source: ChatModelSource.cloud,
      stableKey: 'cloud:${model.modelRef}',
      modelRef: model.modelRef,
      provider: model.provider,
      modelId: model.modelId,
      label: model.displayName,
      subtitle: '${model.provider} • ${model.modelId}',
      state: 'ready',
    );
  }

  factory ChatModelChoice.local(EngineInstance instance) {
    final displayName = instance.servedModelName.trim().isNotEmpty
        ? instance.servedModelName.trim()
        : instance.endpointName.trim().isNotEmpty
        ? instance.endpointName.trim()
        : instance.id;
    return ChatModelChoice(
      source: ChatModelSource.local,
      stableKey: 'local:${instance.id}',
      modelRef: 'local:${instance.id}',
      provider: 'local',
      modelId: instance.id,
      instanceId: instance.id,
      label: displayName,
      subtitle: instance.isReady
          ? 'Lokal • Bereit'
          : 'Lokal • Ausgeschaltet – startet bei Auswahl',
      state: instance.state,
      placement: instance.placement,
    );
  }

  factory ChatModelChoice.unavailableSession({
    required String modelRef,
    required String provider,
    required String modelId,
    String? instanceId,
    String? displayName,
  }) {
    final isLocal = provider == 'local' || modelRef.startsWith('local:');
    final stableId = isLocal
        ? (instanceId?.trim().isNotEmpty == true ? instanceId!.trim() : modelId)
        : modelRef;
    return ChatModelChoice(
      source: isLocal ? ChatModelSource.local : ChatModelSource.cloud,
      stableKey: isLocal ? 'local:$stableId' : 'cloud:$modelRef',
      modelRef: modelRef,
      provider: provider,
      modelId: modelId,
      instanceId: isLocal ? stableId : null,
      label: displayName?.trim().isNotEmpty == true
          ? displayName!.trim()
          : modelId,
      subtitle: isLocal
          ? 'Lokal • Derzeit nicht bereit'
          : '$provider • Derzeit nicht aktiv',
      selectable: false,
      state: isLocal ? 'unavailable' : 'ready',
    );
  }

  factory ChatModelChoice.binding(BotModelBinding binding) {
    final isLocal = binding.isLocal;
    final instanceId = binding.instanceId ?? binding.modelId;
    return ChatModelChoice(
      source: isLocal ? ChatModelSource.local : ChatModelSource.cloud,
      stableKey: isLocal ? 'local:$instanceId' : 'cloud:${binding.modelRef}',
      modelRef: binding.modelRef,
      provider: binding.provider,
      modelId: binding.modelId,
      instanceId: isLocal ? instanceId : null,
      label: binding.displayName.isNotEmpty
          ? binding.displayName
          : binding.modelId,
      subtitle: isLocal
          ? 'Lokal • Gebundenes Modell ist nicht verfügbar'
          : '${binding.provider} • Gebundenes Modell ist nicht aktiv',
      selectable: false,
      state: isLocal ? 'unavailable' : 'ready',
    );
  }
}

List<ChatModelChoice> buildChatModelChoices({
  required Iterable<ActiveApiModel> cloudModels,
  required Iterable<EngineInstance> engineInstances,
}) {
  final cloud = cloudModels.map(ChatModelChoice.cloud).toList()
    ..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
  final local =
      engineInstances
          .where(
            (instance) =>
                instance.isVisibleInChat && instance.id.trim().isNotEmpty,
          )
          .map(ChatModelChoice.local)
          .toList()
        ..sort(
          (a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()),
        );
  return [...cloud, ...local];
}

ChatModelChoice? chatModelChoiceFromSessionMetadata(
  Map<String, dynamic> response,
  Iterable<ChatModelChoice> availableChoices,
) {
  final nested = response['session'];
  final metadata = nested is Map ? Map<String, dynamic>.from(nested) : response;
  var modelRef = metadata['model_ref']?.toString().trim() ?? '';
  final provider = metadata['provider']?.toString().trim() ?? '';
  final modelId = metadata['model_id']?.toString().trim() ?? '';
  final instanceId = metadata['instance_id']?.toString().trim() ?? '';
  final displayName = metadata['display_name']?.toString().trim() ?? '';
  final isLocal = provider == 'local' || modelRef.startsWith('local:');
  if (modelRef.isEmpty && isLocal && instanceId.isNotEmpty) {
    modelRef = 'local:$instanceId';
  }
  if (modelRef.isEmpty) return null;
  final stableKey = isLocal
      ? 'local:${instanceId.isNotEmpty ? instanceId : modelId}'
      : 'cloud:$modelRef';
  for (final choice in availableChoices) {
    if (choice.stableKey == stableKey || choice.modelRef == modelRef) {
      return choice;
    }
  }
  return ChatModelChoice.unavailableSession(
    modelRef: modelRef,
    provider: provider,
    modelId: modelId.isNotEmpty ? modelId : instanceId,
    instanceId: instanceId.isEmpty ? null : instanceId,
    displayName: displayName.isEmpty ? null : displayName,
  );
}

class ChatModelPicker extends StatelessWidget {
  static const refreshValue = '__refresh_local_models__';
  static const openEngineValue = '__open_engine__';
  static const manageCloudValue = '__manage_cloud_models__';

  final ChatModelChoice? selected;
  final List<ChatModelChoice> choices;
  final bool loadingLocalModels;
  final String? localModelsError;
  final bool enabled;
  final String? disabledReason;
  final ValueChanged<ChatModelChoice> onSelected;
  final VoidCallback onRefreshLocalModels;
  final VoidCallback onOpenEngine;
  final VoidCallback onManageCloudModels;
  final bool? useBottomSheet;

  const ChatModelPicker({
    super.key,
    required this.selected,
    required this.choices,
    required this.onSelected,
    required this.onRefreshLocalModels,
    required this.onOpenEngine,
    required this.onManageCloudModels,
    this.loadingLocalModels = false,
    this.localModelsError,
    this.enabled = true,
    this.disabledReason,
    this.useBottomSheet,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            useBottomSheet ??
            (constraints.hasBoundedWidth && constraints.maxWidth < 600);
        return compact
            ? _buildBottomSheetTrigger(context)
            : _buildPopupMenu(context);
      },
    );
  }

  Widget _buildPopupMenu(BuildContext context) {
    return _ModelPopupTrigger(
      enabled: enabled,
      tooltip: disabledReason ?? 'Modell für einen neuen Chat auswählen',
      choices: choices,
      selected: selected,
      onSelected: onSelected,
      child: _selectionLabel(maxLabelWidth: 190),
    );
  }

  Widget _buildBottomSheetTrigger(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: disabledReason ?? 'Modell auswählen',
      child: InkWell(
        key: const Key('chat-model-picker'),
        onTap: enabled ? () => _showBottomSheet(context) : null,
        borderRadius: BorderRadius.circular(8),
        child: _selectionLabel(),
      ),
    );
  }

  Widget _selectionLabel({double maxLabelWidth = 150}) {
    final isLocal = selected?.isLocal == true;
    final label =
        selected?.label ??
        (loadingLocalModels ? 'Modelle werden gesucht…' : 'Modell auswählen');
    return Padding(
      key: const Key('chat-model-picker-label'),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLocal ? Icons.memory_outlined : Icons.cloud_outlined,
            size: 18,
            color: isLocal ? const Color(0xFF4ADE80) : const Color(0xFFEBD9A8),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxLabelWidth),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.keyboard_arrow_down,
            size: 12,
            color: Colors.white54,
          ),
        ],
      ),
    );
  }

  Future<void> _showBottomSheet(BuildContext context) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F0F14),
      constraints: const BoxConstraints(maxWidth: 640),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.78,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                'Chat-Modell auswählen',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Flexible(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 20),
                children: [
                  if (choices.isEmpty)
                    _sheetMessage('Noch kein Modell verfügbar')
                  else
                    ...choices.map((choice) => _sheetChoice(context, choice)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    switch (result) {
      case refreshValue:
        onRefreshLocalModels();
      case openEngineValue:
        onOpenEngine();
      case manageCloudValue:
        onManageCloudModels();
      case null:
        return;
      default:
        for (final choice in choices) {
          if (choice.stableKey == result) {
            onSelected(choice);
            return;
          }
        }
    }
  }

  Widget _sheetMessage(String label) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    child: Text(label, style: const TextStyle(color: Colors.white54)),
  );

  Widget _sheetChoice(BuildContext context, ChatModelChoice choice) {
    return ListTile(
      key: Key('chat-model-sheet-choice-${choice.stableKey}'),
      minTileHeight: 54,
      enabled: choice.selectable,
      leading: Icon(
        choice.isLocal ? Icons.memory_outlined : Icons.cloud_outlined,
        color: choice.isLocal ? const Color(0xFF4ADE80) : Colors.white54,
      ),
      title: Text(choice.label),
      subtitle: Text(
        choice.placementLabel.isEmpty
            ? choice.subtitle
            : '${choice.subtitle} • ${choice.placementLabel}',
      ),
      trailing: selected?.stableKey == choice.stableKey
          ? const Icon(Icons.check, color: Color(0xFFDFC077))
          : null,
      onTap: choice.selectable
          ? () => Navigator.pop(context, choice.stableKey)
          : null,
    );
  }
}

class _ModelPopupTrigger extends StatefulWidget {
  const _ModelPopupTrigger({
    required this.enabled,
    required this.tooltip,
    required this.choices,
    required this.selected,
    required this.onSelected,
    required this.child,
  });

  final bool enabled;
  final String tooltip;
  final List<ChatModelChoice> choices;
  final ChatModelChoice? selected;
  final ValueChanged<ChatModelChoice> onSelected;
  final Widget child;

  @override
  State<_ModelPopupTrigger> createState() => _ModelPopupTriggerState();
}

class _ModelPopupTriggerState extends State<_ModelPopupTrigger> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  void _toggle() => _overlayEntry == null ? _show() : _hide();

  void _show() {
    if (!widget.enabled || _overlayEntry != null) return;
    _overlayEntry = OverlayEntry(builder: (context) => _buildOverlay());
    Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);
  }

  void _hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void deactivate() {
    _hide();
    super.deactivate();
  }

  @override
  void dispose() {
    _hide();
    super.dispose();
  }

  Widget _buildOverlay() {
    return Stack(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _hide,
          child: const SizedBox.expand(),
        ),
        CompositedTransformFollower(
          link: _layerLink,
          targetAnchor: Alignment.topLeft,
          followerAnchor: Alignment.bottomLeft,
          offset: const Offset(0, -12),
          child: Material(
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 390, minWidth: 330),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF161617),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: widget.choices.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Noch kein Modell verfügbar',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: widget.choices
                            .map((choice) => _modelRow(choice))
                            .toList(),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _modelRow(ChatModelChoice choice) {
    final selected = widget.selected?.stableKey == choice.stableKey;
    return InkWell(
      key: Key('chat-model-choice-${choice.stableKey}'),
      onTap: choice.selectable
          ? () {
              widget.onSelected(choice);
              _hide();
            }
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(
              choice.isLocal ? Icons.memory_outlined : Icons.cloud_outlined,
              size: 16,
              color: selected
                  ? const Color(0xFFC9A24A)
                  : Colors.white.withValues(alpha: 0.48),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    choice.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white70,
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  Text(
                    choice.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.38),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check, size: 16, color: Color(0xFFC9A24A)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          key: const Key('chat-model-picker'),
          behavior: HitTestBehavior.opaque,
          onTap: widget.enabled ? _toggle : null,
          child: widget.child,
        ),
      ),
    );
  }
}
