import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:hbt_business_app/shared/services/api_client.dart';
import 'package:hbt_business_app/features/auth/controllers/session_controller.dart';
import 'package:hbt_business_app/shared/models/organization_context.dart';

/// Wraps a widget in a minimal MaterialApp for widget testing.
Widget wrapInApp(Widget child) => MaterialApp(
      home: child,
      theme: ThemeData(useMaterial3: true),
    );

/// In-memory storage that overrides [FlutterSecureStorage] for testing.
class MockStorage extends FlutterSecureStorage {
  final _store = <String, String>{};

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _store[key] = value ?? '';
  }

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      _store[key];

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      _store.remove(key);

  @override
  Future<Map<String, String>> readAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      Map<String, String>.from(_store);

  @override
  Future<void> deleteAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      _store.clear();
}

/// Minimal [ApiClient] mock — override methods in specific test files.
class MockApiClient extends ApiClient {
  MockApiClient() : super(baseUrl: 'https://test.example.com');

  @override
  Future<Map<String, dynamic>> get(String path) async {
    throw ApiException('Unmocked GET $path');
  }

  @override
  Future<List<dynamic>> getList(String path) async {
    throw ApiException('Unmocked GET LIST $path');
  }

  @override
  Future<Map<String, dynamic>> post(
      String path, Map<String, dynamic> body) async {
    throw ApiException('Unmocked POST $path');
  }

  @override
  Future<Map<String, dynamic>> patch(
      String path, Map<String, dynamic> body) async {
    throw ApiException('Unmocked PATCH $path');
  }

  @override
  Future<Map<String, dynamic>> put(
      String path, Map<String, dynamic> body) async {
    throw ApiException('Unmocked PUT $path');
  }
}

/// Creates a mock [SessionController] with test defaults.
SessionController createMockSession({
  bool authenticated = true,
  Set<String> permissions = const {
    'trip.view',
    'booking.manage',
    'passenger.view',
  },
}) {
  final ctrl = SessionController(
    api: MockApiClient(),
    storage: MockStorage(),
  );
  ctrl.loading = false;
  ctrl.authenticated = authenticated;
  ctrl.activeOrganization = OrganizationContext(
    organization: OrganizationSummary(
      id: 'org-001',
      displayName: 'Test Bus Co.',
      status: 'active',
    ),
    permissions: permissions,
  );
  ctrl.addListener(() {});
  return ctrl;
}
