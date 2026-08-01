import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../../../shared/services/api_client.dart';
import '../../../core/widgets/async_state.dart';
import '../../../core/widgets/async_views.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../auth/controllers/session_controller.dart';

class PaymentDecisionPage extends StatefulWidget {
  const PaymentDecisionPage({
    super.key,
    required this.session,
    required this.booking,
    required this.quote,
  });

  final SessionController session;
  final Map<String, dynamic> booking;
  final Map<String, dynamic> quote;

  @override
  State<PaymentDecisionPage> createState() => _PaymentDecisionPageState();
}

class _PaymentDecisionPageState extends State<PaymentDecisionPage> {
  final _paymentNumber = TextEditingController();
  final _reason = TextEditingController();
  final AsyncState _state = AsyncState();
  Map<String, dynamic>? _payment;
  List<Map<String, dynamic>> _accountVersions = [];
  Map<String, dynamic>? _accountVersion;
  PlatformFile? _evidenceFile;
  String _method = 'wallet_qr';
  List<Map<String, dynamic>> _tickets = [];

  String get _organizationId => widget.session.activeOrganization!.organization.id;
  String get _amount => widget.quote['total_amount']?.toString() ?? '0';
  List<Map<String, dynamic>> get _lines =>
      (widget.quote['lines'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();

  @override
  void dispose() {
    _paymentNumber.dispose();
    _reason.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    _state.startAction();
    try {
      final accounts = await widget.session.api.getList(
        '/organizations/$_organizationId/payment-accounts/',
      );
      if (mounted) {
        setState(() {
          _accountVersions = accounts.whereType<Map<String, dynamic>>().expand(
            (account) => (account['versions'] as List<dynamic>? ?? [])
                .whereType<Map<String, dynamic>>()
                .map((version) => {...version, 'account_label': account['provider_name'] ?? account['account_name']}),
          ).toList();
          _state.doneAction();
        });
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _state.fail(error.message));
    }
  }

  Future<void> _pickEvidence() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
      withData: true,
    );
    if (result?.files.single.bytes != null && mounted) {
      setState(() => _evidenceFile = result!.files.single);
    }
  }

  Future<void> _recordEvidencePayment() async {
    if (_paymentNumber.text.trim().isEmpty || _accountVersion == null || _evidenceFile?.bytes == null) {
      setState(() => _state.fail('Payment reference, receiving account နှင့် evidence file ကို ထည့်ပါ။'));
      return;
    }
    _state.startAction();
    try {
      final upload = await widget.session.api.postMultipart(
        '/organizations/$_organizationId/payment-uploads/',
        fields: {'purpose': 'payment_evidence'},
        fileBytes: _evidenceFile!.bytes!,
        fileName: _evidenceFile!.name,
      );
      final payment = await widget.session.api.post(
        '/organizations/$_organizationId/payments/',
        {
          'payment_number': _paymentNumber.text.trim(),
          'booking': widget.booking['id'],
          'method': _method,
          'amount': _amount,
          'currency': widget.quote['currency'] ?? 'MMK',
          'receiving_account_version': _accountVersion!['id'],
          'evidence_upload': upload['id'],
        },
      );
      if (mounted) {
        setState(() {
          _payment = payment;
          _state.doneAction();
        });
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _state.fail(error.message));
    }
  }

  Future<void> _decide(bool approve) async {
    _state.startAction();
    try {
      final payload = <String, dynamic>{
        'approve': approve,
        'reason': _reason.text.trim(),
      };
      if (approve) {
        payload['tickets'] = _lines.asMap().entries.map((entry) {
          final line = entry.value;
          return {
            'booking_passenger': line['booking_passenger'],
            'ticket_number': '${_payment!['payment_number']}-${entry.key + 1}',
            'ticket_type': 'electronic',
            'fare_amount': line['base_fare'],
            'discount_amount': line['discount_amount'],
            'tax_amount': line['tax_amount'],
            'service_charge': '0',
            'total_amount': line['total_amount'],
            'currency': widget.quote['currency'] ?? 'MMK',
            'issuing_channel': 'counter',
          };
        }).toList();
      }
      final payment = await widget.session.api.post(
        '/organizations/$_organizationId/payments/${_payment!['id']}/decision/',
        payload,
      );
      if (mounted) {
        setState(() => _payment = payment);
      }
      if (approve && widget.session.hasPermission('ticket.view')) {
        final records = await widget.session.api.getList(
          '/organizations/$_organizationId/tickets/',
        );
        if (mounted) {
          setState(() {
            _tickets = records.whereType<Map<String, dynamic>>().where(
              (ticket) => ticket['booking'] == widget.booking['id'],
            ).toList();
          });
        }
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _state.fail(error.message));
    } finally {
      if (mounted) setState(() => _state.doneAction());
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Manual Payment')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppListTileCard(
          title: 'Locked Fare Quote',
          subtitle: '$_amount ${widget.quote['currency'] ?? 'MMK'}',
        ),
        if (_state.error != null) ErrorCard(message: _state.error!),
        if (_payment == null) ...[
          DropdownButtonFormField<String>(
            initialValue: _method,
            items: const [
              DropdownMenuItem(value: 'wallet_qr', child: Text('Wallet QR')),
              DropdownMenuItem(value: 'bank_transfer', child: Text('Bank transfer')),
            ],
            onChanged: (value) => setState(() => _method = value!),
            decoration: const InputDecoration(labelText: 'Payment method', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<Map<String, dynamic>>(
            initialValue: _accountVersion,
            items: _accountVersions.map((version) => DropdownMenuItem(value: version, child: Text('${version['account_label']} • ${version['display_label']}'))).toList(),
            onChanged: (value) => setState(() => _accountVersion = value),
            decoration: const InputDecoration(labelText: 'Receiving account', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickEvidence,
            icon: const Icon(Icons.upload_file),
            label: Text(_evidenceFile?.name ?? 'Payment evidence upload'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _paymentNumber,
            decoration: const InputDecoration(
              labelText: 'Payment reference',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          BusyButton(
            label: 'Payment Evidence တင်မည်',
            onPressed: !widget.session.hasPermission('payment.record')
                ? null
                : _recordEvidencePayment,
            busy: _state.actionInProgress,
          ),
        ] else ...[
          AppListTileCard(
            title: _payment!['payment_number']?.toString() ?? 'Payment',
            subtitle: 'Status: ${_payment!['status']}',
          ),
          TextField(
            controller: _reason,
            decoration: const InputDecoration(
              labelText: 'Approval / rejection note',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          if (_payment!['status'] == 'recorded' ||
              _payment!['status'] == 'submitted')
            ActionButtonRow(
              secondaryLabel: 'Reject',
              secondaryOnPressed: _state.actionInProgress ||
                      !widget.session.hasPermission('payment.confirm')
                  ? null
                  : () => _decide(false),
              primaryLabel: 'Confirm + Issue',
              primaryOnPressed: _state.actionInProgress ||
                      !widget.session.hasPermission('payment.confirm') ||
                      !widget.session.hasPermission('ticket.issue')
                  ? null
                  : () => _decide(true),
              primaryBusy: _state.actionInProgress,
            ),
          if (_tickets.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Issued Tickets', style: Theme.of(context).textTheme.titleMedium),
            ..._tickets.map(
              (ticket) => AppListTileCard(
                title: ticket['ticket_number']?.toString() ?? 'Ticket',
                subtitle: ticket['passenger_name']?.toString() ?? '',
              ),
            ),
          ],
        ],
      ],
    ),
  );
}
