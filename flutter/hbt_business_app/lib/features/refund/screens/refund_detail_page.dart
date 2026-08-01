import 'package:flutter/material.dart';

import '../../../shared/services/api_client.dart';
import '../../../core/widgets/async_state.dart';
import '../../../core/widgets/async_views.dart';
import '../../auth/controllers/session_controller.dart';
import '../../../shared/services/refund_service.dart';

/// Shows a single refund request with lifecycle actions.
///
/// Action buttons render based on current status and user permissions:
/// - `requested` → Approve / Reject (requires `refund.approve`)
/// - `approved` → Mark Paid (requires `refund.pay`)
/// - `paid` → Complete (requires `refund.complete`)
class RefundDetailPage extends StatefulWidget {
  const RefundDetailPage({
    super.key,
    required this.session,
    required this.refund,
  });

  final SessionController session;
  final Map<String, dynamic> refund;

  @override
  State<RefundDetailPage> createState() => _RefundDetailPageState();
}

class _RefundDetailPageState extends State<RefundDetailPage> {
  late final RefundService _service;
  late Map<String, dynamic> _refund;
  final AsyncState _state = AsyncState();
  bool _actionBusy = false;

  @override
  void initState() {
    super.initState();
    _state.doneLoading(); // Data provided via constructor
    _service = RefundService(session: widget.session);
    _refund = widget.refund;
  }

  Future<void> _reload() async {
    _state.startLoading();
    try {
      _refund = await _service.get(_refund['id'] as String);
      _state.doneLoading();
    } on ApiException catch (e) {
      _state.fail(e.message);
    } catch (e) {
      _state.fail('$e');
    }
    if (mounted) setState(() {});
  }

  Future<void> _runAction(Future<void> Function() action) async {
    setState(() {
      _actionBusy = true;
      _state.error = null;
    });
    try {
      await action();
    } on ApiException catch (e) {
      if (mounted) setState(() => _state.error = e.message);
    } catch (e) {
      if (mounted) setState(() => _state.error = '$e');
    } finally {
      if (mounted) setState(() => _actionBusy = false);
    }
  }

  /// Show a simple form dialog for a single text field.
  Future<String?> _showTextFieldDialog({
    required String title,
    required String label,
    int maxLines = 1,
    String? initialValue,
  }) {
    final controller = TextEditingController(text: initialValue);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  /// Show a multi-field dialog with cancel/confirm.
  Future<Map<String, String>?> _showMultiFieldDialog({
    required String title,
    required List<_FieldConfig> fields,
  }) {
    final controllers = fields.map((f) => TextEditingController(text: f.initialValue ?? '')).toList();
    return showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < fields.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                TextField(
                  controller: controllers[i],
                  maxLines: fields[i].maxLines,
                  decoration: InputDecoration(
                    labelText: fields[i].label,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final result = <String, String>{};
              for (var i = 0; i < fields.length; i++) {
                result[fields[i].key] = controllers[i].text.trim();
              }
              Navigator.pop(ctx, result);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  // ── Action handlers ──────────────────────────────────────────────

  Future<void> _approve(bool approve) async {
    if (!approve) {
      final reason = await _showTextFieldDialog(
        title: 'Reject Refund',
        label: 'Rejection reason',
        maxLines: 3,
      );
      if (reason == null || reason.isEmpty) return;
      await _runAction(() async {
        _refund = await _service.decide(
          refundId: _refund['id'] as String,
          approve: false,
          reason: reason,
        );
      });
      return;
    }

    final result = await _showMultiFieldDialog(
      title: 'Approve Refund',
      fields: [
        _FieldConfig(
          key: 'amount',
          label: 'Approved Amount',
          initialValue: _refund['requested_amount']?.toString(),
        ),
        _FieldConfig(key: 'note', label: 'Note (optional)', maxLines: 2),
      ],
    );
    if (result == null) return;

    await _runAction(() async {
      _refund = await _service.decide(
        refundId: _refund['id'] as String,
        approve: true,
        approvedAmount: double.tryParse(result['amount'] ?? ''),
        reason: result['note'] ?? '',
      );
    });
  }

  Future<void> _markPaid() async {
    final ref = await _showTextFieldDialog(
      title: 'Record Payout',
      label: 'Payout Reference',
    );
    if (ref == null || ref.isEmpty) return;

    await _runAction(() async {
      _refund = await _service.markPaid(
        refundId: _refund['id'] as String,
        payoutReference: ref,
      );
    });
  }

  Future<void> _complete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete Refund'),
        content: const Text(
          'This will cancel the associated ticket (if any) and finalize the refund. Continue?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Complete')),
        ],
      ),
    );
    if (confirmed != true) return;

