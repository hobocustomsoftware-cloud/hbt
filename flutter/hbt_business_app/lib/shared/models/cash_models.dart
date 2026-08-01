/// Cash reconciliation data aggregated for a shift.
///
/// Expected cash = Opening cash + Cash sales - Cash refunds paid - Cash expenses
/// Difference = Actual cash counted - Expected cash
class ShiftCashData {
  final double openingCash;
  final double cashTicketSales;
  final double cashCargoRevenue;
  final double cashRefundsPaid;
  final double cashExpenses;
  final double cashOther;
  final double? actualCash;

  const ShiftCashData({
    this.openingCash = 0,
    this.cashTicketSales = 0,
    this.cashCargoRevenue = 0,
    this.cashRefundsPaid = 0,
    this.cashExpenses = 0,
    this.cashOther = 0,
    this.actualCash,
  });

  double get totalCashIn => cashTicketSales + cashCargoRevenue + cashOther;

  double get totalCashOut => cashRefundsPaid + cashExpenses;

  double get netCashMovement => totalCashIn - totalCashOut;

  double get expectedCash => openingCash + netCashMovement;

  double? get difference =>
      actualCash != null ? actualCash! - expectedCash : null;

  Map<String, dynamic> toJson() => {
        'opening_cash': openingCash,
        'cash_ticket_sales': cashTicketSales,
        'cash_cargo_revenue': cashCargoRevenue,
        'cash_refunds_paid': cashRefundsPaid,
        'cash_expenses': cashExpenses,
        'cash_other': cashOther,
        if (actualCash != null) 'actual_cash': actualCash,
        'total_cash_in': totalCashIn,
        'total_cash_out': totalCashOut,
        'expected_cash': expectedCash,
        if (difference != null) 'difference': difference,
      };

  factory ShiftCashData.fromJson(Map<String, dynamic> json) => ShiftCashData(
        openingCash: _pDouble(json['opening_cash']),
        cashTicketSales: _pDouble(json['cash_ticket_sales']),
        cashCargoRevenue: _pDouble(json['cash_cargo_revenue']),
        cashRefundsPaid: _pDouble(json['cash_refunds_paid']),
        cashExpenses: _pDouble(json['cash_expenses']),
        cashOther: _pDouble(json['cash_other']),
        actualCash: _pDoubleN(json['actual_cash']),
      );

  static double _pDouble(dynamic v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v?.toString() ?? '0') ?? 0;
  }

  static double? _pDoubleN(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString());
  }
}

/// A single shift's cash reconciliation report.
class ShiftCashReport {
  final String shiftId;
  final String? counterName;
  final String? staffName;
  final String? openedAt;
  final String? closedAt;
  final ShiftCashData cashData;
  final String? differenceReason;
  final int ticketCount;
  final int cargoCount;
  final int refundCount;
  final int expenseCount;

  const ShiftCashReport({
    required this.shiftId,
    this.counterName,
    this.staffName,
    this.openedAt,
    this.closedAt,
    required this.cashData,
    this.differenceReason,
    this.ticketCount = 0,
    this.cargoCount = 0,
    this.refundCount = 0,
    this.expenseCount = 0,
  });

  factory ShiftCashReport.fromJson(Map<String, dynamic> json) =>
      ShiftCashReport(
        shiftId: json['shift_id']?.toString() ?? '',
        counterName: json['counter_name']?.toString(),
        staffName: json['staff_name']?.toString(),
        openedAt: json['opened_at']?.toString(),
        closedAt: json['closed_at']?.toString(),
        cashData: ShiftCashData.fromJson(
            json['cash_data'] as Map<String, dynamic>? ?? {}),
        differenceReason: json['difference_reason']?.toString(),
        ticketCount: json['ticket_count'] is int
            ? json['ticket_count'] as int
            : int.tryParse(json['ticket_count']?.toString() ?? '0') ?? 0,
        cargoCount: json['cargo_count'] is int
            ? json['cargo_count'] as int
            : int.tryParse(json['cargo_count']?.toString() ?? '0') ?? 0,
        refundCount: json['refund_count'] is int
            ? json['refund_count'] as int
            : int.tryParse(json['refund_count']?.toString() ?? '0') ?? 0,
        expenseCount: json['expense_count'] is int
            ? json['expense_count'] as int
            : int.tryParse(json['expense_count']?.toString() ?? '0') ?? 0,
      );
}

/// Daily cash reconciliation summary across all counters.
class DailyCashSummary {
  final String date;
  final int shiftCount;
  final double totalOpeningCash;
  final double totalCashSales;
  final double totalCashRefunds;
  final double totalCashExpenses;
  final double totalExpectedCash;
  final double totalActualCash;
  final double totalDifference;
  final int totalOverCount;
  final int totalShortCount;

  const DailyCashSummary({
    required this.date,
    this.shiftCount = 0,
    this.totalOpeningCash = 0,
    this.totalCashSales = 0,
    this.totalCashRefunds = 0,
    this.totalCashExpenses = 0,
    this.totalExpectedCash = 0,
    this.totalActualCash = 0,
    this.totalDifference = 0,
    this.totalOverCount = 0,
    this.totalShortCount = 0,
  });

  factory DailyCashSummary.fromJson(Map<String, dynamic> json) =>
      DailyCashSummary(
        date: json['date']?.toString() ?? '',
        shiftCount: json['shift_count'] is int
            ? json['shift_count'] as int
            : int.tryParse(json['shift_count']?.toString() ?? '0') ?? 0,
        totalOpeningCash: _pDouble(json['total_opening_cash']),
        totalCashSales: _pDouble(json['total_cash_sales']),
        totalCashRefunds: _pDouble(json['total_cash_refunds']),
        totalCashExpenses: _pDouble(json['total_cash_expenses']),
        totalExpectedCash: _pDouble(json['total_expected_cash']),
        totalActualCash: _pDouble(json['total_actual_cash']),
        totalDifference: _pDouble(json['total_difference']),
        totalOverCount: json['total_over_count'] is int
            ? json['total_over_count'] as int
            : int.tryParse(json['total_over_count']?.toString() ?? '0') ?? 0,
        totalShortCount: json['total_short_count'] is int
            ? json['total_short_count'] as int
            : int.tryParse(json['total_short_count']?.toString() ?? '0') ?? 0,
      );

  static double _pDouble(dynamic v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v?.toString() ?? '0') ?? 0;
  }
}
