import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';
import 'package:culpeo_studio/core/api_client.dart';
import 'package:culpeo_studio/core/api_service.dart';
import 'package:culpeo_studio/generated/culpeostudio/login/v1/login.pbgrpc.dart'
    as loginpb;

/// A real LoginService, so the test exercises the wire: the metadata the client
/// attaches, the request it encodes and the response it maps back.
class _RecordingLoginService extends loginpb.LoginServiceBase {
  String? seenAuthorization;
  loginpb.UpdateUserPreferencesRequest? seenUpdate;

  void _record(ServiceCall call) {
    seenAuthorization = call.clientMetadata?['authorization'];
  }

  @override
  Future<loginpb.GetUserPreferencesResponse> getUserPreferences(
    ServiceCall call,
    loginpb.GetUserPreferencesRequest request,
  ) async {
    _record(call);
    return loginpb.GetUserPreferencesResponse(
      preferences: loginpb.UserPreferences(configured: true, language: 'en'),
    );
  }

  @override
  Future<loginpb.UpdateUserPreferencesResponse> updateUserPreferences(
    ServiceCall call,
    loginpb.UpdateUserPreferencesRequest request,
  ) async {
    _record(call);
    seenUpdate = request;
    return loginpb.UpdateUserPreferencesResponse(
      preferences: loginpb.UserPreferences(
        configured: true,
        language: request.language,
      ),
    );
  }

  // Not exercised here.
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

Future<(ApiService, _RecordingLoginService)> startBackend(String token) async {
  final service = _RecordingLoginService();
  final server = Server.create(services: [service]);
  await server.serve(address: '127.0.0.1', port: 0);
  addTearDown(() => server.shutdown());

  // The suite shortens the deadline to 1ms so unanswered calls do not linger;
  // this test has a backend that answers, so give it room.
  ApiClient.callDeadline = requestTimeout;
  addTearDown(() => ApiClient.callDeadline = const Duration(milliseconds: 1));

  final api = ApiService.test()
    ..baseUrl = 'http://127.0.0.1/api'
    ..token = token;
  api.client.grpcPort = server.port!;
  return (api, service);
}

void main() {
  test(
    'gets authenticated user preferences from the account service',
    () async {
      final (api, service) = await startBackend('token');

      final preferences = await api.login.getUserPreferences();

      expect(service.seenAuthorization, 'Bearer token');
      expect(preferences, {'configured': true, 'language': 'en'});
    },
  );

  test('sends the user preference choice with authentication', () async {
    final (api, service) = await startBackend('account-token');

    final updated = await api.login.updateUserPreferences(language: 'en');

    expect(service.seenAuthorization, 'Bearer account-token');
    expect(service.seenUpdate?.language, 'en');
    expect(updated, {'configured': true, 'language': 'en'});
  });
}
