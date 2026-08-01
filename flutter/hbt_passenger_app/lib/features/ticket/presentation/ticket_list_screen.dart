import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/async_state.dart';
import '../../../core/widgets/async_views.dart';
import '../../../core/widgets/status_chip.dart';

/// Passenger ticket list (wallet) screen.
///
/// Shows all tickets for the logged-in passenger with status.
class TicketListScreen extends StatefulWidget {
  const TicketListScreen({super.key, required this.auth});

  final AuthController auth;

  @override
  State<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends State<TicketListScreen> {
  final AsyncState _state = AsyncState();
  List<Map<String, dynamic>>? _tickets;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    _state.startLoading();
    try {
      final data = await widget.auth.api.get('/passenger/tickets/');
      final list = _extractTicketList(data);
      if (mounted) {
        setState(() {
          _tickets = list;
          _state.doneLoading();
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _state.fail(e.message));
    } catch (e) {
      if (mounted) setState(() => _state.fail('Failed to load tickets: $e'));
    }
  }

  /// Safely extract a `List<Map<String, dynamic>>` from the API response,
  /// handling both `{'results': [...]}` and bare-array responses.
  List<Map<String, dynamic>> _extractTicketList(Map<String, dynamic> data) {
    final rawList = data['results'];
    if (rawList is List) {
      final out = <Map<String, dynamic>>[];
      for (final item in rawList) {
        if (item is Map<String, dynamic>) out.add(item);
      }
      return out;
    }
    // Fallback: iterate values and collect only Map entries
    final out = <Map<String, dynamic>>[];
    for (final value in data.values) {
      if (value is Map<String, dynamic>) out.add(value);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    if (_state.loading) return const LoadingView();
    if (_state.error != null) {
      return ErrorView(message: _state.error!, onRetry: _loadTickets);
    }
    if (_tickets == null || _tickets!.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.confirmation_number_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 12),
            const Text('No tickets yet.'),
            const SizedBox(height: 8),
            const Text(
              'Search and book a trip to get started.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTickets,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _tickets!.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final ticket = _tickets![index];
          final status = ticket['status'] as String? ?? '';
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        ticket['ticket_number'] ?? '-',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      StatusChip(status: status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Trip: ${ticket['trip_number'] ?? '-'}'
                    ' | ${ticket['passenger_name'] ?? ''}',
                  ),
                  Text(
                    'Seat: ${ticket['seat_identifier'] ?? '-'}',
                  ),
                  if (ticket['planned_departure_at'] != null)
                    Text(
                      'Departure: ${ticket['planned_departure_at']}',
                    ),
                  if (ticket['total_amount'] != null)
                    Text(
                      'Fare: ${ticket['total_amount']} ${ticket['currency'] ?? 'MMK'}',
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
