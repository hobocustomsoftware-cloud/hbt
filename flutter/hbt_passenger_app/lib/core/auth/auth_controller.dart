import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/app_config.dart';
import '../network/api_client.dart';
import '../../shared/repositories/booking_repository.dart';
import '../../shared/repositories/ticket_repository.dart';
import '../../shared/repositories/trip_repository.dart';

/// Manages authentication state for the passenger app.
///
/// Handles registration, login, token storage, and session restoration.
class AuthController extends ChangeNotifier {
  AuthController() : api = ApiClient(baseUrl: AppConfig.apiBaseUrl) {
    // Silent 401-triggered token refresh during normal API usage.
    api.onRefreshToken = _refreshAccessToken;
  }

  final ApiClient api;

  /// Repositories built on the authenticated [api] client.
  ///
  /// Lazily created once; screens receive them via [AuthController] so no DI
  /// framework is needed (see M4 migration note).
  late final TripRepository tripRepository = TripRepository(api: api);
  late final BookingRepository bookingRepository = BookingRepository(api: api);
  late final TicketRepository ticketRepository = TicketRepository(api: api);

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const _accessKey = 'hbt_access_token';
  static const _refreshKey = 'hbt_refresh_token';

  bool _loading = false;
  bool _authenticated = false;
  String? _error;
  Map<String, dynamic>? _user;

  bool get loading => _loading;
  bool get authenticated => _authenticated;
  String? get error => _error;
  Map<String, dynamic>? get user => _user;

  /// Try restoring a session from stored tokens.
  Future<bool> tryRestore() async {
    final access = await _storage.read(key: _accessKey);
    if (access == null) return false;

    api.accessToken = access;
    try {
      final me = await api.get('/auth/me/');
      _user = me;
      _authenticated = true;
      notifyListeners();
      return true;
    } on ApiException {
      // Token expired — try refresh
      final refresh = await _storage.read(key: _refreshKey);
      if (refresh == null) {
        await _clearTokens();
        return false;
      }
      try {
        final result = await api.post('/auth/token/refresh/', {
          'refresh': refresh,
        });
        final newAccess = result['access'] as String;
        await _storage.write(key: _accessKey, value: newAccess);
        api.accessToken = newAccess;
        final me = await api.get('/auth/me/');
        _user = me;
        _authenticated = true;
        notifyListeners();
        return true;
      } on ApiException {
        await _clearTokens();
        return false;
      }
    }
  }

  /// Register a new passenger account.
  Future<bool> register({
    required String phone,
    required String password,
    String? firstName,
    String? lastName,
    String? email,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await api.post('/auth/register/', {
        'phone_number': phone,
        'password': password,
        if (firstName != null && firstName.isNotEmpty)
          'first_name': firstName,
        if (lastName != null && lastName.isNotEmpty) 'last_name': lastName,
        if (email != null && email.isNotEmpty) 'email': email,
      });

      // Auto-login after registration
      final success = await login(phone: phone, password: password);
      return success;
    } on ApiException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Registration failed: $e';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  /// Login with phone number + password.
  Future<bool> login({
    required String phone,
    required String password,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await api.post('/auth/login/', {
        'phone_number': phone,
        'password': password,
      });

      final access = result['access'] as String;
      final refresh = result['refresh'] as String;

      await _storage.write(key: _accessKey, value: access);
      await _storage.write(key: _refreshKey, value: refresh);

      api.accessToken = access;

      // Load user profile
      final me = await api.get('/auth/me/');
      _user = me;
      _authenticated = true;
      _loading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Login failed: $e';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  /// Refresh the access token using the stored refresh token.
  ///
  /// Called by [ApiClient] when a request returns 401. Returns the new
  /// access token, or throws if the refresh token is invalid/expired.
  Future<String> _refreshAccessToken() async {
    final refresh = await _storage.read(key: _refreshKey);
    if (refresh == null) {
      throw const ApiException('No refresh token stored.');
    }
    final result = await api.post('/auth/token/refresh/', {
      'refresh': refresh,
    });
    final newAccess = result['access'] as String;
    await _storage.write(key: _accessKey, value: newAccess);
    api.accessToken = newAccess;
    return newAccess;
  }

  /// Sign out and clear stored tokens.
  Future<void> signOut() async {
    final refresh = await _storage.read(key: _refreshKey);
    if (refresh != null) {
      try {
        await api.post('/auth/logout/', {'refresh': refresh});
      } catch (_) {
        // Best-effort server logout
      }
    }
    await _clearTokens();
    _authenticated = false;
    _user = null;
    _error = null;
    notifyListeners();
  }

  Future<void> _clearTokens() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
    api.accessToken = null;
  }
}
