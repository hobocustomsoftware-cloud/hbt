import 'package:flutter/material.dart';

import '../../../shared/services/api_client.dart';
import '../../../core/widgets/async_state.dart';
import '../../../core/widgets/async_views.dart';
import '../../../core/widgets/status_chip.dart';
import '../../auth/controllers/session_controller.dart';
import '../../../shared/services/refund_service.dart';
import 'refund_create_page.dart';
import 'refund_detail_page.dart';

/// Lists all refund requests for the active organization.
///
/// Supports pull-to-refresh, status filter, and create-new action.
/// Gated behind `refund.view` permission.
class RefundListPage extends StatefulWidget {
  const RefundListPage({super.key, required this.session});

  final SessionController session;

  @override
  State<RefundListPage> createState() => _RefundListPageState();
}

class _RefundListPageState extends State<RefundListPage> {
  late final RefundService _service;
  final AsyncState _state = AsyncState();
  List<Map<String, dynamic>> _items = [];
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _service = RefundService(session: widget.session);
    _load();
  }

  Future<void> _load() async {
    _state.startLoading();
    try {
      _items = await _service.list(status: _statusFilter);
      _state.doneLoading();
    } on ApiException catch (e) {
      _state.fail(e.message);
    } catch (e) {
      _state.fail('$e');
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Refund Requests'),
      actions: [
        if (widget.session.hasPermission('refund.request'))
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Request Refund',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => RefundCreatePage(session: widget.session),
              ),
            ).then((_) => _load()),
          ),
      ],
    ),
    body: Column(
      children: [
        _StatusFilterBar(
          selected: _statusFilter,
          onChanged: (value) {
            setState(() => _statusFilter = value);
            _load();
          },
        ),
        Expanded(child: _body()),
      ],
    ),
  );

  Widget _body() {
    if (_state.loading) {
      return const LoadingView();
    }
    if (_state.error != null) {
      return ErrorView(message: _state.error!, onRetry: _load);
    }
    if (_items.isEmpty) {
      return EmptyView(
        icon: Icons.replay_outlined,
        message: 'No refund requests',
        actionLabel: widget.session.hasPermission('refund.request')
            ? 'Request Refund'
            : null,
        onAction: widget.session.hasPermission('refund.request')
            ? () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        RefundCreatePage(session: widget.session),
                  ),
                ).then((_) => _load())
            : null,
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        itemCount: _items.length,
        itemBuilder: (context, index) => _RefundListItem(
          refund: _items[index],
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RefundDetailPage(
                session: widget.session,
                refund: _items[index],
              ),
            ),
          ).then((_) => _load()),
        ),
      ),
    );
  }
}

class _StatusFilterBar extends StatelessWidget {
  const _StatusFilterBar({required this.selected, required this.onChanged});

  final String? selected;
  final ValueChanged<String?> onChanged;

  static const _options = [
    (null, 'All'),
    ('requested', 'Requested'),
    ('approved', 'Approved'),
    ('paid', 'Paid'),
    ('completed', 'Completed'),
    ('rejected', 'Rejected'),
    ('cancelled', 'Cancelled'),
  ];

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _options.map((entry) {
          final (value, label) = entry;
          final isSelected = selected == value;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (_) => onChanged(value),
            ),
          );
        }).toList(),
      ),
    ),
  );
}

class _RefundListItem extends StatelessWidget {
  const _RefundListItem({required this.refund, required this.onTap});

  final Map<String, dynamic> refund;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    child: ListTile(
      title: Text(
        refund['refund_number']?.toString() ??
            'Refund #${refund['id']?.toString().substring(0, 8)}',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text('Amount: ${refund['requested_amount']} ${refund['currency'] ?? 'MMK'}'),
          if (refund['reason'] is String && (refund['reason'] as String).isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              refund['reason'] as String,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
      trailing: StatusChip(status: refund['status']?.toString() ?? 'unknown'),
      onTap: onTap,
    ),
  );
}
