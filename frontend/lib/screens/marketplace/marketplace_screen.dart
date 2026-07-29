import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../l10n/marketplace_screen_strings.dart';
import '../../state/app_state.dart';
import '../../services/api_service.dart';
import '../../widgets/top_notification.dart';
import 'filter_option.dart';
import 'fit_details_dialog.dart';
import 'filter_style_preview.dart';
import 'marketplace_format.dart';
import 'model_detail_dialog.dart';
import 'recommendation_tooltip.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen>
    with WidgetsBindingObserver {
  final ApiService _api = ApiService();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  final FocusNode _searchFocusNode = FocusNode();
  StreamSubscription<String>? _actionSubscription;

  String _provider = 'all';
  String _category = '';
  String _sort = 'popularity';
  String _quantization = '';
  bool _gpuFit = false;
  bool _localOnly = false;
  String? _openFilterDropdownGroup;
  bool _showDownloadsPanel = false;
  bool _searchExpanded = false;
  bool _gridView = true;
  int _page = 1;
  bool _hasMore = true;
  bool _isSearching = false;
  String _error = '';
  // C1: Seperate Fehleranzeige fuer page>1 – statt die Liste zu loeschen
  // wird ein Retry-Tile angehaengt.
  bool _pageError = false;
  // H4: Such-Generation – jeder neue Filter/Suchbegriff inkrementiert sie;
  // ein spaet ankommendes Resultat einer alten Generation wird verworfen.
  int _searchGeneration = 0;
  // H2: Backend-Fehler fuer Seitenleiste sichtbar machen.
  String _hardwareError = '';
  String _jobsError = '';
  // C3: In-Flight-Guard fuer Download/Start-Buttons (Mehrfach-Tap erzeugt
  // sonst mehrere Jobs / API-Starts).
  final Set<String> _pendingActions = {};
  // M9: Pro Aktion ein Timeout-Timer. Wenn der Backend-Request haengt oder
  // das Widget unmounted wird, wuerde der In-Flight-Guard sonst ewig aktiv
  // bleiben – der Button zeigt einen endlosen Spinner. Nach ~30s Timeout
  // wird der Key automatisch entfernt und ein Hinweis angezeigt.
  final Map<String, Timer> _actionTimeouts = {};
  static const Duration _actionTimeout = Duration(seconds: 30);
  // H1: Debounce-Timer fuer onChanged im Suchfeld.
  Timer? _debounce;

  List<dynamic> _searchResults = [];
  Map<String, dynamic> _hardwareProfile = {};
  Map<String, dynamic> _backendSettings = {};
  List<dynamic> _downloadJobs = [];
  Timer? _refreshTimer;

  List<FilterOption> get _providers => <FilterOption>[
    FilterOption(tr('marketplaceScreen.filter.all'), 'all'),
    const FilterOption('OpenRouter', 'openrouter'),
    const FilterOption('Featherless', 'featherless'),
    const FilterOption('HuggingFace', 'huggingface'),
  ];

  List<FilterOption> get _categories => <FilterOption>[
    FilterOption(tr('marketplaceScreen.filter.all'), ''),
    FilterOption(tr('marketplaceScreen.filter.chat'), 'chat'),
    FilterOption(tr('marketplaceScreen.filter.code'), 'code'),
    FilterOption(tr('marketplaceScreen.filter.reasoning'), 'reasoning'),
    FilterOption(tr('marketplaceScreen.filter.vision'), 'vision'),
    FilterOption(tr('marketplaceScreen.filter.embedding'), 'embedding'),
  ];

  // C5: Preissortierung filtert im Backend alle Modelle ohne bekannten
  // Preis heraus – lokal-Modelle (HuggingFace) und "Alle" verschwinden
  // dadurch unbemerkt. Wir bieten Preis-Sortiermodi nur explizit fuer
  // Cloud-Provider (OpenRouter/Featherless) an, damit User nicht in eine
  // scheinbar leere Marketplace-Liste starren, wenn sie von HuggingFace auf
  // "Alle" wechseln.
  List<FilterOption> get _baseSortOptions => <FilterOption>[
    FilterOption(tr('marketplaceScreen.sort.popularity'), 'popularity'),
    FilterOption(
      tr('marketplaceScreen.sort.intelligence'),
      'intelligence_score',
    ),
    FilterOption(tr('marketplaceScreen.sort.context'), 'context'),
    FilterOption(tr('marketplaceScreen.sort.newest'), 'newest'),
  ];

  FilterOption get _priceLowHighSort =>
      FilterOption(tr('marketplaceScreen.sort.priceLowHigh'), 'price_low_high');
  FilterOption get _priceHighLowSort =>
      FilterOption(tr('marketplaceScreen.sort.priceHighLow'), 'price_high_low');

  List<FilterOption> _sortOptionsForProvider() {
    // sort=price ist nur fuer reine Cloud-Provider sinnvoll.
    if (_provider == 'openrouter' || _provider == 'featherless') {
      return [..._baseSortOptions, _priceLowHighSort, _priceHighLowSort];
    }
    final selected = _sort;
    final base = [..._baseSortOptions];
    // Behalte die aktuelle Auswahl als sichtbaren Eintrag, auch wenn sie
    // fuer den neuen Provider nicht angeboten wird – sonst springt der
    // Dropdown still von "price_low_high" auf "popularity".
    if (selected == 'price_low_high' || selected == 'price_high_low') {
      base.add(
        selected == 'price_low_high' ? _priceLowHighSort : _priceHighLowSort,
      );
    }
    return base;
  }

  List<FilterOption> get _quantizations => <FilterOption>[
    FilterOption(tr('marketplaceScreen.filter.all'), ''),
    const FilterOption('Q4_K_M', 'Q4_K_M'),
    const FilterOption('Q8_0', 'Q8_0'),
    const FilterOption('FP16', 'FP16'),
    const FilterOption('Safetensors', 'safetensors'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // H3: App-Lifecycle beobachten
    _scrollController.addListener(_onScroll);
    _actionSubscription = AppState().actionStream.listen((action) {
      if (!mounted) return;
      if (action == 'focus_search') {
        _searchFocusNode.requestFocus();
      }
    });
    _fetchHardwareProfile();
    _fetchDownloadJobs();
    _fetchBackendSettings();
    _triggerSearch();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_onScroll);
    _actionSubscription?.cancel();
    _debounce?.cancel();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    _refreshTimer?.cancel();
    // M9: Beim Verlassen des Screens alle Action-Timeouts abbrechen – sonst
    // wuerde ein noch laufender Timer nach dem dispose ein State-Update auf
    // ein nicht mehr vorhandenes Widget ausloesen.
    for (final timer in _actionTimeouts.values) {
      timer.cancel();
    }
    _actionTimeouts.clear();
    _pendingActions.clear();
    super.dispose();
  }

  // Auf Desktop bedeutet "inactive" meist nur, dass ein anderes Fenster den
  // Fokus hat. Der Download-Timer muss dann weiterlaufen, damit der sichtbare
  // Fortschritt nicht einfriert. Nur echtes Pausieren/Beenden stoppt ihn.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _refreshTimer?.cancel();
      _refreshTimer = null;
    } else if (state == AppLifecycleState.resumed) {
      _fetchDownloadJobs(); // beim Zurueckkehren sofort pruefen
    }
  }

  Future<void> _fetchBackendSettings() async {
    final res = await _api.getSettings();
    if (!mounted || res.containsKey('error')) return;
    setState(() => _backendSettings = res);
  }

  // C4: localOnly / GPU-fit / Quantisation sind nur fuer HuggingFace sinnvoll.
  // Bei Cloud-Providern wuerde localOnly (Backend filtert alle Cloud-Modelle
  // heraus) garantiert leere Ergebnisse liefern. Bei "Alle" ist der Toggle
  // sichtbar, weil der Backend dann automatisch auf HuggingFace schaltet.
  bool get _localControlsVisible =>
      _provider == 'huggingface' || _provider == 'all';

  bool get _gpuFitControlVisible => _localControlsVisible;

  Future<void> _fetchHardwareProfile() async {
    final res = await _api.getHardwareProfile();
    if (!mounted) return;
    setState(() {
      // H2: Backend-Fehler sichtbar machen – früher wurde eine
      // {'error': ...}-Map still in _hardwareProfile geparkt und in der
      // Karte als "Keine GPU" angezeigt.
      if (res.containsKey('error')) {
        _hardwareError = res['error'].toString();
      } else {
        _hardwareError = '';
        _hardwareProfile = res;
      }
    });
  }

  Future<void> _fetchDownloadJobs() async {
    final res = await _api.listDownloadJobs();
    if (!mounted) return;

    setState(() {
      if (res.containsKey('error')) {
        _jobsError = res['error'].toString();
        return;
      }
      _jobsError = '';
      _downloadJobs = res['jobs'] ?? [];
    });

    final hasActiveJobs = _downloadJobs.any(
      (job) =>
          job is Map &&
          (job['status'] == 'queued' || job['status'] == 'running'),
    );
    // Aktive Downloads werden sekündlich aktualisiert. Dadurch ist die
    // Geschwindigkeitsanzeige wirklich live, ohne im Leerlauf Requests zu
    // erzeugen: der Timer läuft nur bei queued/running Jobs.
    if (hasActiveJobs && _refreshTimer == null) {
      _refreshTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => _fetchDownloadJobs(),
      );
    }
    if (!hasActiveJobs) {
      _refreshTimer?.cancel();
      _refreshTimer = null;
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    // M16: Frueher 260px Schwelle – auf Desktop mit grossen Cards
    // reicht das nicht, um rechtzeitig nachzuladen.  Wir vergroessern
    // die Schwelle auf 600px, so dass schon beim sichtbaren Naeheren
    // der letzte Kartenreihe der Reload triggert; der "Weitere laden"
    // Button bleibt als Fallback falls onScroll nie feuert.
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 600) {
      if (!_isSearching && _hasMore) {
        _loadNextPage();
      }
    }
  }

  // H1: Debounce-Callback fuer onChanged im Suchfeld. Tippt der User,
  // wird 350ms nach der letzten Aenderung eine neue Suche ausgeloest.
  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _triggerSearch);
  }

  Future<void> _triggerSearch({bool collapseSearch = false}) async {
    _debounce?.cancel();
    if (collapseSearch && _searchExpanded) {
      _searchFocusNode.unfocus();
      setState(() => _searchExpanded = false);
    }
    final gen =
        ++_searchGeneration; // H4: spaet eintreffende alte Antworten verwerfen
    setState(() {
      _isSearching = true;
      _error = '';
      _pageError = false;
      _page = 1;
      _searchResults = [];
      _hasMore = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
    await _loadPage(1, gen);
  }

  Future<void> _loadNextPage() async {
    if (_isSearching || !_hasMore) return;
    // C2: _page wird erst nach erfolgreichem Load erhoeht – schlaegt die
    // Anfrage fehl, bleibt _page bei der letzten erfolgrechen Seite und
    // onScroll kann erneut feuern (mit _hasMore=true via _pageError).
    final gen = _searchGeneration;
    setState(() {
      _isSearching = true;
      _pageError = false;
    });
    await _loadPage(_page + 1, gen);
  }

  Future<void> _loadPage(int page, int generation) async {
    final res = await _api.searchMarketplace(
      query: _searchController.text.trim(),
      provider: _provider,
      category: _category.isNotEmpty ? _category : null,
      sort: _sort,
      quantization: _localControlsVisible && _quantization.isNotEmpty
          ? _quantization
          : null,
      gpuFit: _gpuFitControlVisible ? _gpuFit : false,
      localOnly: _localOnly,
      page: page,
      limit: 24,
    );

    if (!mounted) return;

    // H4: Antwort gehoert zu einer alten Suche (Filter zwischenzeitlich
    // geaendert) – still verwerfen, kein setState mit veralteten Daten.
    if (generation != _searchGeneration) return;

    setState(() {
      if (res.containsKey('error')) {
        // C1: bei page>1 die bereits angezeigte Liste nicht loeschen,
        // sondern ein Retry-Tile anzeigen.
        if (page == 1) {
          _error = res['error'].toString();
          _searchResults = [];
          _hasMore = false;
        } else {
          _pageError = true;
          _hasMore = true; // erlaubt onScroll, erneut zu probieren
        }
      } else {
        // C2: _page erst nach Erfolg commiten.
        _page = page;
        _searchResults.addAll(res['models'] ?? []);
        _hasMore = res['has_more'] ?? false;
        _pageError = false;
      }
      _isSearching = false;
    });

    // Eine große Desktop-Ansicht kann die erste Seite vollständig anzeigen,
    // ohne dass ein Scroll-Event entsteht. Dann laden wir automatisch weiter,
    // bis wirklich gescrollt werden kann oder keine Seite mehr existiert.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          _isSearching ||
          !_hasMore ||
          !_scrollController.hasClients) {
        return;
      }
      if (_scrollController.position.extentAfter < 600) {
        _loadNextPage();
      }
    });
  }

  void _setProvider(String provider) {
    setState(() {
      _provider = provider;
      // C4 + M2: localOnly/GPU-fit/Quantisation sind nur fuer HuggingFace
      // relevant. Bei Cloud-Providern wuerde localOnly garantiert leere
      // Ergebnisse liefern (Backend filtert alle Cloud-Modelle heraus);
      // bei "Alle" setzen wir ebenfalls zurueck, damit "Alle" wirklich alle
      // Provider anzeigt (sonst wuerde der Backend verdeckt auf HF schalten).
      if (provider != 'huggingface') {
        _localOnly = false;
        _quantization = '';
        _gpuFit = false;
      }
      // C5: Preissortierung verschluckt HF-Modelle im Backend. Beim Wechsel
      // vom Cloud-Provider auf HuggingFace/Alle setzen wir sie still auf den
      // Default zurueck, so dass nicht eine scheinbar leere Liste
      // zurueckkommt.
      final isCloudProvider =
          provider == 'openrouter' || provider == 'featherless';
      if (!isCloudProvider &&
          (_sort == 'price_low_high' || _sort == 'price_high_low')) {
        _sort = 'popularity';
      }
    });
    _triggerSearch();
  }

  Future<void> _deleteJob(String id) async {
    final res = await _api.deleteDownloadJob(id);
    if (!mounted) return;
    if (res.containsKey('error')) {
      _showSnack(res['error'].toString(), Colors.redAccent);
      return;
    }
    _showSnack(tr('marketplaceScreen.notification.jobDeleted'), Colors.green);
    _fetchDownloadJobs();
  }

  // M8: User-lesbare Fehlermeldung aus Backend-Fehlern / Netzwerk-Ausfaellen
  // erzeugen, statt rohe "ClientException"-Texte anzuzeigen.
  String _humanizeError(dynamic error) {
    final msg = error?.toString() ?? '';
    final lower = msg.toLowerCase();
    if (lower.contains('socketexception') ||
        lower.contains('clientexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('network')) {
      return tr('marketplaceScreen.error.network');
    }
    if (lower.contains('timeout') || lower.contains('timed out')) {
      return tr('marketplaceScreen.error.timeout');
    }
    if (lower.contains('nicht autorisiert') ||
        lower.contains('(401)') ||
        lower.contains('(403)') ||
        lower.contains('gated repository') ||
        lower.contains('gated')) {
      return tr('marketplaceScreen.error.huggingFaceToken');
    }
    // Bekannte Backend-Strings etwas lesbarer machen.
    if (lower.contains('ungueltiger')) {
      return tr('marketplaceScreen.error.invalidInput');
    }
    if (lower.contains('muss gesetzt sein')) {
      return tr('marketplaceScreen.error.chooseProvider');
    }
    return msg.isEmpty ? tr('marketplaceScreen.error.unknown') : msg;
  }

  Future<void> _downloadModel(
    Map<String, dynamic> model, {
    Map<String, dynamic>? selectedOption,
  }) async {
    // H5: typsichere Map-Zugriffe – frueher wurde dynamic null direkt an
    // String-Parameter gereicht (Crash unter Null-Safety).
    final modelId =
        (model['model_id'] ?? model['id'] ?? model['name'])?.toString() ?? '';
    if (modelId.isEmpty) {
      _showSnack(
        tr('marketplaceScreen.error.modelIdMissing'),
        Colors.redAccent,
      );
      return;
    }
    final provider = (model['provider'] ?? _provider).toString();
    // M7: 'all' als Provider an den Backend schicken wuerde mit 400
    // abgewiesen ("provider muss gesetzt sein"); bevor wir den Request
    // abschicken, pruefen.
    if (provider.isEmpty || provider == 'all') {
      _showSnack(
        tr('marketplaceScreen.error.concreteProvider'),
        Colors.redAccent,
      );
      return;
    }
    final options = model['download_options'];
    // M10: Provider mit mehreren Download-Varianten (vor allem HuggingFace:
    // Q4_K_M, Q5_K_S, Q8_0, FP16, ...) zeigten frueher einen impliziten
    // "ersten Treffer" — der User sah nie, welche Option gewaehlt wurde.
    // Jetzt gibt es einen BottomSheet, falls >1 Option verfuegbar ist.
    // M14: Die gewaehlte Option wird danach samt size_bytes an downloadModel
    // weitergereicht, damit der Backend einen Disk-Space Pre-Check machen
    // kann – so wird der User nicht erst nach langem Warten eine "failed"-
    // Meldung sehen.
    String assetId = '';
    List<String> assetIds = const [];
    int sizeBytes = 0;
    if (options is List && options.isNotEmpty && options.first is Map) {
      Map<String, dynamic> chosen;
      if (selectedOption != null) {
        chosen = selectedOption;
      } else if (options.length > 1) {
        final picked = await _showDownloadOptionPicker(
          modelId,
          options.whereType<Map>().toList(),
        );
        if (!mounted || picked == null) return;
        chosen = Map<String, dynamic>.from(picked);
      } else {
        chosen = Map<String, dynamic>.from(options.first as Map);
      }
      assetId = chosen['asset_id']?.toString() ?? '';
      final rawAssetIDs = chosen['asset_ids'];
      if (rawAssetIDs is List) {
        assetIds = rawAssetIDs
            .map((value) => value.toString().trim())
            .where((value) => value.isNotEmpty)
            .toList();
      }
      sizeBytes = _asInt(chosen['size_bytes']);
    }

    // C3: In-Flight-Guard – Mehrfach-Tap wuerde mehrere Jobs erzeugen.
    final key = 'dl:$provider:$modelId';
    if (!_beginPendingAction(key)) return;

    final res = await _api.downloadModel(
      provider,
      modelId,
      assetId,
      '',
      assetIds: assetIds,
      sizeBytes: sizeBytes,
    );
    await _fetchDownloadJobs();
    if (!mounted) return;
    _endPendingAction(key);

    if (res.containsKey('error')) {
      _showSnack(_humanizeError(res['error']), Colors.redAccent);
    } else if (res['existing'] == true) {
      // M10+M11: Backend-Dedup hat reagiert – derselbe Job laeuft schon.
      _showSnack(
        tr('marketplaceScreen.notification.alreadyDownloading', {
          'jobId': res['job_id']?.toString() ?? '',
        }),
        Colors.orangeAccent,
      );
    } else {
      // M5: cloud-Branch ist tot (Karte ruft fuer cloud _startApiModel),
      // deshalb reicht die "Download gestartet"-Meldung.
      _showSnack(
        tr('marketplaceScreen.notification.downloadStarted', {
          'modelId': modelId,
        }),
        Colors.green,
      );
    }
  }

  // M10: BottomSheet zum Auswaehlen einer konkreten Download-Option. Bei
  // HuggingFace liefern Backend/Provider oft Q4_K_M/Q5/Q8/FP16 nebeneinander;
  // ohne Auswahlscreen sah der User nie, was mit "Download" ueberhaupt
  // gezogen wurde. Rueckgabewert == null == User hat abgebrochen.
  // M10: BottomSheet zum Auswaehlen einer konkreten Download-Option. Bei
  // HuggingFace liefern Backend/Provider oft Q4_K_M/Q5/Q8/FP16 nebeneinander;
  // ohne Auswahlscreen sah der User nie, was mit "Download" ueberhaupt
  // gezogen wurde. Rueckgabewert == null == User hat abgebrochen.
  Future<Map<String, dynamic>?> _showDownloadOptionPicker(
    String modelId,
    List<Map> options,
  ) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: const Color(0xFF16161D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    tr('marketplaceScreen.download.pickVariant', {
                      'modelId': modelId,
                    }),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    tr('marketplaceScreen.download.variantExplanation'),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (ctx, i) {
                      final option = options[i];
                      final label = option['label']?.toString().trim() ?? '';
                      final format = option['format']?.toString().trim() ?? '';
                      final size = _asInt(option['size_bytes']);
                      final labelLower = label.toLowerCase();
                      final formatLower = format.toLowerCase();
                      final isRecommended =
                          labelLower.contains('q4_k_m') ||
                          labelLower.contains('q4_0') ||
                          formatLower.contains('q4');
                      final isMaxQuality =
                          labelLower.contains('q8') ||
                          formatLower.contains('q8') ||
                          labelLower.contains('fp16') ||
                          formatLower.contains('fp16');
                      final isCompact =
                          labelLower.contains('q2') ||
                          labelLower.contains('q3') ||
                          labelLower.contains('q5_k_s');
                      final sizeText = size > 0
                          ? formatBytes(size)
                          : tr('marketplaceScreen.download.unknownSize');
                      final formatText = format.isEmpty ? '' : ' · $format';
                      Color badgeColor;
                      String badgeText;
                      if (isRecommended) {
                        badgeColor = const Color(0xFF4CAF50);
                        badgeText = tr('marketplaceScreen.download.balanced');
                      } else if (isMaxQuality) {
                        badgeColor = const Color(0xFF8E7CFF);
                        badgeText = tr('marketplaceScreen.download.maxQuality');
                      } else if (isCompact) {
                        badgeColor = const Color(0xFFFFC107);
                        badgeText = tr('marketplaceScreen.download.compact');
                      } else {
                        badgeColor = Colors.white.withValues(alpha: 0.3);
                        badgeText = '';
                      }
                      return InkWell(
                        onTap: () =>
                            Navigator.of(ctx).pop<Map<String, dynamic>>(
                              Map<String, dynamic>.from(option),
                            ),
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.02),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isRecommended
                                  ? const Color(
                                      0xFF4CAF50,
                                    ).withValues(alpha: 0.35)
                                  : Colors.white.withValues(alpha: 0.06),
                              width: isRecommended ? 1.5 : 0.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.file_download_rounded,
                                          color: Color(0xFFC9A24A),
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            label.isEmpty
                                                ? (format.isEmpty
                                                      ? tr(
                                                          'marketplaceScreen.download.variant',
                                                          {
                                                            'number': (i + 1)
                                                                .toString(),
                                                          },
                                                        )
                                                      : format)
                                                : label,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        if (badgeText.isNotEmpty) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: badgeColor.withValues(
                                                alpha: 0.15,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              border: Border.all(
                                                color: badgeColor.withValues(
                                                  alpha: 0.4,
                                                ),
                                              ),
                                            ),
                                            child: Text(
                                              badgeText,
                                              style: TextStyle(
                                                color: badgeColor,
                                                fontSize: 9,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          RecommendationTooltip(
                                            isRecommended: isRecommended,
                                            isMaxQuality: isMaxQuality,
                                            isCompact: isCompact,
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.storage_rounded,
                                          size: 12,
                                          color: Colors.white.withValues(
                                            alpha: 0.4,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$sizeText$formatText',
                                          style: TextStyle(
                                            color: Colors.white.withValues(
                                              alpha: 0.5,
                                            ),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _startApiModel(Map<String, dynamic> model) async {
    final modelId =
        (model['model_id'] ?? model['id'] ?? model['name'])?.toString() ?? '';
    if (modelId.isEmpty) {
      _showSnack(
        tr('marketplaceScreen.error.modelIdMissing'),
        Colors.redAccent,
      );
      return;
    }
    final provider = (model['provider'] ?? _provider).toString();
    if (provider.isEmpty || provider == 'all') {
      _showSnack(
        tr('marketplaceScreen.error.concreteProvider'),
        Colors.redAccent,
      );
      return;
    }
    final displayName = _firstText(model, [
      'display_name',
      'name',
      'model_id',
    ], modelId);

    final key = 'api:$provider:$modelId';
    if (!_beginPendingAction(key)) return;

    final res = await _api.startAPIModelForChat(provider, modelId, displayName);
    if (!mounted) return;
    if (res.containsKey('error')) {
      _endPendingAction(key);
      _showSnack(_humanizeError(res['error']), Colors.redAccent);
      return;
    }

    await AppState().refreshActiveApiModels();
    if (!mounted) return;
    _endPendingAction(key);
    _showSnack(
      tr('marketplaceScreen.notification.chatStarted', {'name': displayName}),
      Colors.green,
    );
  }

  void _showSnack(String message, Color color) {
    showTopNotification(context, message, color: color);
  }

  bool _beginPendingAction(String actionKey) {
    if (_pendingActions.contains(actionKey)) return false;
    _pendingActions.add(actionKey);
    _actionTimeouts[actionKey]?.cancel();
    _actionTimeouts[actionKey] = Timer(_actionTimeout, () {
      // Bindung an this.mounted passiert via setState-Check im caller,
      // aber wir muessen hier trotzdem sicherheitshalber pruefen, weil
      // der Timer auch nach dispose noch feuern koennte (klar via dispose,
      // aber defensiv gegenuber unvorhergesehenen Reihenfolgen).
      if (!mounted) {
        _pendingActions.remove(actionKey);
        _actionTimeouts.remove(actionKey);
        return;
      }
      setState(() {
        _pendingActions.remove(actionKey);
        _actionTimeouts.remove(actionKey);
      });
      _showSnack(
        tr('marketplaceScreen.notification.actionTimedOut'),
        Colors.orangeAccent,
      );
    });
    return true;
  }

  void _endPendingAction(String actionKey) {
    final timer = _actionTimeouts.remove(actionKey);
    timer?.cancel();
    setState(() => _pendingActions.remove(actionKey));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState(),
      builder: (context, _) => Scaffold(
        backgroundColor: Colors.transparent,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1100;
            final drawerWidth = wide ? 380.0 : constraints.maxWidth * 0.94;
            return Stack(
              children: [
                Positioned.fill(child: _buildCatalog()),
                Align(
                  alignment: Alignment.centerRight,
                  child: IgnorePointer(
                    ignoring: !_showDownloadsPanel,
                    child: AnimatedSlide(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      offset: _showDownloadsPanel
                          ? Offset.zero
                          : const Offset(1.06, 0),
                      child: SizedBox(
                        width: drawerWidth,
                        height: constraints.maxHeight,
                        child: _buildDownloadDrawer(),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCatalog() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildToolbar(),
        _buildFilters(),
        const SizedBox(height: 12),
        Expanded(child: _buildResults()),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      key: const ValueKey('marketplace-toolbar'),
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF16161D).withValues(alpha: 0.22),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.045)),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const actionsWidth = 208.0;
          final availableSearchWidth = constraints.maxWidth - actionsWidth - 14;
          final expandedSearchWidth = availableSearchWidth
              .clamp(210.0, 520.0)
              .toDouble();

          // Die Suche ist Teil der Desktop-Kopfzeile wie in der Referenz.
          // Nur in sehr schmalen Fenstern bleibt die bekannte einklappbare
          // Variante erhalten, damit die vorhandenen Toolbar-Aktionen nicht
          // gequetscht werden.
          if (constraints.maxWidth >= 470) {
            return Row(
              children: [
                _buildExpandedSearch(expandedSearchWidth),
                const Spacer(),
                _buildToolbarActions(),
              ],
            );
          }

          return Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.centerLeft,
                  child: _searchExpanded
                      ? _buildExpandedSearch(expandedSearchWidth)
                      : _buildCollapsedSearch(),
                ),
              ),
              Positioned(top: 0, right: 0, child: _buildToolbarActions()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildExpandedSearch(double width) {
    return Container(
      key: const ValueKey('expanded-search'),
      width: width,
      height: 48,
      decoration: _panelDecoration(),
      child: TextField(
        key: const ValueKey('marketplace-search-input'),
        focusNode: _searchFocusNode,
        controller: _searchController,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        onChanged: _onSearchChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: tr('marketplaceScreen.searchHint'),
          hintStyle: const TextStyle(color: Colors.white30),
          // Der Rahmen kommt allein vom umgebenden Panel. Ohne das explizite
          // Abschalten setzt das globale inputDecorationTheme zusaetzlich einen
          // eigenen (enger gerundeten) Rahmen und es entsteht ein Doppelrand.
          filled: false,
          contentPadding: const EdgeInsets.fromLTRB(0, 14, 12, 14),
          prefixIcon: const Icon(Icons.search_rounded, size: 19),
          prefixIconColor: Colors.white38,
          suffixIcon: Tooltip(
            message: tr('marketplaceScreen.search.submit'),
            child: IconButton(
              onPressed: () => _triggerSearch(collapseSearch: true),
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              style: IconButton.styleFrom(
                hoverColor: const Color(0xFFC9A24A).withValues(alpha: 0.22),
              ),
            ),
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
        ),
        onSubmitted: (_) => _triggerSearch(collapseSearch: true),
      ),
    );
  }

  Widget _buildCollapsedSearch() {
    return Container(
      key: const ValueKey('collapsed-search'),
      width: 44,
      height: 48,
      decoration: _panelDecoration(),
      child: Tooltip(
        message: tr('marketplaceScreen.search.open'),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _openSearch,
          child: const Center(child: Icon(Icons.search_rounded, size: 19)),
        ),
      ),
    );
  }

  Widget _buildToolbarActions() {
    return Container(
      key: const ValueKey('marketplace-toolbar-actions'),
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      decoration: _panelDecoration(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToolbarIconControl(
            controlKey: const ValueKey('marketplace-toolbar-wiki'),
            tooltip: tr('marketplaceScreen.wiki.title'),
            accent: const Color(0xFFBAA6FF),
            onPressed: _showMarketplaceWiki,
            icon: Icons.menu_book_outlined,
          ),
          const SizedBox(width: 6),
          _buildToolbarActionDivider(),
          const SizedBox(width: 6),
          _buildToolbarIconControl(
            controlKey: const ValueKey('marketplace-toolbar-downloads'),
            tooltip: _showDownloadsPanel
                ? tr('marketplaceScreen.downloads.close')
                : tr('marketplaceScreen.downloads.title'),
            accent: const Color(0xFFC9A24A),
            selected: _showDownloadsPanel,
            onPressed: () =>
                setState(() => _showDownloadsPanel = !_showDownloadsPanel),
            icon: _showDownloadsPanel
                ? Icons.close_rounded
                : Icons.download_for_offline_rounded,
          ),
          const SizedBox(width: 6),
          _buildToolbarActionDivider(),
          const SizedBox(width: 6),
          Container(
            height: 34,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.025),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildToolbarIconControl(
                  controlKey: const ValueKey('marketplace-toolbar-view-grid'),
                  tooltip: tr('marketplaceScreen.view.grid'),
                  accent: const Color(0xFFC9A24A),
                  selected: _gridView,
                  size: 28,
                  icon: Icons.grid_view_rounded,
                  onPressed: () => setState(() => _gridView = true),
                ),
                const SizedBox(width: 2),
                _buildToolbarIconControl(
                  controlKey: const ValueKey('marketplace-toolbar-view-list'),
                  tooltip: tr('marketplaceScreen.view.list'),
                  accent: const Color(0xFFC9A24A),
                  selected: !_gridView,
                  size: 28,
                  icon: Icons.view_list_rounded,
                  onPressed: () => setState(() => _gridView = false),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarIconControl({
    required Key controlKey,
    required String tooltip,
    required Color accent,
    required IconData icon,
    required VoidCallback onPressed,
    bool selected = false,
    double size = 34,
  }) {
    final cornerRadius = BorderRadius.circular(size <= 28 ? 4 : 6);
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        selected: selected,
        label: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: controlKey,
            borderRadius: cornerRadius,
            onTap: onPressed,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: selected
                    ? accent.withValues(alpha: 0.17)
                    : Colors.white.withValues(alpha: 0.012),
                borderRadius: cornerRadius,
                border: Border.all(
                  color: selected
                      ? accent.withValues(alpha: 0.48)
                      : Colors.white.withValues(alpha: 0.045),
                ),
              ),
              child: Icon(
                icon,
                size: size <= 28 ? 16 : 18,
                color: selected ? accent : accent.withValues(alpha: 0.78),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolbarActionDivider() {
    return Container(
      width: 1,
      height: 20,
      color: Colors.white.withValues(alpha: 0.08),
    );
  }

  void _openSearch() {
    if (_searchExpanded) return;
    setState(() => _searchExpanded = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocusNode.requestFocus();
    });
  }

  void _showMarketplaceWiki() {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF17171F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 560),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.menu_book_rounded,
                      color: Color(0xFF8E7CFF),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        tr('marketplaceScreen.wiki.title'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: tr('marketplaceScreen.wiki.close'),
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, size: 19),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  tr('marketplaceScreen.wiki.intro'),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.62),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC9A24A).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFC9A24A).withValues(alpha: 0.28),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 17,
                        color: Color(0xFFDFC077),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          tr('marketplaceScreen.wiki.quickStart'),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                _wikiItem(
                  Icons.category_outlined,
                  tr('marketplaceScreen.wiki.categoryTitle'),
                  tr('marketplaceScreen.wiki.categoryText'),
                  const Color(0xFFDFC077),
                ),
                _wikiItem(
                  Icons.cloud_outlined,
                  tr('marketplaceScreen.wiki.providerTitle'),
                  tr('marketplaceScreen.wiki.providerText'),
                  const Color(0xFFBAA6FF),
                ),
                _wikiItem(
                  Icons.tune_rounded,
                  tr('marketplaceScreen.wiki.quantizationTitle'),
                  tr('marketplaceScreen.wiki.quantizationText'),
                  const Color(0xFF4DD0E1),
                ),
                _wikiItem(
                  Icons.inventory_2_outlined,
                  tr('marketplaceScreen.wiki.formatsTitle'),
                  tr('marketplaceScreen.wiki.formatsText'),
                  const Color(0xFFEBD9A8),
                ),
                _wikiItem(
                  Icons.memory_rounded,
                  tr('marketplaceScreen.wiki.vramTitle'),
                  tr('marketplaceScreen.wiki.vramText'),
                  const Color(0xFF81C784),
                ),
                _wikiItem(
                  Icons.download_for_offline_rounded,
                  tr('marketplaceScreen.wiki.downloadsTitle'),
                  tr('marketplaceScreen.wiki.downloadsText'),
                  const Color(0xFFFFC107),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _wikiItem(IconData icon, String title, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  text,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.58),
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      key: const ValueKey('marketplace-filter-strip'),
      decoration: BoxDecoration(
        color: const Color(0xFF16161D).withValues(alpha: 0.34),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.045)),
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.055)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 9),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final primaryGroups = _buildPrimaryFilterGroups();
                final quickFilters = _buildQuickFilterControls();

                Widget primaryFilterRow() {
                  return KeyedSubtree(
                    key: const ValueKey('marketplace-primary-filter-row'),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 7,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: primaryGroups,
                    ),
                  );
                }

                // Auf breiten Desktop-Flaechen entspricht die Leiste der
                // horizontalen Referenz: Gruppen links, Schnellfilter rechts.
                // Darunter faellt sie kontrolliert in eine mehrzeilige Wrap-
                // Anordnung statt einen RenderFlex-Overflow zu erzeugen.
                if (constraints.maxWidth >= 2100) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: primaryFilterRow()),
                      if (quickFilters.isNotEmpty) ...[
                        const SizedBox(width: 14),
                        _buildFilterDivider(),
                        const SizedBox(width: 14),
                        Wrap(
                          spacing: 7,
                          runSpacing: 7,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: quickFilters,
                        ),
                      ],
                    ],
                  );
                }

                return KeyedSubtree(
                  key: const ValueKey('marketplace-primary-filter-row'),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 7,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ...primaryGroups,
                      if (quickFilters.isNotEmpty) ...[
                        _buildFilterDivider(),
                        ...quickFilters,
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
          _buildFilterStatusRow(),
        ],
      ),
    );
  }

  List<Widget> _buildPrimaryFilterGroups() {
    return [
      _buildFilterLabel(),
      _buildFilterDivider(),
      _buildInlineFilterGroup(
        group: 'provider',
        label: tr('marketplaceScreen.filters.provider'),
        options: _providers,
        value: _provider,
        onSelected: _setProvider,
      ),
      _buildFilterDivider(),
      _buildFilterDropdown(
        group: 'category',
        label: tr('marketplaceScreen.filters.category'),
        options: _categories,
        value: _category,
        width: 150,
        dropdownKey: const ValueKey('marketplace-category-dropdown'),
        onSelected: (value) {
          setState(() => _category = value);
          _triggerSearch();
        },
      ),
      if (_gpuFitControlVisible) ...[
        _buildFilterDivider(),
        _buildFilterDropdown(
          group: 'quantization',
          label: tr('marketplaceScreen.filters.quantization'),
          options: _quantizations,
          value: _quantization,
          width: 138,
          dropdownKey: const ValueKey('marketplace-quantization-dropdown'),
          onSelected: (value) {
            setState(() => _quantization = value);
            _triggerSearch();
          },
        ),
      ],
      _buildFilterDivider(),
      _buildFilterDropdown(
        group: 'sort',
        label: tr('marketplaceScreen.filters.sort'),
        options: _sortOptionsForProvider(),
        value: _sort,
        width: 178,
        dropdownKey: const ValueKey('marketplace-sort-dropdown'),
        onSelected: (value) {
          setState(() => _sort = value);
          _triggerSearch();
        },
      ),
    ];
  }

  List<Widget> _buildQuickFilterControls() {
    return [
      if (_localControlsVisible)
        _buildToggleBubble(
          label: tr('marketplaceScreen.filters.localOnly'),
          icon: Icons.download_for_offline_outlined,
          selected: _localOnly,
          color: const Color(0xFFFFC107),
          onTap: () {
            setState(() {
              _localOnly = !_localOnly;
              if (!_localOnly) {
                _quantization = '';
                _gpuFit = false;
              }
            });
            _triggerSearch();
          },
        ),
      if (_gpuFitControlVisible)
        _buildToggleBubble(
          label: tr('marketplaceScreen.filters.gpuOnly'),
          icon: Icons.memory_rounded,
          selected: _gpuFit,
          color: const Color(0xFF66BB6A),
          onTap: () {
            setState(() {
              _gpuFit = !_gpuFit;
              if (_gpuFit) _localOnly = true;
            });
            _triggerSearch();
          },
        ),
    ];
  }

  Widget _buildFilterLabel() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.tune_rounded, size: 15, color: Color(0xFFC9A24A)),
        const SizedBox(width: 6),
        Text(
          tr('marketplaceScreen.filters.title'),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterDivider() {
    return Container(
      width: 1,
      height: 38,
      color: Colors.white.withValues(alpha: 0.08),
    );
  }

  Widget _buildInlineFilterGroup({
    required String group,
    required String label,
    required List<FilterOption> options,
    required String value,
    required ValueChanged<String> onSelected,
  }) {
    return Tooltip(
      message: _filterHelp(group),
      child: Wrap(
        spacing: 5,
        runSpacing: 5,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            '$label:',
            style: const TextStyle(color: Colors.white54, fontSize: 10.5),
          ),
          ...options.map(
            (option) => _buildChoiceChip(
              option.label,
              option.value,
              value,
              onSelected,
              _filterOptionColor(group, option.value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String group,
    required String label,
    required List<FilterOption> options,
    required String value,
    required double width,
    required Key dropdownKey,
    required ValueChanged<String> onSelected,
  }) {
    final selectedColor = _filterOptionColor(group, value);
    final selectedLabel = _optionLabel(options, value);
    final isOpen = _openFilterDropdownGroup == group;
    final borderColor = selectedColor.withValues(alpha: 0.32);
    return Tooltip(
      message: _filterHelp(group),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label:',
            style: const TextStyle(color: Colors.white54, fontSize: 10.5),
          ),
          const SizedBox(width: 5),
          PopupMenuButton<String>(
            key: dropdownKey,
            tooltip: _filterHelp(group),
            padding: EdgeInsets.zero,
            position: PopupMenuPosition.under,
            offset: const Offset(0, -1),
            constraints: BoxConstraints.tightFor(width: width),
            menuPadding: const EdgeInsets.all(4),
            color: const Color(0xFF17171F),
            surfaceTintColor: Colors.transparent,
            shadowColor: Colors.black.withValues(alpha: 0.58),
            elevation: 10,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.zero,
                topRight: Radius.zero,
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
              side: BorderSide(color: selectedColor.withValues(alpha: 0.52)),
            ),
            onOpened: () {
              setState(() => _openFilterDropdownGroup = group);
            },
            onCanceled: () {
              if (_openFilterDropdownGroup == group) {
                setState(() => _openFilterDropdownGroup = null);
              }
            },
            onSelected: (selectedValue) {
              if (_openFilterDropdownGroup == group) {
                setState(() => _openFilterDropdownGroup = null);
              }
              onSelected(selectedValue);
            },
            itemBuilder: (context) => options.map((option) {
              final optionColor = _filterOptionColor(group, option.value);
              final selected = option.value == value;
              return PopupMenuItem<String>(
                key: ValueKey(
                  'marketplace-filter-option-$group-${option.value}',
                ),
                value: option.value,
                height: 36,
                padding: EdgeInsets.zero,
                child: Container(
                  key: selected
                      ? ValueKey(
                          'marketplace-filter-option-selected-$group-${option.value}',
                        )
                      : null,
                  height: 32,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? optionColor.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: selected
                          ? optionColor.withValues(alpha: 0.38)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: optionColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          option.label,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: selected ? optionColor : Colors.white70,
                            fontSize: 10.5,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                      if (selected)
                        Icon(Icons.check_rounded, size: 15, color: optionColor),
                    ],
                  ),
                ),
              );
            }).toList(),
            child: Container(
              key: ValueKey('marketplace-$group-dropdown-trigger'),
              width: width,
              height: 30,
              padding: const EdgeInsets.only(left: 8, right: 4),
              decoration: BoxDecoration(
                color: selectedColor.withValues(alpha: 0.075),
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(8),
                  bottom: Radius.circular(isOpen ? 0 : 8),
                ),
                border: Border(
                  top: BorderSide(color: borderColor),
                  left: BorderSide(color: borderColor),
                  right: BorderSide(color: borderColor),
                  bottom: isOpen
                      ? BorderSide.none
                      : BorderSide(color: borderColor),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedLabel,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.expand_more_rounded,
                    size: 17,
                    color: selectedColor.withValues(alpha: 0.88),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterStatusRow() {
    final activeFilters = _activeFilters();
    return Container(
      key: const ValueKey('marketplace-active-filters'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.045)),
        ),
      ),
      child: Wrap(
        spacing: 7,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.filter_alt_outlined,
                size: 14,
                color: Color(0xFFC9A24A),
              ),
              const SizedBox(width: 5),
              Text(
                tr('marketplaceScreen.filters.activeTitle'),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (activeFilters.isEmpty)
            _buildEmptyFilterStatus()
          else
            ...activeFilters.map(_buildActiveFilterBadge),
        ],
      ),
    );
  }

  Widget _buildEmptyFilterStatus() {
    return Container(
      key: const ValueKey('marketplace-empty-filter-state'),
      height: 25,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline_rounded, size: 13),
          const SizedBox(width: 5),
          Text(
            tr('marketplaceScreen.filters.statusDefault'),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.52),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilterBadge(
    ({String group, String value, String label, Color color}) filter,
  ) {
    return Tooltip(
      message: filter.label,
      child: Container(
        key: ValueKey(
          'marketplace-active-filter-${filter.group}-${filter.value}',
        ),
        height: 25,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: filter.color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: filter.color.withValues(alpha: 0.42)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: filter.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              filter.label,
              style: TextStyle(
                color: filter.color.withValues(alpha: 0.96),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<({String group, String value, String label, Color color})>
  _activeFilters() {
    final filters =
        <({String group, String value, String label, Color color})>[];
    if (_provider != 'all') {
      filters.add((
        group: 'provider',
        value: _provider,
        label: _optionLabel(_providers, _provider),
        color: _getProviderColor(_provider),
      ));
    }
    if (_category.isNotEmpty) {
      filters.add((
        group: 'category',
        value: _category,
        label: _optionLabel(_categories, _category),
        color: marketplaceTagColor(_category),
      ));
    }
    if (_quantization.isNotEmpty && _localControlsVisible) {
      filters.add((
        group: 'quantization',
        value: _quantization,
        label: _optionLabel(_quantizations, _quantization),
        color: _filterOptionColor('quantization', _quantization),
      ));
    }
    if (_localOnly) {
      filters.add((
        group: 'local',
        value: 'local',
        label: tr('marketplaceScreen.filters.localOnly'),
        color: const Color(0xFFFFC107),
      ));
    }
    if (_gpuFit) {
      filters.add((
        group: 'gpu',
        value: 'fit',
        label: tr('marketplaceScreen.filters.gpuOnly'),
        color: const Color(0xFF66BB6A),
      ));
    }
    if (_sort != 'popularity') {
      filters.add((
        group: 'sort',
        value: _sort,
        label: _optionLabel(_sortOptionsForProvider(), _sort),
        color: const Color(0xFF8E7CFF),
      ));
    }
    return filters;
  }

  String _optionLabel(List<FilterOption> options, String value) {
    for (final option in options) {
      if (option.value == value) return option.label;
    }
    return value;
  }

  Widget _buildChoiceChip(
    String label,
    String value,
    String groupValue,
    ValueChanged<String> onSelected,
    Color accent,
  ) {
    final selected = value == groupValue;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      labelStyle: TextStyle(
        color: selected ? Colors.white : accent.withValues(alpha: 0.86),
        fontSize: 10.5,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
      selectedColor: accent.withValues(alpha: 0.38),
      backgroundColor: accent.withValues(alpha: 0.075),
      labelPadding: const EdgeInsets.symmetric(horizontal: 6),
      padding: EdgeInsets.zero,
      visualDensity: const VisualDensity(horizontal: -3, vertical: -4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: selected
              ? accent.withValues(alpha: 0.95)
              : accent.withValues(alpha: 0.38),
        ),
      ),
      onSelected: (_) => onSelected(value),
    );
  }

  Color _filterOptionColor(String group, String value) {
    if (value.isEmpty || value == 'all') return Colors.white54;
    if (group == 'category') return marketplaceTagColor(value);
    if (group == 'provider') return _getProviderColor(value);
    return const Color(0xFFDFC077);
  }

  Widget _buildToggleBubble({
    required String label,
    required IconData icon,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 9),
          decoration: BoxDecoration(
            color: color.withValues(alpha: selected ? 0.32 : 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: color.withValues(alpha: selected ? 0.9 : 0.32),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: selected ? color : Colors.white38),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: selected ? color : color.withValues(alpha: 0.86),
                  fontSize: 10.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_isSearching && _page == 1) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error, style: const TextStyle(color: Colors.redAccent)),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _triggerSearch,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(tr('marketplaceScreen.action.retrySearch')),
            ),
          ],
        ),
      );
    }
    if (_searchResults.isEmpty) {
      return Center(
        child: Text(
          tr('marketplaceScreen.results.empty'),
          style: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
        ),
      );
    }

    if (_gridView) {
      return GridView.builder(
        controller: _scrollController,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 360,
          mainAxisExtent: 336,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount:
            _searchResults.length + (_hasMore ? 1 : 0) + (_pageError ? 1 : 0),
        itemBuilder: (context, index) {
          // C1: bei page>1-Fehler ein Retry-Tile ans Ende haengen, statt
          // die ganze Liste zu verwerfen.
          if (_pageError && index == _searchResults.length) {
            return _buildRetryTile();
          }
          if (index == _searchResults.length) {
            return _buildLoadMoreTile();
          }
          return _buildModelCard(_searchResults[index], compact: true);
        },
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount:
          _searchResults.length + (_hasMore ? 1 : 0) + (_pageError ? 1 : 0),
      itemBuilder: (context, index) {
        if (_pageError && index == _searchResults.length) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildRetryTile(),
          );
        }
        if (index == _searchResults.length) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildLoadMoreTile(),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildModelCard(_searchResults[index], compact: false),
        );
      },
    );
  }

  // C1: Retry-Tile, das bei einem page>1-Fehler angezeigt wird. onScroll
  // oder Tap ruft _loadNextPage erneut auf; die bisherige Liste bleibt
  // sichtbar.
  Widget _buildRetryTile() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 18,
            ),
            const SizedBox(height: 6),
            Text(
              tr('marketplaceScreen.results.loadFailed'),
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: _loadNextPage,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(tr('marketplaceScreen.action.retry')),
            ),
          ],
        ),
      ),
    );
  }

  // M16: Smartes "Mehr laden"-Tile.  Zeigt drei Zustaende:
  //   1) Suche laeuft gerade -> Spinner "Weitere Modelle werden geladen …"
  //   2) Suche idle, hat_more=true -> klickbarer Button "Weitere Modelle
  //      laden", der _loadNextPage ausloest.  Wird auch genutzt, wenn
  //      onScroll wegen zu kurzer Liste nie feuert.
  //   3) hat_more=false -> Container ohne Ui (wird oben durch itemCount
  //      ohnehin nie gezeichnet), aber defensiv kein Spinner.
  Widget _buildLoadMoreTile() {
    if (_isSearching) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(height: 8),
              Text(
                tr('marketplaceScreen.results.loadingMore'),
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
        ),
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: OutlinedButton.icon(
          onPressed: _hasMore ? _loadNextPage : null,
          icon: const Icon(Icons.expand_more_rounded, size: 20),
          label: Text(tr('marketplaceScreen.results.loadMore')),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFC9A24A),
            side: BorderSide(
              color: const Color(0xFFC9A24A).withValues(alpha: 0.35),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModelCard(dynamic model, {required bool compact}) {
    // H6: bei nicht-Map-Eintraegen (z.B. malformed backend response) nicht
    // mit TypeError abstuerzen, sondern eine leere Box rendern.
    if (model is! Map) return const SizedBox.shrink();
    final map = Map<String, dynamic>.from(model);
    final provider = map['provider']?.toString() ?? _provider;
    final name = _firstText(map, [
      'display_name',
      'name',
      'model_id',
    ], tr('marketplaceScreen.model.fallbackName'));
    final id = _firstText(map, ['model_id', 'id'], '');
    final desc = _firstText(map, [
      'description',
    ], tr('marketplaceScreen.model.noDescription'));
    final providerBadge = _firstText(map, ['provider_badge'], provider);
    final price = _firstText(map, ['price_per_1m'], '-');
    final priceLabel = _formatPriceMetric(price);
    final contextLength = _asInt(map['context_length']);
    final score = _asInt(map['intelligence_score']);
    final downloads = _asInt(map['downloads']);
    final estimatedVram = _asDouble(map['estimated_vram_gb']);
    final vramEstimated = map['vram_estimated'] == true;
    final fitsGpu = map['fits_detected_gpu'] == true;
    final runtimeFit = map['runtime_fit']?.toString() ?? '';
    final recommendationScore = _asDouble(map['recommendation_score']);
    final local = map['local_model'] == true;
    final tags = _stringList(map['capability_tags']);
    final quantizations = _stringList(map['quantizations']);
    final quantizationSummary = summarizeMarketplaceQuantizations([
      ...quantizations,
      ...tags.where(isMarketplaceQuantization),
    ]);
    final capabilityTags = marketplaceNonQuantizationTags(tags);
    final providerColor = _getProviderColor(provider);
    final cloud = _isCloudProvider(provider);
    // C3: Action-Key fuer den In-Flight-Guard.
    final actionKey =
        '${cloud ? 'api' : 'dl'}:$provider:${map['model_id'] ?? id}';
    final pending = _pendingActions.contains(actionKey);

    // Cloud- und lokale Modelle nutzen dasselbe Kartengeruest; nur die
    // Akzentfarbe bleibt an den Anbieter gebunden (lokale Modelle tragen das
    // Gold der Engine), damit die Herkunft weiter auf einen Blick sichtbar ist.
    final accent = cloud ? providerColor : const Color(0xFFC9A24A);

    // Erste Kennzahlenzeile direkt unter der Beschreibung: Cloud-Modelle zeigen
    // dort den Preis, lokale Modelle die Hardware-Passung (VRAM und Laufzeit).
    final primaryPills = <Widget>[
      if (local) ...[
        if (estimatedVram > 0)
          _statPill(
            fitsGpu ? Icons.check_circle_outline : runtimeFitIcon(runtimeFit),
            tr('marketplaceScreen.model.vram', {
              'prefix': vramEstimated ? '~' : '',
              'value': estimatedVram.toStringAsFixed(1),
            }),
            fitsGpu ? const Color(0xFF4ADE80) : runtimeFitColor(runtimeFit),
            onTap: () => showFitDetailsDialog(
              context,
              modelName: name,
              model: map,
              hardwareProfile: _hardwareProfile,
            ),
          ),
        if (runtimeFit.isNotEmpty)
          _statPill(
            runtimeFitIcon(runtimeFit),
            runtimeFitLabel(runtimeFit),
            runtimeFitColor(runtimeFit),
            onTap: () => showFitDetailsDialog(
              context,
              modelName: name,
              model: map,
              hardwareProfile: _hardwareProfile,
            ),
          ),
      ] else
        _pricePill(
          _asDouble(map['price_per_1m_input']),
          _asDouble(map['price_per_1m_output']),
          priceLabel,
        ),
    ];

    // Zweite Zeile: Kontextlaenge und Intelligenz-Score sitzen wie Ein-/
    // Ausgabepreis in einer geteilten Pille. Zwei getrennte Kaesten passten in
    // schmalen Spalten nicht nebeneinander und rutschten aus der Zeile.
    final secondaryPills = <Widget>[
      if (contextLength > 0)
        _splitPill([
          _PillSegment(
            Icons.memory_rounded,
            _formatContext(contextLength),
            const Color(0xFF22D3EE),
          ),
          _PillSegment(
            Icons.lightbulb_outline_rounded,
            tr('marketplaceScreen.model.score', {'score': score.toString()}),
            const Color(0xFFF472C6),
          ),
        ])
      else
        _statPill(
          Icons.lightbulb_outline_rounded,
          tr('marketplaceScreen.model.score', {'score': score.toString()}),
          const Color(0xFFF472C6),
        ),
      if (local && recommendationScore > 0 && !compact)
        _statPill(
          Icons.auto_awesome_rounded,
          tr('marketplaceScreen.model.recommendation', {
            'score': recommendationScore.toStringAsFixed(0),
          }),
          const Color(0xFF60A5FA),
        ),
      if (!compact)
        _statPill(
          Icons.trending_up_rounded,
          tr('marketplaceScreen.model.hits', {'count': downloads.toString()}),
          Colors.white.withValues(alpha: 0.6),
        ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Jeder Block hat eine feste Hoehe. Dadurch liegen Beschreibung,
          // Kennzahlen, Tags und Aktion auf allen Karten auf derselben Linie –
          // unabhaengig davon, wie viel ein Modell an Daten mitbringt.
          _cardSlot(
            _cardHeaderHeight,
            Row(
              children: [
                Flexible(
                  child: Tooltip(
                    message: id.isNotEmpty ? id : name,
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _badge(
                  providerBadge,
                  providerColor,
                  providerColor.withValues(alpha: 0.22),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _cardSlot(
            _cardDescriptionHeight,
            Text(
              desc,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.62),
                fontSize: 12.5,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _cardSlot(_cardPillRowHeight, _pillRow(primaryPills)),
          const SizedBox(height: 8),
          _cardSlot(_cardPillRowHeight, _pillRow(secondaryPills)),
          if (compact) const Spacer() else const SizedBox(height: 16),
          // Tags sitzen direkt ueber der Aktion – auf jeder Karte an derselben
          // Stelle, egal wie viele Kennzahlen darueber stehen.
          _cardSlot(
            _cardTagsHeight,
            _buildTagRow(
              tags: capabilityTags,
              summary: quantizationSummary,
              cardKey: '$provider:${id.isNotEmpty ? id : name}',
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: ElevatedButton.icon(
                    // C3: Button deaktiviert + Spinner, solange die Aktion
                    // laeuft; verhindert Mehrfach-Tap und damit mehrere Jobs
                    // / API-Starts.
                    onPressed: pending
                        ? null
                        : () => cloud
                              ? _startApiModel(map)
                              : _showModelDetail(map, provider),
                    icon: pending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            cloud ? Icons.add_rounded : Icons.download_rounded,
                            size: 17,
                          ),
                    label: Text(
                      cloud
                          ? tr('marketplaceScreen.model.add')
                          : tr('marketplaceScreen.model.download'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // M12: Detail-Button oeffnet einen Dialog mit den kompletten
              // vom Backend gelieferten Metadaten (Beschreibung, Tags,
              // Download-Optionen, Preise). Frueher ruhte
              // getMarketplaceModelDetail ungenutzt im ApiService.
              IconButton(
                tooltip: tr('marketplaceScreen.model.details'),
                icon: Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
                onPressed: () => _showModelDetail(map, provider),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Gemeinsame Mindesthoehen der Kartenbloecke halten alle Karten ausgerichtet,
  // lassen bei groesserer Schrift aber den noetigen vertikalen Spielraum.
  static const double _cardHeaderHeight = 26;
  static const double _cardDescriptionHeight = 52;
  // 11.5px Text mit der App-Line-Height 1.4, 6px Innenabstand und 1px
  // Rahmen pro Seite braucht gut 30px. 32px lassen die Rundung vollständig
  // sichtbar, statt die unteren zwei Pixel abzuschneiden.
  static const double _cardPillRowHeight = 32;
  static const double _cardTagsHeight = 28;

  /// Tag-Zeile mit gemessener Breite. Ein Wrap haette die nicht mehr passenden
  /// Tags in eine verdeckte zweite Zeile geschoben; ein hartes `take(3)` haette
  /// sie stillschweigend verschluckt. Stattdessen wird gezaehlt, was in eine
  /// Zeile passt – der Rest steckt sichtbar in einem "+N"-Tag mit Tooltip.
  Widget _buildTagRow({
    required List<String> tags,
    required MarketplaceQuantizationSummary summary,
    required String cardKey,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 6.0;
        final quantTag = summary.isEmpty
            ? null
            : MarketplaceQuantizationSummaryTag(
                key: ValueKey(
                  'marketplace-model-quantization-summary-$cardKey',
                ),
                summary: summary,
              );

        final reserved = quantTag == null
            ? 0.0
            : _tagWidth(context, summary.label, withIcon: true) + gap;

        List<String> fitting(double budget) {
          final visible = <String>[];
          var used = 0.0;
          for (final tag in tags) {
            final width = _tagWidth(context, tag) + (visible.isEmpty ? 0 : gap);
            if (used + width > budget) break;
            used += width;
            visible.add(tag);
          }
          return visible;
        }

        final budget = constraints.maxWidth - reserved;
        var visible = fitting(budget);
        String? moreLabel;
        if (visible.length < tags.length) {
          // Platz fuer den Zaehler freihalten – im ungueltigsten Fall traegt er
          // die Gesamtzahl der Tags, deshalb wird damit gemessen.
          final counterWidth = _tagWidth(context, '+${tags.length}') + gap;
          visible = fitting(budget - counterWidth);
          moreLabel = '+${tags.length - visible.length}';
        }

        final hiddenTags = tags.sublist(visible.length);

        return Row(
          children: [
            for (var i = 0; i < visible.length; i++) ...[
              if (i > 0) const SizedBox(width: gap),
              _tag(visible[i]),
            ],
            if (moreLabel != null) ...[
              if (visible.isNotEmpty) const SizedBox(width: gap),
              Tooltip(message: hiddenTags.join(', '), child: _tag(moreLabel)),
            ],
            if (quantTag != null) ...[
              if (visible.isNotEmpty || moreLabel != null)
                const SizedBox(width: gap),
              quantTag,
            ],
          ],
        );
      },
    );
  }

  /// Breite eines Tag-Chips inklusive Innenabstand und Rahmen – muss zu den
  /// Massen in [_tag] passen.
  double _tagWidth(BuildContext context, String text, {bool withIcon = false}) {
    final textStyle = DefaultTextStyle.of(
      context,
    ).style.merge(const TextStyle(fontSize: 11, fontWeight: FontWeight.w500));
    final painter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    // 9px Innenabstand je Seite + 1px Rahmen je Seite, Icon 12px + 5px Abstand.
    return painter.width + 20 + (withIcon ? 17 : 0);
  }

  /// Eine Kennzahlenzeile. Bewusst eine Row statt eines Wrap: die Pillen
  /// schrumpfen und kuerzen ihren Text, wenn die Spalte schmal wird. Ein Wrap
  /// haette die zweite Pille in eine verdeckte zweite Zeile geschoben – sie
  /// war dann schlicht abgeschnitten.
  Widget _pillRow(List<Widget> pills) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < pills.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Flexible(child: pills[i]),
        ],
      ],
    );
  }

  /// Hält die Kartenblöcke auf einer gemeinsamen Mindesthöhe, lässt sie bei
  /// größerer Schrift aber vollständig wachsen. Der Spacer der kompakten Karte
  /// nimmt diese wenigen Pixel auf; ein ClipRect würde sie lautlos abschneiden.
  Widget _cardSlot(double minHeight, Widget child) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: SizedBox(width: double.infinity, child: child),
    );
  }

  // M12: Detail-Dialog, der die reichhaltigen Metadaten des Backend-Endpoints
  // /marktplatz/model/:id anzeigt. Frueher war getMarketplaceModelDetail zwar
  // im ApiService deklariert, wurde aber nirgends aufgerufen – die
  // Backend-Schnittstelle war also per Code-Review "isolated".
  Future<void> _showModelDetail(
    Map<String, dynamic> summary,
    String provider,
  ) async {
    final modelId = _firstText(summary, ['model_id', 'id'], '');
    if (modelId.isEmpty) {
      _showSnack(
        tr('marketplaceScreen.error.modelIdMissing'),
        Colors.redAccent,
      );
      return;
    }
    if (provider.isEmpty || provider == 'all') {
      _showSnack(
        tr('marketplaceScreen.error.providerMissing'),
        Colors.redAccent,
      );
      return;
    }

    void downloadVariant(Map<String, dynamic> option) {
      Navigator.of(context).pop();
      _downloadModel(summary, selectedOption: option);
    }

    // Wir zeigen zuerst eine synchrone Vorschau aus den Such-Daten und
    // reichern sie danach mit den Detail-Werten an. So spart der User eine
    // Wartezeit und sieht zumindest die Basis-Metadaten sofort.
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return ModelDetailDialog(
          summary: summary,
          hardwareProfile: _hardwareProfile,
          onDownload: downloadVariant,
        );
      },
    );

    final detail = await _api.getMarketplaceModelDetail(modelId, provider);
    if (!mounted) return;
    // Replace laufenden Dialog durch angereicherte Version, wenn die
    // Detail-Anfrage erfolgreich war; sonst bleibt die Basis-Vorschau
    // sichtbar.
    if (detail.containsKey('error')) {
      _showSnack(_humanizeError(detail['error']), Colors.orangeAccent);
      return;
    }
    // Stack manipulieren: bisherigen Dialog anzeigen, durch Detail austauschen
    Navigator.of(context).pop();
    showDialog<void>(
      context: context,
      builder: (ctx) => ModelDetailDialog(
        summary: summary,
        detail: detail,
        hardwareProfile: _hardwareProfile,
        onDownload: downloadVariant,
      ),
    );
  }

  Widget _badge(String text, Color color, Color background) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _tag(String text) {
    final tagColor = marketplaceTagColor(text);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: tagColor.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: tagColor.withValues(alpha: 0.45)),
      ),
      child: Text(
        text,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: tagColor,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // Kennzahlen der Modellkarte sitzen in eigenen Pillen statt in einer losen
  // Icon-Text-Reihe: farbiger Inhalt auf neutralem Grund, damit Preis, Kontext
  // und Score als eigenstaendige Bloecke lesbar bleiben.
  // Die Pille traegt einen Hauch ihrer eigenen Farbe, statt neutral grau zu
  // bleiben – dadurch heben sich Preis, Kontext und Score deutlicher ab.
  BoxDecoration _pillDecoration(Color color) {
    return BoxDecoration(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: 0.30)),
    );
  }

  Widget _statPill(
    IconData icon,
    String text,
    Color color, {
    VoidCallback? onTap,
  }) {
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: _pillDecoration(color),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          // Flexible statt fester Breite: auf schmalen Karten kuerzt die Pille
          // ihren Text, statt ueber den Kartenrand zu laufen.
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.info_outline_rounded,
              color: color.withValues(alpha: 0.55),
              size: 11,
            ),
          ],
        ],
      ),
    );
    if (onTap == null) return pill;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: pill,
    );
  }

  // Preis-Pille mit getrennten Segmenten fuer Ein- und Ausgabe-Tokens. Liefert
  // das Backend keine getrennten Werte, faellt sie auf das vorhandene
  // Sammel-Label zurueck (z.B. "Lokal" oder "Gratis").
  Widget _pricePill(double input, double output, String fallbackLabel) {
    if (input <= 0 && output <= 0) {
      return _statPill(
        Icons.payments_outlined,
        fallbackLabel,
        const Color(0xFFA9BDD9),
      );
    }
    return _splitPill([
      _PillSegment(
        Icons.south_rounded,
        tr('marketplaceScreen.price.in', {'value': _formatDollar(input)}),
        const Color(0xFF4ADE80),
      ),
      _PillSegment(
        Icons.north_rounded,
        tr('marketplaceScreen.price.out', {'value': _formatDollar(output)}),
        const Color(0xFFFF8A50),
      ),
    ]);
  }

  /// Pille mit zwei Segmenten, getrennt durch einen duennen Strich. Der
  /// Farbverlauf im Hintergrund nimmt beide Segmentfarben auf, sodass die
  /// Werte zusammengehoeren, aber unterscheidbar bleiben.
  Widget _splitPill(List<_PillSegment> segments) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            segments.first.color.withValues(alpha: 0.16),
            segments.last.color.withValues(alpha: 0.16),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < segments.length; i++) ...[
            if (i > 0)
              Container(
                width: 1,
                height: 12,
                margin: const EdgeInsets.symmetric(horizontal: 9),
                color: Colors.white.withValues(alpha: 0.18),
              ),
            Flexible(child: _pillSegment(segments[i])),
          ],
        ],
      ),
    );
  }

  Widget _pillSegment(_PillSegment segment) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(segment.icon, color: segment.color, size: 13),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            segment.text,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: segment.color,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSidePanel() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [_buildDownloadsCard()],
      ),
    );
  }

  Widget _buildDownloadDrawer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF101015),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.38),
            blurRadius: 22,
            offset: const Offset(-8, 0),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(child: _buildSidePanel()),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              tooltip: tr('marketplaceScreen.downloads.close'),
              icon: const Icon(Icons.close_rounded, size: 18),
              onPressed: () => setState(() => _showDownloadsPanel = false),
            ),
          ),
        ],
      ),
    );
  }

  // Kept temporarily for state migration compatibility; the hardware profile
  // is rendered in Settings and is no longer part of the marketplace layout.
  // ignore: unused_element
  Widget _buildHardwareCard() {
    // H2: Frueher wurde eine {'error': ...}-Antwort still als
    // "Keine GPU" angezeigt; jetzt gibt es einen klaren Fehlerhinweis.
    if (_hardwareError.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: _panelDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.developer_board_rounded,
                  color: Color(0xFFC9A24A),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  tr('marketplaceScreen.hardware.title'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              tr('marketplaceScreen.hardware.loadFailed'),
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              _hardwareError,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.tonalIcon(
              onPressed: _fetchHardwareProfile,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(tr('marketplaceScreen.action.retry')),
            ),
          ],
        ),
      );
    }
    final hasGpu =
        _hardwareProfile['has_gpu'] == true ||
        _numberAsGB('vram_gb', 'vram_mb') > 0;
    final gpu =
        _hardwareProfile['gpu_name'] ??
        _hardwareProfile['gpu'] ??
        (hasGpu
            ? tr('marketplaceScreen.hardware.gpuDetected')
            : tr('marketplaceScreen.hardware.noGpuDetected'));
    final ramGB = _numberAsGB('ram_gb', 'ram_mb');
    final vramGB = _numberAsGB('vram_gb', 'vram_mb');
    final disk = _hardwareProfile['disk_free'] ?? 'N/A';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.developer_board_rounded,
                color: Color(0xFFC9A24A),
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                tr('marketplaceScreen.hardware.title'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            gpu.toString(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _hardwareMetric('VRAM', '${vramGB.toStringAsFixed(1)} GB'),
              _hardwareMetric('RAM', '${ramGB.toStringAsFixed(1)} GB'),
              _hardwareMetric('DISK', disk.toString()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _hardwareMetric(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white30, fontSize: 10),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadsCard() {
    final activeJobs = _downloadJobs
        .where(
          (job) =>
              job is Map &&
              (job['status'] == 'queued' || job['status'] == 'running'),
        )
        .toList();
    final pastJobs = _downloadJobs
        .where(
          (job) =>
              job is Map &&
              (job['status'] == 'done' || job['status'] == 'failed'),
        )
        .toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.download_done_rounded,
                color: Color(0xFFC9A24A),
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                tr('marketplaceScreen.downloads.title'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildBackendAccessSummary(),
          const SizedBox(height: 14),
          // H2: Backend-Fehler beim Laden der Job-Liste sichtbar machen.
          if (_jobsError.isNotEmpty) ...[
            Text(
              tr('marketplaceScreen.downloads.jobsLoadFailed'),
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
            const SizedBox(height: 6),
            Text(
              _jobsError,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.tonalIcon(
              onPressed: _fetchDownloadJobs,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(tr('marketplaceScreen.action.retry')),
            ),
            const SizedBox(height: 12),
          ] else if (activeJobs.isEmpty && pastJobs.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  tr('marketplaceScreen.downloads.empty'),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ...activeJobs.map((job) => _buildActiveJobItem(job)),
          ...pastJobs.map((job) => _buildPastJobItem(job)),
        ],
      ),
    );
  }

  Widget _buildBackendAccessSummary() {
    final modelDir = (_backendSettings['model_dir'] ?? '').toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr('marketplaceScreen.backendAccess'),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.42),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _tokenStatusBadge(
              'HuggingFace',
              _backendSettings['huggingface_token_set'] == true,
              _getProviderColor('huggingface'),
            ),
            _tokenStatusBadge(
              'OpenRouter',
              _backendSettings['openrouter_token_set'] == true,
              _getProviderColor('openrouter'),
            ),
            _tokenStatusBadge(
              'Featherless',
              _backendSettings['featherless_token_set'] == true,
              _getProviderColor('featherless'),
            ),
          ],
        ),
        if (modelDir.isNotEmpty) ...[
          const SizedBox(height: 8),
          Tooltip(
            message: modelDir,
            child: Row(
              children: [
                const Icon(
                  Icons.folder_outlined,
                  size: 13,
                  color: Colors.white38,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    modelDir,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white38, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
          if (_backendSettings['model_dir_valid'] == false) ...[
            const SizedBox(height: 5),
            Text(
              (_backendSettings['model_dir_error'] ??
                      tr('marketplaceScreen.modelDirectoryInvalid'))
                  .toString(),
              style: const TextStyle(color: Colors.orangeAccent, fontSize: 9.5),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildActiveJobItem(dynamic job) {
    if (job is! Map) return const SizedBox.shrink();
    final j = Map<String, dynamic>.from(job);
    final modelId =
        (j['model_id'] ?? tr('marketplaceScreen.downloads.unknownModel'))
            .toString();
    final provider = (j['provider'] ?? 'all').toString();
    final status = (j['status'] ?? 'queued').toString();
    final progress = _asInt(j['progress']);
    final color = _getProviderColor(provider);
    // H5: job['id'] als String sichern – sonst Crash bei null.
    final jobId = j['id']?.toString() ?? '';
    // M16: Live-Stats vom Backend – bytes/sec + gesamt-Bytes zaehler.
    final downloaded = _asInt(j['downloaded_bytes']).toDouble();
    final total = _asInt(j['total_bytes']).toDouble();
    final speed = _asInt(j['speed_bytes_per_sec']).toDouble();
    final targetDir = (j['target_dir'] ?? '').toString();

    String statusLine;
    if (status == 'running') {
      final parts = <String>['$progress%'];
      if (speed > 0) {
        parts.add(_formatSpeed(speed));
      }
      if (total > 0) {
        parts.add(
          '${formatBytes(downloaded.toInt())} / '
          '${formatBytes(total.toInt())}',
        );
      } else if (downloaded > 0) {
        parts.add(formatBytes(downloaded.toInt()));
      }
      statusLine = parts.join(' · ');
    } else {
      statusLine = tr('marketplaceScreen.downloads.queued');
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: _softDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  modelId,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                tooltip: tr('marketplaceScreen.action.cancel'),
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.cancel_outlined,
                  size: 16,
                  color: Colors.redAccent.withValues(alpha: 0.75),
                ),
                onPressed: jobId.isEmpty ? null : () => _deleteJob(jobId),
              ),
            ],
          ),
          Text(
            statusLine,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 11,
            ),
          ),
          if (targetDir.isNotEmpty) ...[
            const SizedBox(height: 4),
            Tooltip(
              message: targetDir,
              child: Text(
                tr('marketplaceScreen.downloads.target', {'target': targetDir}),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white30, fontSize: 9.5),
              ),
            ),
          ],
          const SizedBox(height: 8),
          LinearProgressIndicator(
            // L8: progress auf [0,100] begrenzen, damit der Balken nicht
            // visuell ueberlaeuft, falls der Backend mal >100 liefert.
            value: status == 'running'
                ? (progress < 0
                      ? 0.0
                      : (progress > 100 ? 1.0 : progress / 100.0))
                : null,
            color: color,
            backgroundColor: Colors.white.withValues(alpha: 0.06),
            minHeight: 4,
          ),
        ],
      ),
    );
  }

  // M16: Formatiert Bytes/s als "5.2 MB/s" etc.  Wird fuer die
  // Download-Speed-Anzeige im aktiven Job genutzt.
  String _formatSpeed(double bytesPerSec) {
    if (bytesPerSec <= 0) return '0 B/s';
    if (bytesPerSec < 1024) return '${bytesPerSec.round()} B/s';
    if (bytesPerSec < 1024 * 1024) {
      return '${(bytesPerSec / 1024).toStringAsFixed(1)} KB/s';
    }
    if (bytesPerSec < 1024 * 1024 * 1024) {
      return '${(bytesPerSec / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    }
    return '${(bytesPerSec / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB/s';
  }

  Widget _buildPastJobItem(dynamic job) {
    if (job is! Map) return const SizedBox.shrink();
    final j = Map<String, dynamic>.from(job);
    final modelId =
        (j['model_id'] ?? tr('marketplaceScreen.downloads.unknownModel'))
            .toString();
    final provider = (j['provider'] ?? 'all').toString();
    final status = (j['status'] ?? 'done').toString();
    final error = (j['error'] ?? '').toString();
    final success = status == 'done';
    final color = _getProviderColor(provider);
    final jobId = j['id']?.toString() ?? '';
    final targetDir = (j['target_dir'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: _softDecoration(),
      child: Row(
        children: [
          Icon(
            success ? Icons.check_circle_rounded : Icons.error_rounded,
            color: success ? Colors.green : Colors.redAccent,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  modelId,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  success ? provider : _humanizeError(error),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: success
                        ? color.withValues(alpha: 0.85)
                        : Colors.redAccent.withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                ),
                if (targetDir.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    tr('marketplaceScreen.downloads.target', {
                      'target': targetDir,
                    }),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white30, fontSize: 9),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: tr('marketplaceScreen.action.delete'),
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.delete_outline_rounded,
              size: 16,
              color: Colors.white.withValues(alpha: 0.35),
            ),
            onPressed: jobId.isEmpty ? null : () => _deleteJob(jobId),
          ),
        ],
      ),
    );
  }

  Widget _tokenStatusBadge(String label, bool configured, Color color) {
    final statusColor = configured ? color : Colors.white30;
    return Tooltip(
      message: configured
          ? tr('marketplaceScreen.token.configured', {'provider': label})
          : tr('marketplaceScreen.token.missing', {'provider': label}),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: configured ? 0.12 : 0.025),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: statusColor.withValues(alpha: 0.22)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              configured
                  ? Icons.check_circle_rounded
                  : Icons.remove_circle_outline,
              size: 11,
              color: statusColor,
            ),
            const SizedBox(width: 4),
            Text(
              configured
                  ? tr('marketplaceScreen.token.badgeConfigured', {
                      'provider': label,
                    })
                  : tr('marketplaceScreen.token.badgeMissing', {
                      'provider': label,
                    }),
              style: TextStyle(color: statusColor, fontSize: 9.5),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _panelDecoration() {
    return BoxDecoration(
      color: const Color(0xFF16161D),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
    );
  }

  BoxDecoration _softDecoration() {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.025),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.white.withValues(alpha: 0.035)),
    );
  }

  Color _getProviderColor(String provider) {
    switch (provider.toLowerCase()) {
      case 'huggingface':
        return const Color(0xFFFFC107);
      case 'openrouter':
        return const Color(0xFF8E7CFF);
      case 'featherless':
        return const Color(0xFF26A69A);
      default:
        return const Color(0xFF90A4AE);
    }
  }

  bool _isCloudProvider(dynamic provider) {
    final value = provider.toString().toLowerCase();
    return value == 'openrouter' || value == 'featherless';
  }

  String _firstText(
    Map<String, dynamic> map,
    List<String> keys,
    String fallback,
  ) {
    for (final key in keys) {
      final value = map[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return fallback;
  }

  // Sammel-Label fuer Karten ohne getrennte Token-Preise. Liegen Ein- und
  // Ausgabepreis vor, zeigt die Karte stattdessen die zweigeteilte Preis-Pille.
  String _formatPriceMetric(String rawPrice) {
    final value = rawPrice.trim();
    if (value.isEmpty || value == '-') return '-';
    final lowered = value.toLowerCase();
    if (lowered == 'lokal') return tr('marketplaceScreen.price.local');
    if (lowered == 'gratis' || lowered == 'free' || lowered == r'$0') {
      return tr('marketplaceScreen.price.free');
    }
    return tr('marketplaceScreen.price.perMillion', {'price': value});
  }

  String _formatDollar(double value) {
    if (value == 0) return r'$0';
    return '\$${value.toStringAsFixed(value < 1 ? 4 : 2)}';
  }

  List<String> _stringList(dynamic raw) {
    if (raw is! List) return const [];
    // M1: null-Elemente herausfiltern – frueher wurde item.toString() auf
    // null aufgerufen und ergab den literalen String "null", der dann als
    // Tag gerendert wurde.
    return raw
        .whereType<Object>()
        .map((item) => item.toString())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _numberAsGB(String gbKey, String mbKey) {
    if (_hardwareProfile[gbKey] != null) {
      return _asDouble(_hardwareProfile[gbKey]);
    }
    if (_hardwareProfile[mbKey] != null) {
      return _asDouble(_hardwareProfile[mbKey]) / 1024.0;
    }
    return 0;
  }

  String _formatContext(int value) {
    if (value <= 0) return '- ctx';
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M ctx';
    if (value >= 1000) return '${(value / 1000).round()}K ctx';
    return '$value ctx';
  }

  String _filterHelp(String group) {
    switch (group) {
      case 'provider':
        return tr('marketplaceScreen.filterHelp.provider');
      case 'category':
        return tr('marketplaceScreen.filterHelp.category');
      case 'quantization':
        return tr('marketplaceScreen.filterHelp.quantization');
      default:
        return tr('marketplaceScreen.filterHelp.default');
    }
  }
} // Ende _MarketplaceScreenState

/// Ein Wert innerhalb einer geteilten Kennzahlen-Pille (z.B. "IN $5.00" oder
/// "1.0M ctx").
class _PillSegment {
  const _PillSegment(this.icon, this.text, this.color);

  final IconData icon;
  final String text;
  final Color color;
}

@Preview(name: 'Download-Empfehlung', group: 'Marktplatz', size: Size(360, 150))
Widget marketplaceDownloadRecommendationPreview() {
  return const MaterialApp(
    home: Scaffold(
      backgroundColor: Color(0xFF16161D),
      body: Center(
        child: RecommendationTooltip(
          isRecommended: true,
          isMaxQuality: false,
          isCompact: false,
        ),
      ),
    ),
  );
}

@Preview(name: 'Transparente Filter', group: 'Marktplatz', size: Size(860, 220))
Widget marketplaceTransparentFilterPreview() {
  return const MaterialApp(
    home: Scaffold(
      backgroundColor: Color(0xFF0E0E12),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: MarketplaceFilterStylePreview(),
      ),
    ),
  );
}
