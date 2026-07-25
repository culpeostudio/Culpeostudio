import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import '../../widgets/top_notification.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key, Future<List<dynamic>> Function()? loadNews})
    : loadNews = loadNews ?? _defaultLoadNews;

  final Future<List<dynamic>> Function() loadNews;

  static Future<List<dynamic>> _defaultLoadNews() => ApiService().getNews();

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _newsList = [];
  bool _isLoading = true;
  String? _errorMessage;

  String _searchQuery = '';
  String _selectedCategory = 'Alle';

  final List<String> _categories = [
    'Alle',
    'KI-Releases',
    'Hardware',
    'Open Source',
    'Research',
  ];

  @override
  void initState() {
    super.initState();
    _fetchNews();
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
    return 'Fehler beim Laden der Neuigkeiten: $error';
  }

  bool get _hasActiveFilters =>
      _searchQuery.isNotEmpty || _selectedCategory != 'Alle';

  List<dynamic> get _filteredNewsList {
    return _newsList.where((item) {
      final title = (item['title'] ?? '').toString().toLowerCase();
      final content = (item['content'] ?? '').toString().toLowerCase();
      final tags = List<String>.from(
        item['tags'] ?? [],
      ).map((t) => t.toLowerCase()).toList();
      final category = (item['category'] ?? '').toString();

      // Category filtering
      if (_selectedCategory != 'Alle' && category != _selectedCategory) {
        return false;
      }

      // Search query filtering
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
    }).toList();
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedCategory = 'Alle';
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
          'Konnte Link nicht öffnen: $urlString',
          color: Colors.redAccent,
        );
      }
    } catch (e) {
      if (mounted) {
        showTopNotification(
          context,
          'Fehler beim Öffnen des Artikels: $e',
          color: Colors.redAccent,
        );
      }
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Unbekannt';
    if (dateStr == '0001-01-01T00:00:00Z') {
      return 'Unbekannt';
    }
    try {
      final parsed = DateTime.parse(dateStr).toLocal();
      if (parsed.year <= 1) {
        return 'Unbekannt';
      }
      final now = DateTime.now();
      final difference = now.difference(parsed);

      if (difference.inMinutes < 60) {
        return 'vor ${difference.inMinutes} Min.';
      } else if (difference.inHours < 24) {
        return 'vor ${difference.inHours} Std.';
      } else {
        return '${parsed.day.toString().padLeft(2, '0')}.${parsed.month.toString().padLeft(2, '0')}.${parsed.year}';
      }
    } catch (_) {
      return 'Unbekannt';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _filteredNewsList;
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI & Tech Feed',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Live-Nachrichten aggregiert aus führenden Hardware- und KI-Quellen.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white70),
                onPressed: _fetchNews,
                tooltip: 'Aktualisieren',
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Search and Category Panel
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF16161D),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
            ),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Suche nach Schlagworten, Inhalten oder Tags...',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: Colors.white54,
                              size: 18,
                            ),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                                _searchController.clear();
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFF0F0F12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim();
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Category Pills Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'KATEGORIE:',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _categories.map((category) {
                            final isSelected = _selectedCategory == category;
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(
                                  category,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.6),
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                selected: isSelected,
                                selectedColor: const Color(0xFFC9A24A),
                                backgroundColor: const Color(0xFF0F0F12),
                                checkmarkColor: Colors.white,
                                showCheckmark: false,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    20,
                                  ), // Rounded Capsule Pill shape
                                  side: BorderSide(
                                    color: isSelected
                                        ? const Color(0xFFC9A24A)
                                        : Colors.white.withValues(alpha: 0.04),
                                  ),
                                ),
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _selectedCategory = category;
                                    });
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Google News Layout Cards
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
                          child: const Text('Erneut versuchen'),
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
                          Icons.search_off,
                          size: 48,
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _hasActiveFilters
                              ? 'Keine passenden Artikel gefunden.'
                              : 'Momentan sind keine Artikel verfügbar.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 14,
                          ),
                        ),
                        if (_hasActiveFilters) ...[
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _clearFilters,
                            child: const Text(
                              'Filter zurücksetzen',
                              style: TextStyle(color: Color(0xFFC9A24A)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isDesktop ? 2 : 1,
                      mainAxisExtent:
                          155, // Set explicit height matching Google News cards
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      final title = item['title'] ?? 'Kein Titel';
                      final content = item['content'] ?? '';
                      final author = item['author'] ?? 'Quelle';
                      final publishedAt = item['published_at'] as String?;
                      final imageUrl = item['image_url'] as String?;
                      final url = item['url'] as String?;
                      final category = item['category'] ?? 'KI-Releases';

                      return Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF16161D),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.04),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _launchURL(url),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Left text content: Source + Time + Headline
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Source + Time
                                        Row(
                                          children: [
                                            Text(
                                              author,
                                              style: const TextStyle(
                                                color: Color(0xFFC9A24A),
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              ' • ${_formatDate(publishedAt)}',
                                              style: TextStyle(
                                                color: Colors.white.withValues(
                                                  alpha: 0.4,
                                                ),
                                                fontSize: 11,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            // Optional Category tag indicator
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF0F0F12),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                category,
                                                style: TextStyle(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.3),
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),

                                        // Headline (Title)
                                        Text(
                                          title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            height: 1.3,
                                          ),
                                        ),
                                        const SizedBox(height: 8),

                                        // Snippet
                                        Expanded(
                                          child: Text(
                                            content,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.white.withValues(
                                                alpha: 0.6,
                                              ),
                                              fontSize: 12,
                                              height: 1.3,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),

                                  // Right Thumbnail Image (Google News layout)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      width: 90,
                                      height: 90,
                                      color: const Color(0xFF0F0F12),
                                      child: imageUrl != null
                                          ? Image.network(
                                              imageUrl,
                                              width: 90,
                                              height: 90,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => Center(
                                                    child: Icon(
                                                      Icons.newspaper,
                                                      size: 24,
                                                      color: Colors.white
                                                          .withValues(
                                                            alpha: 0.15,
                                                          ),
                                                    ),
                                                  ),
                                            )
                                          : Center(
                                              child: Icon(
                                                Icons.newspaper,
                                                size: 24,
                                                color: Colors.white.withValues(
                                                  alpha: 0.15,
                                                ),
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
