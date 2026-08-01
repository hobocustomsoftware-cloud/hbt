class OrganizationSummary {
  const OrganizationSummary({
    required this.id,
    required this.displayName,
    required this.status,
  });

  final String id;
  final String displayName;
  final String status;

  factory OrganizationSummary.fromJson(Map<String, dynamic> json) =>
      OrganizationSummary(
        id: json['id'] as String,
        displayName: json['display_name'] as String? ?? '',
        status: json['status'] as String? ?? '',
      );
}

class OrganizationContext {
  const OrganizationContext({
    required this.organization,
    required this.permissions,
  });

  final OrganizationSummary organization;
  final Set<String> permissions;

  factory OrganizationContext.fromJson(Map<String, dynamic> json) {
    final permissions = json['permissions'];
    return OrganizationContext(
      organization: OrganizationSummary.fromJson(
        json['organization'] as Map<String, dynamic>,
      ),
      permissions: {
        if (permissions is List<dynamic>)
          ...permissions.whereType<String>(),
      },
    );
  }
}
