/// Dashboard domain models — mirror the backend owner-dashboard snapshot
/// (apps/operations/dashboard.py). Every value maps to a real aggregate
/// from the API; nothing here is seeded or faked.
library;

import 'package:flutter/foundation.dart';

import '../../core/theme/hbt_tokens.dart';

/// Aggregation window for dashboard KPIs.
enum DashboardPeriod {
  day('day', 'Day'),
  week('week', 'Week'),
  month('month', 'Month'),
  year('year', 'Year');

  const DashboardPeriod(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static DashboardPeriod fromApi(String value) => DashboardPeriod.values
      .firstWhere((p) => p.apiValue == value, orElse: () => DashboardPeriod.day);
}

/// A named KPI row with a real numeric value.
@immutable
class KpiValue {
  const KpiValue({
    required this.label,
    required this.value,
    this.subtitle,
    this.tone = KpiTone.normal,
    this.drill,
  });

  final String label;
  final double value;
  final String? subtitle;

  /// Alert tone when the value crosses a threshold (delayed/cancelled…).
  final KpiTone tone;

  /// Optional semantic drill target id (handled by the screen).
  final String? drill;

  String get formattedValue => _format(value);

  static String _format(double v) {
    // Integer values render without decimals; large money values get
    // thousands separators.
    final rounded = v.round();
    final s = rounded.abs() >= 1000
        ? rounded.toString().replaceAllMapped(
            RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')
        : rounded.toString();
    return v < 0 ? '-$s' : s;
  }
}

@immutable
class MoneySummary {
  const MoneySummary({
    required this.ticketRevenue,
    required this.cargoRevenue,
    required this.totalRevenue,
    this.confirmedPayments = const [],
  });

  final double ticketRevenue;
  final double cargoRevenue;
  final double totalRevenue;
  final List<PaymentMethodTotal> confirmedPayments;

  factory MoneySummary.fromJson(Map<String, dynamic> json) => MoneySummary(
        ticketRevenue: _num(json['ticket_revenue']),
        cargoRevenue: _num(json['cargo_revenue']),
        totalRevenue: _num(json['total_revenue']),
        confirmedPayments: [
          for (final item in (json['confirmed_payments'] as List? ?? []))
            if (item is Map<String, dynamic>)
              PaymentMethodTotal.fromJson(item),
        ],
      );
}

@immutable
class PaymentMethodTotal {
  const PaymentMethodTotal({
    required this.method,
    required this.amount,
    required this.count,
  });

  final String method;
  final double amount;
  final int count;

  factory PaymentMethodTotal.fromJson(Map<String, dynamic> json) =>
      PaymentMethodTotal(
        method: json['method']?.toString() ?? '',
        amount: _num(json['amount']),
        count: (json['count'] as num?)?.toInt() ?? 0,
      );
}

@immutable
class TripOpsSummary {
  const TripOpsSummary({
    required this.total,
    required this.running,
    required this.delayed,
    required this.cancelled,
    required this.completed,
    required this.passengers,
    required this.cargoToday,
    required this.onTimePercent,
  });

  final int total;
  final int running;
  final int delayed;
  final int cancelled;
  final int completed;
  final int passengers;
  final int cargoToday;

  /// Null when no trips have departed yet.
  final double? onTimePercent;

  factory TripOpsSummary.fromJson(Map<String, dynamic> json) => TripOpsSummary(
        total: (json['total'] as num?)?.toInt() ?? 0,
        running: (json['running'] as num?)?.toInt() ?? 0,
        delayed: (json['delayed'] as num?)?.toInt() ?? 0,
        cancelled: (json['cancelled'] as num?)?.toInt() ?? 0,
        completed: (json['completed'] as num?)?.toInt() ?? 0,
        passengers: (json['passengers'] as num?)?.toInt() ?? 0,
        cargoToday: (json['cargo_today'] as num?)?.toInt() ?? 0,
        onTimePercent: (json['on_time_percent'] as num?)?.toDouble(),
      );
}

@immutable
class CargoOpsSummary {
  const CargoOpsSummary({
    required this.accepted,
    required this.inTransit,
    required this.readyForPickup,
    required this.exceptions,
  });

  final int accepted;
  final int inTransit;
  final int readyForPickup;
  final int exceptions;

  factory CargoOpsSummary.fromJson(Map<String, dynamic> json) =>
      CargoOpsSummary(
        accepted: (json['accepted'] as num?)?.toInt() ?? 0,
        inTransit: (json['in_transit'] as num?)?.toInt() ?? 0,
        readyForPickup: (json['ready_for_pickup'] as num?)?.toInt() ?? 0,
        exceptions: (json['exceptions'] as num?)?.toInt() ?? 0,
      );
}

@immutable
class BookingSummary {
  const BookingSummary({
    required this.total,
    required this.confirmed,
    required this.cancelled,
    required this.expired,
  });

