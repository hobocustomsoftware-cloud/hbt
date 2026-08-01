import 'package:flutter/material.dart';

import '../../auth/controllers/session_controller.dart';
import '../../../infrastructure/offline/connectivity_monitor.dart';
import '../../../infrastructure/offline/device_registry.dart';
import '../../../infrastructure/offline/sync_manager.dart';

/// Sync and device status page (replaces the placeholder tab).
///
/// Shows device registration state, backend connectivity, the last sync
/// cursor, and a manual "Sync now" action. Pending offline operations
/// surface here once the upload queue has items.
class SyncStatusPage extends StatefulWidget {
  const SyncStatusPage({
    super.key,
    required this.session,
    required this.registry,
    required this.monitor,
    this.syncManager,
  });

  final SessionController session;
  final DeviceRegistry registry;
  final ConnectivityMonitor monitor;
  final SyncManager? syncManager;

  @override
  State<SyncStatusPage> createState() => _SyncStatusPageState();
}

class _SyncStatusPageState extends State<SyncStatusPage> {
  bool _syncing = false;
  String? _syncResult;

  @override
  void initState() {
    super.initState();
    widget.registry.addListener(_onChanged);
    widget.monitor.addListener(_onChanged);
    widget.syncManager?.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.registry.removeListener(_onChanged);
    widget.monitor.removeListener(_onChanged);
    widget.syncManager?.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _syncNow() async {
    final sync = widget.syncManager;
    final orgId = widget.session.activeOrganization?.organization.id;
    if (sync == null || orgId == null) {
      setState(() => _syncResult = 'Sync not ready (offline bootstrap pending).');
      return;
    }
    setState(() {
      _syncing = true;
      _syncResult = null;
    });
    final ok = await sync.syncAll(orgId.toString());
    if (mounted) {
      setState(() {
        _syncing = false;
        _syncResult = ok ? 'Sync completed.' : 'Sync failed — see error below.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sync = widget.syncManager;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StatusCard(
          icon: Icons.wifi,
          title: 'Connectivity',
          status: widget.monitor.isOnline ? 'Online' : 'Offline',
          color: widget.monitor.isOnline ? Colors.green : Colors.orange,
        ),
        const SizedBox(height: 12),
        _StatusCard(
          icon: Icons.smartphone,
          title: 'Device',
          status: widget.registry.installationId == null
              ? 'Not initialized'
              : widget.registry.registered
                  ? 'Registered'
                  : 'Not registered',
          color: widget.registry.registered ? Colors.green : Colors.orange,
          detail: widget.registry.installationId != null
              ? 'ID: ${widget.registry.installationId!.substring(0, 8)}…'
              : null,
        ),
        const SizedBox(height: 12),
        _StatusCard(
          icon: Icons.storage,
          title: 'Local database',
          status: 'Encrypted (SQLCipher)',
          color: Colors.teal,
        ),
        const SizedBox(height: 12),
        _StatusCard(
          icon: Icons.sync,
          title: 'Last sync cursor',
          status: widget.registry.lastSyncCursor ?? 'None yet',
          color: Colors.blueGrey,
        ),
        if (sync != null && sync.lastError != null) ...[
          const SizedBox(height: 12),
          Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Last sync error: ${sync.lastError}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
          ),
        ],
        if (_syncResult != null) ...[
          const SizedBox(height: 12),
          Text(_syncResult!,
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: (_syncing || sync == null) ? null : _syncNow,
          icon: _syncing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.sync),
          label: Text(_syncing ? 'Syncing…' : 'Sync Now'),
        ),
        const SizedBox(height: 12),
        const Text(
          'Full offline booking mode (queued operations) is the next '
          'milestone; this page will list pending work items then.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.title,
    required this.status,
    required this.color,
    this.detail,
  });

  final IconData icon;
  final String title;
  final String status;
  final Color color;
  final String? detail;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      subtitle: detail == null ? null : Text(detail!),
      trailing: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}
