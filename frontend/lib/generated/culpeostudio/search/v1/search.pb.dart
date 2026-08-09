// This is a generated file - do not edit.
//
// Generated from culpeostudio/search/v1/search.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'search.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'search.pbenum.dart';

class SearchRequest extends $pb.GeneratedMessage {
  factory SearchRequest({
    Category? category,
    $core.String? query,
    $core.String? region,
    $core.String? safesearch,
    $core.String? timelimit,
    $core.int? page,
    $core.int? maxResults,
    $core.String? backend,
  }) {
    final result = create();
    if (category != null) result.category = category;
    if (query != null) result.query = query;
    if (region != null) result.region = region;
    if (safesearch != null) result.safesearch = safesearch;
    if (timelimit != null) result.timelimit = timelimit;
    if (page != null) result.page = page;
    if (maxResults != null) result.maxResults = maxResults;
    if (backend != null) result.backend = backend;
    return result;
  }

  SearchRequest._();

  factory SearchRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SearchRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SearchRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.search.v1'),
      createEmptyInstance: create)
    ..aE<Category>(1, _omitFieldNames ? '' : 'category',
        enumValues: Category.values)
    ..aOS(2, _omitFieldNames ? '' : 'query')
    ..aOS(3, _omitFieldNames ? '' : 'region')
    ..aOS(4, _omitFieldNames ? '' : 'safesearch')
    ..aOS(5, _omitFieldNames ? '' : 'timelimit')
    ..aI(6, _omitFieldNames ? '' : 'page')
    ..aI(7, _omitFieldNames ? '' : 'maxResults')
    ..aOS(8, _omitFieldNames ? '' : 'backend')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SearchRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SearchRequest copyWith(void Function(SearchRequest) updates) =>
      super.copyWith((message) => updates(message as SearchRequest))
          as SearchRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SearchRequest create() => SearchRequest._();
  @$core.override
  SearchRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SearchRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SearchRequest>(create);
  static SearchRequest? _defaultInstance;

  @$pb.TagNumber(1)
  Category get category => $_getN(0);
  @$pb.TagNumber(1)
  set category(Category value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasCategory() => $_has(0);
  @$pb.TagNumber(1)
  void clearCategory() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get query => $_getSZ(1);
  @$pb.TagNumber(2)
  set query($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasQuery() => $_has(1);
  @$pb.TagNumber(2)
  void clearQuery() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get region => $_getSZ(2);
  @$pb.TagNumber(3)
  set region($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRegion() => $_has(2);
  @$pb.TagNumber(3)
  void clearRegion() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get safesearch => $_getSZ(3);
  @$pb.TagNumber(4)
  set safesearch($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSafesearch() => $_has(3);
  @$pb.TagNumber(4)
  void clearSafesearch() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get timelimit => $_getSZ(4);
  @$pb.TagNumber(5)
  set timelimit($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasTimelimit() => $_has(4);
  @$pb.TagNumber(5)
  void clearTimelimit() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get page => $_getIZ(5);
  @$pb.TagNumber(6)
  set page($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasPage() => $_has(5);
  @$pb.TagNumber(6)
  void clearPage() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get maxResults => $_getIZ(6);
  @$pb.TagNumber(7)
  set maxResults($core.int value) => $_setSignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasMaxResults() => $_has(6);
  @$pb.TagNumber(7)
  void clearMaxResults() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get backend => $_getSZ(7);
  @$pb.TagNumber(8)
  set backend($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasBackend() => $_has(7);
  @$pb.TagNumber(8)
  void clearBackend() => $_clearField(8);
}

/// One hit. Which fields are filled depends on the category the search ran in.
class SearchResult extends $pb.GeneratedMessage {
  factory SearchResult({
    $core.String? title,
    $core.String? href,
    $core.String? body,
    $core.String? image,
    $core.String? thumbnail,
    $core.String? url,
    $core.String? height,
    $core.String? width,
    $core.String? source,
    $core.String? date,
    $core.String? content,
    $core.String? description,
    $core.String? duration,
    $core.String? embedHtml,
    $core.String? embedUrl,
    $core.String? imageToken,
    $core.String? provider,
    $core.String? published,
    $core.String? publisher,
    $core.String? uploader,
    $core.String? author,
    $core.String? info,
  }) {
    final result = create();
    if (title != null) result.title = title;
    if (href != null) result.href = href;
    if (body != null) result.body = body;
    if (image != null) result.image = image;
    if (thumbnail != null) result.thumbnail = thumbnail;
    if (url != null) result.url = url;
    if (height != null) result.height = height;
    if (width != null) result.width = width;
    if (source != null) result.source = source;
    if (date != null) result.date = date;
    if (content != null) result.content = content;
    if (description != null) result.description = description;
    if (duration != null) result.duration = duration;
    if (embedHtml != null) result.embedHtml = embedHtml;
    if (embedUrl != null) result.embedUrl = embedUrl;
    if (imageToken != null) result.imageToken = imageToken;
    if (provider != null) result.provider = provider;
    if (published != null) result.published = published;
    if (publisher != null) result.publisher = publisher;
    if (uploader != null) result.uploader = uploader;
    if (author != null) result.author = author;
    if (info != null) result.info = info;
    return result;
  }

  SearchResult._();

  factory SearchResult.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SearchResult.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SearchResult',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.search.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'title')
    ..aOS(2, _omitFieldNames ? '' : 'href')
    ..aOS(3, _omitFieldNames ? '' : 'body')
    ..aOS(4, _omitFieldNames ? '' : 'image')
    ..aOS(5, _omitFieldNames ? '' : 'thumbnail')
    ..aOS(6, _omitFieldNames ? '' : 'url')
    ..aOS(7, _omitFieldNames ? '' : 'height')
    ..aOS(8, _omitFieldNames ? '' : 'width')
    ..aOS(9, _omitFieldNames ? '' : 'source')
    ..aOS(10, _omitFieldNames ? '' : 'date')
    ..aOS(11, _omitFieldNames ? '' : 'content')
    ..aOS(12, _omitFieldNames ? '' : 'description')
    ..aOS(13, _omitFieldNames ? '' : 'duration')
    ..aOS(14, _omitFieldNames ? '' : 'embedHtml')
    ..aOS(15, _omitFieldNames ? '' : 'embedUrl')
    ..aOS(16, _omitFieldNames ? '' : 'imageToken')
    ..aOS(17, _omitFieldNames ? '' : 'provider')
    ..aOS(18, _omitFieldNames ? '' : 'published')
    ..aOS(19, _omitFieldNames ? '' : 'publisher')
    ..aOS(20, _omitFieldNames ? '' : 'uploader')
    ..aOS(21, _omitFieldNames ? '' : 'author')
    ..aOS(22, _omitFieldNames ? '' : 'info')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SearchResult clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SearchResult copyWith(void Function(SearchResult) updates) =>
      super.copyWith((message) => updates(message as SearchResult))
          as SearchResult;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SearchResult create() => SearchResult._();
  @$core.override
  SearchResult createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SearchResult getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SearchResult>(create);
  static SearchResult? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get title => $_getSZ(0);
  @$pb.TagNumber(1)
  set title($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTitle() => $_has(0);
  @$pb.TagNumber(1)
  void clearTitle() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get href => $_getSZ(1);
  @$pb.TagNumber(2)
  set href($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasHref() => $_has(1);
  @$pb.TagNumber(2)
  void clearHref() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get body => $_getSZ(2);
  @$pb.TagNumber(3)
  set body($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasBody() => $_has(2);
  @$pb.TagNumber(3)
  void clearBody() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get image => $_getSZ(3);
  @$pb.TagNumber(4)
  set image($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasImage() => $_has(3);
  @$pb.TagNumber(4)
  void clearImage() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get thumbnail => $_getSZ(4);
  @$pb.TagNumber(5)
  set thumbnail($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasThumbnail() => $_has(4);
  @$pb.TagNumber(5)
  void clearThumbnail() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get url => $_getSZ(5);
  @$pb.TagNumber(6)
  set url($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasUrl() => $_has(5);
  @$pb.TagNumber(6)
  void clearUrl() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get height => $_getSZ(6);
  @$pb.TagNumber(7)
  set height($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasHeight() => $_has(6);
  @$pb.TagNumber(7)
  void clearHeight() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get width => $_getSZ(7);
  @$pb.TagNumber(8)
  set width($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasWidth() => $_has(7);
  @$pb.TagNumber(8)
  void clearWidth() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get source => $_getSZ(8);
  @$pb.TagNumber(9)
  set source($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasSource() => $_has(8);
  @$pb.TagNumber(9)
  void clearSource() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.String get date => $_getSZ(9);
  @$pb.TagNumber(10)
  set date($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasDate() => $_has(9);
  @$pb.TagNumber(10)
  void clearDate() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.String get content => $_getSZ(10);
  @$pb.TagNumber(11)
  set content($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasContent() => $_has(10);
  @$pb.TagNumber(11)
  void clearContent() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.String get description => $_getSZ(11);
  @$pb.TagNumber(12)
  set description($core.String value) => $_setString(11, value);
  @$pb.TagNumber(12)
  $core.bool hasDescription() => $_has(11);
  @$pb.TagNumber(12)
  void clearDescription() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.String get duration => $_getSZ(12);
  @$pb.TagNumber(13)
  set duration($core.String value) => $_setString(12, value);
  @$pb.TagNumber(13)
  $core.bool hasDuration() => $_has(12);
  @$pb.TagNumber(13)
  void clearDuration() => $_clearField(13);

  @$pb.TagNumber(14)
  $core.String get embedHtml => $_getSZ(13);
  @$pb.TagNumber(14)
  set embedHtml($core.String value) => $_setString(13, value);
  @$pb.TagNumber(14)
  $core.bool hasEmbedHtml() => $_has(13);
  @$pb.TagNumber(14)
  void clearEmbedHtml() => $_clearField(14);

  @$pb.TagNumber(15)
  $core.String get embedUrl => $_getSZ(14);
  @$pb.TagNumber(15)
  set embedUrl($core.String value) => $_setString(14, value);
  @$pb.TagNumber(15)
  $core.bool hasEmbedUrl() => $_has(14);
  @$pb.TagNumber(15)
  void clearEmbedUrl() => $_clearField(15);

  @$pb.TagNumber(16)
  $core.String get imageToken => $_getSZ(15);
  @$pb.TagNumber(16)
  set imageToken($core.String value) => $_setString(15, value);
  @$pb.TagNumber(16)
  $core.bool hasImageToken() => $_has(15);
  @$pb.TagNumber(16)
  void clearImageToken() => $_clearField(16);

  @$pb.TagNumber(17)
  $core.String get provider => $_getSZ(16);
  @$pb.TagNumber(17)
  set provider($core.String value) => $_setString(16, value);
  @$pb.TagNumber(17)
  $core.bool hasProvider() => $_has(16);
  @$pb.TagNumber(17)
  void clearProvider() => $_clearField(17);

  @$pb.TagNumber(18)
  $core.String get published => $_getSZ(17);
  @$pb.TagNumber(18)
  set published($core.String value) => $_setString(17, value);
  @$pb.TagNumber(18)
  $core.bool hasPublished() => $_has(17);
  @$pb.TagNumber(18)
  void clearPublished() => $_clearField(18);

  @$pb.TagNumber(19)
  $core.String get publisher => $_getSZ(18);
  @$pb.TagNumber(19)
  set publisher($core.String value) => $_setString(18, value);
  @$pb.TagNumber(19)
  $core.bool hasPublisher() => $_has(18);
  @$pb.TagNumber(19)
  void clearPublisher() => $_clearField(19);

  @$pb.TagNumber(20)
  $core.String get uploader => $_getSZ(19);
  @$pb.TagNumber(20)
  set uploader($core.String value) => $_setString(19, value);
  @$pb.TagNumber(20)
  $core.bool hasUploader() => $_has(19);
  @$pb.TagNumber(20)
  void clearUploader() => $_clearField(20);

  @$pb.TagNumber(21)
  $core.String get author => $_getSZ(20);
  @$pb.TagNumber(21)
  set author($core.String value) => $_setString(20, value);
  @$pb.TagNumber(21)
  $core.bool hasAuthor() => $_has(20);
  @$pb.TagNumber(21)
  void clearAuthor() => $_clearField(21);

  @$pb.TagNumber(22)
  $core.String get info => $_getSZ(21);
  @$pb.TagNumber(22)
  set info($core.String value) => $_setString(21, value);
  @$pb.TagNumber(22)
  $core.bool hasInfo() => $_has(21);
  @$pb.TagNumber(22)
  void clearInfo() => $_clearField(22);
}

class SearchResponse extends $pb.GeneratedMessage {
  factory SearchResponse({
    $core.String? query,
    $core.Iterable<SearchResult>? results,
    $core.int? count,
  }) {
    final result = create();
    if (query != null) result.query = query;
    if (results != null) result.results.addAll(results);
    if (count != null) result.count = count;
    return result;
  }

  SearchResponse._();

  factory SearchResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SearchResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SearchResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.search.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'query')
    ..pPM<SearchResult>(2, _omitFieldNames ? '' : 'results',
        subBuilder: SearchResult.create)
    ..aI(3, _omitFieldNames ? '' : 'count')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SearchResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SearchResponse copyWith(void Function(SearchResponse) updates) =>
      super.copyWith((message) => updates(message as SearchResponse))
          as SearchResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SearchResponse create() => SearchResponse._();
  @$core.override
  SearchResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SearchResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SearchResponse>(create);
  static SearchResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get query => $_getSZ(0);
  @$pb.TagNumber(1)
  set query($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasQuery() => $_has(0);
  @$pb.TagNumber(1)
  void clearQuery() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<SearchResult> get results => $_getList(1);

  @$pb.TagNumber(3)
  $core.int get count => $_getIZ(2);
  @$pb.TagNumber(3)
  set count($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCount() => $_has(2);
  @$pb.TagNumber(3)
  void clearCount() => $_clearField(3);
}

class ExtractRequest extends $pb.GeneratedMessage {
  factory ExtractRequest({
    $core.String? url,
    ExtractFormat? format,
  }) {
    final result = create();
    if (url != null) result.url = url;
    if (format != null) result.format = format;
    return result;
  }

  ExtractRequest._();

  factory ExtractRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ExtractRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ExtractRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.search.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'url')
    ..aE<ExtractFormat>(2, _omitFieldNames ? '' : 'format',
        enumValues: ExtractFormat.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExtractRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExtractRequest copyWith(void Function(ExtractRequest) updates) =>
      super.copyWith((message) => updates(message as ExtractRequest))
          as ExtractRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExtractRequest create() => ExtractRequest._();
  @$core.override
  ExtractRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ExtractRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ExtractRequest>(create);
  static ExtractRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get url => $_getSZ(0);
  @$pb.TagNumber(1)
  set url($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUrl() => $_has(0);
  @$pb.TagNumber(1)
  void clearUrl() => $_clearField(1);

  @$pb.TagNumber(2)
  ExtractFormat get format => $_getN(1);
  @$pb.TagNumber(2)
  set format(ExtractFormat value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFormat() => $_has(1);
  @$pb.TagNumber(2)
  void clearFormat() => $_clearField(2);
}

class ExtractResponse extends $pb.GeneratedMessage {
  factory ExtractResponse({
    $core.String? url,
    ExtractFormat? format,
    $core.String? content,
    $core.List<$core.int>? rawContent,
  }) {
    final result = create();
    if (url != null) result.url = url;
    if (format != null) result.format = format;
    if (content != null) result.content = content;
    if (rawContent != null) result.rawContent = rawContent;
    return result;
  }

  ExtractResponse._();

  factory ExtractResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ExtractResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ExtractResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.search.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'url')
    ..aE<ExtractFormat>(2, _omitFieldNames ? '' : 'format',
        enumValues: ExtractFormat.values)
    ..aOS(3, _omitFieldNames ? '' : 'content')
    ..a<$core.List<$core.int>>(
        4, _omitFieldNames ? '' : 'rawContent', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExtractResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExtractResponse copyWith(void Function(ExtractResponse) updates) =>
      super.copyWith((message) => updates(message as ExtractResponse))
          as ExtractResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExtractResponse create() => ExtractResponse._();
  @$core.override
  ExtractResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ExtractResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ExtractResponse>(create);
  static ExtractResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get url => $_getSZ(0);
  @$pb.TagNumber(1)
  set url($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUrl() => $_has(0);
  @$pb.TagNumber(1)
  void clearUrl() => $_clearField(1);

  @$pb.TagNumber(2)
  ExtractFormat get format => $_getN(1);
  @$pb.TagNumber(2)
  set format(ExtractFormat value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFormat() => $_has(1);
  @$pb.TagNumber(2)
  void clearFormat() => $_clearField(2);

  /// Filled for every textual format.
  @$pb.TagNumber(3)
  $core.String get content => $_getSZ(2);
  @$pb.TagNumber(3)
  set content($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasContent() => $_has(2);
  @$pb.TagNumber(3)
  void clearContent() => $_clearField(3);

  /// Filled for CONTENT: the raw bytes, which the JSON API had to base64
  /// encode and proto carries natively.
  @$pb.TagNumber(4)
  $core.List<$core.int> get rawContent => $_getN(3);
  @$pb.TagNumber(4)
  set rawContent($core.List<$core.int> value) => $_setBytes(3, value);
  @$pb.TagNumber(4)
  $core.bool hasRawContent() => $_has(3);
  @$pb.TagNumber(4)
  void clearRawContent() => $_clearField(4);
}

class ListEnginesRequest extends $pb.GeneratedMessage {
  factory ListEnginesRequest() => create();

  ListEnginesRequest._();

  factory ListEnginesRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListEnginesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListEnginesRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.search.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListEnginesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListEnginesRequest copyWith(void Function(ListEnginesRequest) updates) =>
      super.copyWith((message) => updates(message as ListEnginesRequest))
          as ListEnginesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListEnginesRequest create() => ListEnginesRequest._();
  @$core.override
  ListEnginesRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListEnginesRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListEnginesRequest>(create);
  static ListEnginesRequest? _defaultInstance;
}

class ListEnginesResponse extends $pb.GeneratedMessage {
  factory ListEnginesResponse({
    $core.Iterable<$core.MapEntry<$core.String, EngineNames>>? engines,
  }) {
    final result = create();
    if (engines != null) result.engines.addEntries(engines);
    return result;
  }

  ListEnginesResponse._();

  factory ListEnginesResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListEnginesResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListEnginesResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.search.v1'),
      createEmptyInstance: create)
    ..m<$core.String, EngineNames>(1, _omitFieldNames ? '' : 'engines',
        entryClassName: 'ListEnginesResponse.EnginesEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OM,
        valueCreator: EngineNames.create,
        valueDefaultOrMaker: EngineNames.getDefault,
        packageName: const $pb.PackageName('culpeostudio.search.v1'))
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListEnginesResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListEnginesResponse copyWith(void Function(ListEnginesResponse) updates) =>
      super.copyWith((message) => updates(message as ListEnginesResponse))
          as ListEnginesResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListEnginesResponse create() => ListEnginesResponse._();
  @$core.override
  ListEnginesResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListEnginesResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListEnginesResponse>(create);
  static ListEnginesResponse? _defaultInstance;

  /// Engine names per category. Proto maps cannot hold a repeated value
  /// directly, hence the wrapper.
  @$pb.TagNumber(1)
  $pb.PbMap<$core.String, EngineNames> get engines => $_getMap(0);
}

class EngineNames extends $pb.GeneratedMessage {
  factory EngineNames({
    $core.Iterable<$core.String>? names,
  }) {
    final result = create();
    if (names != null) result.names.addAll(names);
    return result;
  }

  EngineNames._();

  factory EngineNames.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory EngineNames.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EngineNames',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.search.v1'),
      createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'names')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EngineNames clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EngineNames copyWith(void Function(EngineNames) updates) =>
      super.copyWith((message) => updates(message as EngineNames))
          as EngineNames;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EngineNames create() => EngineNames._();
  @$core.override
  EngineNames createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static EngineNames getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EngineNames>(create);
  static EngineNames? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get names => $_getList(0);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
