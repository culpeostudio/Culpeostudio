import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:myphilostudio/services/api_service.dart';

void main() {
  test(
    'gets authenticated user preferences from the account endpoint',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        expect(request.method, 'GET');
        expect(request.uri.path, '/api/user/preferences');
        expect(
          request.headers.value(HttpHeaders.authorizationHeader),
          'Bearer token',
        );
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode({
            'configured': true,
            'language': 'en',
            'frontend_version': 'lite',
          }),
        );
        await request.response.close();
      });

      final api = ApiService.test()
        ..baseUrl = 'http://127.0.0.1:${server.port}/api'
        ..token = 'token';
      addTearDown(() => server.close(force: true));

      final preferences = await api.getUserPreferences();

      expect(preferences, {
        'configured': true,
        'language': 'en',
        'frontend_version': 'lite',
      });
    },
  );

  test(
    'puts both normalized user preference choices with authentication',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final received = Completer<Map<String, dynamic>>();
      server.listen((request) async {
        expect(request.method, 'PUT');
        expect(request.uri.path, '/api/user/preferences');
        expect(
          request.headers.value(HttpHeaders.authorizationHeader),
          'Bearer account-token',
        );
        final body = jsonDecode(await utf8.decoder.bind(request).join());
        received.complete(Map<String, dynamic>.from(body as Map));
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode({
            'configured': true,
            'language': 'de',
            'frontend_version': 'classic',
          }),
        );
        await request.response.close();
      });

      final api = ApiService.test()
        ..baseUrl = 'http://127.0.0.1:${server.port}/api'
        ..token = 'account-token';
      addTearDown(() => server.close(force: true));

      final preferences = await api.updateUserPreferences(
        language: 'de',
        frontendVersion: 'classic',
      );

      expect(await received.future, {
        'language': 'de',
        'frontend_version': 'classic',
      });
      expect(preferences['configured'], isTrue);
    },
  );
}