    await _runAction(() async {
      _refund = await _service.complete(_refund['id'] as String);
    });
  }

  // ── Actions per status ───────────────────────────────────────────

  List<Widget> _actionButtons() {
    final status = _refund['status'] as String? ?? '';
    final perms = widget.session;
    final buttons = <Widget>[];

    switch (status) {
      case 'requested':
        if (perms.hasPermission('refund.approve')) {
          buttons.addAll([
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _actionBusy ? null : () => _approve(false),
                icon: const Icon(Icons.close),
                label: const Text('Reject'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: _actionBusy ? null : () => _approve(true),
                icon: _actionBusy
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check),
                label: const Text('Approve'),
              ),
            ),
          ]);
        }
      case 'approved':
        if (perms.hasPermission('refund.pay')) {
          buttons.add(
            FilledButton.icon(
              onPressed: _actionBusy ? null : _markPaid,
              icon: _actionBusy
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.payments),
              label: const Text('Mark Paid'),
            ),
          );
        }
      case 'paid':
        if (perms.hasPermission('refund.complete')) {
          buttons.add(
            FilledButton.icon(
              onPressed: _actionBusy ? null : _complete,
              icon: _actionBusy
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.done_all),
              label: const Text('Complete Refund'),
            ),
          );
        }
    }

    return buttons;
  }

  Color _statusColor(String? status) => switch (status) {
    'requested' => Colors.orange,
    'approved' => Colors.green,
    'paid' => Colors.blue,
    'completed' => Colors.green.shade700,
    'rejected' => Colors.red,
    'cancelled' => Colors.grey,
    _ => Colors.grey,
  };

  String _statusLabel(String? status) => switch (status) {
    'requested' => 'Pending Approval',
    'approved' => 'Approved',
    'paid' => 'Payout Recorded',
    'completed' => 'Completed',
    'rejected' => 'Rejected',
    'cancelled' => 'Cancelled',
    _ => status ?? 'unknown',
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Refund Detail')),
    body: RefreshIndicator(
      onRefresh: () async => _reload(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status banner
          if (_state.loading)
            const LoadingView()
          else ...[
            Card(
              color: _statusColor(_refund['status'] as String?).withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: _statusColor(_refund['status'] as String?),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _statusLabel(_refund['status'] as String?),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _statusColor(_refund['status'] as String?),
                            ),
                          ),
                          if (_refund['refund_number'] != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              _refund['refund_number'] as String,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Error
            if (_state.error != null) ...[
              ErrorCard(message: _state.error!),
              const SizedBox(height: 12),
            ],

            // Details
            _InfoRow(label: 'Refund Number', value: _refund['refund_number']?.toString() ?? '—'),
            _InfoRow(label: 'Payment', value: _refund['payment']?.toString() ?? '—'),
            _InfoRow(label: 'Requested Amount', value: '${_refund['requested_amount']} ${_refund['currency'] ?? 'MMK'}'),
            if (_refund['approved_amount'] != null)
              _InfoRow(label: 'Approved Amount', value: '${_refund['approved_amount']} ${_refund['currency'] ?? 'MMK'}'),
            _InfoRow(label: 'Reason', value: _refund['reason']?.toString() ?? '—', multiLine: true),
            if (_refund['ticket'] != null)
              _InfoRow(label: 'Ticket', value: _refund['ticket']?.toString() ?? '—'),
            if (_refund['decision_reason']?.toString().isNotEmpty == true)
              _InfoRow(label: 'Decision Note', value: _refund['decision_reason']?.toString() ?? ''),

            const Divider(height: 24),
            Text('Timeline', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            if (_refund['created_at'] != null)
              _TimelineItem(icon: Icons.add_circle_outline, label: 'Requested', timestamp: _refund['created_at'] as String?),
            if (_refund['decided_at'] != null)
              _TimelineItem(
                icon: _refund['status'] == 'rejected' ? Icons.cancel_outlined : Icons.check_circle_outline,
                label: _refund['status'] == 'rejected' ? 'Rejected' : 'Approved',
                timestamp: _refund['decided_at'] as String?,
              ),
            if (_refund['paid_at'] != null)
              _TimelineItem(
                icon: Icons.payments_outlined,
                label: 'Paid',
                subtitle: _refund['payout_reference']?.toString(),
                timestamp: _refund['paid_at'] as String?,
              ),
            if (_refund['completed_at'] != null)
              _TimelineItem(icon: Icons.done_all, label: 'Completed', timestamp: _refund['completed_at'] as String?),

            const SizedBox(height: 24),

            // Actions
            if (_actionButtons().isNotEmpty) ...[
              const Divider(),
              const SizedBox(height: 8),
              Row(children: _actionButtons()),
            ],
          ],
        ],
      ),
    ),
  );
}

class _FieldConfig {
  final String key;
  final String label;
  final String? initialValue;
  final int maxLines;
  const _FieldConfig({
    required this.key,
    required this.label,
    this.initialValue,
    this.maxLines = 1,
  });
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.multiLine = false});

  final String label;
  final String value;
  final bool multiLine;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: multiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 140,
          child: Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500, color: Colors.grey.shade600)),
        ),
        Expanded(
          child: multiLine ? Text(value) : Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ),
      ],
    ),
  );
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({required this.icon, required this.label, this.subtitle, this.timestamp});

  final IconData icon;
  final String label;
  final String? subtitle;
  final String? timestamp;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
              if (subtitle != null && subtitle!.isNotEmpty)
                Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        if (timestamp != null)
          Text(
            _formatTimestamp(timestamp!),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
      ],
    ),
  );

  String _formatTimestamp(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}
