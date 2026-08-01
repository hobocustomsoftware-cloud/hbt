import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/async_state.dart';
import '../../../core/widgets/async_views.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/status_chip.dart';

/// Passenger trip detail screen.
///
/// Shows the full trip overview: route, times, bus company, route stops,
/// fare bands, and available actions.
///
/// This screen is reached from [TripSearchScreen] results list. The trip
/// map is passed as an argument; additional detail is fetched from the API.
class TripDetailScreen extends StatefulWidget {
  const TripDetailScreen({
    super.key,
    required this.auth,
    required this.trip,
    this.pickupStopId,
    this.dropoffStopId,
  });

  final AuthController auth;
  final Map<String, dynamic> trip;
  final String? pickupStopId;
  final String? dropoffStopId;

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  final AsyncState _state = AsyncState();
  List<Map<String, dynamic>>? _stops;
  Map<String, dynamic>? _fullTrip;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    _state.startLoading();
    try {
      // Fetch the full trip detail
      final tripId = widget.trip['id']?.toString() ?? '';
      final data = await widget.auth.api.get(
        '/passenger/trips/$tripId/',
      );
      final stops = _extractStops(data);
      if (mounted) {
        setState(() {
          _fullTrip = data;
          _stops = stops;
          _state.doneLoading();
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _state.fail(e.message));
    } catch (e) {
      if (mounted) setState(() => _state.fail('Failed to load trip: $e'));
    }
  }

  List<Map<String, dynamic>> _extractStops(Map<String, dynamic> data) {
    // Try route_snapshot.stops first, then top-level stops, then fallback
    final raw = data['route_snapshot'] is Map
        ? (data['route_snapshot'] as Map)['stops']
        : data['stops'];
    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map((s) => Map<String, dynamic>.from(s))
          .toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final status = trip['status'] as String? ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(trip['trip_number']?.toString() ?? 'Trip Detail'),
      ),
      body: _state.loading
          ? const LoadingView()
          : RefreshIndicator(
              onRefresh: _loadDetail,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Header card ─────────────────────────────
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.directions_bus_rounded,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      trip['trip_number']?.toString() ??
                                          'Bus Trip',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    if (status.isNotEmpty)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 4),
                                        child: StatusChip(status: status),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Trip info ────────────────────────────────
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Trip Information',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const Divider(),
                          _infoRow(
                            Icons.business,
                            'Operator',
                            _fullTrip?['organization_name']
                                    ?.toString() ??
                                trip['organization_name']?.toString() ??
                                '-',
                          ),
                          _infoRow(
                            Icons.route,
                            'Route',
                            trip['route_name']?.toString() ??
                                trip['route']?.toString() ??
                                '-',
                          ),
                          _infoRow(
                            Icons.calendar_today,
                            'Date',
                            trip['service_date']?.toString() ?? '-',
                          ),
                          _infoRow(
                            Icons.schedule,
                            'Departure',
                            _formatTs(trip['planned_departure_at']),
                          ),
                          _infoRow(
                            Icons.schedule,
                            'Arrival',
                            _formatTs(trip['planned_arrival_at']),
                          ),
                          if (trip['estimated_duration_minutes'] != null)
                            _infoRow(
                              Icons.timer_outlined,
                              'Duration',
                              '${trip['estimated_duration_minutes']} min',
                            ),
                          if (trip['estimated_distance_km'] != null)
                            _infoRow(
                              Icons.straighten,
                              'Distance',
                              '${trip['estimated_distance_km']} km',
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Route stops ──────────────────────────────
                  if (_stops != null && _stops!.isNotEmpty) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Route Stops',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const Divider(),
                            ..._stops!.map((stop) {
                              final seq = stop['sequence'];
                              final name = stop['name']?.toString() ?? '-';
                              final isPickup =
                                  stop['id']?.toString() ==
                                      widget.pickupStopId;
                              final isDropoff =
                                  stop['id']?.toString() ==
                                      widget.dropoffStopId;

                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Column(
                                      children: [
                                        Icon(
                                          isPickup
                                              ? Icons.trip_origin
                                              : isDropoff
                                                  ? Icons.location_on
                                                  : Icons.circle,
                                          size: isPickup || isDropoff
                                              ? 20
                                              : 8,
                                          color: isPickup
                                              ? Colors.green
                                              : isDropoff
                                                  ? Colors.red
                                                  : Colors.grey,
                                        ),
                                        if (seq != _stops!.last['sequence'])
                                          Container(
                                            width: 1,
                                            height: 24,
                                            color: Colors.grey[300],
                                          ),
                                      ],
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: TextStyle(
                                          fontWeight: isPickup || isDropoff
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: isPickup
                                              ? Colors.green[700]
                                              : isDropoff
                                                  ? Colors.red[700]
                                                  : null,
                                        ),
                                      ),
                                    ),
                                    if (isPickup)
                                      Chip(
                                        label: const Text('PICKUP',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.white)),
                                        backgroundColor: Colors.green,
                                        padding: EdgeInsets.zero,
                                        visualDensity:
                                            VisualDensity.compact,
                                      ),
                                    if (isDropoff)
                                      Chip(
                                        label: const Text('DROPOFF',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.white)),
                                        backgroundColor: Colors.red,
                                        padding: EdgeInsets.zero,
                                        visualDensity:
                                            VisualDensity.compact,
                                      ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ── Action button ────────────────────────────
                  BusyButton(
                    label: 'Select Seat & Book',
                    icon: const Icon(Icons.event_seat),
                    onPressed: _onBook,
                    busy: false,
                  ),
                  const SizedBox(height: 16),

                  if (_state.error != null) ErrorCard(message: _state.error!),
                ],
              ),
            ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 12),
            SizedBox(
              width: 100,
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      );

  String _formatTs(String? ts) {
    if (ts == null) return '-';
    try {
      // Show HH:mm from an ISO string
      final dt = DateTime.parse(ts);
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return ts.length > 16 ? ts.substring(0, 16) : ts;
    }
  }

  void _onBook() {
    Navigator.of(context).pushNamed(
      '/booking',
      arguments: {
        'trip': widget.trip,
        'pickup_stop': widget.pickupStopId,
        'dropoff_stop': widget.dropoffStopId,
      },
    );
  }
}
