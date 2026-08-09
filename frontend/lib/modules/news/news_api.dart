import 'package:grpc/grpc.dart';
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart'
    as tspb;
import '../../generated/culpeostudio/news/v1/news.pbgrpc.dart' as newspb;
import '../../core/api_client.dart';
import '../../core/remaining_ui_strings.dart';

/// Nachrichten lesen und merken.
class NewsApi {
  NewsApi(this._c);

  final ApiClient _c;

  Future<List<dynamic>> getNews() async {
    try {
      final response = await _c.newsClient.listNews(newspb.ListNewsRequest());
      return response.items.map(_itemToMap).toList();
    } catch (e) {
      throw ApiException(
        remainingUiText('api.newsLoadFailed', {
          'error': _c.grpcErrorMessage(e),
        }),
      );
    }
  }

  Future<List<dynamic>> getSavedNews() async {
    try {
      final response = await _c.newsClient.listSavedArticles(
        newspb.ListSavedArticlesRequest(),
      );
      return response.articles.map(_savedToMap).toList();
    } catch (e) {
      throw ApiException(
        remainingUiText('api.newsLoadFailed', {
          'error': _c.grpcErrorMessage(e),
        }),
      );
    }
  }

  Future<Map<String, dynamic>> saveNewsArticle(
    Map<String, dynamic> article,
  ) async {
    try {
      final response = await _c.newsClient.saveArticle(
        newspb.SaveArticleRequest(item: _itemFromMap(article)),
      );
      return _savedToMap(response.article);
    } catch (e) {
      throw ApiException(
        remainingUiText('api.newsSaveFailed', {
          'statusCode': _c.grpcErrorMessage(e),
        }),
      );
    }
  }

  Future<void> deleteSavedNewsArticle(String articleId) async {
    try {
      await _c.newsClient.deleteSavedArticle(
        newspb.DeleteSavedArticleRequest(id: articleId),
      );
    } catch (e) {
      // An article that is not on the list is already in the desired state,
      // which is how the HTTP client treated its 404 too.
      if (e is GrpcError && e.code == StatusCode.notFound) return;
      throw ApiException(
        remainingUiText('api.newsUnsaveFailed', {
          'statusCode': _c.grpcErrorMessage(e),
        }),
      );
    }
  }

  /// Flattens the saved article the way the JSON did, because the UI reads the
  /// item's fields directly off the map.
  Map<String, dynamic> _savedToMap(newspb.SavedArticle article) {
    return {
      ..._itemToMap(article.item),
      'saved_at': article.savedAt.toDateTime().toIso8601String(),
    };
  }

  Map<String, dynamic> _itemToMap(newspb.NewsItem item) {
    return {
      'id': item.id,
      'title': item.title,
      'content': item.content,
      'author': item.author,
      'published_at': item.publishedAt.toDateTime().toIso8601String(),
      if (item.tags.isNotEmpty) 'tags': item.tags.toList(),
      if (item.imageUrl.isNotEmpty) 'image_url': item.imageUrl,
      'url': item.url,
      'category': item.category,
    };
  }

  newspb.NewsItem _itemFromMap(Map<String, dynamic> article) {
    final item = newspb.NewsItem(
      id: (article['id'] ?? '').toString(),
      title: (article['title'] ?? '').toString(),
      content: (article['content'] ?? '').toString(),
      author: (article['author'] ?? '').toString(),
      url: (article['url'] ?? '').toString(),
      category: (article['category'] ?? '').toString(),
    );
    if (article['image_url'] != null) {
      item.imageUrl = article['image_url'].toString();
    }
    if (article['tags'] is List) {
      item.tags.addAll((article['tags'] as List).map((tag) => tag.toString()));
    }
    final published = DateTime.tryParse(
      (article['published_at'] ?? '').toString(),
    );
    if (published != null) {
      item.publishedAt = tspb.Timestamp.fromDateTime(published);
    }
    return item;
  }
}
