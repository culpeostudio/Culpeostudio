import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:myphilostudio/l10n/app_strings.dart';
import 'package:myphilostudio/services/api_service.dart';
import 'package:myphilostudio/state/app_state.dart';

class _QueuedResponse {
  const _QueuedResponse(this.statusCode, this.body);

  final int statusCode;
  final Map<String, dynamic> body;
}

class _QueuedClient extends http.BaseClient {
  _QueuedClient(this.responses);

  final List<_QueuedResponse> responses;
  final List<http.BaseRequest> requests = [];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests.add(request);
    final response = responses.removeAt(0);
    return http.StreamedResponse(
      Stream.value(utf8.encode(jsonEncode(response.body))),
      response.statusCode,
      headers: const {'content-type': 'application/json'},
    );
  }
}

void main() {
  tearDown(() => appLanguage = 'de');

  test(
    'an unconfigured backend profile keeps first-login onboarding required',
    () async {
      final client = _QueuedClient([
        const _QueuedResponse(200, {
          'configured': false,
          'language': 'de',
          'frontend_version': 'classic',
        }),
      ]);
      final api = ApiService.test()
        ..token = 'token'
        ..username = 'new-user'
        ..debugSetHttpClient(client);
      final state = AppState.test(api);

      final loaded = await state.loadUserPrefs();

      expect(loaded, isTrue);
      expect(state.userPreferencesLoaded, isTrue);
      expect(state.needsOnboarding, isTrue);
      expect(state.language, 'de');
      expect(state.frontendVersion, 'classic');
      expect(client.requests.single.url.path, '/api/user/preferences');
    },
  );

  test(
    'save failure preserves local state and retry applies server response',
    () async {
      final client = _QueuedClient([
        const _QueuedResponse(500, {
          'error': 'storage temporarily unavailable',
        }),
        const _QueuedResponse(200, {
          'configured': true,
          'language': 'en',
          'frontend_version': 'lite',
        }),
      ]);
      final api = ApiService.test()
        ..token = 'token'
        ..username = 'user'
        ..debugSetHttpClient(client);
      final state = AppState.test(api);

      final saved = await state.saveUserPreferences(
        language: 'en',
        frontendVersion: 'lite',
      );

      expect(saved, isFalse);
      expect(state.language, 'de');
      expect(state.frontendVersion, 'classic');
      expect(state.userPreferencesError, isNotNull);
      expect(state.canRetryUserPreferencesSave, isTrue);

      final retried = await state.retryUserPreferencesSave();

      expect(retried, isTrue);
      expect(state.language, 'en');
      expect(state.frontendVersion, 'lite');
      expect(appLanguage, 'en');
      expect(state.needsOnboarding, isFalse);
      expect(state.canRetryUserPreferencesSave, isFalse);
      expect(client.requests, hasLength(2));
      for (final request in client.requests) {
        expect(request.method, 'PUT');
        expect(request.url.path, '/api/user/preferences');
        final body = jsonDecode((request as http.Request).body);
        expect(body, {'language': 'en', 'frontend_version': 'lite'});
      }
    },
  );

  test(
    'profile-load retry re-fetches before applying an existing profile',
    () async {
      final client = _QueuedClient([
        const _QueuedResponse(503, {'error': 'service unavailable'}),
        const _QueuedResponse(200, {
          'configured': true,
          'language': 'en',
          'frontend_version': 'classic',
        }),
      ]);
      final api = ApiService.test()
        ..token = 'token'
        ..username = 'existing-user'
        ..debugSetHttpClient(client);
      final state = AppState.test(api);

      expect(await state.loadUserPrefs(), isFalse);
      expect(state.needsOnboarding, isTrue);

      expect(await state.retryUserPreferencesLoad(), isTrue);
      expect(state.needsOnboarding, isFalse);
      expect(state.language, 'en');
      expect(
        client.requests.map((request) => request.method),
        everyElement('GET'),
      );
    },
  );
}
