import '../../generated/culpeostudio/login/v1/login.pbgrpc.dart' as loginpb;
import '../../core/api_client.dart';

/// Anmeldung, Authenticator-Einrichtung und Nutzereinstellungen.
class LoginApi {
  LoginApi(this._c);

  final ApiClient _c;

  Future<Map<String, dynamic>> getAuthStatus() async {
    try {
      final response = await _c.loginClient.getAuthStatus(
        loginpb.GetAuthStatusRequest(),
      );
      return {
        'totp_configured': response.totpConfigured,
        'authenticator_app': response.authenticatorApp,
      };
    } catch (e) {
      return {'error': _c.grpcErrorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> startAuthenticatorSetup() async {
    try {
      final response = await _c.loginClient.startAuthenticatorSetup(
        loginpb.StartAuthenticatorSetupRequest(),
      );
      return {'secret': response.secret, 'otpauth_url': response.otpauthUrl};
    } catch (e) {
      return {'error': _c.grpcErrorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> confirmAuthenticatorSetup(
    String code,
    String authenticatorApp,
  ) async {
    try {
      final response = await _c.loginClient.confirmAuthenticatorSetup(
        loginpb.ConfirmAuthenticatorSetupRequest(
          code: code,
          app: authenticatorApp,
        ),
      );
      return {'totp_configured': response.totpConfigured};
    } catch (e) {
      return {'error': _c.grpcErrorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> createAccount(
    String user,
    String pass,
    String totpCode,
  ) async {
    try {
      final response = await _c.loginClient.createAccount(
        loginpb.CreateAccountRequest(
          username: user,
          password: pass,
          totpCode: totpCode,
        ),
      );
      return {'username': response.username};
    } catch (e) {
      return {'error': _c.grpcErrorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> resetPassword(
    String user,
    String newPassword,
    String totpCode,
  ) async {
    try {
      final response = await _c.loginClient.resetPassword(
        loginpb.ResetPasswordRequest(
          username: user,
          newPassword: newPassword,
          totpCode: totpCode,
        ),
      );
      return {
        'username': response.username,
        'password_reset': response.passwordReset,
      };
    } catch (e) {
      return {'error': _c.grpcErrorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> login(
    String user,
    String pass, {
    required String sessionDuration,
  }) async {
    try {
      final response = await _c.loginClient.login(
        loginpb.LoginRequest(
          username: user,
          password: pass,
          sessionDuration: _sessionDurationFromName(sessionDuration),
        ),
      );
      _c.token = response.token;
      _c.username = response.username;
      return {
        'token': response.token,
        'username': response.username,
        'session_duration': _sessionDurationName(response.sessionDuration),
      };
    } catch (e) {
      return {'error': _c.grpcErrorMessage(e)};
    }
  }

  void logout() {
    _c.token = null;
    _c.username = null;
  }

  Future<Map<String, dynamic>> getUserPreferences() async {
    try {
      final response = await _c.loginClient.getUserPreferences(
        loginpb.GetUserPreferencesRequest(),
      );
      return _preferencesToMap(response.preferences);
    } catch (e) {
      return {'error': _c.grpcErrorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> updateUserPreferences({
    required String language,
    required String frontendVersion,
  }) async {
    try {
      final response = await _c.loginClient.updateUserPreferences(
        loginpb.UpdateUserPreferencesRequest(
          language: language,
          frontendVersion: frontendVersion,
        ),
      );
      return _preferencesToMap(response.preferences);
    } catch (e) {
      return {'error': _c.grpcErrorMessage(e)};
    }
  }

  static const Map<String, loginpb.SessionDuration> _sessionDurationsByName = {
    '8h': loginpb.SessionDuration.SESSION_DURATION_8H,
    '24h': loginpb.SessionDuration.SESSION_DURATION_24H,
    '48h': loginpb.SessionDuration.SESSION_DURATION_48H,
    'permanent': loginpb.SessionDuration.SESSION_DURATION_PERMANENT,
  };

  /// Anything unknown stays unspecified, which the backend resolves to 24h -
  /// the same fallback the string-based API applied.
  loginpb.SessionDuration _sessionDurationFromName(String name) =>
      _sessionDurationsByName[name.trim().toLowerCase()] ??
      loginpb.SessionDuration.SESSION_DURATION_UNSPECIFIED;

  String _sessionDurationName(loginpb.SessionDuration duration) {
    for (final entry in _sessionDurationsByName.entries) {
      if (entry.value == duration) return entry.key;
    }
    return '24h';
  }

  Map<String, dynamic> _preferencesToMap(loginpb.UserPreferences preferences) {
    return {
      'configured': preferences.configured,
      'language': preferences.language,
      'frontend_version': preferences.frontendVersion,
    };
  }
}
