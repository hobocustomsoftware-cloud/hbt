import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hbt_business_app/core/theme/hbt_theme.dart';
import 'package:hbt_business_app/features/dashboard/dashboard_controller.dart';
import 'package:hbt_business_app/features/dashboard/dashboard_models.dart';
import 'package:hbt_business_app/features/dashboard/dashboard_repository.dart';
import 'package:hbt_business_app/features/dashboard/owner_dashboard_screen.dart';
import 'package:hbt_business_app/features/auth/controllers/session_controller.dart';
import 'package:hbt_business_app/shared/models/organization_context.dart';
import 'package:hbt_business_app/shared/services/api_client.dart';

import '../../helpers/test_helpers.dart';

/// A repository that serves a fixed snapshot — the production repository is
/// ApiDashboardRepository (real HTTP); tests inject this to stay offline.
class FakeDashboardRepository implements DashboardRepository {
  FakeDashboardRepository({this.snapshot, this.error});

  DashboardSnapshot? snapshot;
  Object? error;
  String? lastOrganizationId;
  DashboardPeriod? lastPeriod;

  @override
  Future<DashboardSnapshot> fetch({
    required String organizationId,
    required DashboardPeriod period,
  }) async {
    lastOrganizationId = organizationId;
    lastPeriod = period;
    if (error != null) throw error!;
    return snapshot!;
  }
}

DashboardSnapshot _sampleSnapshot() => DashboardSnapshot(
      date: DateTime(2026, 8, 4),
      period: DashboardPeriod.day,
      dataFreshness: DateTime(2026, 8, 4, 14),
      money: const MoneySummary(
        ticketRevenue: 12000000,
        cargoRevenue: 5000000,
        totalRevenue: 17000000,
        confirmedPayments: [
          PaymentMethodTotal(method: 'cash', amount: 9000000, count: 45),
        ],
      ),
      tripOps: const TripOpsSummary(
        total: 10,
        running: 4,
        delayed: 2,
        cancelled: 1,
        completed: 5,
        passengers: 120,
        cargoToday: 8,
        onTimePercent: 88.5,
      ),
      cargoOps: const CargoOpsSummary(
        accepted: 8,
        inTransit: 3,
        readyForPickup: 2,
        exceptions: 1,
      ),
      bookings: const BookingSummary(
        total: 30,
        confirmed: 25,
        cancelled: 2,
        expired: 3,
      ),
      cashPending: const CashPendingSummary(
        cashInCounters: 4200000,
        pendingRefunds: PendingRefundSummary(count: 2, amount: 900000),
        pendingApprovals: 2,
      ),
      fleetPeople: const FleetPeopleSummary(
        vehiclesRunning: RatioValue(count: 40, total: 45),
        vehiclesMaintenance: 5,
        driverAttendance: DriverAttendanceSummary(onDuty: 18, total: 20),
      ),
      revenueTrend: const [
        TrendPoint(label: '2026-07-22', ticket: 1, cargo: 0, total: 1),
        TrendPoint(label: '2026-08-04', ticket: 2, cargo: 1, total: 3),
      ],
      rankings: const RankingsSummary(
        branches: [
          RankingRow(name: 'Yangon Central', revenue: 8000000, trips: 6),
        ],
        routes: [
          RankingRow(name: 'YGN → MDY', revenue: 6000000, trips: 5),
        ],
        vehicles: [
          RankingRow(name: 'YK 1234', revenue: 4000000, trips: 4),
        ],
      ),
      pulse: PulseSummary(
        activities: [
          ActivityItem(
            actor: 'U Ko',
            action: 'issued_ticket',
            resourceType: 'ticket',
            occurredAt: DateTime(2026, 8, 4, 13),
          ),
        ],
        alerts: const [
          AlertItem(severity: 'warning', message: '2 delayed trip(s)', count: 2),
        ],
        announcements: const [],
      ),
    );

SessionController _session() {
  final session = SessionController(
    api: MockApiClient(),
    storage: MockStorage(),
  );
  session.loading = false;
  session.authenticated = true;
  session.activeOrganization = OrganizationContext(
    organization: OrganizationSummary(
      id: 'org-001',
      displayName: 'Test Bus Co.',
      status: 'active',
    ),
    permissions: const {'report.owner', 'refund.view'},
  );
  return session;
}

