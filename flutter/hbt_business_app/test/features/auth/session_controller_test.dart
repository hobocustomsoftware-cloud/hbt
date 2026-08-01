import 'package:flutter_test/flutter_test.dart';

import 'package:hbt_business_app/shared/services/api_client.dart';
import 'package:hbt_business_app/features/auth/controllers/auth_controller.dart';
import 'package:hbt_business_app/features/auth/controllers/session_controller.dart';
import 'package:hbt_business_app/features/org/controllers/org_controller.dart';

import '../../helpers/test_helpers.dart';

/// Minimal API mock with scripted responses for auth/org flows.
class _AuthFlowApi extends ApiClient {
  _AuthFlowApi() : super(baseUrl: 'https://test.example.com');

  final loginResults = <String, Map<String, dynamic>>{};
  final meResults = <String, Map<String, dynamic>>{};
  final orgListResults = <List<dynamic>>[];
  final orgContextResults = <String, Map<String, dynamic>>{};
  final logoutCalls = <String>[];

  @override
  Future<Map<String, dynamic>> get(String path) async {
    if (path == '/auth/me/') {
      final result = meResults[path];
      if (result != null) return result;
      throw ApiException('Unmocked GET $path');
    }
    if (path.startsWith('/me/organizations/') && path.endsWith('/context/')) {
      final result = orgContextResults[path];
      if (result != null) return result;
      throw ApiException('Unmocked GET $path');
    }
    throw ApiException('Unmocked GET $path');
  }

  @override
  Future<List<dynamic>> getList(String path) async {
    if (path == '/me/organizations/') {
      if (orgListResults.isNotEmpty) {
        return orgListResults.first;
      }
      throw ApiException('Unmocked GET LIST $path');
    }
    throw ApiException('Unmocked GET LIST $path');
  }

  @override
  Future<Map<String, dynamic>> post(
      String path, Map<String, dynamic> body) async {
    if (path == '/auth/login/') {
      final result = loginResults[path];
      if (result != null) return result;
      throw ApiException('Unmocked POST $path');
    }
    if (path == '/auth/logout/') {
      logoutCalls.add(body.toString());
      return <String, dynamic>{};
    }
    throw ApiException('Unmocked POST $path');
  }
}

Map<String, dynamic> _orgListJson(String id) => {
      'id': id,
      'display_name': 'Test Bus Co.',
      'status': 'active',
    };

Map<String, dynamic> _orgContextJson(String id) => {
      'organization': _orgListJson(id),
      'permissions': ['trip.view', 'booking.manage'],
    };

