import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../../features/printer/controllers/print_controller.dart';
import '../../shared/models/printer_models.dart';

/// Dialog for printer selection, connection, and print job management.
///
/// Shows:
/// 1. Current printer status (connected/disconnected)
/// 2. Discovered printers list
/// 3. Connect/disconnect actions
/// 4. Print queue with retry
/// 5. Paper size selection
class PrinterDialog extends StatefulWidget {
  const PrinterDialog({
    super.key,
    required this.printController,
    this.onPrintReady,
  });

  final PrintController printController;
  final VoidCallback? onPrintReady;

  /// Show the printer dialog as a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required PrintController printController,
    VoidCallback? onPrintReady,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: PrinterDialog(
          printController: printController,
          onPrintReady: onPrintReady,
        ),
      ),
    );
  }

  @override
  State<PrinterDialog> createState() => _PrinterDialogState();
}

class _PrinterDialogState extends State<PrinterDialog> {
  bool _showDiscovery = false;

  @override
  void initState() {
    super.initState();
    widget.printController.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.printController.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.printController;
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Handle
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text('Printer',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              if (ctrl.isConnected)
                _statusBadge(PrinterStatus.connected, cs)
              else
                _statusBadge(PrinterStatus.disconnected, cs),
            ],
          ),
        ),
        const Divider(height: 1),

        Expanded(
          child: ListView(
            padding: AppTheme.pagePadding,
            children: [
              // ── Connected printer ─────────────────────────
              if (ctrl.connectedPrinter != null)
                _connectedSection(context, ctrl)
              else
                _disconnectedSection(context, ctrl),

              const SizedBox(height: AppTheme.spacingMd),

              // ── Discovery section ─────────────────────────
              if (_showDiscovery) _discoverySection(context, ctrl),

              // ── Print queue ───────────────────────────────
              if (ctrl.printQueue.isNotEmpty) ...[
                const Divider(),
                const SizedBox(height: AppTheme.spacingMd),
                Text('Print Queue',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppTheme.spacingSm),
                ...ctrl.printQueue.map((job) => _jobCard(context, job, cs)),
                if (ctrl.pendingJobCount > 0 || ctrl.printQueue
                    .any((j) => j.status == PrintJobStatus.failed))
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        if (ctrl.printQueue
                            .any((j) => j.status == PrintJobStatus.failed))
                          OutlinedButton.icon(
                            onPressed: () => ctrl.retryAllFailed(),
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Retry Failed'),
                          ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () => ctrl.clearCompleted(),
                          icon: const Icon(Icons.clear_all, size: 18),
                          label: const Text('Clear Completed'),
                        ),
                      ],
                    ),
                  ),
              ],

              // ── Error ─────────────────────────────────────
              if (ctrl.lastError != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppTheme.spacingMd),
                  child: Card(
                    color: cs.errorContainer,
                    child: Padding(
                      padding: AppTheme.cardPadding,
                      child: Row(
                        children: [
                          Icon(Icons.error_outline,
                              color: cs.error, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(ctrl.lastError!,
                                  style: TextStyle(color: cs.error))),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Connected printer section ──────────────────────────────────────
  Widget _connectedSection(BuildContext context, PrintController ctrl) {
    final printer = ctrl.connectedPrinter!;
    return Card(
      child: Padding(
        padding: AppTheme.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.print, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(printer.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => ctrl.disconnect(),
                  icon: const Icon(Icons.link_off, size: 16),
                  label: const Text('Disconnect'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _info('Address', printer.address ?? '-'),
            _info('Paper', printer.paperWidth?.label ?? 'Auto'),
            _info('Type', printer.connectionType.label),
          ],
        ),
      ),
    );
  }

  // ── Disconnected section ───────────────────────────────────────────
  Widget _disconnectedSection(BuildContext context, PrintController ctrl) {
    return Column(
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.print_disabled, color: Colors.grey),
            title: const Text('No Printer Connected'),
            subtitle: const Text('Discover and connect to a thermal printer.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => setState(() => _showDiscovery = !_showDiscovery),
          ),
        ),
      ],
    );
  }

  // ── Discovery section ──────────────────────────────────────────────
  Widget _discoverySection(BuildContext context, PrintController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Discovered Printers',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const Spacer(),
            if (ctrl.discovering)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              TextButton.icon(
                onPressed: () => ctrl.discoverPrinters(),
                icon: const Icon(Icons.search, size: 18),
                label: const Text('Scan'),
              ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingSm),
        if (ctrl.discoveredDevices.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                ctrl.discovering
                    ? 'Scanning for printers…'
                    : 'No printers found. Tap "Scan" to search.',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ),
          )
        else
          ...ctrl.discoveredDevices.map(
            (device) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.print),
                title: Text(device.name),
                subtitle: Text(
                    '${device.address ?? '-'}  •  ${device.paperWidth?.label ?? "Unknown"}'),
                trailing: ctrl.connecting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : FilledButton.tonal(
                        onPressed: () => ctrl.connect(device),
                        child: const Text('Connect'),
                      ),
              ),
            ),
          ),
      ],
    );
  }

  // ── Print job card ─────────────────────────────────────────────────
  Widget _jobCard(BuildContext context, PrintJob job, ColorScheme cs) {
    late Color statusColor;
    late IconData statusIcon;
    switch (job.status) {
      case PrintJobStatus.pending:
        statusColor = Colors.grey;
        statusIcon = Icons.schedule;
      case PrintJobStatus.printing:
        statusColor = Colors.blue;
        statusIcon = Icons.print;
      case PrintJobStatus.completed:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
      case PrintJobStatus.failed:
        statusColor = cs.error;
        statusIcon = Icons.error;
      case PrintJobStatus.cancelled:
        statusColor = Colors.grey;
        statusIcon = Icons.cancel;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${job.documentType.label} (x${job.copies})',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  if (job.errorMessage != null)
                    Text(job.errorMessage!,
                        style: TextStyle(
                            fontSize: 12, color: cs.error)),
                ],
              ),
            ),
            Text(job.status.label,
                style: TextStyle(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.w600)),
            if (job.status == PrintJobStatus.failed)
              IconButton(
                onPressed: () => widget.printController.retryJob(job.id),
                icon: const Icon(Icons.refresh, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────
  Widget _info(String label, String value) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Text('$label: ',
                style: TextStyle(
                    fontSize: 12, color: Colors.grey[600])),
            Text(value,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      );

  Widget _statusBadge(PrinterStatus status, ColorScheme cs) {
    final color = status == PrinterStatus.connected
        ? Colors.green
        : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}
