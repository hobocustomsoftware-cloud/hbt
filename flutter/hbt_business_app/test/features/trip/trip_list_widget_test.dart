import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:hbt_business_app/shared/services/api_client.dart';
import 'package:hbt_business_app/core/widgets/async_views.dart';
import 'package:hbt_business_app/core/widgets/loading.dart';
import 'package:hbt_business_app/core/widgets/status_chip.dart';
import 'package:hbt_business_app/features/trip/screens/trip_list_page.dart';
import 'package:hbt_business_app/features/auth/controllers/session_controller.dart';
import 'package:hbt_business_app/shared/models/organization_context.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('TripListPage', () {
    late FlutterSecureStorage storage;

    setUp(() {
      storage = MockStorage();
    });

    Widget _buildPage(ApiClient api, {bool authenticated = true}) {
      final session = SessionController(api: api, storage: storage);
      session.loading = false;
      session.authenticated = authenticated;
      session.activeOrganization = OrganizationContext(
        organization: OrganizationSummary(
          id: 'org-001',
          displayName: 'Test Bus Co.',
          status: 'active',
        ),
        permissions: {
          'trip.view',
          'booking.manage',
          'passenger.view',
        },
      );
      return wrapInApp(TripListPage(session: session));
    }

    testWidgets('shows skeleton loader on initial mount', (tester) async {
      await tester.pumpWidget(_buildPage(_DelayedTripsApi()));
      await tester.pump();
      expect(find.byType(SkeletonLoader), findsOneWidget);
    });

    testWidgets('shows ErrorView when API call fails', (tester) async {
      await tester.pumpWidget(_buildPage(_FailingTripsApi()));
      await tester.pumpAndSettle();

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text('Server error'), findsOneWidget);
    });

    testWidgets('shows empty state when no trips', (tester) async {
      await tester.pumpWidget(_buildPage(_EmptyTripsApi()));
      await tester.pumpAndSettle();

      expect(find.text('No trips found.'), findsOneWidget);
    });

    testWidgets('shows trip list with status chips', (tester) async {
      await tester.pumpWidget(_buildPage(_TripsListApi()));
      await tester.pumpAndSettle();

      expect(find.text('T-001'), findsOneWidget);
      expect(find.text('T-002'), findsOneWidget);
      expect(find.byType(StatusChip), findsNWidgets(2));
    });
  });
}

class _DelayedTripsApi extends ApiClient {
  _DelayedTripsApi() : super(baseUrl: 'https://test.example.com');

  @override
  Future<Map<String, dynamic>> get(String path) async {
    return Completer<Map<String, dynamic>>().future;
  }
}

class _FailingTripsApi extends ApiClient {
  _FailingTripsApi() : super(baseUrl: 'https://test.example.com');

  @override
  Future<Map<String, dynamic>> get(String path) async {
    throw ApiException('Server error');
  }
}

class _EmptyTripsApi extends ApiClient {
  _EmptyTripsApi() : super(baseUrl: 'https://test.example.com');

  @override
  Future<Map<String, dynamic>> get(String path) async {
    return {'results': <Map<String, dynamic>>[]};
  }
}

class _TripsListApi extends ApiClient {
  _TripsListApi() : super(baseUrl: 'https://test.example.com');

  @override
  Future<Map<String, dynamic>> get(String path) async {
    return {
      'results': [
        {
          'id': 't1',
          'trip_number': 'T-001',
          'route': 'Mandalay → Yangon',
          'status': 'planned',
          'service_date': '2026-07-30',
          'planned_departure_at': '2026-07-30T08:00:00Z',
        },
        {
          'id': 't2',
          'trip_number': 'T-002',
          'route': 'Yangon → Mandalay',
          'status': 'ready',
          'service_date': '2026-07-30',
          'planned_departure_at': '2026-07-30T14:00:00Z',
        },
      ],
    };
  }
}
