import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';
import 'package:culpeo_studio/core/api_client.dart';
import 'package:culpeo_studio/core/app_strings.dart';
import 'package:culpeo_studio/core/api_service.dart';
import 'package:culpeo_studio/core/app_state.dart';
import 'package:culpeo_studio/generated/culpeostudio/login/v1/login.pbgrpc.dart'
    as loginpb;

/// One scripted answer: either preferences to return or an error to raise.
class _QueuedAnswer {
  const _QueuedAnswer.preferences({
    required this.configured,
    required this.language,
  }) : error = null;

  const _QueuedAnswer.failure(this.error) : configured = false, language = '';

  final bool configured;
  final String language;
  final GrpcError? error;

  loginpb.UserPreferences toProto() =>
      loginpb.UserPreferences(configured: configured, language: language);
}

/// Answers the preference calls from a queue, recording which were made.
class _QueuedLoginService extends loginpb.LoginServiceBase {
  _QueuedLoginService(this.answers);

  final List<_QueuedAnswer> answers;
  final List<String> calls = [];

  _QueuedAnswer _next(String call) {
    calls.add(call);
    return answers.removeAt(0);
  }

  @override
  Future<loginpb.GetUserPreferencesResponse> getUserPreferences(
    ServiceCall call,
    loginpb.GetUserPreferencesRequest request,
  ) async {
    final answer = _next('get');
    if (answer.error != null) throw answer.error!;
    return loginpb.GetUserPreferencesResponse(preferences: answer.toProto());
  }

  @override
  Future<loginpb.UpdateUserPreferencesResponse> updateUserPreferences(
    ServiceCall call,
    loginpb.UpdateUserPreferencesRequest request,
  ) async {
    final answer = _next('update');
    if (answer.error != null) throw answer.error!;
    return loginpb.UpdateUserPreferencesResponse(preferences: answer.toProto());
  }

  @override
  Future<loginpb.LoginResponse> login(
    ServiceCall call,
    loginpb.LoginRequest r,
  ) async => throw UnimplementedError();

  @override
  Future<loginpb.GetAuthStatusResponse> getAuthStatus(
    ServiceCall call,
    loginpb.GetAuthStatusRequest r,
  ) async => throw UnimplementedError();

  @override
  Future<loginpb.StartAuthenticatorSetupResponse> startAuthenticatorSetup(
    ServiceCall call,
    loginpb.StartAuthenticatorSetupRequest r,
  ) async => throw UnimplementedError();

  @override
  Future<loginpb.ConfirmAuthenticatorSetupResponse> confirmAuthenticatorSetup(
    ServiceCall call,
    loginpb.ConfirmAuthenticatorSetupRequest r,
  ) async => throw UnimplementedError();

  @override
  Future<loginpb.CreateAccountResponse> createAccount(
    ServiceCall call,
    loginpb.CreateAccountRequest r,
  ) async => throw UnimplementedError();

  @override
  Future<loginpb.ResetPasswordResponse> resetPassword(
    ServiceCall call,
    loginpb.ResetPasswordRequest r,
  ) async => throw UnimplementedError();

  @override
  Future<loginpb.EnableGuestModeResponse> enableGuestMode(
    ServiceCall call,
    loginpb.EnableGuestModeRequest r,
  ) async => throw UnimplementedError();

  @override
  Future<loginpb.DisableGuestModeResponse> disableGuestMode(
    ServiceCall call,
    loginpb.DisableGuestModeRequest r,
  ) async => throw UnimplementedError();
}

Future<(ApiService, _QueuedLoginService)> _startBackend(
  String username,
  List<_QueuedAnswer> answers,
) async {
  final service = _QueuedLoginService(answers);
  final server = Server.create(services: [service]);
  await server.serve(address: '127.0.0.1', port: 0);
  addTearDown(() => server.shutdown());

  // The suite shortens the deadline so unanswered calls do not linger; here a
  // backend answers, so give it room.
  ApiClient.callDeadline = requestTimeout;
  addTearDown(() => ApiClient.callDeadline = const Duration(milliseconds: 1));

  final api = ApiService.test()
    ..baseUrl = 'http://127.0.0.1/api'
    ..token = 'token'
    ..username = username;
  api.client.grpcPort = server.port!;
  return (api, service);
}

void main() {
  tearDown(() => appLanguage = 'de');

  test(
    'an unconfigured backend profile keeps first-login onboarding required',
    () async {
      final (api, service) = await _startBackend('new-user', [
        const _QueuedAnswer.preferences(configured: false, language: 'de'),
      ]);
      final state = AppState.test(api);

      final loaded = await state.loadUserPrefs();

      expect(loaded, isTrue);
      expect(state.userPreferencesLoaded, isTrue);
      expect(state.needsOnboarding, isTrue);
      expect(state.language, 'de');
      expect(service.calls, ['get']);
    },
  );

  test(
    'save failure preserves local state and retry applies server response',
    () async {
      final (api, service) = await _startBackend('user', [
        _QueuedAnswer.failure(
          GrpcError.internal('storage temporarily unavailable'),
        ),
        const _QueuedAnswer.preferences(configured: true, language: 'en'),
      ]);
      final state = AppState.test(api);

      final saved = await state.saveUserPreferences(language: 'en');

      expect(saved, isFalse);
      expect(state.language, 'de');
      expect(state.userPreferencesError, isNotNull);
      expect(state.canRetryUserPreferencesSave, isTrue);

      final retried = await state.retryUserPreferencesSave();

      expect(retried, isTrue);
      expect(state.language, 'en');
      expect(appLanguage, 'en');
      expect(state.needsOnboarding, isFalse);
      expect(state.canRetryUserPreferencesSave, isFalse);
      expect(service.calls, ['update', 'update']);
    },
  );

  test(
    'profile-load retry re-fetches before applying an existing profile',
    () async {
      final (api, service) = await _startBackend('existing-user', [
        _QueuedAnswer.failure(GrpcError.unavailable('service unavailable')),
        const _QueuedAnswer.preferences(configured: true, language: 'en'),
      ]);
      final state = AppState.test(api);

      expect(await state.loadUserPrefs(), isFalse);
      expect(state.needsOnboarding, isTrue);

      expect(await state.retryUserPreferencesLoad(), isTrue);
      expect(state.needsOnboarding, isFalse);
      expect(state.language, 'en');
      expect(service.calls, ['get', 'get']);
    },
  );
}
