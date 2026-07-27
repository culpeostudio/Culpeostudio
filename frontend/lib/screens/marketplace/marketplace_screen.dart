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
  bool _showAdvancedFilters = true;
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
        const SizedBox(height: 12),
        _buildFilters(),
        const SizedBox(height: 12),
        Expanded(child: _buildResults()),
      ],
    );
  }

  Widget _buildToolbar() {
    return SizedBox(
      height: 48,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const actionsWidth = 208.0;
          final availableSearchWidth = constraints.maxWidth - actionsWidth - 12;
          final expandedSearchWidth = availableSearchWidth
              .clamp(190.0, 360.0)
              .toDouble();
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
                      ? Container(
                          key: const ValueKey('expanded-search'),
                          width: expandedSearchWidth,
                          height: 48,
                          padding: const EdgeInsets.only(left: 14, right: 4),
                          decoration: _panelDecoration(),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  focusNode: _searchFocusNode,
                                  controller: _searchController,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                  onChanged: _onSearchChanged,
                                  textInputAction: TextInputAction.search,
                                  decoration: InputDecoration(
                                    hintText: tr(
                                      'marketplaceScreen.searchHint',
                                    ),
                                    hintStyle: const TextStyle(
                                      color: Colors.white30,
                                    ),
                                    border: InputBorder.none,
                                  ),
                                  onSubmitted: (_) =>
                                      _triggerSearch(collapseSearch: true),
                                ),
                              ),
                              Tooltip(
                                message: tr('marketplaceScreen.search.submit'),
                                child: IconButton(
                                  onPressed: () =>
                                      _triggerSearch(collapseSearch: true),
                                  icon: const Icon(Icons.search_rounded),
                                  style: IconButton.styleFrom(
                                    hoverColor: const Color(
                                      0xFFC9A24A,
                                    ).withValues(alpha: 0.22),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          key: const ValueKey('collapsed-search'),
                          width: 44,
                          height: 48,
                          decoration: _panelDecoration(),
                          child: Tooltip(
                            message: tr('marketplaceScreen.search.open'),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: _openSearch,
                              child: const Center(
                                child: Icon(Icons.search_rounded, size: 19),
                              ),
                            ),
                          ),
                        ),
                ),
              ),
              Positioned(top: 0, right: 0, child: _buildToolbarActions()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildToolbarActions() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: tr('marketplaceScreen.wiki.title'),
            style: IconButton.styleFrom(
              hoverColor: const Color(0xFF8E7CFF).withValues(alpha: 0.24),
            ),
            onPressed: _showMarketplaceWiki,
            icon: const Icon(Icons.menu_book_outlined),
          ),
          IconButton(
            tooltip: _showDownloadsPanel
                ? tr('marketplaceScreen.downloads.close')
                : tr('marketplaceScreen.downloads.title'),
            onPressed: () =>
                setState(() => _showDownloadsPanel = !_showDownloadsPanel),
            style: IconButton.styleFrom(
              hoverColor: const Color(0xFFC9A24A).withValues(alpha: 0.24),
            ),
            icon: Icon(
              _showDownloadsPanel
                  ? Icons.close_rounded
                  : Icons.download_for_offline_rounded,
            ),
          ),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              backgroundColor: WidgetStateProperty.all(Colors.transparent),
              foregroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? Colors.white
                    : Colors.white60,
              ),
              side: WidgetStateProperty.all(BorderSide.none),
              overlayColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.hovered)
                    ? const Color(0xFFC9A24A).withValues(alpha: 0.18)
                    : null,
              ),
            ),
            segments: [
              ButtonSegment(
                value: true,
                icon: const Icon(Icons.grid_view_rounded, size: 18),
                tooltip: tr('marketplaceScreen.view.grid'),
              ),
              ButtonSegment(
                value: false,
                icon: const Icon(Icons.view_list_rounded, size: 20),
                tooltip: tr('marketplaceScreen.view.list'),
              ),
            ],
            selected: {_gridView},
            onSelectionChanged: (value) {
              setState(() => _gridView = value.first);
            },
          ),
        ],
      ),
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
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1040),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: const Color(0xFF16161D).withValues(alpha: 0.34),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _showAdvancedFilters
                          ? tr('marketplaceScreen.filters.title')
                          : tr('marketplaceScreen.filters.quickSelection'),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => setState(
                      () => _showAdvancedFilters = !_showAdvancedFilters,
                    ),
                    icon: Icon(
                      _showAdvancedFilters
                          ? Icons.tune_rounded
                          : Icons.tune_outlined,
                      size: 16,
                    ),
                    label: Text(
                      _showAdvancedFilters
                          ? tr('marketplaceScreen.filters.collapse')
                          : tr('marketplaceScreen.filters.showAll'),
                    ),
                  ),
                ],
              ),
              if (!_showAdvancedFilters) ...[
                Text(
                  tr('marketplaceScreen.filters.compactHelp'),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.52),
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: Text(tr('marketplaceScreen.filters.localModels')),
                      selected: _localOnly && !_gpuFit,
                      onSelected: (enabled) {
                        setState(() {
                          _provider = 'huggingface';
                          _localOnly = enabled;
                          _gpuFit = false;
                        });
                        _triggerSearch();
                      },
                    ),
                    FilterChip(
                      label: Text(tr('marketplaceScreen.filters.fitsMyPc')),
                      avatar: const Icon(Icons.verified_rounded, size: 16),
                      selected: _gpuFit,
                      onSelected: (enabled) {
                        setState(() {
                          _provider = 'huggingface';
                          _localOnly = enabled;
                          _gpuFit = enabled;
                        });
                        _triggerSearch();
                      },
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 5),
                _buildFilterRow(
                  'provider',
                  tr('marketplaceScreen.filters.provider'),
                  _providers,
                  _provider,
                  _setProvider,
                ),
                const SizedBox(height: 6),
                _buildFilterRow(
                  'category',
                  tr('marketplaceScreen.filters.category'),
                  _categories,
                  _category,
                  (value) {
                    setState(() => _category = value);
                    _triggerSearch();
                  },
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 76,
                      child: Text(
                        tr('marketplaceScreen.filters.sort'),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    _buildSortDropdown(),
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
                  ],
                ),
                if (_gpuFitControlVisible) ...[
                  const SizedBox(height: 10),
                  _buildQuantizationDropdown(),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterRow(
    String group,
    String label,
    List<FilterOption> options,
    String value,
    ValueChanged<String> onSelected,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 76,
          height: 26,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Tooltip(
              message: _filterHelp(group),
              child: Text(
                label,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
          ),
        ),
        Expanded(
          child: Wrap(
            spacing: 5,
            runSpacing: 5,
            children: options
                .map(
                  (option) => _buildChoiceChip(
                    option.label,
                    option.value,
                    value,
                    onSelected,
                    _filterOptionColor(group, option.value),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
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
        borderRadius: BorderRadius.circular(10),
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

  Widget _buildSortDropdown() {
    return SizedBox(
      height: 30,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _sort,
          dropdownColor: const Color(0xEE202028),
          borderRadius: BorderRadius.circular(14),
          elevation: 8,
          style: const TextStyle(color: Colors.white, fontSize: 11),
          items: _sortOptionsForProvider()
              .map(
                (item) => DropdownMenuItem(
                  value: item.value,
                  child: Text(item.label),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() => _sort = value);
            _triggerSearch();
          },
        ),
      ),
    );
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

  Widget _buildQuantizationDropdown() {
    return Row(
      children: [
        SizedBox(
          width: 76,
          child: Tooltip(
            message: _filterHelp('quantization'),
            child: Text(
              tr('marketplaceScreen.filters.quantization'),
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 240,
          height: 30,
          child: Align(
            alignment: Alignment.centerLeft,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _quantization,
                isExpanded: true,
                dropdownColor: const Color(0xEE202028),
                borderRadius: BorderRadius.circular(14),
                elevation: 8,
                icon: const Icon(Icons.expand_more_rounded, size: 18),
                style: const TextStyle(color: Colors.white, fontSize: 11),
                items: _quantizations
                    .map(
                      (option) => DropdownMenuItem(
                        value: option.value,
                        child: Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: option.value.isEmpty
                                    ? Colors.white38
                                    : marketplaceTagColor(option.value),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 7),
                            Text(option.label),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _quantization = value);
                  _triggerSearch();
                },
              ),
            ),
          ),
        ),
      ],
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
    final parameterBadge = _firstText(map, ['parameter_badge'], '');
    final providerBadge = _firstText(map, ['provider_badge'], provider);
    final price = _firstText(map, ['price_per_1m'], '-');
    final priceLabel = _formatPriceMetric(
      price,
      map['price_per_1m_input'],
      map['price_per_1m_output'],
    );
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
    final providerColor = _getProviderColor(provider);
    final cloud = _isCloudProvider(provider);
    // C3: Action-Key fuer den In-Flight-Guard.
    final actionKey =
        '${cloud ? 'api' : 'dl'}:$provider:${map['model_id'] ?? id}';
    final pending = _pendingActions.contains(actionKey);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (parameterBadge.isNotEmpty) ...[
                const SizedBox(width: 8),
                _badge(
                  parameterBadge,
                  Colors.white70,
                  Colors.white.withValues(alpha: 0.05),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _badge(
                providerBadge,
                providerColor,
                providerColor.withValues(alpha: 0.12),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  id,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.38),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            desc,
            maxLines: compact ? 2 : 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.68),
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ...tags.take(compact ? 4 : 8).map(_tag),
              ...quantizations.take(compact ? 2 : 4).map(_tag),
            ],
          ),
          if (compact) const Spacer() else const SizedBox(height: 14),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: [
              _metric(Icons.payments_outlined, priceLabel),
              if (contextLength > 0)
                _metric(Icons.memory_rounded, _formatContext(contextLength)),
              _metric(
                Icons.psychology_alt_outlined,
                tr('marketplaceScreen.model.score', {
                  'score': score.toString(),
                }),
              ),
              if (local && estimatedVram > 0)
                _metric(
                  fitsGpu
                      ? Icons.check_circle_outline
                      : runtimeFitIcon(runtimeFit),
                  tr('marketplaceScreen.model.vram', {
                    'prefix': vramEstimated ? '~' : '',
                    'value': estimatedVram.toStringAsFixed(1),
                  }),
                  color: fitsGpu
                      ? Colors.greenAccent
                      : runtimeFitColor(runtimeFit),
                  onTap: () => showFitDetailsDialog(
                    context,
                    modelName: name,
                    model: map,
                    hardwareProfile: _hardwareProfile,
                  ),
                ),
              if (local && runtimeFit.isNotEmpty)
                _metric(
                  runtimeFitIcon(runtimeFit),
                  runtimeFitLabel(runtimeFit),
                  color: runtimeFitColor(runtimeFit),
                  onTap: () => showFitDetailsDialog(
                    context,
                    modelName: name,
                    model: map,
                    hardwareProfile: _hardwareProfile,
                  ),
                ),
              if (local && recommendationScore > 0 && !compact)
                _metric(
                  Icons.auto_awesome_rounded,
                  tr('marketplaceScreen.model.recommendation', {
                    'score': recommendationScore.toStringAsFixed(0),
                  }),
                  color: Colors.lightBlueAccent,
                ),
              if (!compact)
                _metric(
                  Icons.trending_up_rounded,
                  tr('marketplaceScreen.model.hits', {
                    'count': downloads.toString(),
                  }),
                ),
            ],
          ),
          const SizedBox(height: 14),
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
                            cloud
                                ? Icons.play_arrow_rounded
                                : Icons.download_rounded,
                            size: 17,
                          ),
                    label: Text(
                      cloud
                          ? tr('marketplaceScreen.model.startInChat')
                          : tr('marketplaceScreen.model.download'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cloud
                          ? providerColor
                          : const Color(0xFFC9A24A),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _tag(String text) {
    final tagColor = marketplaceTagColor(text);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: tagColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: tagColor.withValues(alpha: 0.24)),
      ),
      child: Text(text, style: TextStyle(color: tagColor, fontSize: 10)),
    );
  }

  Widget _metric(
    IconData icon,
    String text, {
    Color? color,
    VoidCallback? onTap,
  }) {
    final metricColor = color ?? Colors.white.withValues(alpha: 0.52);
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: metricColor, size: 15),
        const SizedBox(width: 5),
        Text(text, style: TextStyle(color: metricColor, fontSize: 11)),
        if (onTap != null) ...[
          const SizedBox(width: 3),
          Icon(
            Icons.info_outline_rounded,
            color: metricColor.withValues(alpha: 0.55),
            size: 11,
          ),
        ],
      ],
    );
    if (onTap == null) return row;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: row,
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

  String _formatPriceMetric(
    String rawPrice,
    dynamic inputPrice,
    dynamic outputPrice,
  ) {
    final input = _asDouble(inputPrice);
    final output = _asDouble(outputPrice);
    if (input > 0 || output > 0) {
      return tr('marketplaceScreen.price.inputOutput', {
        'input': _formatDollar(input),
        'output': _formatDollar(output),
      });
    }
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
