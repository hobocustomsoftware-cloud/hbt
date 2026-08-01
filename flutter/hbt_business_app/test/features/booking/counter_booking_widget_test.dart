import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hbt_business_app/shared/services/api_client.dart';
import 'package:hbt_business_app/core/widgets/async_views.dart';
import 'package:hbt_business_app/features/ticket_sales/screens/counter_booking_page.dart';
import 'package:hbt_business_app/features/auth/controllers/session_controller.dart';
import 'package:hbt_business_app/shared/models/organization_context.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('CounterBookingPage — loading state', () {
    Widget buildPage(ApiClient api) {
      final storage = MockStorage();
      final session = SessionController(api: api, storage: storage);
      session.loading = false;
      session.authenticated = true;
      session.activeOrganization = OrganizationContext(
        organization: OrganizationSummary(
          id: 'org-001',
          displayName: 'Test Bus Co.',
          status: 'active',
        ),
        permissions: {
          'booking.manage',
          'passenger.view',
          'trip.view',
        },
      );
      return wrapInApp(CounterBookingPage(session: session));
    }

    testWidgets('shows loading indicator on initial load', (tester) async {
      await tester.pumpWidget(buildPage(_HangingApi()));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows ErrorCard on initial load failure', (tester) async {
      await tester.pumpWidget(buildPage(_FailingApi()));
      await tester.pumpAndSettle();

      expect(find.byType(ErrorCard), findsOneWidget);
      expect(find.text('Load failed'), findsOneWidget);
    });

    testWidgets('renders form when data loads successfully', (tester) async {
      await tester.pumpWidget(buildPage(_LoadedBookingApi()));
      await tester.pumpAndSettle();

      expect(find.text('Counter Booking'), findsOneWidget);
    });
  });
}

class _HangingApi extends ApiClient {
  _HangingApi() : super(baseUrl: 'https://test.example.com');

  @override
  Future<List<dynamic>> getList(String path) async {
    // Never completes — no timer, no leak
    return Completer<List<dynamic>>().future;
  }
}

class _FailingApi extends ApiClient {
  _FailingApi() : super(baseUrl: 'https://test.example.com');

  @override
  Future<List<dynamic>> getList(String path) async {
    throw ApiException('Load failed');
  }
}

class _LoadedBookingApi extends ApiClient {
  _LoadedBookingApi() : super(baseUrl: 'https://test.example.com');

  @override
  Future<List<dynamic>> getList(String path) async {
    if (path.contains('passengers')) {
      return [
        {'id': 'p1', 'full_name': 'Maung Maung', 'phone_number': '0912345678'},
        {'id': 'p2', 'full_name': 'Aye Aye', 'phone_number': '0956789012'},
      ];
    }
    if (path.contains('trips')) {
      return [
        {
          'id': 't1',
          'trip_number': 'T-001',
          'route_snapshot': {
            'stops': [
              {'id': 's1', 'name': 'Mandalay', 'sequence': 1},
              {'id': 's2', 'name': 'Meiktila', 'sequence': 2},
              {'id': 's3', 'name': 'Naypyidaw', 'sequence': 3},
              {'id': 's4', 'name': 'Taungoo', 'sequence': 4},
              {'id': 's5', 'name': 'Yangon', 'sequence': 5},
            ],
          },
          'status': 'planned',
          'service_date': '2026-07-30',
          'planned_departure_at': '2026-07-30T08:00:00+06:30',
        },
      ];
    }
    return [];
  }
}
