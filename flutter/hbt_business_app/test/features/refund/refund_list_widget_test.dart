import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hbt_business_app/shared/services/api_client.dart';
import 'package:hbt_business_app/core/widgets/async_views.dart';
import 'package:hbt_business_app/features/refund/screens/refund_list_page.dart';
import 'package:hbt_business_app/features/auth/controllers/session_controller.dart';
import 'package:hbt_business_app/shared/models/organization_context.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('RefundListPage', () {
    Widget _buildPage(ApiClient api) {
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
        permissions: {'refund.view', 'refund.request'},
      );
      return wrapInApp(RefundListPage(session: session));
    }

    testWidgets('shows LoadingView on initial load', (tester) async {
      await tester.pumpWidget(_buildPage(_HangingApi()));
      await tester.pump();
      expect(find.byType(LoadingView), findsOneWidget);
    });

    testWidgets('shows ErrorView on API failure', (tester) async {
      await tester.pumpWidget(_buildPage(_FailingApi()));
      await tester.pumpAndSettle();

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text('API error'), findsOneWidget);
    });

    testWidgets('shows EmptyView when no refunds', (tester) async {
      await tester.pumpWidget(_buildPage(_EmptyApi()));
      await tester.pumpAndSettle();

      expect(find.byType(EmptyView), findsOneWidget);
      expect(find.text('No refund requests'), findsOneWidget);
    });

    testWidgets('shows refund list with status chips', (tester) async {
      await tester.pumpWidget(_buildPage(_RefundListApi()));
      await tester.pumpAndSettle();

      expect(find.text('RF-001'), findsOneWidget);
      expect(find.text('RF-002'), findsOneWidget);
      expect(find.textContaining('Amount:'), findsWidgets);
    });

    testWidgets('status filter chips are interactive', (tester) async {
      await tester.pumpWidget(_buildPage(_RefundListApi()));
      await tester.pumpAndSettle();

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Requested'), findsOneWidget);

      await tester.tap(find.text('Requested'));
      await tester.pump();
    });
  });
}

class _HangingApi extends ApiClient {
  _HangingApi() : super(baseUrl: 'https://test.example.com');

  @override
  Future<List<dynamic>> getList(String path) async {
    return Completer<List<dynamic>>().future;
  }
}

class _FailingApi extends ApiClient {
  _FailingApi() : super(baseUrl: 'https://test.example.com');

  @override
  Future<List<dynamic>> getList(String path) async {
    throw ApiException('API error');
  }
}

class _EmptyApi extends ApiClient {
  _EmptyApi() : super(baseUrl: 'https://test.example.com');

  @override
  Future<List<dynamic>> getList(String path) async {
    return [];
  }
}

class _RefundListApi extends ApiClient {
  _RefundListApi() : super(baseUrl: 'https://test.example.com');

  @override
  Future<List<dynamic>> getList(String path) async {
    return [
      {
        'id': 'rf-1',
        'refund_number': 'RF-001',
        'status': 'paid',
        'requested_amount': '50000',
        'currency': 'MMK',
        'reason': 'Customer cancelled',
      },
      {
        'id': 'rf-2',
        'refund_number': 'RF-002',
        'status': 'requested',
        'requested_amount': '30000',
        'currency': 'MMK',
        'reason': 'Overcharge',
      },
    ];
  }
}
