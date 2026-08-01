import 'package:flutter/material.dart';

import '../../../shared/services/api_client.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/async_views.dart';
import '../../../core/widgets/status_chip.dart';
import '../../auth/controllers/session_controller.dart';
import '../../ticket_sales/screens/counter_booking_page.dart';

/// Trip detail page with operational status transitions.
///
/// Shows trip information and allows status transitions
/// (ready, boarding, depart, en-route, arrive) and resource assignment.
class TripDetailPage extends StatefulWidget {
  const TripDetailPage({
    super.key,
    required this.session,
    required this.trip,
  });

  final SessionController session;
  final Map<String, dynamic> trip;

  @override
  State<TripDetailPage> createState() => _TripDetailPageState();
}

class _TripDetailPageState extends State<TripDetailPage> {
  late Map<String, dynamic> _trip;
  bool _acting = false;
  String? _error;
  String _notes = '';

  String get _orgId =>
      widget.session.activeOrganization!.organization.id;

  @override
  void initState() {
    super.initState();
    _trip = Map<String, dynamic>.from(widget.trip);
  }

  Future<void> _refreshTrip() async {
    try {
      final data = await widget.session.api.get(
        '/organizations/$_orgId/trips/${_trip['id']}/',
      );
      setState(() => _trip = data);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Failed to refresh: $e');
    }
  }

  Future<void> _performAction(String action) async {
    setState(() {
      _acting = true;
      _error = null;
    });

    try {
      final endpoint = switch (action) {
        'ready' => 'ready/',
        'boarding' => 'boarding/start/',
        'depart' => 'depart/',
        'en_route' => 'en-route/',
        'arrive' => 'arrive/',
        _ => throw ArgumentError('Unknown action: $action'),
      };

      final result = await widget.session.api.post(
        '/organizations/$_orgId/trips/${_trip['id']}/$endpoint',
        {'notes': _notes},
      );

      setState(() {
        _trip = result['trip'] as Map<String, dynamic>? ?? _trip;
        _acting = false;
        _notes = '';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Trip ${action.replaceAll('_', ' ')}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _acting = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Action failed: $e';
        _acting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(_trip['trip_number'] as String? ?? 'Trip'),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _acting ? null : _refreshTrip,
        ),
      ],
    ),
    body: RefreshIndicator(
      onRefresh: _refreshTrip,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTripInfo(),
          const SizedBox(height: 16),
          _buildStatusActions(),
          const SizedBox(height: 12),
          _buildNewBookingButton(),
          if (_error != null) ...[
            const SizedBox(height: 12),
            ErrorCard(message: _error!),
          ],
        ],
      ),
    ),
  );

  Widget _buildTripInfo() {
    final status = _trip['status']?.toString() ?? '';
    return InfoCard(
      title: 'Trip ${_trip['trip_number'] ?? ''}',
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: StatusChip(status: status),
        ),
        InfoRow(label: 'Route', value: '${_trip['route'] ?? '-'}'),
        InfoRow(
          label: 'Service Date',
          value: _trip['service_date']?.toString() ?? '-',
        ),
        InfoRow(
          label: 'Departure',
          value: _trip['planned_departure_at']?.toString() ?? '-',
        ),
        InfoRow(
          label: 'Arrival',
          value: _trip['planned_arrival_at']?.toString() ?? '-',
        ),
        if (_trip['vehicle'] != null)
          InfoRow(label: 'Vehicle', value: '${_trip['vehicle']}'),
        if (_trip['driver'] != null)
          InfoRow(label: 'Driver', value: '${_trip['driver']}'),
        if (_trip['conductor'] != null)
          InfoRow(label: 'Conductor', value: '${_trip['conductor']}'),
        if (_trip['operational_notes']?.isNotEmpty == true) ...[
          const SizedBox(height: 8),
          Text('Notes: ${_trip['operational_notes']}'),
        ],
      ],
    );
  }

  Widget _buildNewBookingButton() {
    if (!widget.session.hasPermission('booking.manage') ||
        !widget.session.hasPermission('passenger.view')) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        FilledButton.icon(
          icon: const Icon(Icons.add_shopping_cart),
          label: const Text('New Booking for this Trip'),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CounterBookingPage(
                session: widget.session,
                preselectedTrip: _trip,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusActions() {
    final status = _trip['status'] as String? ?? '';
    final actions = <Widget>[];

    void addAction(String key, String label, IconData icon) {
      actions.add(
        ActionChip(
          avatar: Icon(icon, size: 18),
          label: Text(label),
          onPressed: _acting ? null : () => _performAction(key),
        ),
      );
    }

    switch (status) {
      case 'planned':
        addAction('ready', 'Mark Ready', Icons.check_circle_outline);
        break;
      case 'ready':
        addAction('boarding', 'Start Boarding', Icons.door_front_door);
        break;
      case 'boarding':
        addAction('depart', 'Depart', Icons.directions_bus);
        break;
      case 'departed':
        addAction('en_route', 'En Route', Icons.route);
        break;
      case 'in_progress':
        addAction('arrive', 'Arrive', Icons.location_on);
        break;
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Operations',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Notes (optional)',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          maxLines: 2,
          onChanged: (v) => _notes = v,
        ),
        const SizedBox(height: 12),
        if (_acting)
          const Center(child: CircularProgressIndicator())
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: actions,
          ),
      ],
    );
  }
}
