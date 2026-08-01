import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/async_state.dart';
import '../../../core/widgets/async_views.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/status_chip.dart';

/// Passenger seat selection + booking confirmation screen.
///
/// Flow:
/// 1. Shows trip summary + seat grid with availability + active holds
/// 2. Tapping an available seat acquires a server-side seat lock (TTL 5 min)
/// 3. "Confirm Booking" posts to the API; the server consumes the lock
/// 4. Success screen shows booking reference with actions
///
/// The lock prevents two passengers from booking the same seat
/// simultaneously and shows held seats in real time.
class BookingScreen extends StatefulWidget {
  const BookingScreen({
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
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final AsyncState _state = AsyncState();
  List<Map<String, dynamic>>? _seats;
  String? _selectedSeatId;
  Map<String, dynamic>? _result;
  List<Map<String, dynamic>>? _travelers;

  // Seat lock state
  String? _lockId;
  String? _lockSeatIdentifier;
  DateTime? _lockExpiresAt;
  Timer? _lockTimer;
  String _lockRemaining = '';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _lockTimer?.cancel();
    _releaseLock(); // best-effort release when leaving the screen
    super.dispose();
  }

  List<Map<String, dynamic>> _extractMaps(dynamic response) {
    final rawList = response is List<dynamic>
        ? response
        : (response['results'] as List<dynamic>?) ?? <dynamic>[];
    final out = <Map<String, dynamic>>[];
    for (final item in rawList) {
      if (item is Map<String, dynamic>) out.add(item);
    }
    return out;
  }

  Future<void> _loadInitialData() async {
    _state.startLoading();
    await Future.wait([_loadSeats(), _loadTravelers()]);
    if (mounted) _state.doneLoading();
  }

  Future<void> _loadTravelers() async {
    try {
      final data = await widget.auth.api.get('/passenger/travelers/');
      if (mounted) setState(() => _travelers = _extractMaps(data));
    } catch (_) {
      // Travelers are optional
    }
  }

  Future<void> _loadSeats() async {
    if (widget.pickupStopId == null || widget.dropoffStopId == null) return;

    try {
      final data = await widget.auth.api.get(
        '/passenger/trips/${widget.trip['id']}/seats/'
        '?pickup_stop=${widget.pickupStopId}'
        '&dropoff_stop=${widget.dropoffStopId}',
      );
      final rawSeats = data['seats'] is List
          ? (data['seats'] as List<dynamic>)
          : <dynamic>[];
      final seatList = <Map<String, dynamic>>[];
      for (final item in rawSeats) {
        if (item is Map<String, dynamic>) seatList.add(item);
      }
      if (mounted) setState(() => _seats = seatList);
    } on ApiException catch (e) {
      if (mounted) _state.fail(e.message);
    } catch (e) {
      if (mounted) _state.fail('Failed to load seats: $e');
    }
  }

  // ── Seat lock protocol ───────────────────────────────────────────

  /// Whether the current hold is still valid.
  bool get _hasActiveLock =>
      _lockId != null &&
      _lockExpiresAt != null &&
      _lockExpiresAt!.isAfter(DateTime.now());

  String _lockIdempotencyKey(String seatIdentifier) {
    final user = widget.auth.user;
    final who = user?['id']?.toString() ?? 'anon';
    return 'passenger_${who}_${widget.trip['id']}_$seatIdentifier';
  }

  /// Acquire a server-side hold on the tapped seat.
  Future<void> _selectSeat(Map<String, dynamic> seat) async {
    final seatId = seat['id'].toString();
    final identifier = seat['identifier']?.toString() ?? seatId;

    // Tapping the held seat again releases it.
    if (_selectedSeatId == seatId) {
      await _releaseLock();
      return;
    }

    // Seat is held by another passenger (from a fresh seat map).
    if (seat['active_lock'] != null) {
      _showMessage('This seat is being held by another passenger.');
      return;
    }

    try {
      final lock = await widget.auth.api.post('/passenger/seat-locks/', {
        'trip_id': widget.trip['id'],
        'seat_position': identifier,
        'idempotency_key': _lockIdempotencyKey(identifier),
      });
      if (!mounted) return;
      setState(() {
        _selectedSeatId = seatId;
        _lockId = lock['id']?.toString();
        _lockSeatIdentifier = identifier;
        _lockExpiresAt = DateTime.tryParse(lock['expires_at']?.toString() ?? '');
      });
      _startLockTimer();
      _state.error = null;
    } on ApiException catch (e) {
      // Conflict (seat taken between refresh and tap) or network error.
      if (mounted) {
        setState(() => _state.fail(e.message));
      }
      _loadSeats(); // refresh availability so the user sees the real state
    }
  }

  /// Release the current hold (best-effort; server TTL is the backstop).
  Future<void> _releaseLock() async {
    _lockTimer?.cancel();
    final lockId = _lockId;
    if (lockId != null) {
      try {
        await widget.auth.api.delete('/passenger/seat-locks/$lockId/');
      } catch (_) {
        // Best-effort: TTL will expire the hold server-side.
      }
    }
    if (mounted) {
      setState(() {
        _lockId = null;
        _lockSeatIdentifier = null;
        _lockExpiresAt = null;
        _lockRemaining = '';
        _selectedSeatId = null;
      });
    }
  }

  void _startLockTimer() {
    _lockTimer?.cancel();
    _lockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_hasActiveLock) {
        _lockTimer?.cancel();
        if (mounted) {
          _showMessage('Seat hold expired. Please select the seat again.');
          setState(() {
            _lockId = null;
            _lockSeatIdentifier = null;
            _lockExpiresAt = null;
            _lockRemaining = '';
            _selectedSeatId = null;
          });
        }
        _loadSeats();
        return;
      }
      final remaining = _lockExpiresAt!.difference(DateTime.now());
      final mm = remaining.inMinutes.toString().padLeft(2, '0');
      final ss = (remaining.inSeconds % 60).toString().padLeft(2, '0');
      if (mounted) setState(() => _lockRemaining = '$mm:$ss');
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _bookSeat() async {
    if (_selectedSeatId == null) {
      _showMessage('Please select a seat.');
      return;
    }
    if (!_hasActiveLock) {
      _showMessage('Your seat hold has expired. Please select the seat again.');
      setState(() {
        _selectedSeatId = null;
        _lockId = null;
      });
      _loadSeats();
      return;
    }

    _state.startAction();

    try {
      String passengerId;
      if (_travelers != null && _travelers!.isNotEmpty) {
        passengerId = _travelers!.first['id'].toString();
      } else {
        final user = widget.auth.user;
        final phone = user?['phone_number']?.toString() ?? '';
        final firstName = user?['first_name']?.toString() ?? '';
        final lastName = user?['last_name']?.toString() ?? '';
        final newTraveler = await widget.auth.api.post(
          '/passenger/travelers/',
          {
            'passenger_code': phone.isNotEmpty
                ? phone
                : 'T${DateTime.now().millisecondsSinceEpoch}',
            'full_name': '$firstName $lastName'.trim(),
            'phone_number': phone,
            'organization': widget.trip['organization'],
          },
        );
        passengerId = newTraveler['id'].toString();
      }

      final booking = await widget.auth.api.post(
        '/passenger/bookings/',
        {
          'trip': widget.trip['id'],
          'passenger_seats': [
            {
              'passenger': passengerId,
              'seat_position': _selectedSeatId,
            },
          ],
        },
      );

      if (mounted) {
        _lockTimer?.cancel();
        setState(() {
          _result = booking;
          _lockId = null;
          _lockSeatIdentifier = null;
          _lockExpiresAt = null;
          _state.doneAction();
        });
      }
    } on ApiException catch (e) {
      if (mounted) _state.fail(e.message);
      _loadSeats(); // a conflict may have happened; refresh the grid
    } catch (e) {
      if (mounted) _state.fail('Booking failed: $e');
    }
  }

  /// Safe short id for display (booking references can be short UUIDs).
  static String _shortId(dynamic id) {
    if (id == null) return '-';
    final s = id.toString();
    if (s.length <= 8) return s;
    return s.substring(0, 8);
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Trip ${trip['trip_number'] ?? trip['trip'] ?? ''}',
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final trip = widget.trip;

    if (_state.loading && _seats == null) {
      return const LoadingView();
    }

    // ── Booking success ─────────────────────────────────────
    if (_result != null) {
      return _buildSuccess();
    }

    // ── Seat selection form ──────────────────────────────────
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Trip summary card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.directions_bus_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Trip ${trip['trip_number'] ?? ''}',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (trip['status'] != null)
                      StatusChip(status: trip['status'] as String),
                  ],
                ),
                const Divider(),
                _summaryRow(Icons.business,
                    trip['organization_name']?.toString() ?? 'Bus Co.'),
                _summaryRow(Icons.calendar_today,
                    trip['service_date']?.toString() ?? '-'),
                _summaryRow(Icons.schedule,
                    _fmtTs(trip['planned_departure_at'])),
                if (trip['total_amount'] != null)
                  _summaryRow(
                    Icons.attach_money,
                    '${trip['total_amount']} ${trip['currency'] ?? 'MMK'}',
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Seat section header
        Text(
          'Select Your Seat',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Tap an available seat to select it. Your seat is held for 5 minutes.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
        ),
        const SizedBox(height: 16),

        // Seat grid
        if (_seats != null && _seats!.isNotEmpty)
          _buildSeatGrid()
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  _seats == null
                      ? 'Loading seats…'
                      : 'No seats available for this segment.',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ),