void main() {
  group('DashboardSnapshot.fromJson', () {
    test('parses a full snapshot', () {
      final json = {
        'date': '2026-08-04',
        'period': 'week',
        'data_freshness': '2026-08-04T14:00:00Z',
        'money': {
          'ticket_revenue': '12000000.00',
          'cargo_revenue': '5000000.00',
          'total_revenue': '17000000.00',
          'confirmed_payments': [
            {'method': 'cash', 'amount': '9000000.00', 'count': 45},
          ],
        },
        'trip_ops': {
          'total': 10,
          'running': 4,
          'delayed': 2,
          'cancelled': 1,
          'completed': 5,
          'passengers': 120,
          'cargo_today': 8,
          'on_time_percent': 88.5,
        },
        'cargo_ops': {
          'accepted': 8,
          'in_transit': 3,
          'ready_for_pickup': 2,
          'exceptions': 1,
        },
        'bookings': {'total': 30, 'confirmed': 25, 'cancelled': 2, 'expired': 3},
        'cash_pending': {
          'cash_in_counters': '4200000.00',
          'pending_refunds': {'count': 2, 'amount': '900000.00'},
          'pending_approvals': 2,
        },
        'fleet_people': {
          'vehicles_running': {'count': 40, 'total': 45},
          'vehicles_maintenance': 5,
          'driver_attendance': {'on_duty': 18, 'total': 20},
        },
        'revenue_trend': [
          {'label': '2026-08-04', 'ticket': '2.00', 'cargo': '1.00', 'total': '3.00'},
        ],
        'rankings': {
          'branches': [
            {'name': 'Yangon Central', 'revenue': '8000000.00', 'trips': 6},
          ],
          'routes': [
            {'name': 'YGN → MDY', 'revenue': '6000000.00', 'trips': 5},
          ],
          'vehicles': [
            {'name': 'YK 1234', 'revenue': '4000000.00', 'trips': 4},
          ],
        },
        'pulse': {
          'activities': [
            {
              'actor': 'U Ko',
              'action': 'issued_ticket',
              'resource_type': 'ticket',
              'occurred_at': '2026-08-04T13:00:00Z',
            },
          ],
          'alerts': [
            {'severity': 'warning', 'message': '2 delayed trip(s)', 'count': 2},
          ],
          'announcements': [],
        },
      };

      final snapshot = DashboardSnapshot.fromJson(json);
      expect(snapshot.period, DashboardPeriod.week);
      expect(snapshot.money.totalRevenue, 17000000);
      expect(snapshot.tripOps.delayed, 2);
      expect(snapshot.tripOps.onTimePercent, 88.5);
      expect(snapshot.rankings.routes.first.name, 'YGN → MDY');
      expect(snapshot.pulse.alerts.first.severity, 'warning');
      expect(snapshot.cashPending.pendingApprovals, 2);
    });

    test('tolerates missing sections (backend not yet supporting them)', () {
      final snapshot = DashboardSnapshot.fromJson({
        'date': '2026-08-04',
        'period': 'day',
        'data_freshness': '2026-08-04T14:00:00Z',
      });
      expect(snapshot.money.totalRevenue, 0);
      expect(snapshot.tripOps.running, 0);
      expect(snapshot.revenueTrend, isEmpty);
      expect(snapshot.pulse.alerts, isEmpty);
    });
  });

  group('DashboardController', () {
    test('loads a snapshot and records period + org', () async {
      final repo = FakeDashboardRepository(snapshot: _sampleSnapshot());
      final controller = DashboardController(repository: repo);
      controller.organizationId = 'org-001';

      await controller.load();

      expect(controller.hasData, isTrue);
      expect(repo.lastOrganizationId, 'org-001');
      expect(repo.lastPeriod, DashboardPeriod.day);
    });

    test('setPeriod reloads with the new period', () async {
      final repo = FakeDashboardRepository(snapshot: _sampleSnapshot());
      final controller = DashboardController(repository: repo);

      await controller.setPeriod(DashboardPeriod.month);

      expect(controller.period, DashboardPeriod.month);
      expect(repo.lastPeriod, DashboardPeriod.month);
    });

    test('surfaces errors and keeps no snapshot', () async {
      final repo = FakeDashboardRepository(
        error: const ApiException('Server နှင့် ချိတ်ဆက်မရပါ။'),
      );
      final controller = DashboardController(repository: repo);

      await controller.load();

      expect(controller.hasData, isFalse);
      expect(controller.error, contains('Server'));
    });
  });

  group('OwnerDashboardScreen', () {
    testWidgets('renders real KPI values, alerts and rankings',
        (tester) async {
      final controller = DashboardController(
        repository: FakeDashboardRepository(snapshot: _sampleSnapshot()),
      )..organizationId = 'org-001';
      final session = _session();

      await tester.pumpWidget(MaterialApp(
        theme: HbtTheme.light(),
        home: OwnerDashboardScreen(controller: controller, session: session),
      ));
      await tester.pumpAndSettle();

      // Money zone (top of the dashboard).
      expect(find.text('17,000,000'), findsOneWidget); // total revenue
      expect(find.text('Trip Operations'), findsOneWidget);

      // Scroll to the alerts / rankings zones (below the fold).
      await tester.scrollUntilVisible(
        find.text('2 delayed trip(s)'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('2 delayed trip(s)'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('YGN → MDY'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('YGN → MDY'), findsOneWidget);
      expect(find.text('Yangon Central'), findsOneWidget);
      expect(find.text('YK 1234'), findsOneWidget);
    });

    testWidgets('shows error view with retry when the API fails',
        (tester) async {
      final controller = DashboardController(
        repository: FakeDashboardRepository(
          error: const ApiException('Network error'),
        ),
      )..organizationId = 'org-001';
      final session = _session();

      await tester.pumpWidget(MaterialApp(
        theme: HbtTheme.light(),
        home: OwnerDashboardScreen(controller: controller, session: session),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
