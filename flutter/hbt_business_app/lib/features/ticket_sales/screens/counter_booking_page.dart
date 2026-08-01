import 'package:flutter/material.dart';

import '../../auth/controllers/session_controller.dart';
import '../../../shared/services/api_client.dart';
import '../../../shared/models/seat_lock_models.dart';
import '../../../core/widgets/async_state.dart';
import '../../../core/widgets/async_views.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../controllers/seat_lock_controller.dart';
import 'payment_decision_page.dart';

class CounterBookingPage extends StatefulWidget {
  const CounterBookingPage({
    super.key,
    required this.session,
    this.preselectedTrip,
  });

  final SessionController session;
  final Map<String, dynamic>? preselectedTrip;

  @override
  State<CounterBookingPage> createState() => _CounterBookingPageState();
}

class _CounterBookingPageState extends State<CounterBookingPage> {
  final _contactName = TextEditingController();
  final _contactPhone = TextEditingController();
  final AsyncState _state = AsyncState();
  List<Map<String, dynamic>> _passengers = [];
  List<Map<String, dynamic>> _trips = [];
  List<SeatWithLock> _seats = [];
  Map<String, dynamic>? _passenger;
  Map<String, dynamic>? _trip;
  Map<String, dynamic>? _pickup;
  Map<String, dynamic>? _dropoff;
  Map<String, dynamic>? _seat; // raw seat map from API
  Map<String, dynamic>? _quote;
  Map<String, dynamic>? _booking;
  SeatLockController? _lockCtrl;

