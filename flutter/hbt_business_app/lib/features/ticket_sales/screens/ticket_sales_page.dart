import 'package:flutter/material.dart';

import '../../auth/controllers/session_controller.dart';
import '../../../shared/services/api_client.dart';
import '../../../core/widgets/async_state.dart';
import '../../../core/widgets/async_views.dart';
import '../../../core/widgets/app_card.dart';
import 'counter_booking_page.dart';

class TicketSalesPage extends StatefulWidget {
  const TicketSalesPage({super.key, required this.session});

  final SessionController session;

  @override
  State<TicketSalesPage> createState() => _TicketSalesPageState();
}

class _TicketSalesPageState extends State<TicketSalesPage> {
  final AsyncState _state = AsyncState();
  List<Map<String, dynamic>> _bookings = [];
  List<Map<String, dynamic>> _tickets = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant TicketSalesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session.activeOrganization?.organization.id !=
        widget.session.activeOrganization?.organization.id) {
      _load();
    }
  }

  Future<void> _load() async {
    final organizationId = widget.session.activeOrganization?.organization.id;
    if (organizationId == null) return;
    _state.startLoading();
    try {
      final requests = <Future<List<dynamic>>>[];
      final viewBookings = widget.session.hasPermission('booking.view');
      final viewTickets = widget.session.hasPermission('ticket.view');

      if (viewBookings) {
        requests.add(
          widget.session.api.getList('/organizations/$organizationId/bookings/'),
        );
      }
      if (viewTickets) {
        requests.add(
          widget.session.api.getList('/organizations/$organizationId/tickets/'),
        );
      }

      final results = await Future.wait(requests);
      var resultIndex = 0;
      final bookings = viewBookings
          ? _asMaps(results[resultIndex++])
          : <Map<String, dynamic>>[];
      final tickets = viewTickets
          ? _asMaps(results[resultIndex])
          : <Map<String, dynamic>>[];

      if (mounted) {
        setState(() {
          _bookings = bookings;
          _tickets = tickets;
          _state.doneLoading();
        });
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _state.fail(error.message));
    }
  }

  List<Map<String, dynamic>> _asMaps(List<dynamic> data) => data
      .whereType<Map<String, dynamic>>()
      .toList();

  @override
  Widget build(BuildContext context) {
    final canViewBookings = widget.session.hasPermission('booking.view');
    final canViewTickets = widget.session.hasPermission('ticket.view');
    if (!canViewBookings && !canViewTickets) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('လက်မှတ်နှင့် booking records ကြည့်ခွင့်မရှိပါ။'),
        ),
      );
    }
    if (_state.loading) return const LoadingView();
    if (_state.error != null) {
      return ErrorView(message: _state.error!, onRetry: _load);
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.session.hasPermission('passenger.view') &&
              widget.session.hasPermission('passenger.manage') &&
              widget.session.hasPermission('trip.view') &&
              widget.session.hasPermission('booking.manage') &&
              widget.session.hasPermission('fare.quote'))
            AppListTileCard(
              leadingIcon: Icons.info_outline,
              title: 'Counter ticket sale',
              subtitle:
                  'Passenger, seat, booking နှင့် locked fare quote ပြုလုပ်ရန်',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => CounterBookingPage(session: widget.session),
              )),
            ),
          if (canViewBookings) ...[
            const SizedBox(height: 12),
            Text('လတ်တလော Booking များ', style: Theme.of(context).textTheme.titleMedium),
            if (_bookings.isEmpty)
              const EmptyListTileCard(message: 'Booking မရှိသေးပါ။')
            else
              ..._bookings.map(
                (booking) => AppListTileCard(
                  leadingIcon: Icons.book_online_outlined,
                  title: booking['booking_number']?.toString() ?? 'Booking',
                  subtitle:
                      '${booking['contact_name'] ?? ''} • ${booking['status'] ?? ''}',
                ),
              ),
          ],
          if (canViewTickets) ...[
            const SizedBox(height: 20),
            Text('ထုတ်ပေးထားသော လက်မှတ်များ', style: Theme.of(context).textTheme.titleMedium),
            if (_tickets.isEmpty)
              const EmptyListTileCard(message: 'လက်မှတ်မရှိသေးပါ။')
            else
              ..._tickets.map(
                (ticket) => AppListTileCard(
                  leadingIcon: Icons.confirmation_number_outlined,
                  title: ticket['ticket_number']?.toString() ?? 'Ticket',
                  subtitle:
                      '${ticket['passenger_name'] ?? ''} • ${ticket['status'] ?? ''}',
                ),
              ),
          ],
        ],
      ),
    );
  }
}
