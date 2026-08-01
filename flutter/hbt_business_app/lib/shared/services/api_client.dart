import 'dart:convert';

import 'package:http/http.dart' as http;

/// HTTP API client with token refresh support.
///
/// On 401 responses, attempts a silent token refresh using the stored
/// refresh token (via [onRefreshToken]). If refresh succeeds, the
/// original request is retried. If refresh fails, the caller receives
/// an [ApiException] with the original 401 message.
class ApiClient {
  ApiClient({required this.baseUrl});

  final String baseUrl;
  String? accessToken;

  /// Callback to attempt token refresh.
  ///
  /// Should return the new access token string, or throw [ApiException]
  /// if refresh fails (e.g. refresh token expired).
  Future<String> Function()? onRefreshToken;

  /// Whether a token refresh is in progress (prevents recursive retries).
  bool _refreshing = false;

  Future<Map<String, dynamic>> get(String path) => _request('GET', path);

  Future<List<dynamic>> getList(String path) =>
      _requestList('GET', path);

  Future<Map<String, dynamic>> put(
          String path, Map<String, dynamic> body) =>
      _request('PUT', path, body: body);

  Future<Map<String, dynamic>> patch(
          String path, Map<String, dynamic> body) =>
      _request('PATCH', path, body: body);

  Future<Map<String, dynamic>> delete(String path) =>
      _request('DELETE', path);

  Future<Map<String, dynamic>> post(
          String path, Map<String, dynamic> body) =>
      _request('POST', path, body: body);

