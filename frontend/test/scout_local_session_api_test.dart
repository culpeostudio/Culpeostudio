import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';
import 'package:culpeo_studio/core/api_client.dart';
import 'package:culpeo_studio/core/api_service.dart';
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart';
import 'package:culpeo_studio/generated/culpeostudio/engine/v1/engine.pbgrpc.dart'
    as enginepb;
import 'package:culpeo_studio/generated/culpeostudio/scout/v1/scout.pbgrpc.dart'
    as scoutpb;

import 'engine_service_stub.dart';
import 'scout_service_stub.dart';

class _RecordingScoutService extends ScoutServiceStub {
  scoutpb.CreateSessionRequest? seenCreate;

  @override
  Future<scoutpb.CreateSessionResponse> createSession(
    ServiceCall call,
    scoutpb.CreateSessionRequest request,
  ) async {
    seenCreate = request;
    return scoutpb.CreateSessionResponse(sessionId: 'session-local');
  }
}

class _BusyScoutService extends ScoutServiceStub {
  @override
  Stream<scoutpb.StreamMessageResponse> streamMessage(
    ServiceCall call,
    scoutpb.StreamMessageRequest request,
  ) async* {
    yield scoutpb.StreamMessageResponse(
      error: scoutpb.StreamError(
        message: 'In dieser Sitzung läuft bereits eine Anfrage.',
        code: 'session_busy',
        retryAfter: 1,
      ),
    );
  }
}

class _EnsureReadyEngineService extends EngineServiceStub {
  enginepb.EnsureInstanceReadyRequest? seen;

  @override
  Future<enginepb.EnsureInstanceReadyResponse> ensureInstanceReady(
    ServiceCall call,
    enginepb.EnsureInstanceReadyRequest request,
  ) async {
    seen = request;
    return enginepb.EnsureInstanceReadyResponse(
      operationId: 'warmup-1',
      state: enginepb.OperationState.OPERATION_STATE_QUEUED,
      queuePosition: 2,
      instance: enginepb.EngineInstance(
        id: 'local-1',
        state: enginepb.InstanceState.INSTANCE_STATE_STOPPED,
      ),
    );
  }
}

class _EventStreamEngineService extends EngineServiceStub {
  @override
  Stream<enginepb.StreamEventsResponse> streamEvents(
    ServiceCall call,
    enginepb.StreamEventsRequest request,
  ) async* {
    yield enginepb.StreamEventsResponse(
      timestamp: Timestamp.fromDateTime(DateTime.utc(2026, 7, 13, 10)),
      operation: enginepb.EngineOperation(
        id: 'warmup-1',
        instanceId: 'local-1',
        state: enginepb.OperationState.OPERATION_STATE_RUNNING,
        progress: 0.4,
      ),
    );
  }
}

/// Serves one chat service on a loopback port and points the API at it.
Future<void> serveScout(Service service, ApiService api) async {
  final backend = Server.create(services: [service]);
  await backend.serve(address: '127.0.0.1', port: 0);
  api.client.grpcPort = backend.port!;

  // The suite shortens the deadline so calls with no backend give up at once;
  // here one answers, so give it room.
  ApiClient.callDeadline = requestTimeout;
  addTearDown(() {
    ApiClient.callDeadline = const Duration(milliseconds: 1);
    return backend.shutdown();
  });
}

void main() {
  test('local Scout session sends stable engine instance identity', () async {
    final service = _RecordingScoutService();
    final api = ApiService();
    final previousToken = api.token;
    // The suite shortens the deadline so unanswered calls do not linger; here
    // a backend answers, so give it room.
    ApiClient.callDeadline = requestTimeout;
    addTearDown(() {
      api.token = previousToken;
      ApiClient.callDeadline = const Duration(milliseconds: 1);
    });
    api.token = 'test-token';
    await serveScout(service, api);

    final result = await api.scout.createSession(
      modelRef: 'local:instance-123',
      provider: 'local',
      modelId: 'instance-123',
      instanceId: 'instance-123',
      botId: 'kant-bot',
    );

    expect(result['session_id'], 'session-local');
    final seen = service.seenCreate!;
    expect(seen.modelRef, 'local:instance-123');
    expect(seen.provider, 'local');
    expect(seen.modelId, 'instance-123');
    expect(seen.instanceId, 'instance-123');
    expect(seen.botId, 'kant-bot');
  });

  test('ensure-ready keeps queue and operation identity', () async {
    final service = _EnsureReadyEngineService();
    final api = ApiService();
    final previousToken = api.token;
    addTearDown(() => api.token = previousToken);
    api.token = 'test-token';
    await serveScout(service, api);

    final result = await api.ensureEngineInstanceReady('local-1');

    expect(service.seen?.instanceId, 'local-1');
    expect(result.operationId, 'warmup-1');
    expect(result.status, 'queued');
    expect(result.queuePosition, 2);
    expect(result.instance?.id, 'local-1');
  });

  // The ticket dance is gone: a gRPC stream authenticates itself, so there is
  // no second call to fetch a single-use token first. What still has to hold is
  // that an event keeps its identity and its timestamp on the way through.
  test(
    'engine event stream carries operation identity and timestamp',
    () async {
      final api = ApiService();
      final previousToken = api.token;
      addTearDown(() => api.token = previousToken);
      api.token = 'test-token';
      await serveScout(_EventStreamEngineService(), api);

      final event = await api.streamEngineEvents().first;

      expect(event.type, 'operation');
      expect(event.data['instanceId'], 'local-1');
      // The schema spells its enums out; the client hands the models the
      // spelling they were written against.
      expect(event.data['state'], 'running');
      expect(event.timestamp, DateTime.utc(2026, 7, 13, 10));
    },
  );

  // A busy session is an event on the stream rather than a refused call, so
  // the reason and the wait reach the client the same way a half-written reply
  // failing would. The HTTP status the JSON body carried is gone with the
  // transport that produced it.
  test('Scout stream preserves structured session-busy data', () async {
    final api = ApiService();
    final previousToken = api.token;
    ApiClient.callDeadline = requestTimeout;
    addTearDown(() {
      api.token = previousToken;
      ApiClient.callDeadline = const Duration(milliseconds: 1);
    });
    api.token = 'test-token';
    await serveScout(_BusyScoutService(), api);

    final event = await api.scout.streamMessage('session-1', 'Hallo').first;
    expect(event.type, 'error');
    expect(event.data['code'], 'session_busy');
    expect(event.data['retry_after'], 1);
    expect(event.data['message'], contains('läuft bereits'));
  });
}
