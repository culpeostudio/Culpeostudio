import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/api_service.dart';
import '../../core/culpeo_grid.dart';
import '../../core/design_tokens.dart';
import '../settings/settings_api.dart';
import '../settings/settings_widgets.dart';
import 'provider_visuals.dart';

/// A vendor that ships with Culpeo Studio instead of being added as a
/// connection.  Its models are downloaded or enabled in the Marketplace, so it
/// has no catalogue to browse here — only a key to store.
class MarketplaceProvider {
  const MarketplaceProvider({
    required this.id,
    required this.name,
    required this.description,
    required this.keyLabel,
  });

  final String id;
  final String name;
  final String description;

  /// Vendors differ in what they call the credential; using their own wording
  /// keeps the field recognizable next to the page that issues it.
  final String keyLabel;
}

const marketplaceProviders = <MarketplaceProvider>[
  MarketplaceProvider(
    id: 'huggingface',
    name: 'HuggingFace',
    description:
        'Quelle für lokale Modelle. Ein Token hebt das Rate-Limit an und öffnet Repos, die eine Zustimmung verlangen.',
    keyLabel: 'Access Token',
  ),
  MarketplaceProvider(
    id: 'openrouter',
    name: 'OpenRouter',
    description:
        'Ein Zugang zu vielen Modell-Anbietern mit zentralem Katalog, Preisen und Kontextdaten.',
    keyLabel: 'API-Schlüssel',
  ),
  MarketplaceProvider(
    id: 'featherless',
    name: 'Featherless',
    description:
        'Gehostete Open-Weight-Modelle über einen OpenAI-kompatiblen Endpunkt.',
    keyLabel: 'API-Schlüssel',
  ),
];

/// The always-present half of the Anbieter view.
///
/// These three vendors are not picked from the catalogue and cannot be
/// removed: they are part of the app, and the only thing the user owns is the
/// key.  The key itself is write-only — the backend returns whether one is
/// stored, never the value, so nothing here caches it.
class MarketplaceProvidersSection extends StatefulWidget {
  const MarketplaceProvidersSection({super.key, this.api});

  final SettingsApi? api;

  @override
  State<MarketplaceProvidersSection> createState() =>
      _MarketplaceProvidersSectionState();
}

