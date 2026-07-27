import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:grpc/grpc.dart';
import 'package:http/http.dart' as http;
import '../generated/fillyengine.pbgrpc.dart' as pb;
import '../engine/engine_api.dart';
import '../engine/models.dart';
import '../l10n/remaining_ui_strings.dart';

export '../engine/engine_api.dart' show EngineStreamEvent;

class ApiException extends EngineApiException {
  const ApiException(
    super.message, {
    super.statusCode,
    super.code,
    super.details,
  });
}

class PhiloBotStreamEvent {
  final String type;
  final Map<String, dynamic> data;

  const PhiloBotStreamEvent({required this.type, required this.data});
}

/// Obergrenze fuer eine normale (nicht streamende) Backend-Anfrage.
///
/// Grosszuegig gewaehlt: das Backend begrenzt Provider-Abfragen selbst auf 30s,
/// eine Modellsuche darf also durchaus ein paar Sekunden brauchen. Der Wert
/// soll nur verhindern, dass die Oberflaeche bei einem stummen Backend
/// unbegrenzt wartet — nicht langsame, aber funktionierende Aufrufe abwuergen.
const Duration _requestTimeout = Duration(seconds: 60);

/// HTTP-Client, der jede Anfrage nach [_requestTimeout] abbricht.
///
/// Ohne ihn wartete die Oberflaeche bei einem haengenden Backend endlos, ohne
/// Fehlermeldung und ohne Abbruchmoeglichkeit. Begrenzt wird die Zeit bis zur
/// Antwort (Header); ein bereits laufender Download darf weiterlaufen. Die
/// SSE-Streams nutzen bewusst eigene Clients und bleiben davon unberuehrt —
/// sie sollen ja lange offen bleiben.
class _TimeoutHttpClient extends http.BaseClient {
  _TimeoutHttpClient(this._onUnauthorized, [http.Client? inner])
    : _inner = inner ?? http.Client();

  final http.Client _inner;

  /// Wird gerufen, wenn das Backend eine Anfrage mit 401 ablehnt.
  final void Function() _onUnauthorized;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await _inner.send(request).timeout(_requestTimeout);
    if (response.statusCode == 401) {
      _onUnauthorized();
    }
    return response;
  }
}

class ApiService implements EngineApi {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();
  ApiService.test();

  /// Client mit Timeout fuer alle normalen Anfragen (die SSE-Streams unten
  /// erzeugen bewusst eigene Clients ohne diese Begrenzung).
  ///
  /// `late` ist hier wichtig: dieser Service ist ein Singleton, den Tests auf
  /// Top-Level anlegen. Ein sofort erzeugter http.Client wuerde dort ausserhalb
  /// der Test-Zone landen und das Laden der Testdatei abbrechen.
  late http.Client _http = _TimeoutHttpClient(_handleUnauthorized);

  /// Wird gesetzt, wenn eine gespeicherte Anmeldung vom Backend abgelehnt wird
  /// (z. B. abgelaufen oder mit einem anderen Server-Geheimnis signiert).
  ///
  /// Ohne diese Rueckmeldung sah die Anwendung angemeldet aus, waehrend jede
  /// Anfrage still mit 401 scheiterte — der Nutzer bekam ein leeres Dashboard
  /// zu sehen und musste glauben, seine Daten seien verloren.
  void Function()? onSessionExpired;

  /// Ersetzt den HTTP-Client — ausschliesslich fuer Tests, damit
  /// Server-Antworten ohne echtes Backend nachgestellt werden koennen.
  @visibleForTesting
  void debugSetHttpClient(http.Client client) {
    _http = _TimeoutHttpClient(_handleUnauthorized, client);
  }

  void _handleUnauthorized() {
    // Nur melden, wenn wir uns fuer angemeldet hielten. Ein 401 beim Anmelden
    // selbst ist ein normaler Fehlversuch und kein Sitzungsende.
    if (token == null) return;
    token = null;
    username = null;
    onSessionExpired?.call();
  }

  String baseUrl = 'http://localhost:8080/api';
  String? token;
  String? username;
  ClientChannel? _skillsGrpcChannel;
  pb.SkillsServiceClient? _skillsGrpcClient;
  String? _skillsGrpcEndpointKey;

