// This is a generated file - do not edit.
//
// Generated from culpeostudio/news/v1/news.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart'
    as $1;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class NewsItem extends $pb.GeneratedMessage {
  factory NewsItem({
    $core.String? id,
    $core.String? title,
    $core.String? content,
    $core.String? author,
    $1.Timestamp? publishedAt,
    $core.Iterable<$core.String>? tags,
    $core.String? imageUrl,
    $core.String? url,
    $core.String? category,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (title != null) result.title = title;
    if (content != null) result.content = content;
    if (author != null) result.author = author;
    if (publishedAt != null) result.publishedAt = publishedAt;
    if (tags != null) result.tags.addAll(tags);
    if (imageUrl != null) result.imageUrl = imageUrl;
    if (url != null) result.url = url;
    if (category != null) result.category = category;
    return result;
  }

  NewsItem._();

  factory NewsItem.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory NewsItem.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NewsItem',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.news.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'title')
    ..aOS(3, _omitFieldNames ? '' : 'content')
    ..aOS(4, _omitFieldNames ? '' : 'author')
    ..aOM<$1.Timestamp>(5, _omitFieldNames ? '' : 'publishedAt',
        subBuilder: $1.Timestamp.create)
    ..pPS(6, _omitFieldNames ? '' : 'tags')
    ..aOS(7, _omitFieldNames ? '' : 'imageUrl')
    ..aOS(8, _omitFieldNames ? '' : 'url')
    ..aOS(9, _omitFieldNames ? '' : 'category')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NewsItem clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NewsItem copyWith(void Function(NewsItem) updates) =>
      super.copyWith((message) => updates(message as NewsItem)) as NewsItem;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NewsItem create() => NewsItem._();
  @$core.override
  NewsItem createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static NewsItem getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<NewsItem>(create);
  static NewsItem? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get title => $_getSZ(1);
  @$pb.TagNumber(2)
  set title($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTitle() => $_has(1);
  @$pb.TagNumber(2)
  void clearTitle() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get content => $_getSZ(2);
  @$pb.TagNumber(3)
  set content($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasContent() => $_has(2);
  @$pb.TagNumber(3)
  void clearContent() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get author => $_getSZ(3);
  @$pb.TagNumber(4)
  set author($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAuthor() => $_has(3);
  @$pb.TagNumber(4)
  void clearAuthor() => $_clearField(4);

  @$pb.TagNumber(5)
  $1.Timestamp get publishedAt => $_getN(4);
  @$pb.TagNumber(5)
  set publishedAt($1.Timestamp value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasPublishedAt() => $_has(4);
  @$pb.TagNumber(5)
  void clearPublishedAt() => $_clearField(5);
  @$pb.TagNumber(5)
  $1.Timestamp ensurePublishedAt() => $_ensure(4);

  @$pb.TagNumber(6)
  $pb.PbList<$core.String> get tags => $_getList(5);

  @$pb.TagNumber(7)
  $core.String get imageUrl => $_getSZ(6);
  @$pb.TagNumber(7)
  set imageUrl($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasImageUrl() => $_has(6);
  @$pb.TagNumber(7)
  void clearImageUrl() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get url => $_getSZ(7);
  @$pb.TagNumber(8)
  set url($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasUrl() => $_has(7);
  @$pb.TagNumber(8)
  void clearUrl() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get category => $_getSZ(8);
  @$pb.TagNumber(9)
  set category($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasCategory() => $_has(8);
  @$pb.TagNumber(9)
  void clearCategory() => $_clearField(9);
}

/// SavedArticle keeps the item and when it was saved. The Go type embeds
/// NewsItem and the JSON flattened it; here it stays a nested field, and the
/// client flattens it back for the UI.
class SavedArticle extends $pb.GeneratedMessage {
  factory SavedArticle({
    NewsItem? item,
    $1.Timestamp? savedAt,
  }) {
    final result = create();
    if (item != null) result.item = item;
    if (savedAt != null) result.savedAt = savedAt;
    return result;
  }

  SavedArticle._();

  factory SavedArticle.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SavedArticle.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SavedArticle',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.news.v1'),
      createEmptyInstance: create)
    ..aOM<NewsItem>(1, _omitFieldNames ? '' : 'item',
        subBuilder: NewsItem.create)
    ..aOM<$1.Timestamp>(2, _omitFieldNames ? '' : 'savedAt',
        subBuilder: $1.Timestamp.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SavedArticle clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SavedArticle copyWith(void Function(SavedArticle) updates) =>
      super.copyWith((message) => updates(message as SavedArticle))
          as SavedArticle;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SavedArticle create() => SavedArticle._();
  @$core.override
  SavedArticle createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SavedArticle getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SavedArticle>(create);
  static SavedArticle? _defaultInstance;

  @$pb.TagNumber(1)
  NewsItem get item => $_getN(0);
  @$pb.TagNumber(1)
  set item(NewsItem value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasItem() => $_has(0);
  @$pb.TagNumber(1)
  void clearItem() => $_clearField(1);
  @$pb.TagNumber(1)
  NewsItem ensureItem() => $_ensure(0);

  @$pb.TagNumber(2)
  $1.Timestamp get savedAt => $_getN(1);
  @$pb.TagNumber(2)
  set savedAt($1.Timestamp value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasSavedAt() => $_has(1);
  @$pb.TagNumber(2)
  void clearSavedAt() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.Timestamp ensureSavedAt() => $_ensure(1);
}

class ListNewsRequest extends $pb.GeneratedMessage {
  factory ListNewsRequest() => create();

  ListNewsRequest._();

  factory ListNewsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListNewsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListNewsRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.news.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListNewsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListNewsRequest copyWith(void Function(ListNewsRequest) updates) =>
      super.copyWith((message) => updates(message as ListNewsRequest))
          as ListNewsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListNewsRequest create() => ListNewsRequest._();
  @$core.override
  ListNewsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListNewsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListNewsRequest>(create);
  static ListNewsRequest? _defaultInstance;
}

class ListNewsResponse extends $pb.GeneratedMessage {
  factory ListNewsResponse({
    $core.Iterable<NewsItem>? items,
  }) {
    final result = create();
    if (items != null) result.items.addAll(items);
    return result;
  }

  ListNewsResponse._();

  factory ListNewsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListNewsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListNewsResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.news.v1'),
      createEmptyInstance: create)
    ..pPM<NewsItem>(1, _omitFieldNames ? '' : 'items',
        subBuilder: NewsItem.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListNewsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListNewsResponse copyWith(void Function(ListNewsResponse) updates) =>
      super.copyWith((message) => updates(message as ListNewsResponse))
          as ListNewsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListNewsResponse create() => ListNewsResponse._();
  @$core.override
  ListNewsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListNewsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListNewsResponse>(create);
  static ListNewsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<NewsItem> get items => $_getList(0);
}

class GetNewsRequest extends $pb.GeneratedMessage {
  factory GetNewsRequest({
    $core.String? id,
  }) {
    final result = create();
    if (id != null) result.id = id;
    return result;
  }

  GetNewsRequest._();

  factory GetNewsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetNewsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetNewsRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.news.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetNewsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetNewsRequest copyWith(void Function(GetNewsRequest) updates) =>
      super.copyWith((message) => updates(message as GetNewsRequest))
          as GetNewsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetNewsRequest create() => GetNewsRequest._();
  @$core.override
  GetNewsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetNewsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetNewsRequest>(create);
  static GetNewsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);
}

class GetNewsResponse extends $pb.GeneratedMessage {
  factory GetNewsResponse({
    NewsItem? item,
  }) {
    final result = create();
    if (item != null) result.item = item;
    return result;
  }

  GetNewsResponse._();

  factory GetNewsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetNewsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetNewsResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.news.v1'),
      createEmptyInstance: create)
    ..aOM<NewsItem>(1, _omitFieldNames ? '' : 'item',
        subBuilder: NewsItem.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetNewsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetNewsResponse copyWith(void Function(GetNewsResponse) updates) =>
      super.copyWith((message) => updates(message as GetNewsResponse))
          as GetNewsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetNewsResponse create() => GetNewsResponse._();
  @$core.override
  GetNewsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetNewsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetNewsResponse>(create);
  static GetNewsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  NewsItem get item => $_getN(0);
  @$pb.TagNumber(1)
  set item(NewsItem value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasItem() => $_has(0);
  @$pb.TagNumber(1)
  void clearItem() => $_clearField(1);
  @$pb.TagNumber(1)
  NewsItem ensureItem() => $_ensure(0);
}

class ListSavedArticlesRequest extends $pb.GeneratedMessage {
  factory ListSavedArticlesRequest() => create();

  ListSavedArticlesRequest._();

  factory ListSavedArticlesRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListSavedArticlesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListSavedArticlesRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.news.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListSavedArticlesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListSavedArticlesRequest copyWith(
          void Function(ListSavedArticlesRequest) updates) =>
      super.copyWith((message) => updates(message as ListSavedArticlesRequest))
          as ListSavedArticlesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListSavedArticlesRequest create() => ListSavedArticlesRequest._();
  @$core.override
  ListSavedArticlesRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListSavedArticlesRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListSavedArticlesRequest>(create);
  static ListSavedArticlesRequest? _defaultInstance;
}

class ListSavedArticlesResponse extends $pb.GeneratedMessage {
  factory ListSavedArticlesResponse({
    $core.Iterable<SavedArticle>? articles,
  }) {
    final result = create();
    if (articles != null) result.articles.addAll(articles);
    return result;
  }

  ListSavedArticlesResponse._();

  factory ListSavedArticlesResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListSavedArticlesResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListSavedArticlesResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.news.v1'),
      createEmptyInstance: create)
    ..pPM<SavedArticle>(1, _omitFieldNames ? '' : 'articles',
        subBuilder: SavedArticle.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListSavedArticlesResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListSavedArticlesResponse copyWith(
          void Function(ListSavedArticlesResponse) updates) =>
      super.copyWith((message) => updates(message as ListSavedArticlesResponse))
          as ListSavedArticlesResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListSavedArticlesResponse create() => ListSavedArticlesResponse._();
  @$core.override
  ListSavedArticlesResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListSavedArticlesResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListSavedArticlesResponse>(create);
  static ListSavedArticlesResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<SavedArticle> get articles => $_getList(0);
}

/// The backend prefers its own cached copy of the item when it knows the id, so
/// a client cannot store a doctored article.
class SaveArticleRequest extends $pb.GeneratedMessage {
  factory SaveArticleRequest({
    NewsItem? item,
  }) {
    final result = create();
    if (item != null) result.item = item;
    return result;
  }

  SaveArticleRequest._();

  factory SaveArticleRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SaveArticleRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SaveArticleRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.news.v1'),
      createEmptyInstance: create)
    ..aOM<NewsItem>(1, _omitFieldNames ? '' : 'item',
        subBuilder: NewsItem.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SaveArticleRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SaveArticleRequest copyWith(void Function(SaveArticleRequest) updates) =>
      super.copyWith((message) => updates(message as SaveArticleRequest))
          as SaveArticleRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SaveArticleRequest create() => SaveArticleRequest._();
  @$core.override
  SaveArticleRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SaveArticleRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SaveArticleRequest>(create);
  static SaveArticleRequest? _defaultInstance;

  @$pb.TagNumber(1)
  NewsItem get item => $_getN(0);
  @$pb.TagNumber(1)
  set item(NewsItem value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasItem() => $_has(0);
  @$pb.TagNumber(1)
  void clearItem() => $_clearField(1);
  @$pb.TagNumber(1)
  NewsItem ensureItem() => $_ensure(0);
}

class SaveArticleResponse extends $pb.GeneratedMessage {
  factory SaveArticleResponse({
    SavedArticle? article,
  }) {
    final result = create();
    if (article != null) result.article = article;
    return result;
  }

  SaveArticleResponse._();

  factory SaveArticleResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SaveArticleResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SaveArticleResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.news.v1'),
      createEmptyInstance: create)
    ..aOM<SavedArticle>(1, _omitFieldNames ? '' : 'article',
        subBuilder: SavedArticle.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SaveArticleResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SaveArticleResponse copyWith(void Function(SaveArticleResponse) updates) =>
      super.copyWith((message) => updates(message as SaveArticleResponse))
          as SaveArticleResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SaveArticleResponse create() => SaveArticleResponse._();
  @$core.override
  SaveArticleResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SaveArticleResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SaveArticleResponse>(create);
  static SaveArticleResponse? _defaultInstance;

  @$pb.TagNumber(1)
  SavedArticle get article => $_getN(0);
  @$pb.TagNumber(1)
  set article(SavedArticle value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasArticle() => $_has(0);
  @$pb.TagNumber(1)
  void clearArticle() => $_clearField(1);
  @$pb.TagNumber(1)
  SavedArticle ensureArticle() => $_ensure(0);
}

class DeleteSavedArticleRequest extends $pb.GeneratedMessage {
  factory DeleteSavedArticleRequest({
    $core.String? id,
  }) {
    final result = create();
    if (id != null) result.id = id;
    return result;
  }

  DeleteSavedArticleRequest._();

  factory DeleteSavedArticleRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeleteSavedArticleRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteSavedArticleRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.news.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteSavedArticleRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteSavedArticleRequest copyWith(
          void Function(DeleteSavedArticleRequest) updates) =>
      super.copyWith((message) => updates(message as DeleteSavedArticleRequest))
          as DeleteSavedArticleRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteSavedArticleRequest create() => DeleteSavedArticleRequest._();
  @$core.override
  DeleteSavedArticleRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeleteSavedArticleRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteSavedArticleRequest>(create);
  static DeleteSavedArticleRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);
}

class DeleteSavedArticleResponse extends $pb.GeneratedMessage {
  factory DeleteSavedArticleResponse() => create();

  DeleteSavedArticleResponse._();

  factory DeleteSavedArticleResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeleteSavedArticleResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteSavedArticleResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.news.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteSavedArticleResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteSavedArticleResponse copyWith(
          void Function(DeleteSavedArticleResponse) updates) =>
      super.copyWith(
              (message) => updates(message as DeleteSavedArticleResponse))
          as DeleteSavedArticleResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteSavedArticleResponse create() => DeleteSavedArticleResponse._();
  @$core.override
  DeleteSavedArticleResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeleteSavedArticleResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteSavedArticleResponse>(create);
  static DeleteSavedArticleResponse? _defaultInstance;
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
