import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:myphilostudio/services/api_service.dart';

class _StubClient extends http.BaseClient {
  _StubClient(this.statusCode);

  final int statusCode;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(
      Stream.value(utf8.encode(jsonEncode({'error': 'Ungueltiger Token'}))),
      statusCode,
    );
  }
}

void main() {
  test('401 beendet eine bestehende Sitzung und meldet sie', () async {
    final api = ApiService.test();
    api.debugSetHttpClient(_StubClient(401));
    api.token = 'abgelaufenes-token';
    api.username = 'tester';

    var gemeldet = false;
    api.onSessionExpired = () => gemeldet = true;

    await api.getPhiloBots();

    expect(api.token, isNull, reason: 'Token muss verworfen werden');
    expect(api.username, isNull);
    expect(gemeldet, isTrue, reason: 'Sitzungsende muss gemeldet werden');
  });

  test('401 ohne bestehende Sitzung meldet nichts', () async {
    final api = ApiService.test();
    api.debugSetHttpClient(_StubClient(401));
    api.token = null;

    var gemeldet = false;
    api.onSessionExpired = () => gemeldet = true;

    await api.getPhiloBots();

    expect(gemeldet, isFalse);
  });

  test('erfolgreiche Antwort laesst die Sitzung unangetastet', () async {
    final api = ApiService.test();
    api.debugSetHttpClient(_StubClient(200));
    api.token = 'gueltiges-token';

    var gemeldet = false;
    api.onSessionExpired = () => gemeldet = true;

    await api.getPhiloBots();

    expect(api.token, 'gueltiges-token');
    expect(gemeldet, isFalse);
  });
}
