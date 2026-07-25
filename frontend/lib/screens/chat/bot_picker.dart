import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

import '../../state/app_state.dart';

class BotPicker extends StatelessWidget {
  const BotPicker({
    super.key,
    required this.bots,
    required this.selectedBotId,
    required this.onSelected,
    this.enabled = true,
    this.useBottomSheet,
  });

  final List<PhiloBotChoice> bots;
  final String? selectedBotId;
  final ValueChanged<String?> onSelected;
  final bool enabled;
  final bool? useBottomSheet;

  PhiloBotChoice? get selectedBot {
    for (final bot in bots) {
      if (bot.id == selectedBotId) return bot;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            useBottomSheet ??
            (constraints.hasBoundedWidth && constraints.maxWidth < 600);
        final label = selectedBot?.name ?? 'Automatisch';
        final binding = selectedBot?.modelBinding;
        final button = _BotPickerLabel(
          label: label,
          lockedToModel: binding != null,
        );
        if (compact) {
          return Semantics(
            button: true,
            enabled: enabled,
            label: 'Bot auswählen: $label',
            child: InkWell(
              key: const Key('bot-picker'),
              borderRadius: BorderRadius.circular(8),
              onTap: enabled ? () => _showBottomSheet(context) : null,
              child: button,
            ),
          );
        }
        return PopupMenuButton<String>(
          key: const Key('bot-picker'),
          enabled: enabled,
          tooltip: 'Bot auswählen',
          color: const Color(0xFF0F0F14),
          constraints: const BoxConstraints(minWidth: 300, maxWidth: 420),
          onSelected: (value) => onSelected(value == '__auto__' ? null : value),
          itemBuilder: (context) => [
            _popupItem(null),
            const PopupMenuDivider(),
            ...bots.map((bot) => _popupItem(bot)),
          ],
          child: button,
        );
      },
    );
  }

  Future<void> _showBottomSheet(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
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
          maxHeight: MediaQuery.sizeOf(context).height * 0.72,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Text(
                'Bot auswählen',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Flexible(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                children: [
                  _sheetItem(context, null),
                  ...bots.map((bot) => _sheetItem(context, bot)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (selected != null) {
      onSelected(selected == '__auto__' ? null : selected);
    }
  }

  PopupMenuItem<String> _popupItem(PhiloBotChoice? bot) {
    final id = bot?.id ?? '__auto__';
    final selected =
        bot?.id == selectedBotId || (bot == null && selectedBotId == null);
    return PopupMenuItem<String>(
      key: Key('bot-choice-$id'),
      value: id,
      height: 52,
      child: _BotChoiceRow(bot: bot, selected: selected),
    );
  }

  Widget _sheetItem(BuildContext context, PhiloBotChoice? bot) {
    final id = bot?.id ?? '__auto__';
    final selected =
        bot?.id == selectedBotId || (bot == null && selectedBotId == null);
    return ListTile(
      key: Key('bot-sheet-choice-$id'),
      minTileHeight: 52,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onTap: () => Navigator.pop(context, id),
      title: _BotChoiceRow(bot: bot, selected: selected),
    );
  }
}

class _BotPickerLabel extends StatelessWidget {
  const _BotPickerLabel({required this.label, required this.lockedToModel});

  final String label;
  final bool lockedToModel;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final textPrimary = AppColors.textPrimary(brightness);
    final textSecondary = AppColors.textSecondary(brightness);
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: textPrimary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider(brightness)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.smart_toy_outlined, size: 16, color: textSecondary),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (lockedToModel) ...[
            const SizedBox(width: 6),
            const Tooltip(
              message: 'Dieser Bot verwendet immer sein fest gebundenes Modell',
              child: Icon(Icons.link, size: 14, color: Color(0xFFEBD9A8)),
            ),
          ],
          const SizedBox(width: 4),
          Icon(Icons.keyboard_arrow_down, size: 16, color: textSecondary),
        ],
      ),
    );
  }
}

class _BotChoiceRow extends StatelessWidget {
  const _BotChoiceRow({required this.bot, required this.selected});

  final PhiloBotChoice? bot;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final binding = bot?.modelBinding;
    return Row(
      children: [
        Icon(
          bot == null ? Icons.auto_awesome : Icons.smart_toy_outlined,
          color: selected ? const Color(0xFFDFC077) : Colors.white54,
          size: 18,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                bot?.name ?? 'Automatisch',
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white70,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              Text(
                bot == null
                    ? 'Bot anhand der Nachricht auswählen'
                    : binding == null
                    ? 'Verwendet die normale Modellauswahl'
                    : 'Fest verbunden: ${binding.displayName.isNotEmpty ? binding.displayName : binding.modelId}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ),
        if (binding != null)
          const Icon(Icons.link, size: 15, color: Color(0xFFEBD9A8)),
        if (selected) ...[
          const SizedBox(width: 8),
          const Icon(Icons.check, size: 16, color: Color(0xFFDFC077)),
        ],
      ],
    );
  }
}
