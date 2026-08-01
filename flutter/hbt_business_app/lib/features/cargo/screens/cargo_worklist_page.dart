import 'package:flutter/material.dart';

import '../../auth/controllers/session_controller.dart';
import '../../../shared/services/api_client.dart';
import '../../../core/widgets/async_state.dart';
import '../../../core/widgets/async_views.dart';
import '../../../core/widgets/app_dialog.dart';
import 'cargo_acceptance_page.dart';

class CargoWorklistPage extends StatefulWidget {
  const CargoWorklistPage({super.key, required this.session});

  final SessionController session;

  @override
  State<CargoWorklistPage> createState() => _CargoWorklistPageState();
}

class _CargoWorklistPageState extends State<CargoWorklistPage> {
  final AsyncState _state = AsyncState();
  List<Map<String, dynamic>> _shipments = [];

  String get _organizationId => widget.session.activeOrganization!.organization.id;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _state.startLoading();
    try {
      final records = await widget.session.api.getAllPages(
        '/organizations/$_organizationId/cargo/shipments/',
      );
      if (mounted) {
        setState(() {
          _shipments = records.whereType<Map<String, dynamic>>().toList();
          _state.doneLoading();
        });
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _state.fail(error.message));
    }
  }

  String? _nextStatus(String? current) => switch (current) {
    'assigned' => 'loaded',
    'loaded' => 'in_transit',
    'in_transit' => 'arrived',
    'arrived' => 'ready_pickup',
    _ => null,
  };

  Future<void> _transition(Map<String, dynamic> shipment) async {
    final next = _nextStatus(shipment['status'] as String?);
    if (next == null) return;
    try {
      await widget.session.api.post(
        '/organizations/$_organizationId/cargo/shipments/${shipment['id']}/transition/',
        {'to_status': next, 'notes': ''},
      );
      await _load();
    } on ApiException catch (error) {
      if (mounted) setState(() => _state.fail(error.message));
    }
  }

  Future<void> _assignTrip(Map<String, dynamic> shipment) async {
    try {
      final trips = (await widget.session.api.getList('/organizations/$_organizationId/trips/'))
          .whereType<Map<String, dynamic>>()
          .where((trip) => !{'completed', 'cancelled'}.contains(trip['status']))
          .toList();
      if (!mounted) return;
      final trip = await AppDialog.showPicker<Map<String, dynamic>>(
        context,
        title: 'Trip သတ်မှတ်ရန်',
        items: trips,
        itemBuilder: (item) => Text('${item['trip_number']} • ${item['planned_departure_at']}'),
        emptyLabel: 'အသုံးပြုနိုင်သော trip မရှိပါ။',
      );
      if (trip == null) return;
      await widget.session.api.post(
        '/organizations/$_organizationId/cargo/shipments/${shipment['id']}/assign-trip/',
        {'trip': trip['id'], 'notes': ''},
      );
      await _load();
    } on ApiException catch (error) {
      if (mounted) setState(() => _state.fail(error.message));
    }
  }

  Future<void> _handover(Map<String, dynamic> shipment) async {
    final recipient = TextEditingController();
    final reference = TextEditingController();
    final data = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('လက်ခံသူထံ အပ်နှံရန်'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: recipient, decoration: const InputDecoration(labelText: 'လက်ခံသူအမည်')),
          TextField(controller: reference, decoration: const InputDecoration(labelText: 'ဖုန်း/ID နောက်ဆုံး 4 လုံး')),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('မလုပ်တော့ပါ')), FilledButton(onPressed: () => Navigator.pop(context, {'recipient': recipient.text.trim(), 'reference': reference.text.trim()}), child: const Text('အပ်နှံမည်'))],
      ),
    );
    recipient.dispose();
    reference.dispose();
    if (data == null) return;
    try {
      await widget.session.api.post(
        '/organizations/$_organizationId/cargo/shipments/${shipment['id']}/transition/',
        {'to_status': 'handed_over', 'notes': '', 'evidence': {'verification_method': 'phone', 'verification_reference_last4': data['reference'], 'recipient_name': data['recipient']}},
      );
      await _load();
    } on ApiException catch (error) {
      if (mounted) setState(() => _state.fail(error.message));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.session.hasPermission('cargo.view')) {
      return const Center(child: Text('Cargo records ကြည့်ခွင့်မရှိပါ။'));
    }
    if (_state.loading) return const LoadingView();
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.session.hasPermission('cargo.accept'))
            FilledButton.icon(
              onPressed: () async {
                final accepted = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => CargoAcceptancePage(session: widget.session)));
                if (accepted == true) await _load();
              },
              icon: const Icon(Icons.add_box_outlined),
              label: const Text('Cargo လက်ခံရန်'),
            ),
          if (widget.session.hasPermission('cargo.accept')) const SizedBox(height: 12),
          if (_state.error != null) ErrorCard(message: _state.error!),
          if (_shipments.isEmpty)
            const EmptyListTileCard(message: 'Cargo shipment မရှိသေးပါ။')
          else
            ..._shipments.map((shipment) {
              final next = _nextStatus(shipment['status'] as String?);
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.inventory_2_outlined),
                  title: Text(shipment['shipment_number']?.toString() ?? 'Shipment'),
                  subtitle: Text('${shipment['status']} • ${shipment['payment_status']}'),
                  trailing: !widget.session.hasPermission('cargo.manage')
                      ? null
                      : shipment['status'] == 'accepted'
                          ? FilledButton(onPressed: () => _assignTrip(shipment), child: const Text('Trip သတ်မှတ်'))
                          : shipment['status'] == 'ready_pickup'
                              ? FilledButton(onPressed: () => _handover(shipment), child: const Text('အပ်နှံ'))
                              : next == null
                                  ? null
                                  : FilledButton(onPressed: () => _transition(shipment), child: Text(next)),
                ),
              );
            }),
        ],
      ),
    );
  }
}
