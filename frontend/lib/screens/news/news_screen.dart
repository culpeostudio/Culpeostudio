import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_strings.dart';
import '../../l10n/remaining_ui_strings.dart';
import '../../services/api_service.dart';
import '../../theme/dark_theme.dart';
import 'news_sources.dart';
import '../../widgets/top_notification.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({
    super.key,
    Future<List<dynamic>> Function()? loadNews,
    Future<List<dynamic>> Function()? loadSavedNews,
    Future<void> Function(Map<String, dynamic> article)? saveNews,
    Future<void> Function(String articleId)? unsaveNews,
  }) : loadNews = loadNews ?? _defaultLoadNews,
       loadSavedNews = loadSavedNews ?? _defaultLoadSavedNews,
       saveNews = saveNews ?? _defaultSaveNews,
       unsaveNews = unsaveNews ?? _defaultUnsaveNews;

  final Future<List<dynamic>> Function() loadNews;

  final Future<List<dynamic>> Function() loadSavedNews;
  final Future<void> Function(Map<String, dynamic> article) saveNews;
  final Future<void> Function(String articleId) unsaveNews;

  static Future<List<dynamic>> _defaultLoadNews() => ApiService().getNews();

  static Future<List<dynamic>> _defaultLoadSavedNews() =>
      ApiService().getSavedNews();

  static Future<void> _defaultSaveNews(Map<String, dynamic> article) =>
      ApiService().saveNewsArticle(article);

  static Future<void> _defaultUnsaveNews(String articleId) =>
      ApiService().deleteSavedNewsArticle(articleId);

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  static const double _cardRadius = 16;
  static const double _cardImageHeight = 158;
  static const double _cardExtent = 348;
  static const double _tileMaxWidth = 360;
  static const double _gridGap = 16;
  static const double _searchFieldWidth = 300;
  static const double _categoryMenuWidth = 190;
  static const double _sourceMenuWidth = 210;

  static const double _headerInset = 38;

  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _newsList = [];
  bool _isLoading = true;
  String? _errorMessage;

  List<dynamic> _savedList = [];
  Set<String> _savedIds = <String>{};
  String? _savedErrorMessage;
  bool _showSavedOnly = false;

  String _searchQuery = '';
  String _selectedCategory = 'news.categoryAll';
  bool _categoryMenuOpen = false;
  String _selectedSource = '';
  bool _sourceMenuOpen = false;

  final List<String> _categoryKeys = [
    'news.categoryAll',
    'news.categoryReleases',
    'news.categoryHardware',
    'news.categorySoftware',
    'news.categorySecurity',
    'news.categoryOpenSource',
    'news.categoryResearch',
  ];

  static const Map<String, String> _backendCategories = {
    'news.categoryReleases': 'KI-Releases',
    'news.categoryHardware': 'Hardware',
    'news.categorySoftware': 'Software',
    'news.categorySecurity': 'Security',
    'news.categoryOpenSource': 'Open Source',
    'news.categoryResearch': 'Research',
  };

  @override
  void initState() {
    super.initState();
    _fetchNews();
    _fetchSavedNews();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchNews() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final news = await widget.loadNews();
      if (!mounted) return;
      setState(() {
        _newsList = news;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _buildLoadErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  String _buildLoadErrorMessage(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    return tr('news.loadError', {'error': error.toString()});
  }

  Future<void> _fetchSavedNews() async {
    try {
      final saved = await widget.loadSavedNews();
      if (!mounted) return;
      setState(() {
        _savedList = saved;
        _savedIds = _idsOf(saved);
        _savedErrorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _savedErrorMessage = e is ApiException
            ? e.message
            : tr('news.savedLoadError', {'error': e.toString()});
      });
    }
  }

  Set<String> _idsOf(List<dynamic> items) {
    return items
        .map((item) => _articleId(item))
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  String _articleId(dynamic item) {
    if (item is Map) {
      return (item['id'] ?? '').toString();
    }
    return '';
  }

  Future<void> _toggleSaved(dynamic item) async {
    final id = _articleId(item);
    if (id.isEmpty || item is! Map) return;

    final article = Map<String, dynamic>.from(item);
    final wasSaved = _savedIds.contains(id);
    final previousSaved = List<dynamic>.from(_savedList);

    setState(() {
      if (wasSaved) {
        _savedIds = {..._savedIds}..remove(id);
        _savedList = _savedList
            .where((entry) => _articleId(entry) != id)
            .toList();
      } else {
        _savedIds = {..._savedIds, id};
        _savedList = [article, ..._savedList];
      }
    });

    try {
      if (wasSaved) {
        await widget.unsaveNews(id);
      } else {
        await widget.saveNews(article);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _savedList = previousSaved;
        _savedIds = _idsOf(previousSaved);
      });
      showTopNotification(
        context,
        e is ApiException ? e.message : e.toString(),
        color: Colors.redAccent,
      );
    }
  }

  bool get _hasActiveFilters =>
      _searchQuery.isNotEmpty ||
      _selectedCategory != 'news.categoryAll' ||
      _selectedSource.isNotEmpty;

  List<String> get _availableSources {
    final source = _showSavedOnly ? _savedList : _newsList;
    final names = <String>{};
    for (final item in source) {
      if (item is! Map) continue;
      final author = (item['author'] ?? '').toString().trim();
      if (author.isNotEmpty) names.add(author);
    }
    final sorted = names.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return sorted;
  }

  List<dynamic> get _visibleItems {
    final source = _showSavedOnly ? _savedList : _newsList;
    return source.where(_matchesFilters).toList();
  }

  bool _matchesFilters(dynamic item) {
    final title = (item['title'] ?? '').toString().toLowerCase();
    final content = (item['content'] ?? '').toString().toLowerCase();
    final tags = List<String>.from(
      item['tags'] ?? [],
    ).map((t) => t.toLowerCase()).toList();
    final category = (item['category'] ?? '').toString();

    if (_selectedSource.isNotEmpty &&
        (item['author'] ?? '').toString() != _selectedSource) {
      return false;
    }

    final selectedBackendCategory = _backendCategories[_selectedCategory];
    if (selectedBackendCategory != null &&
        category != selectedBackendCategory) {
      return false;
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      final matchesTitle = title.contains(query);
      final matchesContent = content.contains(query);
      final matchesTag = tags.any((tag) => tag.contains(query));
      if (!matchesTitle && !matchesContent && !matchesTag) {
        return false;
      }
    }

    return true;
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedCategory = 'news.categoryAll';
      _selectedSource = '';
      _searchController.clear();
    });
  }

  Future<void> _launchURL(String? urlString) async {
    if (urlString == null || urlString.isEmpty) return;
    final url = Uri.parse(urlString.trim());
    try {
      final success = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
      if (!success && mounted) {
        showTopNotification(
          context,
          remainingUiText('news.openLinkFailed', {'url': urlString}),
          color: Colors.redAccent,
        );
      }
    } catch (e) {
      if (mounted) {
        showTopNotification(
          context,
          remainingUiText('news.openArticleFailed', {'error': '$e'}),
          color: Colors.redAccent,
        );
      }
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) {
      return remainingUiText('news.unknown');
    }
    if (dateStr == '0001-01-01T00:00:00Z') {
      return remainingUiText('news.unknown');
    }
    try {
      final parsed = DateTime.parse(dateStr).toLocal();
      if (parsed.year <= 1) {
        return remainingUiText('news.unknown');
      }
      final now = DateTime.now();
      final difference = now.difference(parsed);

      if (difference.inMinutes < 60) {
        return remainingUiText('news.minutesAgo', {
          'count': '${difference.inMinutes}',
        });
      } else if (difference.inHours < 24) {
        return remainingUiText('news.hoursAgo', {
          'count': '${difference.inHours}',
        });
      } else {
        return remainingUiText('news.date', {
          'day': parsed.day.toString().padLeft(2, '0'),
          'month': parsed.month.toString().padLeft(2, '0'),
          'year': '${parsed.year}',
        });
      }
    } catch (_) {
      return remainingUiText('news.unknown');
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _visibleItems;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(_headerInset, 10, 0, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    tr('news.title'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white70),
                  onPressed: () {
                    _fetchNews();
                    _fetchSavedNews();
                  },
                  tooltip: tr('news.refresh'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          Padding(
            padding: const EdgeInsets.only(left: _headerInset),
            child: _buildToolbar(),
          ),
          const SizedBox(height: 24),

          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Color(0xFFC9A24A)),
                    ),
                  )
                : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchNews,
                          child: Text(tr('common.retry')),
                        ),
                      ],
                    ),
                  )
                : filteredItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _showSavedOnly && !_hasActiveFilters
                              ? Icons.bookmark_border_rounded
                              : Icons.search_off,
                          size: 48,
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _emptyStateMessage(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _showSavedOnly && _savedErrorMessage != null
                                ? Colors.redAccent
                                : Colors.white.withValues(alpha: 0.4),
                            fontSize: 14,
                          ),
                        ),
                        if (_hasActiveFilters) ...[
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _clearFilters,
                            child: Text(
                              tr('news.resetFilters'),
                              style: const TextStyle(color: Color(0xFFC9A24A)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: EdgeInsets.zero,
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: _tileMaxWidth,
                          mainAxisExtent: _cardExtent,
                          crossAxisSpacing: _gridGap,
                          mainAxisSpacing: _gridGap,
                        ),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) =>
                        _buildNewsCard(filteredItems[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Wrap(
      spacing: 18,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _searchFieldWidth),
          child: _buildSearchField(),
        ),
        _buildSourceFilter(),
        _buildCategoryFilter(),
        _buildSavedToggle(),
      ],
    );
  }

  Widget _buildSavedToggle() {
    final active = _showSavedOnly;
    final color = active
        ? DarkColors.accent
        : Colors.white.withValues(alpha: 0.5);

    return Tooltip(
      message: tr('news.savedFilter'),
      child: Material(
        color: active
            ? DarkColors.accent.withValues(alpha: 0.12)
            : DarkColors.surface,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: const ValueKey('news-saved-toggle'),
          onTap: () => setState(() => _showSavedOnly = !_showSavedOnly),
          child: Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: active
                    ? DarkColors.accent.withValues(alpha: 0.4)
                    : Colors.white.withValues(alpha: 0.07),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  active
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  size: 16,
                  color: color,
                ),
                const SizedBox(width: 7),
                Text(
                  _savedIds.isEmpty
                      ? tr('news.savedFilter')
                      : '${tr('news.savedFilter')} ${_savedIds.length}',
                  style: TextStyle(color: color, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _emptyStateMessage() {
    if (_showSavedOnly) {
      if (_savedErrorMessage != null) {
        return _savedErrorMessage!;
      }
      return _hasActiveFilters ? tr('news.noResults') : tr('news.savedEmpty');
    }
    return _hasActiveFilters ? tr('news.noResults') : tr('news.empty');
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      cursorColor: DarkColors.accent,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 11),
        hintText: tr('news.searchHint'),
        hintStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.28),
          fontSize: 13,
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 17,
          color: Colors.white.withValues(alpha: 0.35),
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 38,
          minHeight: 34,
        ),
        suffixIcon: _searchQuery.isEmpty
            ? null
            : IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.white54,
                  size: 15,
                ),
                splashRadius: 16,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _searchController.clear();
                  });
                },
              ),
        suffixIconConstraints: const BoxConstraints(
          minWidth: 34,
          minHeight: 34,
        ),
        filled: true,
        fillColor: DarkColors.surface,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: DarkColors.accent.withValues(alpha: 0.55),
            width: 1.2,
          ),
        ),
      ),
      onChanged: (val) {
        setState(() {
          _searchQuery = val.trim();
        });
      },
    );
  }

  Widget _buildCategoryFilter() {
    return _buildFilterMenu(
      label: tr('news.categoryLabel'),
      triggerKey: const ValueKey('news-category-dropdown-trigger'),
      optionKeyPrefix: 'news-category-option-',
      width: _categoryMenuWidth,
      selected: _selectedCategory,
      isOpen: _categoryMenuOpen,
      options: _categoryKeys
          .map(
            (key) => _FilterOption(
              value: key,
              label: tr(key),
              color: _categoryColor(key),
            ),
          )
          .toList(),
      onOpened: () => setState(() => _categoryMenuOpen = true),
      onClosed: () => setState(() => _categoryMenuOpen = false),
      onSelected: (value) => setState(() {
        _categoryMenuOpen = false;
        _selectedCategory = value;
      }),
    );
  }

  Widget _buildSourceFilter() {
    final options = <_FilterOption>[
      _FilterOption(
        value: '',
        label: tr('news.sourceAll'),
        color: DarkColors.accent,
      ),
      ..._availableSources.map(
        (name) => _FilterOption(
          value: name,
          label: name,
          color: newsSourceBrand(name).color,
          leading: _buildSourceMark(name, size: 16),
        ),
      ),
    ];

    return _buildFilterMenu(
      label: tr('news.sourceLabel'),
      triggerKey: const ValueKey('news-source-dropdown-trigger'),
      optionKeyPrefix: 'news-source-option-',
      width: _sourceMenuWidth,
      selected: _selectedSource,
      isOpen: _sourceMenuOpen,
      options: options,
      onOpened: () => setState(() => _sourceMenuOpen = true),
      onClosed: () => setState(() => _sourceMenuOpen = false),
      onSelected: (value) => setState(() {
        _sourceMenuOpen = false;
        _selectedSource = value;
      }),
    );
  }

  Widget _buildFilterMenu({
    required String label,
    required Key triggerKey,
    required String optionKeyPrefix,
    required double width,
    required String selected,
    required bool isOpen,
    required List<_FilterOption> options,
    required VoidCallback onOpened,
    required VoidCallback onClosed,
    required ValueChanged<String> onSelected,
  }) {
    final active = options.firstWhere(
      (option) => option.value == selected,
      orElse: () => options.first,
    );
    final borderColor = active.color.withValues(alpha: 0.32);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 10.5),
        ),
        const SizedBox(width: 6),
        PopupMenuButton<String>(
          key: triggerKey,
          tooltip: label,
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
              bottomLeft: Radius.circular(10),
              bottomRight: Radius.circular(10),
            ),
            side: BorderSide(color: active.color.withValues(alpha: 0.52)),
          ),
          onOpened: onOpened,
          onCanceled: onClosed,
          onSelected: onSelected,
          itemBuilder: (context) => options.map((option) {
            final isSelected = option.value == selected;
            return PopupMenuItem<String>(
              key: ValueKey('$optionKeyPrefix${option.value}'),
              value: option.value,
              height: 36,
              padding: EdgeInsets.zero,
              child: Container(
                height: 32,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? option.color.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected
                        ? option.color.withValues(alpha: 0.38)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    option.leading ?? _colorDot(option.color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        option.label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isSelected ? option.color : Colors.white70,
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_rounded, size: 15, color: option.color),
                  ],
                ),
              ),
            );
          }).toList(),
          child: Container(
            width: width,
            height: 34,
            padding: const EdgeInsets.only(left: 10, right: 4),
            decoration: BoxDecoration(
              color: active.color.withValues(alpha: 0.075),
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
                active.leading ?? _colorDot(active.color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    active.label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
                Icon(
                  Icons.expand_more_rounded,
                  size: 17,
                  color: active.color.withValues(alpha: 0.88),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _colorDot(Color color) => Container(
    width: 6,
    height: 6,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );

  static const Map<String, Color> _categoryColors = {
    'news.categoryAll': DarkColors.accent,
    'news.categoryReleases': Color(0xFF7C9CF0),
    'news.categoryHardware': Color(0xFFE08A4A),
    'news.categorySoftware': Color(0xFF4FC3D9),
    'news.categorySecurity': Color(0xFFE05A73),
    'news.categoryOpenSource': Color(0xFF5FBF8C),
    'news.categoryResearch': Color(0xFFB98BE0),
  };

  Color _categoryColor(String categoryKey) =>
      _categoryColors[categoryKey] ?? DarkColors.accent;

  Widget _buildNewsCard(dynamic item) {
    final title = item['title'] ?? remainingUiText('news.untitled');
    final content = item['content'] ?? '';
    final author = item['author'] ?? remainingUiText('news.source');
    final publishedAt = item['published_at'] as String?;
    final imageUrl = item['image_url'] as String?;
    final url = item['url'] as String?;
    final category = item['category'] ?? tr('news.categoryReleases');
    final sourceColor = newsSourceBrand(author.toString()).color;

    return Material(
      color: DarkColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_cardRadius),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: InkWell(
        onTap: () => _launchURL(url),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCardImage(imageUrl, sourceColor, item),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildSourceMark(author.toString()),
                        const SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            author,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: sourceColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),

                        Flexible(
                          child: Text(
                            ' • ${_formatDate(publishedAt)}',
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.35),
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Expanded(
                      child: Text(
                        content,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12.5,
                          height: 1.45,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: DarkColors.bg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardImage(String? imageUrl, Color sourceColor, dynamic item) {
    return SizedBox(
      height: _cardImageHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: DarkColors.bg),
          if (imageUrl != null && imageUrl.isNotEmpty)
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (context, error, stackTrace) => _imagePlaceholder(),
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : _imagePlaceholder(),
            )
          else
            _imagePlaceholder(),

          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.center,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.45),
                ],
              ),
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Container(height: 3, color: sourceColor),
          ),

          Positioned(top: 8, right: 8, child: _buildSaveButton(item)),
        ],
      ),
    );
  }

  Widget _buildSaveButton(dynamic item) {
    final id = _articleId(item);
    final isSaved = _savedIds.contains(id);

    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('news-save-toggle-$id'),
        onTap: () => _toggleSaved(item),
        child: Tooltip(
          message: isSaved ? tr('news.unsave') : tr('news.save'),
          child: SizedBox(
            width: 32,
            height: 32,
            child: Icon(
              isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              size: 17,
              color: isSaved ? DarkColors.accent : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSourceMark(String author, {double size = 18}) {
    final brand = newsSourceBrand(author);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: brand.color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: brand.color.withValues(alpha: 0.45)),
      ),
      child: Text(
        brand.mark,
        maxLines: 1,
        style: TextStyle(
          color: brand.color,
          fontSize: size * 0.44,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
          height: 1,
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return ColoredBox(
      color: DarkColors.bg,
      child: Center(
        child: Icon(
          Icons.newspaper,
          size: 28,
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
    );
  }
}

class _FilterOption {
  const _FilterOption({
    required this.value,
    required this.label,
    required this.color,
    this.leading,
  });

  final String value;
  final String label;
  final Color color;

  final Widget? leading;
}
