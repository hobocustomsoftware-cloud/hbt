import 'package:flutter/material.dart';

import '../../../shared/services/api_client.dart';
import '../../../core/widgets/async_state.dart';
import '../../../core/widgets/async_views.dart';
import '../../../core/widgets/app_button.dart';
import '../../auth/controllers/session_controller.dart';

class CargoAcceptancePage extends StatefulWidget {
  const CargoAcceptancePage({super.key, required this.session});

  final SessionController session;

  @override
  State<CargoAcceptancePage> createState() => _CargoAcceptancePageState();
}

class _CargoAcceptancePageState extends State<CargoAcceptancePage> {
  final _shipmentNumber = TextEditingController();
  final _category = TextEditingController();
  final _description = TextEditingController();
  final _pieces = TextEditingController(text: '1');
  final _manualCharge = TextEditingController();
  final AsyncState _state = AsyncState();
  List<Map<String, dynamic>> _contacts = [];
  List<Map<String, dynamic>> _terminals = [];
  Map<String, dynamic>? _sender;
  Map<String, dynamic>? _receiver;
  Map<String, dynamic>? _origin;
  Map<String, dynamic>? _destination;

  String get _organizationId => widget.session.activeOrganization!.organization.id;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _shipmentNumber.dispose();
    _category.dispose();
    _description.dispose();
    _pieces.dispose();
    _manualCharge.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _maps(List<dynamic> values) =>
      values.whereType<Map<String, dynamic>>().toList();

  Future<void> _load() async {
    _state.startLoading();
    try {
      final results = await Future.wait([
        widget.session.api.getList('/organizations/$_organizationId/cargo/contacts/'),
        widget.session.api.getList('/organizations/$_organizationId/terminal-operations/'),
      ]);
      if (mounted) {
        setState(() {
          _contacts = _maps(results[0]);
          _terminals = _maps(results[1]).where((item) => item['status'] == 'active').toList();
          _state.doneLoading();
        });
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _state.fail(error.message));
    }
  }

