import 'package:flutter/foundation.dart';
import 'package:grpc/grpc.dart';

import '../generated/culpeostudio/benchmark/v1/benchmark.pbgrpc.dart'
    as benchpb;
import '../generated/culpeostudio/engine/v1/engine.pbgrpc.dart' as enginepb;
import '../generated/culpeostudio/login/v1/login.pbgrpc.dart' as loginpb;
import '../generated/culpeostudio/marketplace/v1/marketplace.pbgrpc.dart'
    as marketpb;
import '../generated/culpeostudio/news/v1/news.pbgrpc.dart' as newspb;
import '../generated/culpeostudio/node/v1/node.pbgrpc.dart' as nodepb;
import '../generated/culpeostudio/scout/v1/scout.pbgrpc.dart' as scoutpb;
import '../generated/culpeostudio/settings/v1/settings.pbgrpc.dart'
    as settingspb;
import '../generated/culpeostudio/skills/v1/skills.pbgrpc.dart' as pb;
import '../generated/culpeostudio/spark/v1/spark.pbgrpc.dart' as sparkpb;
import '../modules/engine/engine_api.dart';

class ApiException extends EngineApiException {
  const ApiException(
    super.message, {
    super.statusCode,
    super.code,
    super.details,
  });
}

class ScoutStreamEvent {
  final String type;
  final Map<String, dynamic> data;

  const ScoutStreamEvent({required this.type, required this.data});
}

/// Budget for a single backend call. Widget tests need it to drain the pending
/// timeout timer of an in-flight call before they finish.
const Duration requestTimeout = Duration(seconds: 60);

/// Everything the module APIs share: the backend address, the session token and
/// the gRPC connection.
class ApiClient {
  String baseUrl = 'http://localhost:8080/api';
  int grpcPort = 50051;
  String? token;
  String? username;
  void Function()? onSessionExpired;

  ClientChannel? _channel;
  String? _channelEndpoint;
  pb.SkillsServiceClient? _skillsClient;
  settingspb.SettingsServiceClient? _settingsClient;
  loginpb.LoginServiceClient? _loginClient;
  enginepb.EngineServiceClient? _engineClient;
  newspb.NewsServiceClient? _newsClient;
  nodepb.NodeServiceClient? _nodeClient;
  sparkpb.SparkServiceClient? _sparkClient;
  marketpb.MarketplaceServiceClient? _marketplaceClient;
  benchpb.BenchmarkServiceClient? _benchmarkClient;
  scoutpb.ScoutServiceClient? _scoutClient;

  void handleUnauthorized() {
    if (token == null) return;
    token = null;
    username = null;
    onSessionExpired?.call();
  }

  /// Host the gRPC channel dials, taken from [baseUrl] so both point at the
  /// same backend.
  String get _grpcHost {
    final host = Uri.tryParse(baseUrl)?.host ?? '';
    return host.isEmpty ? 'localhost' : host;
  }

  /// The channel shared by every service client. It is rebuilt when the backend
  /// address changes, which invalidates the clients cached on top of it.
  ClientChannel get channel {
    final endpoint = '$_grpcHost:$grpcPort';
    if (_channel == null || _channelEndpoint != endpoint) {
      _channel?.shutdown();
      _channel = ClientChannel(
        _grpcHost,
        port: grpcPort,
        options: const ChannelOptions(
          credentials: ChannelCredentials.insecure(),
        ),
      );
      _channelEndpoint = endpoint;
      _skillsClient = null;
      _settingsClient = null;
      _loginClient = null;
      _engineClient = null;
      _newsClient = null;
      _nodeClient = null;
      _sparkClient = null;
      _marketplaceClient = null;
      _benchmarkClient = null;
      _scoutClient = null;
    }
    return _channel!;
  }

  /// Deadline for a single call. Widget tests shorten it in
  /// test/flutter_test_config.dart so the calls a screen fires while mounting
  /// give up at once instead of leaving a pending timer behind - the HTTP
  /// client used to fail just as quickly with "connection refused".
  @visibleForTesting
  static Duration callDeadline = requestTimeout;

  /// Options every service client is built with: they attach the session token
  /// as request metadata and give a call the same budget the HTTP client had.
  CallOptions get callOptions =>
      CallOptions(providers: [_attachAuthorization], timeout: callDeadline);

  Future<void> _attachAuthorization(
    Map<String, String> metadata,
    String uri,
  ) async {
    final current = token;
    if (current != null) {
      metadata['authorization'] = 'Bearer $current';
    }
  }