  String get _organizationId =>
      widget.session.activeOrganization!.organization.id;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _releaseLock();
    _lockCtrl?.dispose();
    _contactName.dispose();
    _contactPhone.dispose();
    super.dispose();
  }

  void _releaseLock() {
    _lockCtrl?.removeListener(_onLockChanged);
    _lockCtrl?.release();
  }

  Future<void> _loadInitialData() async {
    _state.startLoading();
    try {
      final results = await Future.wait([
        widget.session.api.getList(
          '/organizations/$_organizationId/passengers/',
        ),
        widget.session.api.getList(
          '/organizations/$_organizationId/trips/',
        ),
      ]);
      if (mounted) {
        final allTrips = _maps(results[1]).where((trip) {
          final status = trip['status'];
          return status == 'planned' || status == 'ready';
        }).toList();
        setState(() {
          _passengers = _maps(results[0]);
          _trips = allTrips;
        });
        if (widget.preselectedTrip != null) {
          final match = allTrips.cast<Map<String, dynamic>?>().firstWhere(
            (t) => t?['id'] == widget.preselectedTrip!['id'],
            orElse: () => null,
          );
          if (match != null) {
            setState(() => _trip = match);
          }
        }
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _state.fail(error.message));
    } finally {
      if (mounted) setState(() => _state.doneLoading());
    }
  }

  void _onTripChanged(Map<String, dynamic>? trip) {
    _releaseLock();
    _lockCtrl?.dispose();
    setState(() {
      _trip = trip;
      _pickup = null;
      _dropoff = null;
      _seats = [];
      _seat = null;
      _lockCtrl = null;
    });
  }

  List<Map<String, dynamic>> _maps(List<dynamic> values) =>
      values.whereType<Map<String, dynamic>>().toList();

  List<Map<String, dynamic>> get _stops =>
      _maps((_trip?['route_snapshot']
              as Map<String, dynamic>?)?['stops']
          as List<dynamic>? ?? []);

  Future<void> _loadSeats() async {
    if (_trip == null || _pickup == null || _dropoff == null) return;
    setState(() {
      _seats = [];
      _seat = null;
      _state.error = null;
    });
    try {
      final response = await widget.session.api.get(
        '/organizations/$_organizationId/trips/${_trip!['id']}/seats/'
        '?pickup_stop=${_pickup!['id']}&dropoff_stop=${_dropoff!['id']}',
      );
      if (mounted) {
        final raw = response['seats'] as List<dynamic>? ?? [];
        final parsed = raw
            .map((e) => SeatWithLock.fromJson(e as Map<String, dynamic>))
            .toList();
        setState(() => _seats = parsed);

        // Initialise lock controller for this trip
        _lockCtrl?.removeListener(_onLockChanged);
        _lockCtrl?.dispose();
        _lockCtrl = SeatLockController(
          api: widget.session.api,
          organizationId: _organizationId,
          tripId: _trip!['id'].toString(),
        );
        _lockCtrl!.addListener(_onLockChanged);
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _state.fail(error.message));
    }
  }

  void _onLockChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _onSeatTapped(SeatWithLock seat) async {
    if (_lockCtrl == null) return;

    // If already holding this seat, deselect
    if (_seat?['id'] == seat.id) {
      _releaseLock();
      setState(() => _seat = null);
      return;
    }

    // Seat held by someone else — cannot select
    if (seat.lockStatus == SeatLockStatus.locked) return;

    // Seat booked — cannot select
    if (seat.lockStatus == SeatLockStatus.booked) return;

    // Acquire lock
    final ok = await _lockCtrl!.acquire(seat.identifier);
    if (mounted && ok) {
      setState(() {
        _seat = {
          'id': seat.id,
          'identifier': seat.identifier,
          'row': seat.row,
          'col': seat.col,
        };
      });
    }
  }

  Future<void> _createPassenger() async {
    final codeCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passenger = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ခရီးသည်အသစ်'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: codeCtrl,
                decoration:
                    const InputDecoration(labelText: 'ခရီးသည်ကုဒ်')),
            TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'အမည်')),
            TextField(
                controller: phoneCtrl,
                decoration:
                    const InputDecoration(labelText: 'ဖုန်းနံပါတ်')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('မလုပ်တော့ပါ')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, {
              'passenger_code': codeCtrl.text.trim(),
              'full_name': nameCtrl.text.trim(),
              'phone_number': phoneCtrl.text.trim(),
              'category': 'adult',
              'gender': 'unspecified',
            }),
            child: const Text('သိမ်းမည်'),
          ),
        ],
      ),
    );
    codeCtrl.dispose();
    nameCtrl.dispose();
    phoneCtrl.dispose();
    if (passenger == null) return;
    try {
      final created = await widget.session.api.post(
        '/organizations/$_organizationId/passengers/',
        passenger,
      );
      if (mounted) {
        setState(() {
          _passengers = [..._passengers, created];
          _passenger = created;
        });
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _state.fail(error.message));
    }
  }

  Future<void> _createAndLockQuote() async {
    if (_passenger == null ||
        _trip == null ||
        _pickup == null ||
        _dropoff == null ||
        _seat == null) {
      setState(() => _state.fail(
          'ခရီးသည်၊ ခရီးစဉ်၊ မှတ်တိုင်နှင့် ထိုင်ခုံကို ရွေးပါ။'));
      return;
    }
    _state.startAction();
    setState(() {
      _quote = null;
      _state.error = null;
    });
    try {
      final booking = await widget.session.api.post(
        '/organizations/$_organizationId/bookings/',
        {
          'trip': _trip!['id'],
          'booking_type': 'individual',
          'channel': 'counter',
          'contact_name': _contactName.text.trim().isEmpty
              ? _passenger!['full_name']
              : _contactName.text.trim(),
          'contact_phone': _contactPhone.text.trim(),
          'pickup_stop': _pickup!['id'],
          'dropoff_stop': _dropoff!['id'],
          'passenger_seats': [
            {
              'passenger': _passenger!['id'],
              'seat_position': _seat!['identifier'],
            },
          ],
        },
      );
      final quote = await widget.session.api.post(
        '/organizations/$_organizationId/bookings/${booking['id']}/fare-quotes/create/',
        {'coupon_code': ''},
      );
      final locked = await widget.session.api.post(
        '/organizations/$_organizationId/fare-quotes/${quote['id']}/lock/',
        {},
      );
      if (mounted) {
        // Booking succeeded — lock is now server-side associated with booking
        _lockCtrl?.onBookingSuccess();
        setState(() {
          _booking = booking;
          _quote = locked;
        });
        // Record audit
        widget.session.recordAudit(
          action: 'booking.create',
          resourceType: 'booking',
          resourceId: booking['id']?.toString() ?? '',
          details: {
            'trip_id': _trip!['id'],
            'trip_number': _trip!['trip_number'],
            'passenger_id': _passenger!['id'],
            'seat': _seat!['identifier'],
            'pickup': _pickup!['id'],
            'dropoff': _dropoff!['id'],
            'total_amount': locked['total_amount']?.toString(),
          },
        );
      }
    } on ApiException catch (error) {
      // Booking failed — release the seat lock automatically
      _lockCtrl?.onBookingCancelled();
      if (mounted) setState(() => _state.fail(error.message));
    } finally {
      if (mounted) setState(() => _state.doneAction());
    }
  }

  // ── Seat builders ─────────────────────────────────────────────────
  Widget _buildSeatChip(SeatWithLock seat) {
    final isSelected = _seat?['id'] == seat.id;
    final isLockedByOther = seat.lockStatus == SeatLockStatus.locked;
    final isBooked = seat.lockStatus == SeatLockStatus.booked;
    final isHeldByMe = _lockCtrl?.currentLock != null &&
        _lockCtrl!.currentLock!.seatPosition == seat.identifier &&
        _lockCtrl!.hasActiveLock;

    Color? chipColor;
    bool enabled = true;
    String? tooltip;

    if (isSelected || isHeldByMe) {
      chipColor = Colors.green;
      tooltip = 'Selected — ${_lockCtrl?.remainingFormatted ?? ""} remaining';
    } else if (isLockedByOther) {
      chipColor = Colors.orange[100];
      enabled = false;
      tooltip = 'Held by another counter';
    } else if (isBooked) {
      chipColor = Colors.grey[300];
      enabled = false;
      tooltip = 'Already booked';
    }

    return Tooltip(
      message: tooltip ?? 'Available',
      child: ChoiceChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(seat.identifier),
            if (isLockedByOther || isBooked) ...[
              const SizedBox(width: 4),
              Icon(
                isLockedByOther ? Icons.lock : Icons.block,
                size: 14,
                color: isLockedByOther ? Colors.orange : Colors.grey,
              ),
            ],
            if (isHeldByMe) ...[
              const SizedBox(width: 4),
              Icon(Icons.lock_open, size: 14, color: Colors.green[700]),
            ],
          ],
        ),
        selected: isSelected || isHeldByMe,
        selectedColor: chipColor,
        onSelected: enabled ? (_) => _onSeatTapped(seat) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_state.loading) {
      return const Scaffold(body: LoadingView());
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Counter Booking')),
      body: RefreshIndicator(
        onRefresh: _loadInitialData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_state.error != null) ErrorCard(message: _state.error!),

            // ── Passenger ──────────────────────────────────
            Row(children: [
              Expanded(
                child: Text('ခရီးသည်',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              IconButton(
                onPressed:
                    widget.session.hasPermission('passenger.manage')
                        ? _createPassenger
                        : null,
                icon: const Icon(Icons.person_add),
              ),
            ]),
            DropdownButtonFormField<Map<String, dynamic>>(
              key: ValueKey(_passenger?['id']),
              initialValue: _passenger,
              items: _passengers
                  .map((item) => DropdownMenuItem(
                      value: item,
                      child: Text(
                          item['full_name']?.toString() ?? 'Passenger')))
                  .toList(),
              onChanged: (value) => setState(() => _passenger = value),
              decoration:
                  const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),

            // ── Trip ────────────────────────────────────────
            Text('ခရီးစဉ်',
                style: Theme.of(context).textTheme.titleMedium),
            DropdownButtonFormField<Map<String, dynamic>>(
              key: ValueKey(_trip?['id']),
              initialValue: _trip,
              items: _trips
                  .map((item) => DropdownMenuItem(
                      value: item,
                      child: Text(
                          '${item['trip_number']} • ${item['planned_departure_at']}')))
                  .toList(),
              onChanged: _onTripChanged,
              decoration:
                  const InputDecoration(border: OutlineInputBorder()),
            ),
            if (_trip != null) ...[
              const SizedBox(height: 16),

              // ── Stops ─────────────────────────────────────
              DropdownButtonFormField<Map<String, dynamic>>(
                key: ValueKey(_pickup?['id']),
                initialValue: _pickup,
                items: _stops
                    .map((item) => DropdownMenuItem(
                        value: item,
                        child: Text(
                            item['name']?.toString() ?? 'Stop')))
                    .toList(),
                onChanged: (value) => setState(() {
                  _pickup = value;
                  _dropoff = null;
                  _seats = [];
                  _seat = null;
                }),
                decoration: const InputDecoration(
                    labelText: 'စတင်မှတ်တိုင်',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Map<String, dynamic>>(
                key: ValueKey(_dropoff?['id']),
                initialValue: _dropoff,
                items: _stops
                    .where((item) =>
                        _pickup == null ||
                        (item['sequence'] as int) >
                            (_pickup!['sequence'] as int))
                    .map((item) => DropdownMenuItem(
                        value: item,
                        child: Text(
                            item['name']?.toString() ?? 'Stop')))
                    .toList(),
                onChanged: (value) {
                  setState(() => _dropoff = value);
                  _loadSeats();
                },
                decoration: const InputDecoration(
                    labelText: 'ဆင်းမည့်မှတ်တိုင်',
                    border: OutlineInputBorder()),
              ),
            ],

            // ── Seats ───────────────────────────────────────
            if (_seats.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('ထိုင်ခုံ',
                      style:
                          Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  // Lock status legend
                  _lockLegend(context),
                ],
              ),
              const SizedBox(height: 8),

              // Lock holder / timer indicator
              if (_lockCtrl != null && _lockCtrl!.hasActiveLock)
                Card(
                  color: _lockCtrl!.isCloseToExpiry
                      ? Theme.of(context).colorScheme.errorContainer
                      : Colors.green[50],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _lockCtrl!.isCloseToExpiry
                              ? Icons.timer_off
                              : Icons.timer,
                          size: 16,
                          color: _lockCtrl!.isCloseToExpiry
                              ? Theme.of(context).colorScheme.error
                              : Colors.green[700],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _lockCtrl!.remainingFormatted,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _lockCtrl!.isCloseToExpiry
                                ? Theme.of(context).colorScheme.error
                                : Colors.green[700],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'remaining',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 8),

              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _seats.map(_buildSeatChip).toList(),
              ),

              // Lock acquire error
              if (_lockCtrl != null &&
                  _lockCtrl!.error != null &&
                  _lockCtrl!.currentLock == null)
                Padding(
                  padding:
                      const EdgeInsets.only(top: 8),
                  child: Text(
                    _lockCtrl!.error!,
                    style: TextStyle(
                      color:
                          Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],

            const SizedBox(height: 16),

            // ── Contact info ─────────────────────────────────
            TextField(
              controller: _contactName,
              decoration: const InputDecoration(
                  labelText: 'ဆက်သွယ်ရန်အမည်',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contactPhone,
              decoration: const InputDecoration(
                  labelText: 'ဆက်သွယ်ရန်ဖုန်း',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),

            // ── Submit ───────────────────────────────────────
            BusyButton(
              label: 'Booking နှင့် Fare Quote ပြုလုပ်မည်',
              onPressed: _createAndLockQuote,
              busy: _state.actionInProgress,
            ),

            // ── Quote result ─────────────────────────────────
            if (_quote != null)
              AppListTileCard(
                title: 'Locked Fare Quote',
                subtitle:
                    '${_quote!['total_amount']} ${_quote!['currency']}',
                onTap: () {
                  // Lock released by server on booking completion
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PaymentDecisionPage(
                        session: widget.session,
                        booking: _booking!,
                        quote: _quote!,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _lockLegend(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _legendDot(Colors.green, 'Held'),
        const SizedBox(width: 8),
        _legendDot(Colors.orange, 'Locked'),
        const SizedBox(width: 8),
        _legendDot(Colors.grey, 'Booked'),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 3),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}
