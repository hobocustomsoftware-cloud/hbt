import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:hbt_business_app/shared/services/api_client.dart';

ApiClient _client(Future<http.Response> Function(http.Request) handler) =>
    ApiClient(baseUrl: 'https://test.example.com', client: MockClient(handler));

http.Response _json(Object body, {int status = 200}) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json'},
    );

void main() {
  group('ApiClient.getAllPages', () {
    test('follows next links until exhausted', () async {
      final requested = <String>[];
      final api = _client((req) async {
        requested.add(req.url.toString());
        if (req.url.queryParameters['page'] == '2') {
          return _json({
            'results': [
              {'id': 3},
              {'id': 4},
            ],
            'next': null,
          });
        }
        return _json({
          'results': [
            {'id': 1},
            {'id': 2},
          ],
          'next':
              'https://test.example.com/api/v1/organizations/org-1/cargo/shipments/?page=2',
        });
      });

      final all = await api.getAllPages(
        '/api/v1/organizations/org-1/cargo/shipments/',
      );

      expect(all.length, 4);
      expect(all[0]['id'], 1);
      expect(all[3]['id'], 4);
      // First request uses the relative path prefixed with baseUrl.
      expect(requested.first,
          'https://test.example.com/api/v1/organizations/org-1/cargo/shipments/');
      // Second request uses the absolute next URL as-is.
      expect(requested.last, contains('page=2'));
    });

    test('returns bare-array responses unchanged', () async {
      final api = _client((req) async => _json([
            {'id': 1},
          ]));
      final all = await api.getAllPages('/api/v1/org-1/routes/');
      expect(all.length, 1);
      expect(all.first['id'], 1);
    });

    test('single-page paginated response has no next', () async {
      final api = _client((req) async => _json({
            'results': [
              {'id': 1},
            ],
            'next': null,
          }));
      final all = await api.getAllPages('/api/v1/org-1/refunds/');
      expect(all.length, 1);
    });

    test('propagates API errors', () async {
      final api =
          _client((req) async => _json({'detail': 'nope'}, status: 403));
      expect(
        () => api.getAllPages('/api/v1/org-1/routes/'),
        throwsA(isA<ApiException>()),
      );
    });

    test('401 triggers refresh then retries with new token', () async {
      var calls = 0;
      final api = _client((req) async {
        calls++;
        if (calls == 1) return _json({'detail': 'expired'}, status: 401);
        return _json({
          'results': [
            {'id': 1},
          ],
          'next': null,
        });
      });
      api.onRefreshToken = () async => 'new-token';
      final all = await api.getAllPages('/api/v1/org-1/routes/');
      expect(all.length, 1);
      expect(calls, 2);
      expect(api.accessToken, 'new-token');
    });
  });
}
