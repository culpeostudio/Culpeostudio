import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';
import 'package:culpeo_studio/core/api_client.dart';
import 'package:culpeo_studio/core/api_service.dart';
import 'package:culpeo_studio/generated/culpeostudio/scout/v1/scout.pbgrpc.dart'
    as scoutpb;

import 'scout_service_stub.dart';

/// UNAUTHENTICATED is what the backend answers with once a token no longer
/// belongs to an account - the gRPC counterpart of the 401 this used to check.
class _RejectingService extends ScoutServiceStub {
  @override
  Future<scoutpb.ListBotsResponse> listBots(
    ServiceCall call,
    scoutpb.ListBotsRequest request,
  ) async {
    throw GrpcError.unauthenticated('Ungueltiger Token');
  }
}

class _AnsweringService extends ScoutServiceStub {
  @override
  Future<scoutpb.ListBotsResponse> listBots(
    ServiceCall call,
    scoutpb.ListBotsRequest request,
  ) async => scoutpb.ListBotsResponse();
}

Future<ApiService> apiFor(Service service) async {
  final backend = Server.create(services: [service]);
  await backend.serve(address: '127.0.0.1', port: 0);
  addTearDown(() async => backend.shutdown());

  // The suite shortens the deadline so unanswered calls do not linger; here a
  // backend answers, so give it room.
  ApiClient.callDeadline = requestTimeout;
  addTearDown(() => ApiClient.callDeadline = const Duration(milliseconds: 1));

  final api = ApiService.test();
  api.client.grpcPort = backend.port!;
  return api;
}

void main() {
  test(
    'abgelehnter Token beendet eine bestehende Sitzung und meldet sie',
    () async {
      final api = await apiFor(_RejectingService());
      api.token = 'abgelaufenes-token';
      api.username = 'tester';

      var gemeldet = false;
      api.onSessionExpired = () => gemeldet = true;

      await api.scout.getBots();

      expect(api.token, isNull, reason: 'Token muss verworfen werden');
      expect(api.username, isNull);
      expect(gemeldet, isTrue, reason: 'Sitzungsende muss gemeldet werden');
    },
  );

  test('abgelehnter Token ohne bestehende Sitzung meldet nichts', () async {
    final api = await apiFor(_RejectingService());
    api.token = null;

    var gemeldet = false;
    api.onSessionExpired = () => gemeldet = true;

    await api.scout.getBots();

    expect(gemeldet, isFalse);
  });

  test('erfolgreiche Antwort laesst die Sitzung unangetastet', () async {
    final api = await apiFor(_AnsweringService());
    api.token = 'gueltiges-token';

    var gemeldet = false;
    api.onSessionExpired = () => gemeldet = true;

    await api.scout.getBots();

    expect(api.token, 'gueltiges-token');
    expect(gemeldet, isFalse);
  });
}