        const SizedBox(height: 24),

        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _legendItem(Colors.green, 'Available'),
            const SizedBox(width: 16),
            _legendItem(Colors.orange, 'Held'),
            const SizedBox(width: 16),
            _legendItem(Colors.grey[300]!, 'Booked'),
            const SizedBox(width: 16),
            _legendItem(Theme.of(context).colorScheme.primary, 'Selected'),
          ],
        ),

        // Hold countdown banner
        if (_hasActiveLock) ...[
          const SizedBox(height: 16),
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.lock_clock, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Seat $_lockSeatIdentifier held for $_lockRemaining',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  TextButton(
                    onPressed: _releaseLock,
                    child: const Text('Release'),
                  ),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 16),

        // Error
        if (_state.error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ErrorCard(message: _state.error!),
          ),

        // Book button
        BusyButton(
          label: _selectedSeatId != null
              ? 'Confirm Booking'
              : 'Select a Seat First',
          icon: _selectedSeatId != null
              ? const Icon(Icons.check_circle)
              : null,
          onPressed: _selectedSeatId != null ? _bookSeat : null,
          busy: _state.actionInProgress,
        ),
      ],
    );
  }

  Widget _buildSeatGrid() {
    // Group seats by row (default layout: floor plan)
    final cs = Theme.of(context).colorScheme;
    final rows = <String, List<Map<String, dynamic>>>{};
    for (final seat in _seats!) {
      final row = seat['row']?.toString() ?? seat['label']?.toString() ?? '?';
      final firstChar = row.isNotEmpty ? row[0] : '?';
      rows.putIfAbsent(firstChar, () => []).add(seat);
    }

    // If no row grouping, flatten into columns
    if (rows.isEmpty) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _seats!.map((seat) => _seatChip(seat)).toList(),
      );
    }

    // Lay out as bus floor plan
    return Column(
      children: [
        // Front indicator
        Center(
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'FRONT',
              style: TextStyle(
                fontSize: 11,
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        for (final entry in rows.entries) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Left side
              ...entry.value
                  .where((s) => s['side']?.toString() != 'right')
                  .map((s) => _seatChip(s)),
              // Aisle gap
              const SizedBox(width: 24),
              // Right side
              ...entry.value
                  .where((s) => s['side']?.toString() == 'right')
                  .map((s) => _seatChip(s)),
            ],
          ),
          const SizedBox(height: 6),
        ],
      ],
    );
  }

  Widget _seatChip(Map<String, dynamic> seat) {
    final seatId = seat['id'].toString();
    final label = seat['identifier']?.toString() ??
        seat['label']?.toString() ??
        seat['id']?.toString() ??
        '?';
    final available = seat['available'] == true;
    final isSelected = _selectedSeatId == seatId;
    final isHeldByOther = !isSelected && seat['active_lock'] != null;
    final cs = Theme.of(context).colorScheme;

    Color bg;
    Color fg;
    if (isSelected) {
      bg = cs.primary;
      fg = cs.onPrimary;
    } else if (isHeldByOther) {
      bg = Colors.orange[100]!;
      fg = Colors.orange[800]!;
    } else if (!available) {
      bg = Colors.grey[300]!;
      fg = Colors.grey[500]!;
    } else {
      bg = Colors.green[50]!;
      fg = Colors.green[700]!;
    }

    return GestureDetector(
      onTap: (available && !isHeldByOther)
          ? () => _selectSeat(seat)
          : null,
      child: Container(
        width: 48,
        height: 48,
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? cs.primary
                : available && !isHeldByOther
                    ? Colors.green[200]!
                    : Colors.transparent,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            isHeldByOther ? '$label 🔒' : label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: color.withAlpha(100)),
            ),
          ),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      );

  Widget _summaryRow(IconData icon, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(text),
          ],
        ),
      );

  // ── Success view ──────────────────────────────────────────
  Widget _buildSuccess() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 48,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Booking Confirmed!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Booking #${_shortId(_result!['id'])}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),

              // Trip summary
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _checkRow('Trip',
                          widget.trip['trip_number']?.toString() ?? '-'),
                      _checkRow('Date',
                          widget.trip['service_date']?.toString() ?? '-'),
                      _checkRow('Departure',
                          _fmtTs(widget.trip['planned_departure_at'])),
                      if (_result!['seat'] != null)
                        _checkRow(
                            'Seat', '${_result!['seat']}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              ActionButtonRow(
                secondaryLabel: 'Home',
                secondaryOnPressed: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
                primaryLabel: 'My Tickets',
                primaryOnPressed: () {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/tickets',
                    (route) => route.isFirst,
                  );
                },
              ),
            ],
          ),
        ),
      );

  Widget _checkRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            const Icon(Icons.check, size: 18, color: Colors.green),
            const SizedBox(width: 8),
            SizedBox(
              width: 80,
              child: Text(label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  )),
            ),
            Expanded(
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      );

  String _fmtTs(String? ts) {
    if (ts == null) return '-';
    try {
      final dt = DateTime.parse(ts);
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return ts.length > 16 ? ts.substring(0, 16) : ts;
    }
  }
}
