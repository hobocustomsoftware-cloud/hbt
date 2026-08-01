import 'package:flutter/material.dart';

import '../../../shared/services/api_client.dart';
import '../../../core/widgets/async_state.dart';
import '../../../core/widgets/async_views.dart';
import '../../../core/widgets/status_chip.dart';
import '../../auth/controllers/session_controller.dart';
import 'route_detail_page.dart';

/// Displays all routes for the active organization with CRUD support.
class RouteListPage extends StatefulWidget {
  const RouteListPage({super.key, required this.session});

  final SessionController session;

  @override
  State<RouteListPage> createState() => _RouteListPageState();
}

class _RouteListPageState extends State<RouteListPage> {
  final AsyncState _state = AsyncState();
  List<Map<String, dynamic>>? _routes;

  String get _orgId =>
      widget.session.activeOrganization!.organization.id;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    _state.startLoading();
    try {
      final results = await widget.session.api.getAllPages(
        '/organizations/$_orgId/routes/',
      );
      setState(() {
        _routes = results.cast<Map<String, dynamic>>();
        _state.doneLoading();
      });
    } on ApiException catch (e) {
      setState(() => _state.fail(e.message));
    } catch (e) {
      setState(() => _state.fail('Failed to load routes: $e'));
    }
  }

  Future<void> _createRoute() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => RouteDetailPage(
          session: widget.session,
          organizationId: _orgId,
        ),
      ),
    );
    if (result != null) {
      _routes?.insert(0, result);
      if (mounted) setState(() {});
    }
  }

  Future<void> _editRoute(Map<String, dynamic> route) async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => RouteDetailPage(
          session: widget.session,
          organizationId: _orgId,
          route: route,
        ),
      ),
    );
    if (result != null && mounted) {
      final idx = _routes?.indexWhere((r) => r['id'] == result['id']);
      if (idx != null && idx >= 0) {
        _routes![idx] = result;
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Routes'),
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          tooltip: 'Create route',
          onPressed: _createRoute,
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
          onPressed: _loadRoutes,
        ),
      ],
    ),
    body: _buildBody(),
  );

  Widget _buildBody() {
    if (_state.loading) return const LoadingView();
    if (_state.error != null) {
      return ErrorView(message: _state.error!, onRetry: _loadRoutes);
    }
    if (_routes == null || _routes!.isEmpty) {
      return EmptyView(
        icon: Icons.route_outlined,
        message: 'No routes yet.',
        actionLabel: 'Create Route',
        onAction: _createRoute,
      );
    }
    return RefreshIndicator(
      onRefresh: _loadRoutes,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _routes!.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final route = _routes![index];
          final status = route['status'] as String? ?? '';
          return ListTile(
            leading: Icon(
              Icons.route,
              color: (StatusChip.defaultColors[status] ?? Colors.grey),
            ),
            title: Text('${route['code']} — ${route['name']}'),
            subtitle: Text(
              '${route['stop_count'] ?? 0} stops | ${route['operating_region'] ?? ''} | $status',
            ),
            trailing: StatusChip(status: status),
            onTap: () => _editRoute(route),
          );
        },
      ),
    );
  }
}
