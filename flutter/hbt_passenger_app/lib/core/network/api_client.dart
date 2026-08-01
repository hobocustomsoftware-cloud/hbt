import 'dart:convert';

import 'package:http/http.dart' as http;

/// HTTP API client with token refresh support.
///
/// On 401 responses, attempts a silent token refresh using the stored
/// refresh token (via [onRefreshToken]). If refresh succeeds, the original
/// request is retried. If refresh fails, the caller receives an
/// [ApiException] with the original 401 message.
class ApiClient {
  ApiClient({required this.baseUrl, http.Client? client})
      : _clientOverride = client;

  final String baseUrl;
  final http.Client? _clientOverride;
  String? accessToken;

  /// Callback to attempt token refresh (set by the auth controller).
  ///
  /// Should return the new access token, or throw if refresh fails
  /// (e.g. refresh token expired).
  Future<String> Function()? onRefreshToken;

  /// Whether a token refresh is in progress (prevents recursive retries).
  bool _refreshing = false;

  Future<Map<String, dynamic>> get(String path) => _request('GET', path);

  Future<List<dynamic>> getList(String path) => _requestList('GET', path);

  Future<Map<String, dynamic>> post(
    String path, [
    Map<String, dynamic>? body,
  ]) =>
      _request('POST', path, body: body);

  Future<Map<String, dynamic>> put(
    String path,
    Map<String, dynamic> body,
  ) =>
      _request('PUT', path, body: body);

  Future<Map<String, dynamic>> patch(
    String path,
    Map<String, dynamic> body,
  ) =>
      _request('PATCH', path, body: body);

  Future<Map<String, dynamic>> delete(String path) =>
      _request('DELETE', path);

  Future<http.Response> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final request = http.Request(method, uri)
      ..headers.addAll({
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      });
    if (accessToken != null) {
      request.headers['Authorization'] = 'Bearer $accessToken';
    }
    if (body != null) {
      request.body = jsonEncode(body);
    }
    final client = _clientOverride ?? http.Client();
    try {
      final streamed =
          await client.send(request).timeout(const Duration(seconds: 15));
      return http.Response.fromStream(streamed);
    } finally {
      // Only close clients we created; injected clients are owned by the
      // caller (tests reuse one instance across requests).
      if (_clientOverride == null) client.close();
    }
  }

  /// Attempt a token refresh, then retry the original request once.
  ///
  /// Returns `true` if the retry succeeded. Throws [ApiException] with the
  /// original 401 message when refresh fails.
  Future<bool> _refreshAndRetry() async {
    if (onRefreshToken == null) return false;
    if (_refreshing) return false;
    _refreshing = true;
    try {
      final newToken = await onRefreshToken!();
      accessToken = newToken;
      return true;
    } catch (_) {
      return false;
    } finally {
      _refreshing = false;
    }
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    try {
      var response = await _send(method, path, body: body);
      if (response.statusCode == 401) {
        final refreshed = await _refreshAndRetry();
        if (refreshed) {
          response = await _send(method, path, body: body);
        }
      }
      final text = response.body;
      final decoded = text.isEmpty ? <String, dynamic>{} : jsonDecode(text);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          _apiErrorMessage(decoded, response.statusCode),
        );
      }
      if (decoded is! Map<String, dynamic>) {
        throw const ApiException('Invalid API response format.');
      }
      return decoded;
    } on http.ClientException {
      throw const ApiException('No internet connection. Please try again.');
    } on FormatException {
      throw const ApiException('Invalid server response.');
    }
  }

  Future<List<dynamic>> _requestList(String method, String path) async {
    try {
      var response = await _send(method, path);
      if (response.statusCode == 401) {
        final refreshed = await _refreshAndRetry();
        if (refreshed) {
          response = await _send(method, path);
        }
      }
      final text = response.body;
      final raw = text.isEmpty ? <dynamic>[] : jsonDecode(text);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          _apiErrorMessage(raw, response.statusCode),
        );
      }
      // Handle both paginated ({results: [...]}) and bare-array responses
      if (raw is List<dynamic>) return raw;
      if (raw is Map<String, dynamic>) {
        final results = raw['results'];
        if (results is List<dynamic>) return results;
      }
      throw const ApiException('Invalid API response format.');
    } on http.ClientException {
      throw const ApiException('No internet connection. Please try again.');
    } on FormatException {
      throw const ApiException('Invalid server response.');
    }
  }

  String _apiErrorMessage(dynamic body, int status) {
    if (body is Map<String, dynamic>) {
      final detail = body['detail'] ?? body['message'];
      if (detail is String && detail.isNotEmpty) return detail;
      if (body.isNotEmpty) return body.values.first.toString();
    }
    return 'API error ($status)';
  }
}

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;
}
