import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../shared/services/api_client.dart';
import '../../../shared/models/organization_context.dart';

/// Manages organization context: list available orgs, switch active org,
/// load the full context (including permissions).
///
/// This controller is domain-level and does NOT manage auth state.
/// Auth is handled by [AuthController]; both are composed into
/// [SessionController] for screen-level convenience.
class OrgController extends ChangeNotifier {
  OrgController({required this.api, required this.storage});

  final ApiClient api;
  final FlutterSecureStorage storage;

  bool contextLoading = false;
  String? contextError;
  List<OrganizationSummary> organizations = [];
  OrganizationContext? activeOrganization;

  /// Whether the active organization grants the given permission.
  bool hasPermission(String permission) =>
      activeOrganization?.permissions.contains(permission) ?? false;

  /// Load or switch organization context.
  ///
  /// Fetches the user's accessible organizations from the API. If
  /// [organizationId] is provided, switches to that org; otherwise
  /// restores the previously selected org (or picks the first one).
  Future<void> loadOrganizationContext({String? organizationId}) async {
    contextLoading = true;
    contextError = null;
    notifyListeners();
    try {
      final data = await api.getList('/me/organizations/');
      organizations = data
          .whereType<Map<String, dynamic>>()
          .map(OrganizationSummary.fromJson)
          .toList();
      if (organizations.isEmpty) {
        activeOrganization = null;
        await storage.delete(key: 'active_organization_id');
        return;
      }
      final savedId = await storage.read(key: 'active_organization_id');
      final selectedId = organizationId ?? savedId;
      final organization = organizations.any(
        (organization) => organization.id == selectedId,
      )
          ? selectedId!
          : organizations.first.id;
      final context =
          await api.get('/me/organizations/$organization/context/');
      activeOrganization = OrganizationContext.fromJson(context);
      await storage.write(key: 'active_organization_id', value: organization);
    } on ApiException catch (error) {
      activeOrganization = null;
      contextError = error.message;
    } finally {
      contextLoading = false;
      notifyListeners();
    }
  }

  /// Clear org state (e.g. on sign-out).
  void clear() {
    organizations = [];
    activeOrganization = null;
    contextError = null;
    storage.delete(key: 'active_organization_id');
    notifyListeners();
  }
}
