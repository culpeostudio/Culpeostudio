import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';
import 'package:culpeo_studio/core/api_client.dart';
import 'package:culpeo_studio/core/api_service.dart';
import 'package:culpeo_studio/generated/culpeostudio/scout/v1/scout.pbgrpc.dart'
    as scoutpb;

import 'scout_service_stub.dart';

/// A planned Spark run works for minutes, but every client was built with the
/// 60 second budget meant for a single answer: the app hung up mid-step and the
/// backend logged `StreamMessage Canceled 1m0.001s`, so the worklist never got
/// past whatever fit into that minute.
///
/// The catch that made the first fix look right and do nothing: gRPC merges
/// per-call options into the client's as `other.timeout ?? timeout`. Handing a
/// call an option set without a deadline inherits the client's instead of
/// clearing it - the deadline has to be off the client itself.
class _SlowScoutService extends ScoutServiceStub {
  @override
  Stream<scoutpb.StreamMessageResponse> streamMessage(
    ServiceCall call,
    scoutpb.StreamMessageRequest request,
  ) async* {
    // Longer than the deadline a unary call would carry here.
    await Future<void>.delayed(const Duration(milliseconds: 400));
    yield scoutpb.StreamMessageResponse(
      textDelta: scoutpb.TextDelta(chunk: 'spaet, aber da'),
    );
  }
}

void main() {
  test('per-call options cannot clear the deadline, only override it', () {
    final client = ApiClient();

    // Documents the trap: this is what the streaming call used to do.
    expect(
      client.callOptions.mergedWith(client.streamCallOptions).timeout,
      isNotNull,
    );
    expect(client.streamCallOptions.timeout, isNull);
  });

  test('the streaming client is its own, without a deadline', () {
    final client = ApiClient();
    expect(identical(client.scoutClient, client.scoutStreamClient), isFalse);
    expect(identical(client.engineClient, client.engineStreamClient), isFalse);
  });

  test('a reply that outlasts the call budget still arrives', () async {
    final api = ApiService();
    final backend = Server.create(services: [_SlowScoutService()]);
    await backend.serve(address: '127.0.0.1', port: 0);
    api.client.grpcPort = backend.port!;

    // Every unary call gives up long before the service answers. The stream
    // must not: it carries work, not an answer.
    ApiClient.callDeadline = const Duration(milliseconds: 50);
    addTearDown(() {
      ApiClient.callDeadline = const Duration(milliseconds: 1);
      return backend.shutdown();
    });

    final events = await api.scout
        .streamMessage('session-1', 'Plan abarbeiten')
        .toList();

    expect(events, isNotEmpty);
    expect(events.first.type, 'text_delta');
    expect(events.first.data['chunk'], 'spaet, aber da');
    expect(
      events.map((event) => event.type),
      isNot(contains('error')),
      reason: 'a deadline would end the run as an error event',
    );
  });
}
