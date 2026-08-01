import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/widgets/async_state.dart';
import '../../../core/widgets/async_views.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../shared/models/booking_models.dart';
import '../../../shared/repositories/result.dart';

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
  bool _staleData = false;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    _state.startLoading();
    final result = await widget.auth.ticketRepository.myTickets();
    if (!mounted) return;
    if (result.isOk) {
      final ok = result as Ok<List<TicketSummary>>;
      setState(() {
        _tickets = ok.value.map((t) => t.raw).toList(growable: false);
        _staleData = ok.stale;
        _state.doneLoading();
      });
    } else {
      setState(() => _state.fail(result.errorMessage!));
    }
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

    return Column(
      children: [
        if (_staleData)
          Container(
            width: double.infinity,
            color: Colors.orange.shade100,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: const Text(
              'Showing saved tickets — may be out of date.',
              style: TextStyle(color: Colors.orange, fontSize: 12),
            ),
          ),
        Expanded(
          child: RefreshIndicator(
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
          ),
        ),
      ],
    );
  }
}
