/// A physical or logical branch/terminal location.
class Branch {
  final String id;
  final String code;
  final String name;
  final String? city;
  final String? address;

  const Branch({
    required this.id,
    required this.code,
    required this.name,
    this.city,
    this.address,
  });

  factory Branch.fromJson(Map<String, dynamic> json) => Branch(
        id: json['id']?.toString() ?? '',
        code: json['code']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        city: json['city']?.toString(),
        address: json['address']?.toString(),
      );
}

/// A specific sales counter within a branch.
class Counter {
  final String id;
  final String branchId;
  final String code;
  final String? displayName;
  final String status;

  const Counter({
    required this.id,
    required this.branchId,
    required this.code,
    this.displayName,
    this.status = 'active',
  });

  factory Counter.fromJson(Map<String, dynamic> json) => Counter(
        id: json['id']?.toString() ?? '',
        branchId: json['branch_id']?.toString() ?? '',
        code: json['code']?.toString() ?? '',
        displayName: json['display_name']?.toString(),
        status: json['status']?.toString() ?? 'active',
      );
}

/// Status of a counter shift.
enum ShiftStatus {
  opened,
  active,
  closed;

  String get value => name;

  static ShiftStatus fromString(String value) =>
      ShiftStatus.values.firstWhere(
        (s) => s.name == value,
        orElse: () => ShiftStatus.closed,
      );
}

/// A single work shift at a counter.
///
/// Tracks opening/closing cash, all revenue and expense sources,
/// and time period. Integrates with ticket sales, cargo, expenses,
/// and profit & loss reporting.
class Shift {
  final String? id;
  final String branchId;
  final String counterId;
  final String staffUserId;
  final String organizationId;
  final ShiftStatus status;
  final double openingCash;
  final double? closingCash;
  final double? expectedCash;
  final double? cashDifference;
  final String? differenceReason;
  final int ticketSalesCount;
  final int cargoCount;
  final int refundCount;
  final int expenseCount;
  final double ticketRevenue;
  final double cargoRevenue;
  final double expenseTotal;
  final double totalRevenue;
  final String? openedAt;
  final String? closedAt;
  final String createdAt;

  const Shift({
    this.id,
    required this.branchId,
    required this.counterId,
    required this.staffUserId,
    required this.organizationId,
    this.status = ShiftStatus.opened,
    this.openingCash = 0,
    this.closingCash,
    this.expectedCash,
    this.cashDifference,
    this.differenceReason,
    this.ticketSalesCount = 0,
    this.cargoCount = 0,
    this.refundCount = 0,
    this.expenseCount = 0,
    this.ticketRevenue = 0,
    this.cargoRevenue = 0,
    this.expenseTotal = 0,
    this.totalRevenue = 0,
    this.openedAt,
    this.closedAt,
    required this.createdAt,
  });

  /// Net revenue after expenses (for P&L integration).
  double get netRevenue => totalRevenue - expenseTotal;

  factory Shift.fromJson(Map<String, dynamic> json) => Shift(
        id: json['id']?.toString(),
        branchId: json['branch_id']?.toString() ?? '',
        counterId: json['counter_id']?.toString() ?? '',
        staffUserId: json['staff_user_id']?.toString() ?? '',
        organizationId: json['organization_id']?.toString() ?? '',
        status: ShiftStatus.fromString(json['status']?.toString() ?? 'opened'),
        openingCash: _pDouble(json['opening_cash']),
        closingCash: _pDoubleN(json['closing_cash']),
        expectedCash: _pDoubleN(json['expected_cash']),
        cashDifference: _pDoubleN(json['cash_difference']),
        differenceReason: json['difference_reason']?.toString(),
        ticketSalesCount: _pInt(json['ticket_sales_count']),
        cargoCount: _pInt(json['cargo_count']),
        refundCount: _pInt(json['refund_count']),
        expenseCount: _pInt(json['expense_count']),
        ticketRevenue: _pDouble(json['ticket_revenue']),
        cargoRevenue: _pDouble(json['cargo_revenue']),
        expenseTotal: _pDouble(json['expense_total']),
        totalRevenue: _pDouble(json['total_revenue']),
        openedAt: json['opened_at']?.toString(),
        closedAt: json['closed_at']?.toString(),
        createdAt: json['created_at']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'branch_id': branchId,
        'counter_id': counterId,
        'staff_user_id': staffUserId,
        'organization_id': organizationId,
        'status': status.value,
        'opening_cash': openingCash,
        if (closingCash != null) 'closing_cash': closingCash,
        if (expectedCash != null) 'expected_cash': expectedCash,
        if (cashDifference != null) 'cash_difference': cashDifference,
        if (differenceReason != null) 'difference_reason': differenceReason,
        'ticket_sales_count': ticketSalesCount,
        'cargo_count': cargoCount,
        'refund_count': refundCount,
        'expense_count': expenseCount,
        'ticket_revenue': ticketRevenue,
        'cargo_revenue': cargoRevenue,
        'expense_total': expenseTotal,
        'total_revenue': totalRevenue,
        'opened_at': openedAt,
        'closed_at': closedAt,
        'created_at': createdAt,
      };

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

  static int _pInt(dynamic v) {
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '0') ?? 0;
  }
}
