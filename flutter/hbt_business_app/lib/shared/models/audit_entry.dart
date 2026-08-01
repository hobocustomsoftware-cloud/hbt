/// A single audit log entry recording an operation performed at a counter.
///
/// Every business operation (ticket sale, cargo acceptance, refund,
/// expense, shift event) produces an audit entry with the identity of
/// who performed it, where (counter), on which device, and when.
class AuditEntry {
  final String? id;
  final String organizationId;
  final String action;
  final String resourceType;
  final String resourceId;
  final String? counterId;
  final String? branchId;
  final String? userId;
  final String? deviceId;
  final Map<String, dynamic>? details;
  final String createdAt;

  AuditEntry({
    this.id,
    required this.organizationId,
    required this.action,
    required this.resourceType,
    required this.resourceId,
    this.counterId,
    this.branchId,
    this.userId,
    this.deviceId,
    this.details,
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toUtc().toIso8601String();

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'organization_id': organizationId,
        'action': action,
        'resource_type': resourceType,
        'resource_id': resourceId,
        if (counterId != null) 'counter_id': counterId,
        if (branchId != null) 'branch_id': branchId,
        if (userId != null) 'user_id': userId,
        if (deviceId != null) 'device_id': deviceId,
        if (details != null) 'details': details,
        'created_at': createdAt,
      };

  factory AuditEntry.fromJson(Map<String, dynamic> json) => AuditEntry(
        id: json['id']?.toString(),
        organizationId: json['organization_id']?.toString() ?? '',
        action: json['action']?.toString() ?? '',
        resourceType: json['resource_type']?.toString() ?? '',
        resourceId: json['resource_id']?.toString() ?? '',
        counterId: json['counter_id']?.toString(),
        branchId: json['branch_id']?.toString(),
        userId: json['user_id']?.toString(),
        deviceId: json['device_id']?.toString(),
        details: json['details'] as Map<String, dynamic>?,
        createdAt: json['created_at']?.toString(),
      );
}
