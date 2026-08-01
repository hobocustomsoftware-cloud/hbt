import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/async_state.dart';

/// Two-step passenger trip search.
///
/// Step 1: Pickup / Dropoff city selection from terminals.
/// Step 2: Date + trip results.
class TripSearchScreen extends StatefulWidget {
  const TripSearchScreen({super.key, required this.auth});

  final AuthController auth;

  @override
  State<TripSearchScreen> createState() => _TripSearchScreenState();
}

class _TripSearchScreenState extends State<TripSearchScreen> {
  final AsyncState _state = AsyncState();
  List<Map<String, dynamic>>? _terminals;

  // Route/stop selection
  List<Map<String, dynamic>>? _routes;
  List<Map<String, dynamic>>? _pickupStops;
  List<Map<String, dynamic>>? _dropoffStops;

  // Selection state
  String? _pickupTerminalId;
  String? _dropoffTerminalId;
  String? _selectedRouteId;
  String? _pickupStopId;
  String? _dropoffStopId;
  DateTime _selectedDate = DateTime.now();

  // Independent button loading states
  bool _searching = false;
  bool _loadingRoutes = false;
  List<Map<String, dynamic>>? _trips;

  @override
  void initState() {
    super.initState();
    _loadTerminals();
  }

  /// Safely extract a `List<dynamic>` from a dynamic API response.
  List<dynamic> _extractList(dynamic response) {
    if (response is List<dynamic>) return response;
    if (response is Map<String, dynamic>) {
      final results = response['results'];
      if (results is List<dynamic>) return results;
    }
    return <dynamic>[];
  }

  /// Safely convert a `List<dynamic>` to a list of `Map<String, dynamic>`.
  List<Map<String, dynamic>> _toMapList(List<dynamic> list) {
    final out = <Map<String, dynamic>>[];
    for (final item in list) {
      if (item is Map<String, dynamic>) out.add(item);
    }
    return out;
  }

  // ---- Terminal loading --------------------------------------------------
  Future<void> _loadTerminals() async {
    _state.startLoading();
    try {
      final data = await widget.auth.api.get('/terminals/');
      final list = _toMapList(_extractList(data));
      setState(() {
        _terminals = list;
        _state.doneLoading();
      });
    } on ApiException catch (e) {
      setState(() => _state.fail(e.message));
    } catch (e) {
      setState(() => _state.fail('Failed to load terminals: $e'));
    }
  }

