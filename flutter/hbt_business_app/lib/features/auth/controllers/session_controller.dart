import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../shared/services/api_client.dart';
import '../../../shared/models/organization_context.dart';
import '../../../shared/services/audit_service.dart';
import '../../../features/counter/controllers/counter_controller.dart';
import 'auth_controller.dart';
import '../../org/controllers/org_controller.dart';

/// Facade that composes [AuthController], [OrgController], and
/// [CounterController] into a single object for backward compatibility.
///
/// ## Properties delegated
///
/// | Property/Method | Delegates to |
/// |----------------|-------------|
/// | `loading`, `authenticated`, `user` | `AuthController` |
/// | `restore()`, `signIn()`, `signOut()` | `AuthController` |
/// | `organizations`, `activeOrganization` | `OrgController` |
/// | `contextLoading`, `contextError` | `OrgController` |
/// | `loadOrganizationContext()` | `OrgController` |
/// | `hasPermission()` | `OrgController` |
/// | `counterId`, `counterName`, `hasActiveCounter`, etc. | `CounterController` |
/// | `setActiveCounter()`, `clearCounter()` | `CounterController` |
/// | `recordAudit(...)` | `AuditService` |
/// | `api`, `storage` | Owned (shared reference) |
class SessionController extends ChangeNotifier {
  SessionController({required this.api, required this.storage})
      : auth = AuthController(api: api, storage: storage),
        org = OrgController(api: api, storage: storage),
        counter = CounterController(storage: storage) {
    auth.addListener(notifyListeners);
    org.addListener(notifyListeners);
    counter.addListener(notifyListeners);
  }

  /// The underlying HTTP client (shared reference).
  final ApiClient api;

  /// Secure storage for tokens and org preferences.
  final FlutterSecureStorage storage;

  /// Auth sub-controller.
  final AuthController auth;

  /// Organization sub-controller.
  final OrgController org;

  /// Counter identity sub-controller.
  final CounterController counter;

  /// Lazily initialised audit service (set up once org is loaded).
  AuditService? _audit;

  AuditService get _auditService {
    _audit ??= AuditService(
      api: api,
      organizationId: activeOrganization?.organization.id ?? '',
      deviceId: null, // Set via setDeviceId() when available
    );
    return _audit!;
  }

  /// Set the device ID for audit logging.
  void setDeviceId(String deviceId) {
    _audit = AuditService(
      api: api,
      organizationId: activeOrganization?.organization.id ?? '',
      deviceId: deviceId,
    );
  }

  // ── Auth delegation ───────────────────────────────────────────────

  bool get loading => auth.loading;
  set loading(bool value) => auth.loading = value;
  bool get authenticated => auth.authenticated;
  set authenticated(bool value) => auth.authenticated = value;
  Map<String, dynamic>? get user => auth.user;

  Future<void> restore() => auth.restore();

  Future<void> signIn({
    required String phone,
    required String password,
  }) async {
    await auth.signIn(phone: phone, password: password);
    if (auth.authenticated) {
      await org.loadOrganizationContext();
      await counter.restore();
    }
  }

  Future<void> signOut() async {
    await auth.signOut();
    org.clear();
    await counter.clear();
  }

  // ── Org delegation ───────────────────────────────────────────────

  bool get contextLoading => org.contextLoading;
  String? get contextError => org.contextError;
  List<OrganizationSummary> get organizations => org.organizations;
  OrganizationContext? get activeOrganization => org.activeOrganization;
  set activeOrganization(OrganizationContext? value) =>
      org.activeOrganization = value;

  bool hasPermission(String permission) => org.hasPermission(permission);

  Future<void> loadOrganizationContext({String? organizationId}) =>
      org.loadOrganizationContext(organizationId: organizationId);

  // ── Counter delegation ──────────────────────────────────────────

  String? get branchId => counter.branchId;
  String? get branchName => counter.branchName;
  String? get counterId => counter.counterId;
  String? get counterName => counter.counterName;
  bool get hasActiveCounter => counter.hasActiveCounter;

  Future<void> setActiveCounter({
    required String branchId,
    required String branchName,
    required String counterId,
    required String counterName,
  }) => counter.setActiveCounter(
        branchId: branchId,
        branchName: branchName,
        counterId: counterId,
        counterName: counterName,
      );

  Future<void> clearCounter() => counter.clear();

  // ── Audit delegation ────────────────────────────────────────────

  /// The active shift ID (set by BusinessHome when shift starts).
  String? shiftId;

  /// Record an audit entry for an operation performed at a counter.
  ///
  /// Automatically includes the active counter ID, branch ID, shift ID,
  /// user ID, and device ID (if set). Call after any ticket sale, cargo
  /// acceptance, refund, expense, or shift event.
  Future<bool> recordAudit({
    required String action,
    required String resourceType,
    required String resourceId,
    Map<String, dynamic>? details,
  }) {
    return _auditService.record(
      action: action,
      resourceType: resourceType,
      resourceId: resourceId,
      counterId: counter.counterId,
      branchId: counter.branchId,
      userId: auth.user?['id']?.toString(),
      shiftId: shiftId,
      details: details,
    );
  }

  // ── Lifecycle ────────────────────────────────────────────────────

  /// Clear all state (auth + org + counter).
  void clear() {
    auth.authenticated = false;
    auth.user = null;
    auth.loading = true;
    auth.api.accessToken = null;
    org.clear();
    counter.clear();
    notifyListeners();
  }

  @override
  void addListener(VoidCallback listener) {
    super.addListener(listener);
    auth.addListener(listener);
    org.addListener(listener);
    counter.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    auth.removeListener(listener);
    org.removeListener(listener);
    counter.removeListener(listener);
  }

  @override
  void dispose() {
    auth.removeListener(notifyListeners);
    org.removeListener(notifyListeners);
    counter.removeListener(notifyListeners);
    auth.dispose();
    org.dispose();
    counter.dispose();
    super.dispose();
  }
}
