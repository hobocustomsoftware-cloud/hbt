import 'package:flutter/material.dart';

import '../../../shared/services/api_client.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/async_state.dart';
import '../../../core/widgets/async_views.dart';
import '../../auth/controllers/session_controller.dart';
import '../../../shared/services/refund_service.dart';

/// Form to create a new refund request.
///
/// Requires `refund.request` permission. The user selects a confirmed
/// payment, optionally a ticket, enters a reason, and the refund amount
/// defaults to the payment amount.
class RefundCreatePage extends StatefulWidget {
  const RefundCreatePage({super.key, required this.session});

  final SessionController session;

  @override
  State<RefundCreatePage> createState() => _RefundCreatePageState();
}

class _RefundCreatePageState extends State<RefundCreatePage> {
  late final RefundService _service;
  final AsyncState _state = AsyncState();
  final _reasonController = TextEditingController();
  List<Map<String, dynamic>> _payments = [];
  List<Map<String, dynamic>> _tickets = [];
  Map<String, dynamic>? _selectedPayment;
  Map<String, dynamic>? _selectedTicket;
  double _requestedAmount = 0;
  String? _success;

  String get _orgId => widget.session.activeOrganization?.organization.id ?? '';

  @override
  void initState() {
    super.initState();
    _state.startLoading();
    _service = RefundService(session: widget.session);
    _load();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final payments = await widget.session.api.getList(
        '/organizations/$_orgId/payments/',
      );
      _payments = payments.cast<Map<String, dynamic>>();
      // Only show confirmed payments that haven't been fully refunded
      _payments = _payments
          .where((p) => p['status'] == 'confirmed' || p['status'] == 'refunded')
          .toList();
      _state.doneLoading();
    } on ApiException catch (e) {
      _state.fail(e.message);
    } catch (e) {
      _state.fail('$e');
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadTickets(String paymentId) async {
    try {
      final allTickets = await widget.session.api.getList(
        '/organizations/$_orgId/tickets/',
      );
      _tickets = allTickets.cast<Map<String, dynamic>>();
      // Filter tickets for this payment's booking
      final bookingId = _selectedPayment?['booking']?.toString();
      if (bookingId != null) {
        _tickets = _tickets
            .where((t) =>
                t['booking']?.toString() == bookingId &&
                t['status'] != 'cancelled' &&
                t['status'] != 'archived')
            .toList();
      }
    } on ApiException {
      // Non-critical — tickets are optional
      _tickets = [];
    }
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    if (_selectedPayment == null) {
      _state.fail('Please select a payment.');
      if (mounted) setState(() {});
      return;
    }
    if (_reasonController.text.trim().isEmpty) {
      _state.fail('Please enter a reason for the refund.');
      if (mounted) setState(() {});
      return;
    }
    if (_requestedAmount <= 0) {
      _state.fail('Refund amount must be greater than zero.');
      if (mounted) setState(() {});
      return;
    }

    _state.startAction();
    try {
      await _service.request(
        paymentId: _selectedPayment!['id'] as String,
        requestedAmount: _requestedAmount,
        reason: _reasonController.text.trim(),
        ticketId: _selectedTicket?['id'] as String?,
      );
      if (mounted) {
        // Record audit
        widget.session.recordAudit(
          action: 'refund.request',
          resourceType: 'refund',
          resourceId: _selectedPayment!['id'] as String,
          details: {
            'payment_id': _selectedPayment!['id'],
            'amount': _requestedAmount,
            'reason': _reasonController.text.trim(),
            if (_selectedTicket != null)
              'ticket_id': _selectedTicket!['id'],
          },
        );
        setState(() {
          _success = 'Refund request submitted successfully.';
          _state.doneAction();
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        _state.fail(e.message);
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        _state.fail('$e');
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Request Refund')),
    body: _state.loading
        ? const LoadingView()
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_state.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ErrorCard(message: _state.error!),
                ),
              if (_success != null) ...[
                Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 48),
                        const SizedBox(height: 8),
                        Text(_success!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Back to List'),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                // Payment selector
                DropdownButtonFormField<Map<String, dynamic>>(
                  initialValue: _selectedPayment,
                  items: _payments.isNotEmpty
                      ? _payments.map((p) => DropdownMenuItem(
                            value: p,
                            child: Text('${p['payment_number']} — ${p['amount']} ${p['currency'] ?? 'MMK'}'),
                          )).toList()
                      : [const DropdownMenuItem(value: null, child: Text('No confirmed payments'))],
                  onChanged: (value) {
                    setState(() {
                      _selectedPayment = value;
                      _selectedTicket = null;
                      if (value != null) {
                        _requestedAmount = double.tryParse(value['amount']?.toString() ?? '0') ?? 0;
                        _loadTickets(value['id'] as String);
                      }
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Payment', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),

                // Ticket picker
                if (_tickets.isNotEmpty) ...[
                  DropdownButtonFormField<Map<String, dynamic>>(
                    initialValue: _selectedTicket,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('— No specific ticket —')),
                      ..._tickets.map((t) => DropdownMenuItem(
                            value: t,
                            child: Text('${t['ticket_number']} — ${t['passenger_name']}'),
                          )),
                    ],
                    onChanged: (value) => setState(() => _selectedTicket = value),
                    decoration: const InputDecoration(labelText: 'Ticket (optional)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                ],

                // Amount
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Refund Amount (MMK)',
                    border: OutlineInputBorder(),
                  ),
                  controller: TextEditingController(
                    text: _requestedAmount.toString(),
                  ),
                  onChanged: (value) => _requestedAmount = double.tryParse(value) ?? 0,
                ),
                const SizedBox(height: 12),

                // Reason
                TextField(
                  controller: _reasonController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Reason for Refund',
                    border: OutlineInputBorder(),
                    hintText: 'Explain why this refund is being requested…',
                  ),
                ),
                const SizedBox(height: 16),

                BusyButton(
                  label: 'Submit Refund Request',
                  onPressed: _save,
                  busy: _state.actionInProgress,
                  icon: const Icon(Icons.send),
                ),
              ],
            ],
          ),
  );
}