  Future<void> _createContact({required bool sender}) async {
    final code = TextEditingController();
    final name = TextEditingController();
    final phone = TextEditingController();
    final contact = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(sender ? 'ပို့သူအသစ်' : 'လက်ခံသူအသစ်'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: code, decoration: const InputDecoration(labelText: 'Contact code')),
            TextField(controller: name, decoration: const InputDecoration(labelText: 'အမည်')),
            TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'ဖုန်းနံပါတ်')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('မလုပ်တော့ပါ')),
          FilledButton(
            onPressed: () => Navigator.pop(context, {
              'contact_code': code.text.trim(),
              'name': name.text.trim(),
              'phone_number': phone.text.trim(),
              'contact_type': 'individual',
              'identity_type': 'not_provided',
              'identity_missing_reason': 'Counter cargo intake',
            }),
            child: const Text('သိမ်းမည်'),
          ),
        ],
      ),
    );
    code.dispose();
    name.dispose();
    phone.dispose();
    if (contact == null) return;
    try {
      final created = await widget.session.api.post(
        '/organizations/$_organizationId/cargo/contacts/',
        contact,
      );
      if (mounted) {
        setState(() {
          _contacts = [..._contacts, created];
          if (sender) {
            _sender = created;
          } else {
            _receiver = created;
          }
        });
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _state.fail(error.message));
    }
  }

  Future<void> _accept() async {
    if (_sender == null || _receiver == null || _origin == null || _destination == null) {
      setState(() => _state.fail('ပို့သူ၊ လက်ခံသူ၊ စတင်နှင့် ရောက်မည့် terminal ကိုရွေးပါ။'));
      return;
    }
    if (_shipmentNumber.text.trim().isEmpty || _category.text.trim().isEmpty ||
        int.tryParse(_pieces.text.trim()) == null || double.tryParse(_manualCharge.text.trim()) == null) {
      setState(() => _state.fail('Shipment number၊ အမျိုးအစား၊ အထုပ်အရေအတွက်နှင့် ကျသင့်ငွေကို မှန်ကန်စွာဖြည့်ပါ။'));
      return;
    }
    _state.startAction();
    try {
      final shipment = await widget.session.api.post(
        '/organizations/$_organizationId/cargo/shipments/',
        {
          'shipment_number': _shipmentNumber.text.trim(),
          'sender': _sender!['id'],
          'receiver': _receiver!['id'],
          'origin_terminal': _origin!['id'],
          'destination_terminal': _destination!['id'],
          'acceptance_channel': 'counter',
          'item_category': _category.text.trim(),
          'description': _description.text.trim(),
          'piece_count': int.parse(_pieces.text.trim()),
          'pricing_method': 'manual',
          'manual_charge': _manualCharge.text.trim(),
          'currency': 'MMK',
          'liability_acknowledged': true,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${shipment['shipment_number']} ကိုလက်ခံပြီးပါပြီ။')),
        );
        // Record audit
        widget.session.recordAudit(
          action: 'cargo.accept',
          resourceType: 'cargo_shipment',
          resourceId: shipment['id']?.toString() ?? '',
          details: {
            'shipment_number': shipment['shipment_number']?.toString(),
            'origin': _origin!['id'],
            'destination': _destination!['id'],
            'charge': _manualCharge.text.trim(),
          },
        );
        Navigator.pop(context, true);
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _state.fail(error.message));
    } finally {
      if (mounted) setState(() => _state.doneAction());
    }
  }

  String _terminalLabel(Map<String, dynamic> terminal) =>
      terminal['display_name']?.toString() ?? terminal['code']?.toString() ?? 'Terminal';

  @override
  Widget build(BuildContext context) {
    if (_state.loading) return const Scaffold(body: LoadingView());
    return Scaffold(
      appBar: AppBar(title: const Text('Cargo လက်ခံရန်')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_state.error != null) ErrorCard(message: _state.error!),
          TextField(controller: _shipmentNumber, decoration: const InputDecoration(labelText: 'Shipment number', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          _contactPicker('ပို့သူ', _sender, (value) => setState(() => _sender = value), () => _createContact(sender: true)),
          const SizedBox(height: 12),
          _contactPicker('လက်ခံသူ', _receiver, (value) => setState(() => _receiver = value), () => _createContact(sender: false)),
          const SizedBox(height: 12),
          DropdownButtonFormField<Map<String, dynamic>>(key: ValueKey(_origin?['id']), initialValue: _origin, items: _terminals.map((item) => DropdownMenuItem(value: item, child: Text(_terminalLabel(item)))).toList(), onChanged: (value) => setState(() => _origin = value), decoration: const InputDecoration(labelText: 'စတင် terminal', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          DropdownButtonFormField<Map<String, dynamic>>(key: ValueKey(_destination?['id']), initialValue: _destination, items: _terminals.where((item) => item['id'] != _origin?['id']).map((item) => DropdownMenuItem(value: item, child: Text(_terminalLabel(item)))).toList(), onChanged: (value) => setState(() => _destination = value), decoration: const InputDecoration(labelText: 'ရောက်မည့် terminal', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _category, decoration: const InputDecoration(labelText: 'ကုန်အမျိုးအစား', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _description, decoration: const InputDecoration(labelText: 'ဖော်ပြချက် (မဖြစ်မနေမဟုတ်)', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _pieces, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'အထုပ်အရေအတွက်', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _manualCharge, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'ကျသင့်ငွေ (MMK)', border: OutlineInputBorder())),
          const SizedBox(height: 20),
          BusyButton(
            label: 'Cargo လက်ခံမည်',
            onPressed: _accept,
            busy: _state.actionInProgress,
          ),
        ],
      ),
    );
  }

  Widget _contactPicker(String label, Map<String, dynamic>? value, ValueChanged<Map<String, dynamic>?> onChanged, VoidCallback onCreate) =>
      Row(children: [Expanded(child: DropdownButtonFormField<Map<String, dynamic>>(key: ValueKey(value?['id']), initialValue: value, items: _contacts.map((item) => DropdownMenuItem(value: item, child: Text('${item['name']} • ${item['phone_number']}'))).toList(), onChanged: onChanged, decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()))), IconButton(onPressed: onCreate, icon: const Icon(Icons.person_add), tooltip: '$label အသစ်')]);
}
