/// Enum of all expense categories used in bus operations.
///
/// Each category maps to a display label and icon for UI use.
enum ExpenseCategory {
  driverSalary,
  spareSalary,
  counterSalary,
  fuel,
  vehicleRepair,
  tires,
  officeRent,
  electricity,
  internet,
  municipalTax,
  insurance,
  parking,
  toll,
  cleaning,
  miscellaneous;

  String get label {
    switch (this) {
      case ExpenseCategory.driverSalary:
        return 'Driver Salary';
      case ExpenseCategory.spareSalary:
        return 'Spare Salary';
      case ExpenseCategory.counterSalary:
        return 'Counter Salary';
      case ExpenseCategory.fuel:
        return 'Fuel';
      case ExpenseCategory.vehicleRepair:
        return 'Vehicle Repair';
      case ExpenseCategory.tires:
        return 'Tires';
      case ExpenseCategory.officeRent:
        return 'Office Rent';
      case ExpenseCategory.electricity:
        return 'Electricity';
      case ExpenseCategory.internet:
        return 'Internet';
      case ExpenseCategory.municipalTax:
        return 'Municipal Tax';
      case ExpenseCategory.insurance:
        return 'Insurance';
      case ExpenseCategory.parking:
        return 'Parking';
      case ExpenseCategory.toll:
        return 'Toll';
      case ExpenseCategory.cleaning:
        return 'Cleaning';
      case ExpenseCategory.miscellaneous:
        return 'Miscellaneous';
    }
  }

  String get apiValue => name;

  static ExpenseCategory fromString(String value) =>
      ExpenseCategory.values.firstWhere(
        (c) => c.name == value,
        orElse: () => ExpenseCategory.miscellaneous,
      );

  /// Expense grouping for report views.
  ExpenseGroup get group {
    switch (this) {
      case ExpenseCategory.driverSalary:
      case ExpenseCategory.spareSalary:
      case ExpenseCategory.counterSalary:
        return ExpenseGroup.staff;
      case ExpenseCategory.fuel:
      case ExpenseCategory.vehicleRepair:
      case ExpenseCategory.tires:
      case ExpenseCategory.parking:
      case ExpenseCategory.toll:
      case ExpenseCategory.cleaning:
        return ExpenseGroup.vehicle;
      case ExpenseCategory.officeRent:
      case ExpenseCategory.electricity:
      case ExpenseCategory.internet:
        return ExpenseGroup.office;
      case ExpenseCategory.municipalTax:
      case ExpenseCategory.insurance:
        return ExpenseGroup.admin;
      case ExpenseCategory.miscellaneous:
        return ExpenseGroup.other;
    }
  }
}

/// High-level expense grouping for reporting.
enum ExpenseGroup {
  staff,
  vehicle,
  office,
  admin,
  other;

  String get label {
    switch (this) {
      case ExpenseGroup.staff:
        return 'Staff';
      case ExpenseGroup.vehicle:
        return 'Vehicle';
      case ExpenseGroup.office:
        return 'Office';
      case ExpenseGroup.admin:
        return 'Admin';
      case ExpenseGroup.other:
        return 'Other';
    }
  }
}

/// Date range filter for expense reports.
enum ExpenseDateRange {
  all,
  today,
  thisWeek,
  thisMonth,
  custom;

  String get label {
    switch (this) {
      case ExpenseDateRange.all:
        return 'All';
      case ExpenseDateRange.today:
        return 'Today';
      case ExpenseDateRange.thisWeek:
        return 'This Week';
      case ExpenseDateRange.thisMonth:
        return 'This Month';
      case ExpenseDateRange.custom:
        return 'Custom';
    }
  }
}

/// A single expense record.
class Expense {
  final String? id;
  final String organizationId;
  final ExpenseCategory category;
  final double amount;
  final String? description;
  final String? vehicleId;
  final String? tripId;
  final DateTime expenseDate;
  final String? receiptNumber;
  final String? paidTo;
  final String status;
  final String? approvedBy;
  final String? createdAt;
  final String? updatedAt;

  const Expense({
    this.id,
    required this.organizationId,
    required this.category,
    required this.amount,
    this.description,
    this.vehicleId,
    this.tripId,
    required this.expenseDate,
    this.receiptNumber,
    this.paidTo,
    this.status = 'pending',
    this.approvedBy,
    this.createdAt,
    this.updatedAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id']?.toString(),
        organizationId: json['organization_id']?.toString() ?? '',
        category:
            ExpenseCategory.fromString(json['category']?.toString() ?? ''),
        amount: _parseDouble(json['amount']),
        description: json['description']?.toString(),
        vehicleId: json['vehicle_id']?.toString(),
        tripId: json['trip_id']?.toString(),
        expenseDate: _parseDate(json['expense_date']),
        receiptNumber: json['receipt_number']?.toString(),
        paidTo: json['paid_to']?.toString(),
        status: json['status']?.toString() ?? 'pending',
        approvedBy: json['approved_by']?.toString(),
        createdAt: json['created_at']?.toString(),
        updatedAt: json['updated_at']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'organization_id': organizationId,
        'category': category.apiValue,
        'amount': amount,
        if (description != null) 'description': description,
        if (vehicleId != null) 'vehicle_id': vehicleId,
        if (tripId != null) 'trip_id': tripId,
        'expense_date': _formatDate(expenseDate),
        if (receiptNumber != null) 'receipt_number': receiptNumber,
        if (paidTo != null) 'paid_to': paidTo,
        'status': status,
      };

  static double _parseDouble(dynamic v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v?.toString() ?? '0') ?? 0;
  }

  static DateTime _parseDate(dynamic v) {
    if (v is DateTime) return v;
    final parsed = DateTime.tryParse(v?.toString() ?? '');
    return parsed ?? DateTime.now();
  }

  static String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
