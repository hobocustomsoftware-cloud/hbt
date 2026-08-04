/// Dashboard controller — owns the period state and the snapshot lifecycle
/// (loading / error / data) for the owner dashboard screen.
library;

import 'package:flutter/foundation.dart';

import '../../shared/services/api_client.dart';
import 'dashboard_models.dart';
import 'dashboard_repository.dart';

class DashboardController extends ChangeNotifier {
  DashboardController({required DashboardRepository repository})
      : _repository = repository;

  final DashboardRepository _repository;

  DashboardPeriod _period = DashboardPeriod.day;
  DashboardSnapshot? _snapshot;
  bool _loading = false;
  String? _error;
  bool _disposed = false;

  DashboardPeriod get period => _period;
  DashboardSnapshot? get snapshot => _snapshot;
  bool get loading => _loading;
  String? get error => _error;
  bool get hasData => _snapshot != null;

  /// Loads (or reloads) the snapshot for the current period.
  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final snapshot = await _fetch();
      if (_disposed) return;
      _snapshot = snapshot;
      _error = null;
    } catch (e) {
      if (_disposed) return;
      _error = _messageFor(e);
    } finally {
      if (!_disposed) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> refresh() => load();

  /// Switches the aggregation window and reloads.
  Future<void> setPeriod(DashboardPeriod period) async {
    if (period == _period) return;
    _period = period;
    await load();
  }

  Future<DashboardSnapshot> _fetch() {
    // The org id is resolved by the screen/repository wiring; subclasses or
    // callers that need it can override [organizationId].
    return _repository.fetch(
      organizationId: organizationId,
      period: _period,
    );
  }

  /// Resolved by the owning screen (kept as a field so the controller stays
  /// repository-agnostic and unit-testable).
  String organizationId = '';

  static String _messageFor(Object error) {
    if (error is ApiException) return error.message;
    return error.toString();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