void main() {
  group('AuthController', () {
    test('restore with stored token fetches profile and authenticates',
        () async {
      final api = _AuthFlowApi()
        ..meResults['/auth/me/'] = {
          'id': 'u1',
          'phone_number': '09123456789',
        };
      final storage = MockStorage();
      await storage.write(key: 'access_token', value: 'token-1');
      await storage.write(key: 'refresh_token', value: 'refresh-1');

      final auth = AuthController(api: api, storage: storage);
      await auth.restore();

      expect(auth.authenticated, isTrue);
      expect(auth.user?['id'], 'u1');
      expect(auth.loading, isFalse);
      expect(api.accessToken, 'token-1');
    });

    test('restore without token stays logged out', () async {
      final api = _AuthFlowApi();
      final auth = AuthController(api: api, storage: MockStorage());
      await auth.restore();
      expect(auth.authenticated, isFalse);
      expect(auth.loading, isFalse);
    });

    test('restore with expired token clears credentials', () async {
      final api = _AuthFlowApi(); // /auth/me/ not mocked -> throws
      final storage = MockStorage();
      await storage.write(key: 'access_token', value: 'expired-token');

      final auth = AuthController(api: api, storage: storage);
      await auth.restore();

      expect(auth.authenticated, isFalse);
      expect(await storage.read(key: 'access_token'), isNull);
      expect(api.accessToken, isNull);
    });

    test('signIn stores tokens, fetches profile, authenticates', () async {
      final api = _AuthFlowApi()
        ..loginResults['/auth/login/'] = {
          'access': 'access-1',
          'refresh': 'refresh-1',
        }
        ..meResults['/auth/me/'] = {'id': 'u1'};
      final storage = MockStorage();

      final auth = AuthController(api: api, storage: storage);
      await auth.signIn(phone: '09123456789', password: 'secret');

      expect(auth.authenticated, isTrue);
      expect(await storage.read(key: 'access_token'), 'access-1');
      expect(await storage.read(key: 'refresh_token'), 'refresh-1');
      expect(api.accessToken, 'access-1');
    });

    test('signIn propagates API failure', () async {
      final api = _AuthFlowApi(); // login not mocked -> throws
      final auth = AuthController(api: api, storage: MockStorage());
      await expectLater(
        auth.signIn(phone: '09123456789', password: 'wrong'),
        throwsA(isA<ApiException>()),
      );
      expect(auth.authenticated, isFalse);
    });

    test('signIn rejects response without access token', () async {
      final api = _AuthFlowApi()
        ..loginResults['/auth/login/'] = {'refresh': 'r1'};
      final auth = AuthController(api: api, storage: MockStorage());
      await expectLater(
        auth.signIn(phone: '09123456789', password: 'secret'),
        throwsA(isA<ApiException>()),
      );
      expect(auth.authenticated, isFalse);
    });

    test('signOut clears credentials and notifies backend', () async {
      final api = _AuthFlowApi()
        ..loginResults['/auth/login/'] = {
          'access': 'access-1',
          'refresh': 'refresh-1',
        }
        ..meResults['/auth/me/'] = {'id': 'u1'};
      final storage = MockStorage();

      final auth = AuthController(api: api, storage: storage);
      await auth.signIn(phone: '09123456789', password: 'secret');
      expect(auth.authenticated, isTrue);

      await auth.signOut();
      expect(auth.authenticated, isFalse);
      expect(auth.user, isNull);
      expect(api.accessToken, isNull);
      expect(api.logoutCalls, hasLength(1));
    });
  });

  group('OrgController', () {
    test('loadOrganizationContext picks saved org and loads permissions',
        () async {
      final api = _AuthFlowApi()
        ..orgListResults.add([
          _orgListJson('org-1'),
          _orgListJson('org-2'),
        ])
        ..orgContextResults['/me/organizations/org-2/context/'] =
            _orgContextJson('org-2');
      final storage = MockStorage();
      await storage.write(key: 'active_organization_id', value: 'org-2');

      final org = OrgController(api: api, storage: storage);
      await org.loadOrganizationContext();

      expect(org.activeOrganization?.organization.id, 'org-2');
      expect(org.hasPermission('booking.manage'), isTrue);
      expect(org.hasPermission('refund.approve'), isFalse);
      expect(
        await storage.read(key: 'active_organization_id'),
        'org-2',
      );
    });

    test('loadOrganizationContext falls back to first org when none saved',
        () async {
      final api = _AuthFlowApi()
        ..orgListResults.add([_orgListJson('org-1')])
        ..orgContextResults['/me/organizations/org-1/context/'] =
            _orgContextJson('org-1');

      final org = OrgController(api: api, storage: MockStorage());
      await org.loadOrganizationContext();

      expect(org.activeOrganization?.organization.id, 'org-1');
    });
  });

  group('SessionController facade', () {
    test('signIn composes auth + org context + counter restore', () async {
      final api = _AuthFlowApi()
        ..loginResults['/auth/login/'] = {
          'access': 'access-1',
          'refresh': 'refresh-1',
        }
        ..meResults['/auth/me/'] = {'id': 'u1'}
        ..orgListResults.add([_orgListJson('org-1')])
        ..orgContextResults['/me/organizations/org-1/context/'] =
            _orgContextJson('org-1');

      final session = SessionController(api: api, storage: MockStorage());
      await session.signIn(phone: '09123456789', password: 'secret');

      expect(session.authenticated, isTrue);
      expect(session.user?['id'], 'u1');
      expect(session.organizations, hasLength(1));
      expect(session.activeOrganization?.organization.id, 'org-1');
      expect(session.hasPermission('trip.view'), isTrue);
    });

    test('signOut clears auth, org, and counter state', () async {
      final api = _AuthFlowApi()
        ..loginResults['/auth/login/'] = {
          'access': 'access-1',
          'refresh': 'refresh-1',
        }
        ..meResults['/auth/me/'] = {'id': 'u1'}
        ..orgListResults.add([_orgListJson('org-1')])
        ..orgContextResults['/me/organizations/org-1/context/'] =
            _orgContextJson('org-1');
      final session = SessionController(api: api, storage: MockStorage());
      await session.signIn(phone: '09123456789', password: 'secret');
      await session.setActiveCounter(
        branchId: 'b1',
        branchName: 'Branch 1',
        counterId: 'c1',
        counterName: 'Counter 1',
      );
      expect(session.hasActiveCounter, isTrue);

      await session.signOut();

      expect(session.authenticated, isFalse);
      expect(session.organizations, isEmpty);
      expect(session.activeOrganization, isNull);
      expect(session.hasActiveCounter, isFalse);
    });
  });
}