  Future<Map<String, dynamic>> postJson(String path, dynamic body) async {
    final uri = Uri.parse('$baseUrl$path');
    try {
      final request = http.Request('POST', uri)
        ..headers.addAll({
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        });
      if (accessToken != null) {
        request.headers['Authorization'] = 'Bearer $accessToken';
      }
      request.body = jsonEncode(body);
      final streamed =
          await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamed);
      final text = response.body;
      final decoded = text.isEmpty ? <String, dynamic>{} : jsonDecode(text);
      if (response.statusCode == 401 && !_refreshing) {
        return _handleRefresh(() => postJson(path, body));
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(_apiErrorMessage(decoded, response.statusCode));
      }
      if (decoded is! Map<String, dynamic>) {
        throw const ApiException('API response ပုံစံ မမှန်ပါ။');
      }
      return decoded;
    } on http.ClientException {
      throw const ApiException('အင်တာနက်မရပါ။ ပြန်ချိတ်ပြီး ထပ်စမ်းပါ။');
    } on UnsupportedError {
      throw const ApiException('Server နှင့် ချိတ်ဆက်မရပါ။');
    } on FormatException {
      throw const ApiException('Server response ပုံစံ မမှန်ပါ။');
    }
  }

  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required Map<String, String> fields,
    required List<int> fileBytes,
    required String fileName,
  }) async {
    final request =
        http.MultipartRequest('POST', Uri.parse('$baseUrl$path'))
          ..headers['Accept'] = 'application/json'
          ..fields.addAll(fields)
          ..files.add(http.MultipartFile.fromBytes(
              'file', fileBytes,
              filename: fileName));
    if (accessToken != null) {
      request.headers['Authorization'] = 'Bearer $accessToken';
    }
    try {
      final response = await http.Response.fromStream(
        await request.send().timeout(const Duration(seconds: 30)),
      );
      final decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body);
      if (response.statusCode == 401 && !_refreshing) {
        return _handleRefresh(() => postMultipart(
              path,
              fields: fields,
              fileBytes: fileBytes,
              fileName: fileName,
            ));
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
            _apiErrorMessage(decoded, response.statusCode));
      }
      if (decoded is! Map<String, dynamic>) {
        throw const ApiException('API response ပုံစံ မမှန်ပါ။');
      }
      return decoded;
    } on http.ClientException {
      throw const ApiException('အင်တာနက်မရပါ။ ပြန်ချိတ်ပြီး ထပ်စမ်းပါ။');
    } on FormatException {
      throw const ApiException('Server response ပုံစံ မမှန်ပါ။');
    }
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    try {
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
      final streamed =
          await request.send().timeout(const Duration(seconds: 15));
      final response = await http.Response.fromStream(streamed);
      final text = response.body;
      final decoded = text.isEmpty ? <String, dynamic>{} : jsonDecode(text);
      if (response.statusCode == 401 && !_refreshing) {
        return _handleRefresh(
            () => _request(method, path, body: body));
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
            _apiErrorMessage(decoded, response.statusCode));
      }
      if (decoded is! Map<String, dynamic>) {
        throw const ApiException('API response ပုံစံ မမှန်ပါ။');
      }
      return decoded;
    } on http.ClientException {
      throw const ApiException('အင်တာနက်မရပါ။ ပြန်ချိတ်ပြီး ထပ်စမ်းပါ။');
    } on UnsupportedError {
      throw const ApiException('Server နှင့် ချိတ်ဆက်မရပါ။');
    } on FormatException {
      throw const ApiException('Server response ပုံစံ မမှန်ပါ။');
    }
  }

  Future<List<dynamic>> _requestList(String method, String path) async {
    final uri = Uri.parse('$baseUrl$path');
    try {
      final request = http.Request(method, uri)
        ..headers.addAll({
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        });
      if (accessToken != null) {
        request.headers['Authorization'] = 'Bearer $accessToken';
      }
      final streamed =
          await request.send().timeout(const Duration(seconds: 15));
      final response = await http.Response.fromStream(streamed);
      final text = response.body;
      final raw = text.isEmpty ? <dynamic>[] : jsonDecode(text);
      if (response.statusCode == 401 && !_refreshing) {
        // Retry after refresh
        return _handleRefreshList(
            () => _requestList(method, path));
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
            _apiErrorMessage(raw, response.statusCode));
      }
      // Handle both paginated ({results: [...]}) and bare-array responses
      if (raw is List<dynamic>) return raw;
      if (raw is Map<String, dynamic>) {
        final results = raw['results'];
        if (results is List<dynamic>) return results;
      }
      throw const ApiException('API response ပုံစံ မမှန်ပါ။');
    } on http.ClientException {
      throw const ApiException('အင်တာနက်မရပါ။ ပြန်ချိတ်ပြီး ထပ်စမ်းပါ။');
    } on UnsupportedError {
      throw const ApiException('Server နှင့် ချိတ်ဆက်မရပါ။');
    } on FormatException {
      throw const ApiException('Server response ပုံစံ မမှန်ပါ။');
    }
  }

  /// Attempt a token refresh and retry the original request.
  Future<Map<String, dynamic>> _handleRefresh(
    Future<Map<String, dynamic>> Function() retry,
  ) async {
    if (onRefreshToken == null) {
      throw const ApiException('Session expired. Please sign in again.');
    }
    _refreshing = true;
    try {
      final newToken = await onRefreshToken!();
      accessToken = newToken;
      _refreshing = false;
      return retry();
    } on ApiException {
      _refreshing = false;
      rethrow;
    } catch (e) {
      _refreshing = false;
      throw ApiException('Session refresh failed: $e');
    }
  }

  /// Attempt a token refresh and retry the original list request.
  Future<List<dynamic>> _handleRefreshList(
    Future<List<dynamic>> Function() retry,
  ) async {
    if (onRefreshToken == null) {
      throw const ApiException('Session expired. Please sign in again.');
    }
    _refreshing = true;
    try {
      final newToken = await onRefreshToken!();
      accessToken = newToken;
      _refreshing = false;
      return retry();
    } on ApiException {
      _refreshing = false;
      rethrow;
    } catch (e) {
      _refreshing = false;
      throw ApiException('Session refresh failed: $e');
    }
  }

  String _apiErrorMessage(dynamic body, int status) {
    if (body is Map<String, dynamic>) {
      final detail = body['detail'] ?? body['message'];
      if (detail is String && detail.isNotEmpty) {
        return detail;
      }
      if (body.isNotEmpty) {
        return body.values.first.toString();
      }
    }
    return 'API error ($status)';
  }
}

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;
}