  final int total;
  final int confirmed;
  final int cancelled;
  final int expired;

  factory BookingSummary.fromJson(Map<String, dynamic> json) => BookingSummary(
        total: (json['total'] as num?)?.toInt() ?? 0,
        confirmed: (json['confirmed'] as num?)?.toInt() ?? 0,
        cancelled: (json['cancelled'] as num?)?.toInt() ?? 0,
        expired: (json['expired'] as num?)?.toInt() ?? 0,
      );
}

@immutable
class PendingRefundSummary {
  const PendingRefundSummary({required this.count, required this.amount});

  final int count;
  final double amount;

  factory PendingRefundSummary.fromJson(Map<String, dynamic> json) =>
      PendingRefundSummary(
        count: (json['count'] as num?)?.toInt() ?? 0,
        amount: _num(json['amount']),
      );
}

@immutable
class CashPendingSummary {
  const CashPendingSummary({
    required this.cashInCounters,
    required this.pendingRefunds,
    required this.pendingApprovals,
  });

  final double cashInCounters;
  final PendingRefundSummary pendingRefunds;
  final int pendingApprovals;

  factory CashPendingSummary.fromJson(Map<String, dynamic> json) =>
      CashPendingSummary(
        cashInCounters: _num(json['cash_in_counters']),
        pendingRefunds: PendingRefundSummary.fromJson(
          (json['pending_refunds'] as Map<String, dynamic>?) ?? const {},
        ),
        pendingApprovals: (json['pending_approvals'] as num?)?.toInt() ?? 0,
      );
}

@immutable
class RatioValue {
  const RatioValue({required this.count, required this.total});

  final int count;
  final int total;

  factory RatioValue.fromJson(Map<String, dynamic> json) => RatioValue(
        count: (json['count'] as num?)?.toInt() ?? 0,
        total: (json['total'] as num?)?.toInt() ?? 0,
      );
}

@immutable
class DriverAttendanceSummary {
  const DriverAttendanceSummary({required this.onDuty, required this.total});

  final int onDuty;
  final int total;

  factory DriverAttendanceSummary.fromJson(Map<String, dynamic> json) =>
      DriverAttendanceSummary(
        onDuty: (json['on_duty'] as num?)?.toInt() ?? 0,
        total: (json['total'] as num?)?.toInt() ?? 0,
      );
}

@immutable
class FleetPeopleSummary {
  const FleetPeopleSummary({
    required this.vehiclesRunning,
    required this.vehiclesMaintenance,
    required this.driverAttendance,
  });

  final RatioValue vehiclesRunning;
  final int vehiclesMaintenance;
  final DriverAttendanceSummary driverAttendance;

  factory FleetPeopleSummary.fromJson(Map<String, dynamic> json) =>
      FleetPeopleSummary(
        vehiclesRunning: RatioValue.fromJson(
          (json['vehicles_running'] as Map<String, dynamic>?) ?? const {},
        ),
        vehiclesMaintenance:
            (json['vehicles_maintenance'] as num?)?.toInt() ?? 0,
        driverAttendance: DriverAttendanceSummary.fromJson(
          (json['driver_attendance'] as Map<String, dynamic>?) ?? const {},
        ),
      );
}

@immutable
class TrendPoint {
  const TrendPoint({
    required this.label,
    required this.ticket,
    required this.cargo,
    required this.total,
  });

  final String label;
  final double ticket;
  final double cargo;
  final double total;

  factory TrendPoint.fromJson(Map<String, dynamic> json) => TrendPoint(
        label: json['label']?.toString() ?? '',
        ticket: _num(json['ticket']),
        cargo: _num(json['cargo']),
        total: _num(json['total']),
      );
}

@immutable
class RankingRow {
  const RankingRow({
    required this.name,
    required this.revenue,
    required this.trips,
  });

  final String name;
  final double revenue;
  final int trips;

  factory RankingRow.fromJson(Map<String, dynamic> json) => RankingRow(
        name: json['name']?.toString() ?? '',
        revenue: _num(json['revenue']),
        trips: (json['trips'] as num?)?.toInt() ?? 0,
      );
}

@immutable
class RankingsSummary {
  const RankingsSummary({
    required this.branches,
    required this.routes,
    required this.vehicles,
  });

  final List<RankingRow> branches;
  final List<RankingRow> routes;
  final List<RankingRow> vehicles;

  factory RankingsSummary.fromJson(Map<String, dynamic> json) =>
      RankingsSummary(
        branches: _rows(json['branches']),
        routes: _rows(json['routes']),
        vehicles: _rows(json['vehicles']),
      );

  static List<RankingRow> _rows(Object? value) => [
        for (final item in (value as List? ?? []))
          if (item is Map<String, dynamic>) RankingRow.fromJson(item),
      ];
}

@immutable
class ActivityItem {
  const ActivityItem({
    required this.actor,
    required this.action,
    required this.resourceType,
    required this.occurredAt,
  });

