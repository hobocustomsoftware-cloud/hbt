import 'package:flutter/material.dart';

import '../../../shared/services/api_client.dart';
import '../../../core/widgets/async_state.dart';
import '../../../core/widgets/async_views.dart';
import '../../../core/widgets/loading.dart';
import '../../../core/widgets/pagination.dart';
import '../../../core/widgets/status_chip.dart';
import '../../auth/controllers/session_controller.dart';
import 'trip_detail_page.dart';

/// Displays all trips for the active organization with pagination support.
class TripListPage extends StatefulWidget {
  const TripListPage({super.key, required this.session});

  final SessionController session;

  @override
  State<TripListPage> createState() => _TripListPageState();
}

class _TripListPageState extends State<TripListPage> {
  final AsyncState _state = AsyncState();
  List<Map<String, dynamic>> _allTrips = [];
  List<Map<String, dynamic>>? _trips;
  String? _statusFilter;

  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  bool _loadingMore = false;

  String get _orgId =>
      widget.session.activeOrganization!.organization.id;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips({int page = 1}) async {
    if (page == 1) {
      _state.startLoading();
    } else {
      _loadingMore = true;
      if (mounted) setState(() {});
    }

    try {
      final data = await widget.session.api.get(
        '/organizations/$_orgId/trips/?page=$page',
      );
      final results = data['results'] as List<dynamic>? ?? [];
      final items = results.cast<Map<String, dynamic>>();

      if (page == 1) {
        _allTrips = items;
      } else {
        _allTrips.addAll(items);
      }

      // Parse pagination metadata
      _currentPage = page;
      final count = data['count'];
      if (count is int && count > 0) {
        _totalItems = count;
        _totalPages = (count / 25).ceil(); // 25 items per page
      }
      final next = data['next'];
      if (next == null) {
        _totalPages = _currentPage;
      }

      _applyFilter();
      if (page == 1) {
        _state.doneLoading();
      }
      _loadingMore = false;
      if (mounted) setState(() {});
    } on ApiException catch (e) {
      if (page == 1) {
        setState(() => _state.fail(e.message));
      }
      _loadingMore = false;
      if (mounted) setState(() {});
    } catch (e) {
      if (page == 1) {
        setState(() => _state.fail('Failed to load trips: $e'));
      }
      _loadingMore = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _loadNextPage() {
    if (_loadingMore || _currentPage >= _totalPages) {
      return Future.value();
    }
    return _loadTrips(page: _currentPage + 1);
  }

  void _applyFilter() {
    if (_statusFilter != null && _statusFilter!.isNotEmpty) {
      _trips = _allTrips.where(
        (t) => t['status']?.toString() == _statusFilter,
      ).toList();
    } else {
      _trips = List<Map<String, dynamic>>.from(_allTrips);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Trips'),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.filter_list),
          tooltip: 'Filter by status',
          onSelected: (status) {
            setState(() {
              _statusFilter = status.isEmpty ? null : status;
              _applyFilter();
            });
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: '', child: Text('All Trips')),
            const PopupMenuItem(value: 'planned', child: Text('Planned')),
            const PopupMenuItem(value: 'ready', child: Text('Ready')),
            const PopupMenuItem(value: 'boarding', child: Text('Boarding')),
            const PopupMenuItem(value: 'departed', child: Text('Departed')),
            const PopupMenuItem(value: 'in_progress', child: Text('In Progress')),
            const PopupMenuItem(value: 'delayed', child: Text('Delayed')),
            const PopupMenuItem(value: 'cancelled', child: Text('Cancelled')),
          ],
        ),
      ],
    ),
    body: _buildBody(),
  );

  Widget _buildBody() {
    if (_state.loading) {
      return const SkeletonLoader(
        itemCount: 6,
        itemBuilder: _skeletonItem,
      );
    }
    if (_state.error != null) {
      return ErrorView(message: _state.error!, onRetry: () => _loadTrips());
    }
    if (_trips == null || _trips!.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _loadTrips(),
        child: ListView(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.3),
            const EmptyView(
              icon: Icons.directions_bus_outlined,
              message: 'No trips found.',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadTrips(),
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // Filter chip
          if (_statusFilter != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 4),
              child: Chip(
                avatar: const Icon(Icons.filter_alt, size: 16),
                label: Text('Status: $_statusFilter'),
                onDeleted: () {
                  setState(() {
                    _statusFilter = null;
                    _applyFilter();
                  });
                },
              ),
            ),

          // Trip list
          ..._trips!.map(
            (trip) => _tripCard(trip),
          ),

          // Pagination
          if (_totalPages > 1)
            PaginationBar(
              currentPage: _currentPage,
              totalPages: _totalPages,
              totalItems: _totalItems,
              onPageChanged: (page) {
                if (page > _currentPage) {
                  _loadNextPage();
                }
              },
            ),

          // Loading more indicator
          if (_loadingMore)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tripCard(Map<String, dynamic> trip) {
    final status = trip['status'] as String? ?? '';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: StatusAvatar(status: status, icon: Icons.directions_bus),
        title: Text(trip['trip_number'] as String? ?? ''),
        subtitle: Text(
          '${trip['service_date'] ?? '-'} | '
          '${status.replaceAll('_', ' ')}',
        ),
        trailing: StatusChip(status: status),
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TripDetailPage(
                session: widget.session,
                trip: trip,
              ),
            ),
          );
          _loadTrips();
        },
      ),
    );
  }

  static Widget _skeletonItem(int index) => Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const SkeletonLine(width: 40, height: 40, borderRadius: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLine(
                        width: 120 + (index % 3) * 40.0, height: 14),
                    const SizedBox(height: 8),
                    SkeletonLine(width: 200, height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