  Map<String, String> get _headers {
    final headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  pb.SkillsServiceClient get _skillsClient {
    final apiUri = Uri.tryParse(baseUrl);
    final host = (apiUri?.host.isNotEmpty ?? false)
        ? apiUri!.host
        : 'localhost';
    const port = 50051;
    final endpointKey = '$host:$port';
    if (_skillsGrpcClient == null || _skillsGrpcEndpointKey != endpointKey) {
      _skillsGrpcChannel?.shutdown();
      _skillsGrpcChannel = ClientChannel(
        host,
        port: port,
        options: const ChannelOptions(
          credentials: ChannelCredentials.insecure(),
        ),
      );
      _skillsGrpcClient = pb.SkillsServiceClient(_skillsGrpcChannel!);
      _skillsGrpcEndpointKey = endpointKey;
    }
    return _skillsGrpcClient!;
  }

  String _grpcErrorMessage(Object error) {
    if (error is GrpcError) {
      final message = error.message;
      if (message != null && message.trim().isNotEmpty) {
        return message;
      }
      return error.codeName;
    }
    return error.toString();
  }

  // --- Auth ---
  Future<Map<String, dynamic>> getAuthStatus() async {
    try {
      final response = await _http.get(
        Uri.parse('$baseUrl/auth/status'),
        headers: {'Content-Type': 'application/json'},
      );
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> startAuthenticatorSetup() async {
    try {
      final response = await _http.post(
        Uri.parse('$baseUrl/auth/setup/start'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({}),
      );
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> confirmAuthenticatorSetup(
    String code,
    String authenticatorApp,
  ) async {
    try {
      final response = await _http.post(
        Uri.parse('$baseUrl/auth/setup/confirm'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'code': code, 'app': authenticatorApp}),
      );
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> createAccount(
    String user,
    String pass,
    String totpCode,
  ) async {
    try {
      final response = await _http.post(
        Uri.parse('$baseUrl/accounts'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': user,
          'password': pass,
          'totp_code': totpCode,
        }),
      );
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> resetPassword(
    String user,
    String newPassword,
    String totpCode,
  ) async {
    try {
      final response = await _http.post(
        Uri.parse('$baseUrl/password/reset'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': user,
          'new_password': newPassword,
          'totp_code': totpCode,
        }),
      );
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> login(
    String user,
    String pass, {
    required String sessionDuration,
  }) async {
    try {
      final response = await _http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': user,
          'password': pass,
          'session_duration': sessionDuration,
        }),
      );
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        token = data['token'];
        username = data['username'];
      }
      return data;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  void logout() {
    token = null;
    username = null;
  }

  // --- Per-user UI preferences ---
  //
  // These settings deliberately live behind an authenticated endpoint instead
  // of in SharedPreferences: language and frontend variant belong to the
  // account, not to one browser or device.
  Future<Map<String, dynamic>> getUserPreferences() async {
    try {
      final response = await _http.get(
        Uri.parse('$baseUrl/user/preferences'),
        headers: _headers,
      );
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateUserPreferences({
    required String language,
    required String frontendVersion,
  }) async {
    try {
      final response = await _http.put(
        Uri.parse('$baseUrl/user/preferences'),
        headers: _headers,
        body: jsonEncode({
          'language': language,
          'frontend_version': frontendVersion,
        }),
      );
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // --- Engine ---
  Future<Map<String, dynamic>> getEngineStatus() async {
    try {
      final response = await _http.get(
        Uri.parse('$baseUrl/engine/status'),
        headers: _headers,
      );
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> startEngine(String modelPath) async {
    try {
      final response = await _http.post(
        Uri.parse('$baseUrl/engine/start'),
        headers: _headers,
        body: jsonEncode({'model_path': modelPath}),
      );
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> stopEngine() async {
    try {
      final response = await _http.post(
        Uri.parse('$baseUrl/engine/stop'),
        headers: _headers,
      );
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> loadModel(String modelPath) async {
    try {
      final response = await _http.post(
        Uri.parse('$baseUrl/engine/load'),
        headers: _headers,
        body: jsonEncode({'model_path': modelPath}),
      );
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> listModels() async {
    try {
      final response = await _http.get(
        Uri.parse('$baseUrl/engine/models'),
        headers: _headers,
      );
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _engineJsonRequest(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/engine$path');
      late final http.Response response;
      switch (method) {
        case 'GET':
          response = await _http.get(uri, headers: _headers);
        case 'POST':
          response = await _http.post(
            uri,
            headers: _headers,
            body: body == null ? null : jsonEncode(body),
          );
        case 'PATCH':
          response = await _http.patch(
            uri,
            headers: _headers,
            body: jsonEncode(body ?? const <String, dynamic>{}),
          );
        case 'DELETE':
          response = await _http.delete(uri, headers: _headers);
        default:
          throw ApiException(
            remainingUiText('api.unsupportedHttpMethod', {'method': method}),
          );
      }

      dynamic decoded = const <String, dynamic>{};
      if (response.bodyBytes.isNotEmpty) {
        decoded = jsonDecode(utf8.decode(response.bodyBytes));
      }
      final data = decoded is Map
          ? decoded.map((key, value) => MapEntry(key.toString(), value))
          : <String, dynamic>{'data': decoded};
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final rawError = data['error'] ?? data['message'];
        final errorDetails = rawError is Map
            ? rawError.map((key, value) => MapEntry(key.toString(), value))
            : <String, dynamic>{};
        final message = rawError is Map
            ? errorDetails['message'] ??
                  errorDetails['detail'] ??
                  errorDetails.toString()
            : rawError;
        throw ApiException(
          message?.toString().trim().isNotEmpty == true
              ? message.toString()
              : remainingUiText('api.engineRequestFailed', {
                  'statusCode': '${response.statusCode}',
                }),
          statusCode: response.statusCode,
          code: errorDetails['code']?.toString(),
          details: errorDetails,
        );
      }
      return data;
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException(
        remainingUiText('api.engineUnavailable', {'error': '$error'}),
      );
    }
  }

  List<dynamic> _engineList(Map<String, dynamic> json, String key) {
    final value = json[key] ?? json['data'];
    return value is List ? value : const [];
  }

  @override
  Future<List<ModelRecord>> getEngineModels() async {
    final json = await _engineJsonRequest('GET', '/models');
    return _engineList(json, 'models').map(ModelRecord.fromJson).toList();
  }

  @override
  Future<List<ModelRecord>> rescanEngineModels() async {
    final json = await _engineJsonRequest('POST', '/models/rescan');
    return _engineList(json, 'models').map(ModelRecord.fromJson).toList();
  }

  @override
  Future<List<ModelRecord>> deleteEngineModel(String modelId) async {
    final json = await _engineJsonRequest(
      'DELETE',
      '/models/${Uri.encodeComponent(modelId)}',
    );
    return _engineList(json, 'models').map(ModelRecord.fromJson).toList();
  }

  @override
  Future<EngineCapabilities> getEngineCapabilities() async {
    final json = await _engineJsonRequest('GET', '/capabilities');
    return EngineCapabilities.fromJson(json);
  }

  @override
  Future<List<RuntimeCapability>> getEngineRuntimes() async {
    final json = await _engineJsonRequest('GET', '/runtimes');
    return _engineList(
      json,
      'runtimes',
    ).map(RuntimeCapability.fromJson).toList();
  }

  @override
  Future<EngineMutationResult> installEngineRuntime(String runtimeId) async {
    final json = await _engineJsonRequest(
      'POST',
      '/runtimes/${Uri.encodeComponent(runtimeId)}/install',
    );
    return EngineMutationResult.fromJson(json);
  }

  @override
  Future<SystemDependencyConsent> createVulkanDependencyConsent() async {
    final json = await _engineJsonRequest(
      'POST',
      '/system-dependencies/vulkan/consent',
    );
    return SystemDependencyConsent.fromJson(json);
  }

  @override
  Future<EngineMutationResult> installVulkanDependency(
    SystemDependencyConsent consent,
  ) async {
    final json = await _engineJsonRequest(
      'POST',
      '/system-dependencies/vulkan/install',
      body: {
        'consent_token': consent.token,
        'acknowledgement': 'install_vulkan_build_dependencies',
      },
    );
    return EngineMutationResult.fromJson(json);
  }

  @override
  Future<ContextPlan> getEngineRecommendation(
    String modelId, {
    EngineConfig? config,
  }) async {
    final json = await _engineJsonRequest(
      'POST',
      '/models/${Uri.encodeComponent(modelId)}/recommendation',
      body: config?.toJson() ?? const <String, dynamic>{},
    );
    return ContextPlan.fromJson(json['plan'] ?? json['recommendation'] ?? json);
  }

  @override
  Future<RemoteCodeApproval> approveRemoteCode(String modelId) async {
    final json = await _engineJsonRequest(
      'POST',
      '/models/${Uri.encodeComponent(modelId)}/trust-remote-code',
      body: const <String, dynamic>{
        'accepted': true,
        'acknowledgement': 'not_sandboxed',
      },
    );
    return RemoteCodeApproval.fromJson(json);
  }

  @override
  Future<List<EngineInstance>> getEngineInstances() async {
    final json = await _engineJsonRequest('GET', '/instances');
    return _engineList(json, 'instances').map(EngineInstance.fromJson).toList();
  }

  @override
  Future<EngineMutationResult> createEngineInstance({
    required String modelId,
    String? servedModelName,
    required EngineConfig config,
  }) async {
    final body = <String, dynamic>{
      'model_id': modelId,
      if (servedModelName != null && servedModelName.trim().isNotEmpty)
        'served_model_name': servedModelName.trim(),
      ...config.toJson(),
    };
    final json = await _engineJsonRequest('POST', '/instances', body: body);
    return EngineMutationResult.fromJson(json);
  }

  @override
  Future<EngineInstance> getEngineInstance(String instanceId) async {
    final json = await _engineJsonRequest(
      'GET',
      '/instances/${Uri.encodeComponent(instanceId)}',
    );
    return EngineInstance.fromJson(json['instance'] ?? json);
  }

  @override
  Future<EngineEnsureReadyResult> ensureEngineInstanceReady(
    String instanceId,
  ) async {
    final json = await _engineJsonRequest(
      'POST',
      '/instances/${Uri.encodeComponent(instanceId)}/ensure-ready',
    );
    return EngineEnsureReadyResult.fromJson(json);
  }

  Future<String> createEngineEventTicket() async {
    final json = await _engineJsonRequest('POST', '/events/ticket');
    final ticket = json['ticket']?.toString().trim() ?? '';
    if (ticket.isEmpty) {
      throw ApiException(remainingUiText('api.eventTicketMissing'));
    }
    return ticket;
  }

  @override
  Stream<EngineStreamEvent> streamEngineEvents() async* {
    final ticket = await createEngineEventTicket();
    final client = http.Client();
    final request = http.Request(
      'GET',
      Uri.parse(
        '$baseUrl/engine/events?ticket=${Uri.encodeQueryComponent(ticket)}',
      ),
    );
    try {
      final response = await client.send(request);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = await response.stream.bytesToString();
        throw ApiException(
          message.trim().isEmpty
              ? remainingUiText('api.eventStreamOpenFailed')
              : message.trim(),
          statusCode: response.statusCode,
        );
      }
      await for (final raw in _decodeSseDataEvents(response.stream)) {
        if (raw.isEmpty || raw == '[DONE]') continue;
        final decoded = jsonDecode(raw);
        if (decoded is! Map) continue;
        final envelope = Map<String, dynamic>.from(decoded);
        final rawData = envelope['data'];
        yield EngineStreamEvent(
          type: envelope['type']?.toString() ?? '',
          data: rawData is Map
              ? Map<String, dynamic>.from(rawData)
              : const <String, dynamic>{},
          timestamp: DateTime.tryParse(envelope['timestamp']?.toString() ?? ''),
        );
      }
    } finally {
      client.close();
    }
  }

  @override
  Future<EngineMutationResult> updateEngineInstance(
    String instanceId,
    Map<String, dynamic> changes,
  ) async {
    final json = await _engineJsonRequest(
      'PATCH',
      '/instances/${Uri.encodeComponent(instanceId)}',
      body: changes,
    );
    return EngineMutationResult.fromJson(json);
  }

  @override
  Future<EngineMutationResult> deleteEngineInstance(String instanceId) async {
    final json = await _engineJsonRequest(
      'DELETE',
      '/instances/${Uri.encodeComponent(instanceId)}',
    );
    return EngineMutationResult.fromJson(json);
  }

  @override
  Future<EngineOperation> getEngineOperation(String operationId) async {
    final json = await _engineJsonRequest(
      'GET',
      '/operations/${Uri.encodeComponent(operationId)}',
    );
    return EngineOperation.fromJson(json['operation'] ?? json);
  }

  @override
  Future<EngineOperation> cancelEngineOperation(String operationId) async {
    final json = await _engineJsonRequest(
      'POST',
      '/operations/${Uri.encodeComponent(operationId)}/cancel',
    );
    return EngineOperation.fromJson(json['operation'] ?? json);
  }

  // --- PhiloBot ---
  Future<Map<String, dynamic>> createPhiloBotSession({
    String? modelRef,
    String? provider,
    String? modelId,
    String? instanceId,
    String? thinkingLevel,
    String? responseStyle,
    String? botId,
    String? projectId,
  }) async {
    try {
      final body = <String, String>{};
      if (modelRef != null && modelRef.trim().isNotEmpty) {
        body['model_ref'] = modelRef.trim();
      }
      if (provider != null && provider.trim().isNotEmpty) {
        body['provider'] = provider.trim();
      }
      if (modelId != null && modelId.trim().isNotEmpty) {
        body['model_id'] = modelId.trim();
      }
      if (instanceId != null && instanceId.trim().isNotEmpty) {
        body['instance_id'] = instanceId.trim();
      }
      if (thinkingLevel != null && thinkingLevel.trim().isNotEmpty) {
        body['thinking_level'] = thinkingLevel.trim();
      }
      if (responseStyle != null && responseStyle.trim().isNotEmpty) {
        body['response_style'] = responseStyle.trim();
      }
      if (botId != null && botId.trim().isNotEmpty) {
        body['bot_id'] = botId.trim();
      }
      if (projectId != null && projectId.trim().isNotEmpty) {
        body['project_id'] = projectId.trim();
      }
      final response = await _http.post(
        Uri.parse('$baseUrl/philobot/session'),
        headers: _headers,
        body: jsonEncode(body),
      );
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Wechselt das Modell einer bestehenden Session (Verlauf bleibt erhalten).
  /// Bei lokalen Modellen wird die instance_id als model_id gesendet.
  Future<Map<String, dynamic>> setPhiloBotSessionModel(
    String sessionId, {
    required String provider,
    required String modelId,
    String? modelRef,
    String? displayName,
  }) async {
    try {
      final response = await _http.post(
        Uri.parse('$baseUrl/philobot/session/$sessionId/model'),
        headers: _headers,
        body: jsonEncode({
          'provider': provider,
          'model_id': modelId,
          'model_ref': modelRef ?? '',
          'display_name': displayName ?? '',
        }),
      );
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> sendPhiloBotMessage(
    String sessionId,
    String message, {
    String? thinkingLevel,
    String? responseStyle,
    int? editMessageIndex,
  }) async {
    try {
      final body = <String, dynamic>{
        'session_id': sessionId,
        'message': message,
      };
      if (thinkingLevel != null && thinkingLevel.trim().isNotEmpty) {
        body['thinking_level'] = thinkingLevel.trim();
      }
      if (responseStyle != null && responseStyle.trim().isNotEmpty) {
        body['response_style'] = responseStyle.trim();
      }
      if (editMessageIndex != null) {
        body['edit_message_index'] = editMessageIndex;
      }
      final response = await _http.post(
        Uri.parse('$baseUrl/philobot/message'),
        headers: _headers,
        body: jsonEncode(body),
      );
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getPhiloBotHistory(String sessionId) async {
    try {
      final response = await _http.get(
        Uri.parse('$baseUrl/philobot/history/$sessionId'),
        headers: _headers,
      );
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Stream<PhiloBotStreamEvent> streamPhiloBotMessage(
    String sessionId,
    String message, {
    String? thinkingLevel,
    String? responseStyle,
    int? editMessageIndex,
    String? mode,
    List<String>? allowedRoots,
    bool? approvePlan,
    bool? planning,
  }) async* {
    final client = http.Client();
    final request = http.Request('POST', Uri.parse('$baseUrl/philobot/stream'));
    request.headers.addAll(_headers);
    final body = <String, dynamic>{'session_id': sessionId, 'message': message};
    if (thinkingLevel != null && thinkingLevel.trim().isNotEmpty) {
      body['thinking_level'] = thinkingLevel.trim();
    }
    if (responseStyle != null && responseStyle.trim().isNotEmpty) {
      body['response_style'] = responseStyle.trim();
    }
    if (editMessageIndex != null) {
      body['edit_message_index'] = editMessageIndex;
    }
    if (mode != null && mode.trim().isNotEmpty) {
      body['mode'] = mode.trim();
    }
    if (allowedRoots != null) {
      body['allowed_roots'] = allowedRoots;
    }
    if (approvePlan != null) {
      body['approve_plan'] = approvePlan;
    }
    if (planning != null) {
      body['planning'] = planning;
    }
    request.body = jsonEncode(body);

    try {
      final response = await client.send(request);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final responseBody = await response.stream.bytesToString();
        final data = <String, dynamic>{
          'message': responseBody.trim().isEmpty
              ? remainingUiText('api.streamFailed')
              : responseBody,
          'status': response.statusCode,
        };
        try {
          final decoded = jsonDecode(responseBody);
          if (decoded is Map) {
            final error = decoded['error']?.toString().trim();
            final message = decoded['message']?.toString().trim();
            if (error?.isNotEmpty == true) {
              data['message'] = error;
            } else if (message?.isNotEmpty == true) {
              data['message'] = message;
            }
            final code = decoded['code']?.toString().trim();
            if (code?.isNotEmpty == true) data['code'] = code;
          }
        } catch (_) {
          // Preserve the raw body for non-JSON upstream failures.
        }
        final retryAfter = response.headers['retry-after'];
        if (retryAfter?.isNotEmpty == true) {
          data['retry_after'] = int.tryParse(retryAfter!) ?? retryAfter;
        }
        yield PhiloBotStreamEvent(type: 'error', data: data);
        return;
      }

      await for (final raw in _decodeSseDataEvents(response.stream)) {
        if (raw.isEmpty || raw == '[DONE]') {
          continue;
        }
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map<String, dynamic>) {
            final type = decoded['type']?.toString() ?? '';
            final data = decoded['data'];
            yield PhiloBotStreamEvent(
              type: type,
              data: data is Map<String, dynamic> ? data : <String, dynamic>{},
            );
          }
        } catch (_) {
          yield PhiloBotStreamEvent(
            type: 'error',
            data: {'message': remainingUiText('api.streamDataUnreadable')},
          );
        }
      }
    } finally {
      client.close();
    }
  }

  // --- Bots Management ---
  Future<Map<String, dynamic>> getPhiloBots() async {
    try {
      final response = await _http.get(
        Uri.parse('$baseUrl/philobot/bots'),
        headers: _headers,
      );
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> savePhiloBot(Map<String, dynamic> bot) async {
    try {
      final response = await _http.post(
        Uri.parse('$baseUrl/philobot/bots'),
        headers: _headers,
        body: jsonEncode(bot),
      );
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deletePhiloBot(String id) async {
    try {
      final response = await _http.delete(
        Uri.parse('$baseUrl/philobot/bots/$id'),
        headers: _headers,
      );
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Lists the user's persisted PhiloBot chat history so past conversations can
  /// be restored after an app restart.
  Future<Map<String, dynamic>> listPhiloBotSessions() async {
    try {
      final response = await _http.get(
        Uri.parse('$baseUrl/philobot/sessions'),
        headers: _headers,
      );
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deletePhiloBotSession(String sessionId) async {
    try {
      final response = await _http.delete(
        Uri.parse('$baseUrl/philobot/session/$sessionId'),
        headers: _headers,
      );
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> renamePhiloBotSession(
    String sessionId,
    String title,
  ) async {
    try {
      final response = await _http.post(
        Uri.parse('$baseUrl/philobot/session/$sessionId/rename'),
        headers: _headers,
        body: jsonEncode({'title': title}),
      );
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // --- PhiloBot Projekte (Ordner zum Buendeln von Chats) ---
  Future<Map<String, dynamic>> listPhiloBotProjects() async {
    try {
      final response = await _http.get(
        Uri.parse('$baseUrl/philobot/projects'),
        headers: _headers,
      );
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> createPhiloBotProject(
    String name, {
    String? color,
    String? path,
    String? icon,
  }) async {
    try {
      final body = <String, String>{'name': name};
      if (color != null && color.trim().isNotEmpty) {
        body['color'] = color.trim();
      }
      if (path != null && path.trim().isNotEmpty) {
        body['path'] = path.trim();
      }
      if (icon != null && icon.trim().isNotEmpty) {
        body['icon'] = icon.trim();
      }
      final response = await _http.post(
        Uri.parse('$baseUrl/philobot/project'),
        headers: _headers,
        body: jsonEncode(body),
      );
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> renamePhiloBotProject(
    String projectId,
    String name, {
    String? color,
    String? path,
    String? icon,
  }) async {
    try {
      final body = <String, String>{'name': name};
      if (color != null && color.trim().isNotEmpty) {
        body['color'] = color.trim();
      }
      // Wird immer mitgeschickt (auch leer): erlaubt das gezielte Loeschen
      // des Pfads ueber die Checkbox im Bearbeiten-Dialog.
      body['path'] = path?.trim() ?? '';
      // Icon analog: leer = Standard-Icon; null (alter Aufrufer) = Key
      // weglassen, damit das bestehende Icon nicht geloescht wird.
      if (icon != null) {
        body['icon'] = icon.trim();
      }
      final response = await _http.post(
        Uri.parse('$baseUrl/philobot/project/$projectId/rename'),
        headers: _headers,
        body: jsonEncode(body),
      );
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deletePhiloBotProject(String projectId) async {
    try {
      final response = await _http.delete(
        Uri.parse('$baseUrl/philobot/project/$projectId'),
        headers: _headers,
      );
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> setPhiloBotSessionProject(
    String sessionId,
    String? projectId,
  ) async {
    try {
      final response = await _http.post(
        Uri.parse('$baseUrl/philobot/session/$sessionId/project'),
        headers: _headers,
        body: jsonEncode({'project_id': projectId ?? ''}),
      );
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Laedt den Dateibaum des Projekt-Pfads einer Session (tiefen- und
  /// eintragsbegrenzt). Liefert {root, tree, truncated} oder {error}.
  Future<Map<String, dynamic>> getPhiloBotSessionTree(String sessionId) async {
    try {
      final response = await _http.get(
        Uri.parse('$baseUrl/philobot/session/$sessionId/tree'),
        headers: _headers,
      );
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Beantwortet eine Permission-Anfrage aus dem laufenden Chat-Stream: darf
  /// der Agent auf einen Pfad ausserhalb des Projektpfads zugreifen?
  /// [decision]: "once" (einmalig), "session" (Ordner fuer diese Sitzung
  /// freigeben) oder "deny" (ablehnen).
  Future<bool> respondPhiloBotPermission({
    required String sessionId,
    required String requestId,
    required String decision,
  }) async {
    try {
      final response = await _http.post(
        Uri.parse('$baseUrl/philobot/permission'),
        headers: _headers,
        body: jsonEncode({
          'session_id': sessionId,
          'request_id': requestId,
          'decision': decision,
        }),
      );
      final result =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return result['ok'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> searchMarketplace({
    String? provider,
    String? query,
    String? format,
    String? quantization,
    String? category,
    String? sort,
    bool? gpuFit,
    bool? localOnly,
    int? page,
    int? limit,
  }) async {
    try {
      final params = <String, String>{};
      if (provider != null) {
        params['provider'] = provider;
      }
      if (query != null) {
        params['q'] = query;
      }
      if (format != null) {
        params['format'] = format;
      }
      if (quantization != null) {
        params['quantization'] = quantization;
      }
      if (category != null) {
        params['category'] = category;
      }
      if (sort != null) {
        params['sort'] = sort;
      }
      if (gpuFit != null) {
        params['gpu_fit'] = gpuFit.toString();
      }
      if (localOnly != null) {
        params['local_only'] = localOnly.toString();
      }
      if (page != null) {
        params['page'] = page.toString();
      }
      if (limit != null) {
        params['limit'] = limit.toString();
      }

      final uri = Uri.parse(
        '$baseUrl/marktplatz/search',
      ).replace(queryParameters: params);
      final response = await _http.get(uri, headers: _headers);
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getMarketplaceModelDetail(
    String id,
    String provider,
  ) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/marktplatz/model',
      ).replace(queryParameters: {'provider': provider, 'id': id});
      final response = await _http.get(uri, headers: _headers);
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getHardwareProfile() async {
    try {
      final response = await _http.get(
        Uri.parse('$baseUrl/marktplatz/hardware/profile'),
        headers: _headers,
      );
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> downloadModel(
    String provider,
    String modelId,
    String assetId,
    String targetDir, {
    List<String> assetIds = const [],
    int sizeBytes = 0,
  }) async {
    try {
      final payload = <String, dynamic>{
        'provider': provider,
        'model_id': modelId,
        'asset_id': assetId,
        'target_dir': targetDir,
      };
      // M14: Disk-Pre-Check – wenn der Client size_bytes mitgibt
      // ( aus download_options der angewaehlten Variante ), wird der
      // Backend frueh genug ablehnen, statt erst nach langem Download in
      // "failed" zu enden.
      if (sizeBytes > 0) {
        payload['size_bytes'] = sizeBytes;
      }
      if (assetIds.isNotEmpty) {
        payload['asset_ids'] = assetIds;
      }
      final response = await _http.post(
        Uri.parse('$baseUrl/marktplatz/download'),
        headers: _headers,
        body: jsonEncode(payload),
      );
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> listDownloadJobs() async {
    try {
      final response = await _http.get(
        Uri.parse('$baseUrl/marktplatz/jobs'),
        headers: _headers,
      );
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getDownloadJobStatus(String id) async {
    try {
      final response = await _http.get(
        Uri.parse('$baseUrl/marktplatz/job/$id'),
        headers: _headers,
      );
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteDownloadJob(String id) async {
    try {
      final response = await _http.delete(
        Uri.parse('$baseUrl/marktplatz/job/$id'),
        headers: _headers,
      );
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> startAPIModelForChat(
    String provider,
    String modelId,
    String displayName,
  ) async {
    try {
      final response = await _http.post(
        Uri.parse('$baseUrl/marktplatz/api-models/start'),
        headers: _headers,
        body: jsonEncode({
          'provider': provider,
          'model_id': modelId,
          'display_name': displayName,
        }),
      );
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> listActiveAPIModels() async {
    try {
      final response = await _http.get(
        Uri.parse('$baseUrl/marktplatz/api-models/active'),
        headers: _headers,
      );
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteActiveAPIModel(String modelRef) async {
    try {
      final response = await _http.delete(
        Uri.parse('$baseUrl/marktplatz/api-models/$modelRef'),
        headers: _headers,
      );
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // --- Settings ---
  Future<Map<String, dynamic>> getSettings() async {
    try {
      final response = await _http.get(
        Uri.parse('$baseUrl/settings'),
        headers: _headers,
      );
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateSettings({
    String? modelDir,
    String? huggingfaceToken,
    String? openrouterToken,
    String? featherlessToken,
    Map<String, String>? shortcuts,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (modelDir != null) {
        body['model_dir'] = modelDir;
      }
      if (huggingfaceToken != null) {
        body['huggingface_token'] = huggingfaceToken;
      }
      if (openrouterToken != null) {
        body['openrouter_token'] = openrouterToken;
      }
      if (featherlessToken != null) {
        body['featherless_token'] = featherlessToken;
      }
      if (shortcuts != null) {
        body['shortcuts'] = shortcuts;
      }

      final response = await _http.put(
        Uri.parse('$baseUrl/settings'),
        headers: _headers,
        body: jsonEncode(body),
      );
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getSystemInfo() async {
    try {
      final response = await _http.get(
        Uri.parse('$baseUrl/settings/system'),
        headers: _headers,
      );
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> testProviderConnection(String provider) async {
    try {
      final response = await _http.get(
        Uri.parse('$baseUrl/settings/test-provider/$provider'),
        headers: _headers,
      );
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // --- Skills ---
  Future<Map<String, dynamic>> listSkills() async {
    try {
      final response = await _skillsClient.listSkills(pb.Empty());
      return _skillListToMap(response);
    } catch (e) {
      return {'error': _grpcErrorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> importSkill(
    String sourcePath, {
    bool enabled = true,
  }) async {
    try {
      final response = await _skillsClient.importSkill(
        pb.ImportSkillRequest(sourcePath: sourcePath, enabled: enabled),
      );
      return _skillResponseToMap(response);
    } catch (e) {
      return {'error': _grpcErrorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> updateSkill(
    String name, {
    required bool enabled,
  }) async {
    try {
      final response = await _skillsClient.updateSkill(
        pb.UpdateSkillRequest(name: name, enabled: enabled),
      );
      return _skillResponseToMap(response);
    } catch (e) {
      return {'error': _grpcErrorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> deleteSkill(String name) async {
    try {
      final response = await _skillsClient.deleteSkill(
        pb.DeleteSkillRequest(name: name),
      );
      return {
        'name': response.name,
        'status': response.status,
        'message': response.message,
      };
    } catch (e) {
      return {'error': _grpcErrorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> rescanSkills() async {
    try {
      final response = await _skillsClient.rescanSkills(pb.Empty());
      return _skillListToMap(response);
    } catch (e) {
      return {'error': _grpcErrorMessage(e)};
    }
  }

  Map<String, dynamic> _skillListToMap(pb.SkillListResponse response) {
    return {
      'skills': response.skills.map(_skillRecordToMap).toList(),
      'count': response.count,
    };
  }

  Map<String, dynamic> _skillResponseToMap(pb.SkillResponse response) {
    return {
      'skill': _skillRecordToMap(response.skill),
      'message': response.message,
    };
  }

  Map<String, dynamic> _skillRecordToMap(pb.SkillRecord skill) {
    final summary = skill.hasFileSummary()
        ? skill.fileSummary
        : pb.SkillFileSummary();
    return {
      'name': skill.name,
      'description': skill.description,
      'enabled': skill.enabled,
      'path': skill.path,
      'imported_at_unix': skill.importedAtUnix.toInt(),
      'updated_at_unix': skill.updatedAtUnix.toInt(),
      'license': skill.license,
      'compatibility': skill.compatibility,
      'metadata_json': skill.metadataJson,
      'allowed_tools': skill.allowedTools,
      'valid': skill.valid,
      'errors': skill.errors.toList(),
      'file_summary': {
        'file_count': summary.fileCount,
        'directory_count': summary.directoryCount,
        'has_scripts': summary.hasScripts,
        'has_references': summary.hasReferences,
        'has_assets': summary.hasAssets,
      },
    };
  }

  // --- News ---
  Future<List<dynamic>> getNews() async {
    try {
      final response = await _http.get(
        Uri.parse('$baseUrl/news'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is List<dynamic>) {
          return decoded;
        }
        throw ApiException(remainingUiText('api.newsUnexpectedResponse'));
      }
      throw ApiException(
        remainingUiText('api.newsLoadHttpFailed', {
          'statusCode': '${response.statusCode}',
        }),
      );
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        remainingUiText('api.newsLoadFailed', {'error': '$e'}),
      );
    }
  }
}

Stream<String> _decodeSseDataEvents(Stream<List<int>> source) async* {
  final pendingLineBytes = <int>[];
  final currentEventData = <String>[];

  await for (final chunk in source) {
    pendingLineBytes.addAll(chunk);

    while (true) {
      final newlineIndex = pendingLineBytes.indexOf(10);
      if (newlineIndex < 0) {
        break;
      }

      final lineBytes = pendingLineBytes.sublist(0, newlineIndex);
      pendingLineBytes.removeRange(0, newlineIndex + 1);
      final eventPayload = _consumeSseLine(lineBytes, currentEventData);
      if (eventPayload != null) {
        yield eventPayload;
      }
    }
  }

  if (pendingLineBytes.isNotEmpty) {
    final eventPayload = _consumeSseLine(pendingLineBytes, currentEventData);
    pendingLineBytes.clear();
    if (eventPayload != null) {
      yield eventPayload;
    }
  }

  if (currentEventData.isNotEmpty) {
    final payload = currentEventData.join('\n').trim();
    currentEventData.clear();
    if (payload.isNotEmpty) {
      yield payload;
    }
  }
}

String? _consumeSseLine(List<int> rawLineBytes, List<String> currentEventData) {
  var lineBytes = rawLineBytes;
  if (lineBytes.isNotEmpty && lineBytes.last == 13) {
    lineBytes = lineBytes.sublist(0, lineBytes.length - 1);
  }

  if (_isAsciiWhitespaceOnly(lineBytes)) {
    if (currentEventData.isEmpty) {
      return null;
    }
    final payload = currentEventData.join('\n').trim();
    currentEventData.clear();
    return payload.isEmpty ? null : payload;
  }

  final trimmedLeft = _trimAsciiLeft(lineBytes);
  if (trimmedLeft.isEmpty || trimmedLeft.first == 58) {
    return null;
  }
  if (_startsWithAscii(trimmedLeft, 'event:')) {
    return null;
  }
  if (!_startsWithAscii(trimmedLeft, 'data:')) {
    return null;
  }

  final dataBytes = _trimAscii(trimmedLeft.sublist(5));
  if (dataBytes.isNotEmpty) {
    currentEventData.add(utf8.decode(dataBytes));
  }
  return null;
}

bool _startsWithAscii(List<int> value, String prefix) {
  final prefixBytes = ascii.encode(prefix);
  if (value.length < prefixBytes.length) {
    return false;
  }
  for (var i = 0; i < prefixBytes.length; i++) {
    if (value[i] != prefixBytes[i]) {
      return false;
    }
  }
  return true;
}

bool _isAsciiWhitespaceOnly(List<int> value) {
  for (final byte in value) {
    if (byte != 9 && byte != 32) {
      return false;
    }
  }
  return true;
}

List<int> _trimAsciiLeft(List<int> value) {
  var start = 0;
  while (start < value.length && (value[start] == 9 || value[start] == 32)) {
    start++;
  }
  return value.sublist(start);
}

List<int> _trimAscii(List<int> value) {
  var start = 0;
  var end = value.length;
  while (start < end && (value[start] == 9 || value[start] == 32)) {
    start++;
  }
  while (end > start && (value[end - 1] == 9 || value[end - 1] == 32)) {
    end--;
  }
  return value.sublist(start, end);
}