  final String actor;
  final String action;
  final String resourceType;
  final DateTime occurredAt;

  factory ActivityItem.fromJson(Map<String, dynamic> json) => ActivityItem(
        actor: json['actor']?.toString() ?? '',
        action: json['action']?.toString() ?? '',
        resourceType: json['resource_type']?.toString() ?? '',
        occurredAt:
            DateTime.tryParse(json['occurred_at']?.toString() ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0),
      );
}

@immutable
class AlertItem {
  const AlertItem({
    required this.severity,
    required this.message,
    required this.count,
  });

  final String severity; // info | warning | danger
  final String message;
  final int count;

  factory AlertItem.fromJson(Map<String, dynamic> json) => AlertItem(
        severity: json['severity']?.toString() ?? 'info',
        message: json['message']?.toString() ?? '',
        count: (json['count'] as num?)?.toInt() ?? 0,
      );
}

@immutable
class AnnouncementItem {
  const AnnouncementItem({
    required this.title,
    required this.body,
    required this.createdAt,
  });

  final String title;
  final String body;
  final DateTime createdAt;

  factory AnnouncementItem.fromJson(Map<String, dynamic> json) =>
      AnnouncementItem(
        title: json['title']?.toString() ?? '',
        body: json['body']?.toString() ?? '',
        createdAt:
            DateTime.tryParse(json['created_at']?.toString() ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0),
      );
}

@immutable
class PulseSummary {
  const PulseSummary({
    required this.activities,
    required this.alerts,
    required this.announcements,
  });

  final List<ActivityItem> activities;
  final List<AlertItem> alerts;
  final List<AnnouncementItem> announcements;

  factory PulseSummary.fromJson(Map<String, dynamic> json) => PulseSummary(
        activities: [
          for (final item in (json['activities'] as List? ?? []))
            if (item is Map<String, dynamic>) ActivityItem.fromJson(item),
        ],
        alerts: [
          for (final item in (json['alerts'] as List? ?? []))
            if (item is Map<String, dynamic>) AlertItem.fromJson(item),
        ],
        announcements: [
          for (final item in (json['announcements'] as List? ?? []))
            if (item is Map<String, dynamic>) AnnouncementItem.fromJson(item),
        ],
      );
}

/// The full owner dashboard snapshot.
@immutable
class DashboardSnapshot {
  const DashboardSnapshot({
    required this.date,
    required this.period,
    required this.dataFreshness,
    required this.money,
    required this.tripOps,
    required this.cargoOps,
    required this.bookings,
    required this.cashPending,
    required this.fleetPeople,
    required this.revenueTrend,
    required this.rankings,
    required this.pulse,
  });

  final DateTime date;
  final DashboardPeriod period;
  final DateTime dataFreshness;
  final MoneySummary money;
  final TripOpsSummary tripOps;
  final CargoOpsSummary cargoOps;
  final BookingSummary bookings;
  final CashPendingSummary cashPending;
  final FleetPeopleSummary fleetPeople;
  final List<TrendPoint> revenueTrend;
  final RankingsSummary rankings;
  final PulseSummary pulse;

  factory DashboardSnapshot.fromJson(Map<String, dynamic> json) =>
      DashboardSnapshot(
        date: DateTime.tryParse(json['date']?.toString() ?? '') ??
            DateTime.now(),
        period: DashboardPeriod.fromApi(json['period']?.toString() ?? 'day'),
        dataFreshness:
            DateTime.tryParse(json['data_freshness']?.toString() ?? '') ??
                DateTime.now(),
        money: MoneySummary.fromJson(
          (json['money'] as Map<String, dynamic>?) ?? const {},
        ),
        tripOps: TripOpsSummary.fromJson(
          (json['trip_ops'] as Map<String, dynamic>?) ?? const {},
        ),
        cargoOps: CargoOpsSummary.fromJson(
          (json['cargo_ops'] as Map<String, dynamic>?) ?? const {},
        ),
        bookings: BookingSummary.fromJson(
          (json['bookings'] as Map<String, dynamic>?) ?? const {},
        ),
        cashPending: CashPendingSummary.fromJson(
          (json['cash_pending'] as Map<String, dynamic>?) ?? const {},
        ),
        fleetPeople: FleetPeopleSummary.fromJson(
          (json['fleet_people'] as Map<String, dynamic>?) ?? const {},
        ),
        revenueTrend: [
          for (final item in (json['revenue_trend'] as List? ?? []))
            if (item is Map<String, dynamic>) TrendPoint.fromJson(item),
        ],
        rankings: RankingsSummary.fromJson(
          (json['rankings'] as Map<String, dynamic>?) ?? const {},
        ),
        pulse: PulseSummary.fromJson(
          (json['pulse'] as Map<String, dynamic>?) ?? const {},
        ),
      );
}

double _num(Object? value) =>
    value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '') ?? 0;