  /// Ends the session when the backend rejected the token. Unary calls report
  /// this through [_SessionInterceptor]; streaming APIs call it from their own
  /// error path, because a response stream cannot be observed without
  /// consuming it.
  void reportGrpcError(Object error) {
    if (error is GrpcError && error.code == StatusCode.unauthenticated) {
      handleUnauthorized();
    }
  }

  pb.SkillsServiceClient get skillsClient {
    final activeChannel = channel;
    return _skillsClient ??= pb.SkillsServiceClient(
      activeChannel,
      options: callOptions,
      interceptors: [_SessionInterceptor(reportGrpcError)],
    );
  }

  enginepb.EngineServiceClient get engineClient {
    final activeChannel = channel;
    return _engineClient ??= enginepb.EngineServiceClient(
      activeChannel,
      options: callOptions,
      interceptors: [_SessionInterceptor(reportGrpcError)],
    );
  }

  loginpb.LoginServiceClient get loginClient {
    final activeChannel = channel;
    return _loginClient ??= loginpb.LoginServiceClient(
      activeChannel,
      options: callOptions,
      interceptors: [_SessionInterceptor(reportGrpcError)],
    );
  }

  newspb.NewsServiceClient get newsClient {
    final activeChannel = channel;
    return _newsClient ??= newspb.NewsServiceClient(
      activeChannel,
      options: callOptions,
      interceptors: [_SessionInterceptor(reportGrpcError)],
    );
  }

  nodepb.NodeServiceClient get nodeClient {
    final activeChannel = channel;
    return _nodeClient ??= nodepb.NodeServiceClient(
      activeChannel,
      options: callOptions,
      interceptors: [_SessionInterceptor(reportGrpcError)],
    );
  }

  sparkpb.SparkServiceClient get sparkClient {
    final activeChannel = channel;
    return _sparkClient ??= sparkpb.SparkServiceClient(
      activeChannel,
      options: callOptions,
      interceptors: [_SessionInterceptor(reportGrpcError)],
    );
  }

  scoutpb.ScoutServiceClient get scoutClient {
    final activeChannel = channel;
    return _scoutClient ??= scoutpb.ScoutServiceClient(
      activeChannel,
      options: callOptions,
      interceptors: [_SessionInterceptor(reportGrpcError)],
    );
  }

  benchpb.BenchmarkServiceClient get benchmarkClient {
    final activeChannel = channel;
    return _benchmarkClient ??= benchpb.BenchmarkServiceClient(
      activeChannel,
      options: callOptions,
      interceptors: [_SessionInterceptor(reportGrpcError)],
    );
  }

  marketpb.MarketplaceServiceClient get marketplaceClient {
    final activeChannel = channel;
    return _marketplaceClient ??= marketpb.MarketplaceServiceClient(
      activeChannel,
      options: callOptions,
      interceptors: [_SessionInterceptor(reportGrpcError)],
    );
  }

  settingspb.SettingsServiceClient get settingsClient {
    final activeChannel = channel;
    return _settingsClient ??= settingspb.SettingsServiceClient(
      activeChannel,
      options: callOptions,
      interceptors: [_SessionInterceptor(reportGrpcError)],
    );
  }

  String grpcErrorMessage(Object error) {
    if (error is GrpcError) {
      final message = error.message;
      if (message != null && message.trim().isNotEmpty) {
        return message;
      }
      return error.codeName;
    }
    return error.toString();
  }
}

/// Reports a rejected session token on unary calls. UNAUTHENTICATED is the gRPC
/// counterpart of the HTTP 401 the client used to watch for.
class _SessionInterceptor implements ClientInterceptor {
  const _SessionInterceptor(this._report);

  final void Function(Object error) _report;

  @override
  ResponseFuture<R> interceptUnary<Q, R>(
    ClientMethod<Q, R> method,
    Q request,
    CallOptions options,
    ClientUnaryInvoker<Q, R> invoker,
  ) {
    final response = invoker(method, request, options);
    // Observe the failure without swallowing it: this derived future handles
    // the error so nothing is reported as unhandled, while `response` still
    // delivers it to the caller.
    response.then<void>((_) {}, onError: _report);
    return response;
  }

  @override
  ResponseStream<R> interceptStreaming<Q, R>(
    ClientMethod<Q, R> method,
    Stream<Q> requests,
    CallOptions options,
    ClientStreamingInvoker<Q, R> invoker,
  ) {
    // A ResponseStream has a single subscriber, so listening here would steal
    // the events from the caller. Streaming APIs report through
    // ApiClient.reportGrpcError instead.
    return invoker(method, requests, options);
  }
}