class _MarketplaceProvidersSectionState
    extends State<MarketplaceProvidersSection> {
  late final SettingsApi _api = widget.api ?? ApiService().settings;

  /// Provider id -> a key is stored for it.  Absent while still loading.
  Map<String, bool> _keyState = const {};
  final Set<String> _testing = {};
  bool _loading = true;
  String _loadError = '';

  @override
  void initState() {
    super.initState();
    unawaited(_loadKeyState());
  }

  Future<void> _loadKeyState() async {
    final result = await _api.getSettings();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.containsKey('error')) {
        _loadError = result['error'].toString();
        return;
      }
      _loadError = '';
      _keyState = {
        for (final provider in marketplaceProviders)
          provider.id: result['${provider.id}_token_set'] == true,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(
              Icons.storefront_outlined,
              size: 15,
              color: CulpeoColors.metricBright,
            ),
            const SizedBox(width: 7),
            const Expanded(
              child: Text(
                'Marktplatz-Anbieter',
                style: TextStyle(
                  color: SettingsPalette.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            if (_loading)
              const SizedBox(
                width: 13,
                height: 13,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Fest eingebaut. Hinterlege nur deinen Schlüssel — die Modelle wählst du danach im Marktplatz aus.',
          style: TextStyle(
            color: SettingsPalette.textMuted,
            fontSize: 11,
            height: 1.35,
          ),
        ),
        if (_loadError.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            'Schlüsselstatus nicht abrufbar: $_loadError',
            style: const TextStyle(color: CulpeoColors.warning, fontSize: 11),
          ),
        ],
        const SizedBox(height: 11),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: culpeoGridDelegate(extent: 186, maxTileWidth: 360),
          itemCount: marketplaceProviders.length,
          itemBuilder: (context, index) =>
              _buildProviderCard(context, marketplaceProviders[index]),
        ),
      ],
    );
  }

  Widget _buildProviderCard(BuildContext context, MarketplaceProvider provider) {
    final color = providerColorFor(provider.id);
    final keySet = _keyState[provider.id] ?? false;
    final testing = _testing.contains(provider.id);
    return CulpeoGridTile(
      semanticLabel: keySet
          ? '${provider.name}, Schlüssel hinterlegt'
          : '${provider.name}, kein Schlüssel hinterlegt',
      selected: keySet,
      onTap: () => _showKeyEditor(provider),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProviderLogo(
                icon: providerIconFor(provider.id),
                color: color,
                size: 34,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: CulpeoColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Modelle über den Marktplatz',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: CulpeoColors.textMuted,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              ProviderStatusDot(
                color: keySet ? CulpeoColors.success : CulpeoColors.textMuted,
              ),
            ],
          ),
          const SizedBox(height: 9),
          Expanded(
            child: Text(
              provider.description,
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
          CulpeoStatPill(
            icon: keySet ? Icons.lock_rounded : Icons.lock_open_rounded,
            label: keySet ? 'Schlüssel gesetzt' : 'Kein Schlüssel',
            color: keySet ? CulpeoColors.success : CulpeoColors.warning,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showKeyEditor(provider),
                  icon: Icon(
                    keySet ? Icons.key_rounded : Icons.add_link_rounded,
                    size: 15,
                  ),
                  label: Text(
                    keySet ? 'Schlüssel' : 'Verknüpfen',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: color.withValues(alpha: 0.16),
                    foregroundColor: color,
                    side: BorderSide(color: color.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Tooltip(
                message: 'Verbindung testen',
                child: IconButton(
                  onPressed: testing ? null : () => _testProvider(provider),
                  icon: testing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.network_ping_rounded, size: 17),
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

  Future<void> _testProvider(MarketplaceProvider provider) async {
    setState(() => _testing.add(provider.id));
    final result = await _api.testProviderConnection(provider.id);
    if (!mounted) return;
    setState(() => _testing.remove(provider.id));
    if (result.containsKey('error')) {
      showProviderMessage(
        context,
        result['error'].toString(),
        CulpeoColors.danger,
      );
      return;
    }
    final reachable = result['reachable'] == true;
    showProviderMessage(
      context,
      '${provider.name}: ${result['message']}',
      reachable ? CulpeoColors.success : CulpeoColors.warning,
    );
  }

  Future<void> _openLink(String url) async {
    final error = await openProviderLink(url);
    if (error != null && mounted) {
      showProviderMessage(context, error, CulpeoColors.danger);
    }
  }

  /// Opens the key dialog and reports the outcome once it is closed.
  ///
  /// The dialog owns its text controller so the secret is disposed with the
  /// route, not when this future resolves: the route is still animating out at
  /// that point and rebuilds once more on the way.
  Future<void> _showKeyEditor(MarketplaceProvider provider) async {
    final outcome = await showDialog<_KeyEditorOutcome>(
      context: context,
      builder: (dialogContext) => _ProviderKeyDialog(
        provider: provider,
        keySet: _keyState[provider.id] ?? false,
        onSave: (value) => _saveKey(provider.id, value),
        onOpenLink: _openLink,
      ),
    );
    if (outcome == null || !mounted) return;
    showProviderMessage(
      context,
      outcome == _KeyEditorOutcome.cleared
          ? '${provider.name}: Schlüssel entfernt'
          : '${provider.name}: Schlüssel gespeichert',
      CulpeoColors.success,
    );
  }

  /// Returns an error message, or null once the new state is reflected here.
  Future<String?> _saveKey(String providerId, String value) async {
    final result = await _api.updateSettings(
      huggingfaceToken: providerId == 'huggingface' ? value : null,
      openrouterToken: providerId == 'openrouter' ? value : null,
      featherlessToken: providerId == 'featherless' ? value : null,
    );
    if (result.containsKey('error')) return result['error'].toString();
    if (!mounted) return null;
    setState(() {
      _keyState = {
        ..._keyState,
        for (final provider in marketplaceProviders)
          if (result.containsKey('${provider.id}_token_set'))
            provider.id: result['${provider.id}_token_set'] == true,
      };
    });
    return null;
  }
}

enum _KeyEditorOutcome { saved, cleared }

/// The key editor as a route-owned widget.
///
/// The controller is created and disposed with this State, so it dies exactly
/// when the route leaves the tree.  Holding it in the calling method instead
/// disposed it while the dialog was still animating out, and the next rebuild
/// hit a dead controller.
class _ProviderKeyDialog extends StatefulWidget {
  const _ProviderKeyDialog({
    required this.provider,
    required this.keySet,
    required this.onSave,
    required this.onOpenLink,
  });

  final MarketplaceProvider provider;
  final bool keySet;

  /// Returns an error message, or null when the key was stored.
  final Future<String?> Function(String value) onSave;
  final Future<void> Function(String url) onOpenLink;

  @override
  State<_ProviderKeyDialog> createState() => _ProviderKeyDialogState();
}

class _ProviderKeyDialogState extends State<_ProviderKeyDialog> {
  final TextEditingController _keyController = TextEditingController();
  bool _obscureKey = true;
  bool _isSaving = false;
  String _error = '';

  @override
  void dispose() {
    // The field can hold a secret while the dialog is open; clear it before
    // the controller is released.
    _keyController.clear();
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _submit({required bool clear}) async {
    final value = clear ? '' : _keyController.text.trim();
    if (!clear && value.isEmpty) {
      setState(() => _error = 'Bitte einen Schlüssel eingeben.');
      return;
    }
    setState(() {
      _isSaving = true;
      _error = '';
    });
    final error = await widget.onSave(value);
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _isSaving = false;
        _error = error;
      });
      return;
    }
    Navigator.pop(
      context,
      clear ? _KeyEditorOutcome.cleared : _KeyEditorOutcome.saved,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final color = providerColorFor(provider.id);
    final keyUrl = providerApiKeyUrlFor(provider.id);
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
            icon: providerIconFor(provider.id),
            color: color,
            size: 40,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Marktplatz-Anbieter verknüpfen',
                  style: TextStyle(
                    color: SettingsPalette.textFaint,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  provider.name,
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
        width: 460,
        // Scrolls so a short window shrinks the dialog instead of overflowing
        // it.
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                provider.description,
                style: const TextStyle(
                  color: SettingsPalette.textMuted,
                  fontSize: 11.5,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              providerDialogLabel(provider.keyLabel.toUpperCase()),
              const SizedBox(height: 6),
              TextField(
                controller: _keyController,
                obscureText: _obscureKey,
                enabled: !_isSaving,
                autofocus: true,
                onSubmitted: (_) => _isSaving ? null : _submit(clear: false),
                decoration: providerDialogInputDecoration(
                  hintText: widget.keySet
                      ? 'Neuen Schlüssel eingeben, um den gespeicherten zu ersetzen'
                      : 'Schlüssel einfügen',
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _obscureKey = !_obscureKey),
                    icon: Icon(
                      _obscureKey
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      size: 18,
                    ),
                    color: SettingsPalette.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.keySet
                    ? 'Es ist bereits ein Schlüssel hinterlegt. Er wird nie zurückgegeben, nur ersetzt oder entfernt.'
                    : 'Der Schlüssel wird im Backend abgelegt und nie an die Oberfläche zurückgegeben.',
                style: const TextStyle(
                  color: SettingsPalette.textFaint,
                  fontSize: 10.5,
                  height: 1.35,
                ),
              ),
              if (keyUrl != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => widget.onOpenLink(keyUrl),
                    icon: const Icon(Icons.open_in_new_rounded, size: 14),
                    label: Text('Schlüssel bei ${provider.name} holen'),
                    style: TextButton.styleFrom(
                      foregroundColor: CulpeoColors.metricBright,
                      padding: const EdgeInsets.symmetric(vertical: 5),
                    ),
                  ),
                ),
              if (_error.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  _error,
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
      actionsPadding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
      actions: [
        if (widget.keySet)
          TextButton(
            onPressed: _isSaving ? null : () => _submit(clear: true),
            style: TextButton.styleFrom(foregroundColor: CulpeoColors.danger),
            child: const Text('Schlüssel entfernen'),
          ),
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : () => _submit(clear: false),
          style: ElevatedButton.styleFrom(
            backgroundColor: CulpeoColors.action,
            foregroundColor: Colors.white,
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Speichern'),
        ),
      ],
    );
  }
}