  // ---- Routes loading (parallelized to eliminate N+1) --------------------
  Future<void> _loadRoutes() async {
    if (_pickupTerminalId == null || _dropoffTerminalId == null) return;

    setState(() {
      _loadingRoutes = true;
      _routes = null;
      _pickupStops = null;
      _dropoffStops = null;
      _selectedRouteId = null;
      _pickupStopId = null;
      _dropoffStopId = null;
      _trips = null;
      _state.error = null;
    });

    try {
      final matchedRoutes = <Map<String, dynamic>>[];
      final orgData = await widget.auth.api.get('/me/organizations/');
      final orgs = _toMapList(_extractList(orgData));

      // Phase 1: Fetch all routes for all orgs in parallel.
      final orgRouteFutures = <Future<List<Map<String, dynamic>>>>[];
      final orgIds = <String>[];
      for (final org in orgs) {
        final orgId = org['id']?.toString();
        if (orgId == null) continue;
        orgIds.add(orgId);
        orgRouteFutures.add(_fetchOrgRoutes(orgId));
      }

      final allOrgRoutes = await Future.wait(orgRouteFutures);

      // Phase 2: Fetch stops for every route across all orgs in parallel.
      final stopFutures = <Future<List<Map<String, dynamic>>>>[];
      final routeIndex = <String, Map<String, dynamic>>{};
      for (var oi = 0; oi < allOrgRoutes.length; oi++) {
        for (final route in allOrgRoutes[oi]) {
          final routeId = route['id']?.toString();
          if (routeId == null) continue;
          routeIndex[routeId] = route;
          stopFutures.add(_fetchRouteStops(orgIds[oi], routeId));
        }
      }

      final allStops = await Future.wait(stopFutures);

      // Phase 3: Client-side matching (same logic as before).
      for (var i = 0; i < stopFutures.length; i++) {
        final routeId = routeIndex.keys.elementAt(i);
        final route = routeIndex[routeId]!;
        final stops = allStops[i];

        final pickupMatch = stops.where(
          (s) => s['terminal']?.toString() == _pickupTerminalId,
        ).toList();
        final dropoffMatch = stops.where(
          (s) => s['terminal']?.toString() == _dropoffTerminalId,
        ).toList();

        if (pickupMatch.isNotEmpty && dropoffMatch.isNotEmpty) {
          route['_pickup_stops'] = pickupMatch;
          route['_dropoff_stops'] = dropoffMatch;
          matchedRoutes.add(route);
        }
      }

      if (mounted) {
        setState(() {
          _routes = matchedRoutes;
          _loadingRoutes = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _state.fail('Route search failed: ${e.message}');
          _loadingRoutes = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _state.fail('Route search failed: $e');
          _loadingRoutes = false;
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchOrgRoutes(String orgId) async {
    try {
      final data = await widget.auth.api.get('/organizations/$orgId/routes/');
      return _toMapList(_extractList(data));
    } on ApiException {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchRouteStops(
      String orgId, String routeId) async {
    try {
      final data = await widget.auth.api.get(
        '/organizations/$orgId/routes/$routeId/stops/',
      );
      return _toMapList(_extractList(data));
    } on ApiException {
      return [];
    }
  }

  // ---- Trip search -------------------------------------------------------
  Future<void> _searchTrips() async {
    if (_pickupStopId == null || _dropoffStopId == null) return;

    setState(() {
      _searching = true;
      _state.error = null;
      _trips = null;
    });

    try {
      final dateStr =
          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
      final data = await widget.auth.api.get(
        '/passenger/trips/search/'
        '?pickup_stop=$_pickupStopId'
        '&dropoff_stop=$_dropoffStopId'
        '&date=$dateStr',
      );
      final list = _toMapList(_extractList(data));
      setState(() {
        _trips = list;
        _searching = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _state.fail(e.message);
        _searching = false;
      });
    } catch (e) {
      setState(() {
        _state.fail('Search failed: $e');
        _searching = false;
      });
    }
  }

  // ---- UI -----------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (_state.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadTerminals,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_trips == null) ..._buildSearchForm() else ..._buildResults(),
        ],
      ),
    );
  }

  List<Widget> _buildSearchForm() {
    final terminals = _terminals;

    // Group terminals by city
    final cityGroups = <String, List<Map<String, dynamic>>>{};
    if (terminals != null) {
      for (final t in terminals) {
        final city = t['city'] as String? ?? 'Unknown';
        cityGroups.putIfAbsent(city, () => []).add(t);
      }
    }

    return [
      const Text(
        'Where are you going?',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 16),

      // Pickup terminal
      DropdownButtonFormField<String>(
        initialValue: _pickupTerminalId,
        decoration: const InputDecoration(
          labelText: 'From',
          prefixIcon: Icon(Icons.trip_origin),
          border: OutlineInputBorder(),
        ),
        items: _terminalItems(cityGroups),
        onChanged: (v) => setState(() => _pickupTerminalId = v),
      ),
      const SizedBox(height: 12),

      // Dropoff terminal
      DropdownButtonFormField<String>(
        initialValue: _dropoffTerminalId,
        decoration: const InputDecoration(
          labelText: 'To',
          prefixIcon: Icon(Icons.location_on),
          border: OutlineInputBorder(),
        ),
        items: _terminalItems(cityGroups),
        onChanged: (v) => setState(() => _dropoffTerminalId = v),
      ),
      const SizedBox(height: 16),

      // Find routes button
      if (_pickupTerminalId != null && _dropoffTerminalId != null)
        FilledButton.icon(
          onPressed: _loadingRoutes ? null : _loadRoutes,
          icon: _loadingRoutes
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.route),
          label: const Text('Find Routes'),
        ),
      const SizedBox(height: 16),

      // Route selection
      if (_routes != null && _routes!.isNotEmpty) ...[
        DropdownButtonFormField<String>(
          initialValue: _selectedRouteId,
          decoration: const InputDecoration(
            labelText: 'Select Route',
            border: OutlineInputBorder(),
          ),
          items: _routes!.map((r) {
            final name = '${r['display_name'] ?? r['name'] ?? 'Route'}';
            return DropdownMenuItem(
              value: r['id'].toString(),
              child: Text(name),
            );
          }).toList(),
          onChanged: (v) {
            setState(() {
              _selectedRouteId = v;
              _pickupStopId = null;
              _dropoffStopId = null;
              final route = _routes!.firstWhere(
                (r) => r['id'].toString() == v,
              );
              final rawPickup = route['_pickup_stops'];
              final rawDropoff = route['_dropoff_stops'];
              _pickupStops = (rawPickup is List)
                  ? _toMapList(rawPickup.cast<dynamic>())
                  : [];
              _dropoffStops = (rawDropoff is List)
                  ? _toMapList(rawDropoff.cast<dynamic>())
                  : [];
            });
          },
        ),
        const SizedBox(height: 12),

        if (_pickupStops != null && _selectedRouteId != null) ...[
          DropdownButtonFormField<String>(
            initialValue: _pickupStopId,
            decoration: const InputDecoration(
              labelText: 'Pickup Stop',
              border: OutlineInputBorder(),
            ),
            items: _pickupStops!.map((s) {
              return DropdownMenuItem(
                value: s['id'].toString(),
                child: Text(s['name'] ?? 'Stop'),
              );
            }).toList(),
            onChanged: (v) => setState(() => _pickupStopId = v),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _dropoffStopId,
            decoration: const InputDecoration(
              labelText: 'Dropoff Stop',
              border: OutlineInputBorder(),
            ),
            items: _dropoffStops!.map((s) {
              return DropdownMenuItem(
                value: s['id'].toString(),
                child: Text(s['name'] ?? 'Stop'),
              );
            }).toList(),
            onChanged: (v) => setState(() => _dropoffStopId = v),
          ),
          const SizedBox(height: 12),
        ],
      ],

      // Date picker
      if (_selectedRouteId != null) ...[
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 60)),
            );
            if (picked != null) setState(() => _selectedDate = picked);
          },
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Travel Date',
              prefixIcon: Icon(Icons.calendar_today),
              border: OutlineInputBorder(),
            ),
            child: Text(
              '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
            ),
          ),
        ),
        const SizedBox(height: 16),

        FilledButton.icon(
          onPressed: _searching ? null : _searchTrips,
          icon: _searching
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.search),
          label: const Text('Search Trips'),
        ),
      ],

      // Empty routes
      if (_routes != null && _routes!.isEmpty) ...[
        const SizedBox(height: 16),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'No routes found between these cities.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],

      // Error
      if (_state.error != null)
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text(
            _state.error!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
    ];
  }

  List<DropdownMenuItem<String>> _terminalItems(
    Map<String, List<Map<String, dynamic>>> cityGroups,
  ) {
    final items = <DropdownMenuItem<String>>[];
    final sortedCities = cityGroups.keys.toList()..sort();
    for (final city in sortedCities) {
      for (final t in cityGroups[city]!) {
        items.add(
          DropdownMenuItem(
            value: t['id'].toString(),
            child: Text('$city — ${t['name']}'),
          ),
        );
      }
    }
    return items;
  }

  // ---- Results -----------------------------------------------------------
  List<Widget> _buildResults() {
    if (_trips!.isEmpty) {
      return [
        const SizedBox(height: 40),
        const Icon(Icons.search_off, size: 64, color: Colors.grey),
        const SizedBox(height: 12),
        const Center(child: Text('No trips found for this route and date.')),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () => setState(() => _trips = null),
            child: const Text('Back to Search'),
          ),
        ),
      ];
    }

    return [
      Row(
        children: [
          const BackButton(),
          Expanded(
            child: Text(
              'Found ${_trips!.length} trip(s)',
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      ..._trips!.map((trip) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.directions_bus),
              title: Text(
                trip['trip_number']?.toString() ?? 'Trip',
              ),
              subtitle: Text(
                '${trip['organization_name']?.toString() ?? 'Bus Co.'}\n'
                'Depart: ${_formatDate(trip['planned_departure_at'])}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).pushNamed(
                '/trip-detail',
                arguments: {
                  'trip': trip,
                  'pickup_stop': _pickupStopId,
                  'dropoff_stop': _dropoffStopId,
                },
              ),
            ),
          )),
    ];
  }

  String _formatDate(String? dt) {
    if (dt == null) return '-';
    return dt.substring(0, dt.length > 16 ? 16 : dt.length).replaceAll('T', ' ');
  }
}
