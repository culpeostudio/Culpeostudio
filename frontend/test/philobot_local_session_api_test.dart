import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:myphilostudio/services/api_service.dart';

void main() {
  test(
    'local PhiloBot session sends stable engine instance identity',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final received = Completer<Map<String, dynamic>>();
      server.listen((request) async {
        expect(request.method, 'POST');
        expect(request.uri.path, '/api/philobot/session');
        final body = jsonDecode(await utf8.decoder.bind(request).join());
        received.complete(Map<String, dynamic>.from(body as Map));
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({'session_id': 'session-local'}));
        await request.response.close();
      });

      final api = ApiService();
      final previousBaseUrl = api.baseUrl;
      final previousToken = api.token;
      addTearDown(() async {
        api.baseUrl = previousBaseUrl;
        api.token = previousToken;
        await server.close(force: true);
      });
      api.baseUrl = 'http://127.0.0.1:${server.port}/api';
      api.token = 'test-token';

      final result = await api.createPhiloBotSession(
        modelRef: 'local:instance-123',
        provider: 'local',
        modelId: 'instance-123',
        instanceId: 'instance-123',
        botId: 'kant-bot',
      );
      final body = await received.future;

      expect(result['session_id'], 'session-local');
      expect(body, {
        'model_ref': 'local:instance-123',
        'provider': 'local',
        'model_id': 'instance-123',
        'instance_id': 'instance-123',
        'bot_id': 'kant-bot',
      });
    },
  );

  test('ensure-ready keeps queue and operation identity', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      expect(request.method, 'POST');
      expect(request.uri.path, '/api/engine/instances/local-1/ensure-ready');
      request.response.statusCode = HttpStatus.accepted;
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode({
          'operation_id': 'warmup-1',
          'status': 'queued',
          'queue_position': 2,
          'instance': {'id': 'local-1', 'state': 'stopped'},
        }),
      );
      await request.response.close();
    });

    final api = ApiService();
    final previousBaseUrl = api.baseUrl;
    final previousToken = api.token;
    addTearDown(() async {
      api.baseUrl = previousBaseUrl;
      api.token = previousToken;
      await server.close(force: true);
    });
    api.baseUrl = 'http://127.0.0.1:${server.port}/api';
    api.token = 'test-token';

    final result = await api.ensureEngineInstanceReady('local-1');
    expect(result.operationId, 'warmup-1');
    expect(result.status, 'queued');
    expect(result.queuePosition, 2);
    expect(result.instance?.id, 'local-1');
  });

  test('engine event stream uses a single-use ticket and parses SSE', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      if (request.uri.path == '/api/engine/events/ticket') {
        expect(request.method, 'POST');
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({'ticket': 'single-use-ticket'}));
      } else if (request.uri.path == '/api/engine/events') {
        expect(request.uri.queryParameters['ticket'], 'single-use-ticket');
        request.response.headers.contentType = ContentType(
          'text',
          'event-stream',
        );
        request.response.write(
          'data: ${jsonEncode({
            'type': 'operation',
            'data': {'id': 'warmup-1', 'instance_id': 'local-1', 'state': 'starting', 'progress': 0.4},
            'timestamp': '2026-07-13T10:00:00Z',
          })}\n\n',
        );
      } else {
        request.response.statusCode = HttpStatus.notFound;
      }
      await request.response.close();
    });

    final api = ApiService();
    final previousBaseUrl = api.baseUrl;
    final previousToken = api.token;
    addTearDown(() async {
      api.baseUrl = previousBaseUrl;
      api.token = previousToken;
      await server.close(force: true);
    });
    api.baseUrl = 'http://127.0.0.1:${server.port}/api';
    api.token = 'test-token';

    final event = await api.streamEngineEvents().first;
    expect(event.type, 'operation');
    expect(event.data['instance_id'], 'local-1');
    expect(event.timestamp, DateTime.utc(2026, 7, 13, 10));
  });

  test('PhiloBot stream preserves structured 429 session-busy data', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      expect(request.method, 'POST');
      expect(request.uri.path, '/api/philobot/stream');
      request.response.statusCode = HttpStatus.tooManyRequests;
      request.response.headers.contentType = ContentType.json;
      request.response.headers.set(HttpHeaders.retryAfterHeader, '1');
      request.response.write(
        jsonEncode({
          'error': 'In dieser Sitzung läuft bereits eine Anfrage.',
          'code': 'session_busy',
        }),
      );
      await request.response.close();
    });

    final api = ApiService();
    final previousBaseUrl = api.baseUrl;
    final previousToken = api.token;
    addTearDown(() async {
      api.baseUrl = previousBaseUrl;
      api.token = previousToken;
      await server.close(force: true);
    });
    api.baseUrl = 'http://127.0.0.1:${server.port}/api';
    api.token = 'test-token';

    final event = await api.streamPhiloBotMessage('session-1', 'Hallo').first;
    expect(event.type, 'error');
    expect(event.data['code'], 'session_busy');
    expect(event.data['status'], HttpStatus.tooManyRequests);
    expect(event.data['retry_after'], 1);
    expect(event.data['message'], contains('läuft bereits'));
  });
}
