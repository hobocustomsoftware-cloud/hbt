import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../shared/services/api_client.dart';

/// Manages authentication lifecycle: login, session restore, token storage,
/// sign-out, and user profile retrieval.
///
/// This controller owns the auth domain. It does NOT manage organization
/// context or permission checking — those are in [OrgController] and
/// exposed via [SessionController].
class AuthController extends ChangeNotifier {
  AuthController({required this.api, required this.storage});

  final ApiClient api;
  final FlutterSecureStorage storage;

  bool loading = true;
  bool authenticated = false;
  Map<String, dynamic>? user;

  /// Restore a previous session from secure storage.
  ///
  /// Reads a stored access token; if valid, fetches the user profile and
  /// sets [authenticated] to `true`. On failure (expired/revoked token),
  /// clears all stored credentials silently.
  Future<void> restore() async {
    try {
      final token = await storage.read(key: 'access_token');
      final refreshToken = await storage.read(key: 'refresh_token');
      if (token != null && token.isNotEmpty) {
        api.accessToken = token;
        // Wire token refresh callback
        api.onRefreshToken = () => _refreshAccessToken(refreshToken);
        user = await api.get('/auth/me/');
        authenticated = true;
      }
    } on ApiException {
      await _clearCredentials();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Authenticate with phone number and password.
  ///
  /// On success, stores the access + refresh tokens in secure storage,
  /// fetches the user profile, and sets [authenticated] to `true`.
  /// Throws [ApiException] on failure.
  Future<void> signIn({
    required String phone,
    required String password,
  }) async {
    final result = await api.post('/auth/login/', {
      'phone_number': phone,
      'password': password,
    });
    final access = result['access'] as String?;
    if (access == null || access.isEmpty) {
      throw const ApiException('Login response တွင် access token မပါရှိပါ။');
    }
    api.accessToken = access;
    await storage.write(key: 'access_token', value: access);
    final refresh = result['refresh'] as String?;
    await storage.write(key: 'refresh_token', value: refresh);
    api.onRefreshToken = () => _refreshAccessToken(refresh);
    user = await api.get('/auth/me/');
    authenticated = true;
    notifyListeners();
  }

  /// Attempt to refresh the access token using the stored refresh token.
  Future<String> _refreshAccessToken(String? refreshToken) async {
    if (refreshToken == null || refreshToken.isEmpty) {
      throw const ApiException('No refresh token available.');
    }
    final result = await api.post('/auth/token/refresh/', {
      'refresh': refreshToken,
    });
    final newAccess = result['access'] as String?;
    if (newAccess == null || newAccess.isEmpty) {
      throw const ApiException('Refresh response missing access token.');
    }
    await storage.write(key: 'access_token', value: newAccess);
    // Update stored refresh token if server issues a new one
    final newRefresh = result['refresh'] as String?;
    if (newRefresh != null && newRefresh.isNotEmpty) {
      await storage.write(key: 'refresh_token', value: newRefresh);
      api.onRefreshToken = () => _refreshAccessToken(newRefresh);
    }
    return newAccess;
  }

  /// Sign out: notify the backend, then clear local credentials.
  Future<void> signOut() async {
    final refresh = await storage.read(key: 'refresh_token');
    try {
      if (refresh != null) {
        await api.post('/auth/logout/', {'refresh': refresh});
      }
    } on ApiException {
      // A locally signed-out device must not be blocked by an unavailable API.
    }
    await _clearCredentials();
    notifyListeners();
  }

  /// Clear auth state without notifying the backend.
  Future<void> _clearCredentials() async {
    api.accessToken = null;
    user = null;
    authenticated = false;
    await storage.delete(key: 'access_token');
    await storage.delete(key: 'refresh_token');
    notifyListeners();
  }
}
