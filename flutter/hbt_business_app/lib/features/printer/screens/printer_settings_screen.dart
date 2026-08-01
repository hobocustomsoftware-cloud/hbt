import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/printer_models.dart';
import '../controllers/printer_settings_controller.dart';
import '../controllers/print_controller.dart';

/// Printer settings screen.
///
/// Manage default printer, paper width, auto-connect, saved printers,
/// and reprint last document.
class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({
    super.key,
    required this.settingsController,
    required this.printController,
  });

  final PrinterSettingsController settingsController;
  final PrintController printController;

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  @override
  void initState() {
    super.initState();
    widget.settingsController.addListener(_onChanged);
    widget.printController.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.settingsController.removeListener(_onChanged);
    widget.printController.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.settingsController;
    final printCtrl = widget.printController;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Printer Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => printCtrl.discoverPrinters(),
            tooltip: 'Scan for printers',
          ),
        ],
      ),
      body: ListView(
        padding: AppTheme.pagePadding,
        children: [
          // ── Default Printer ──────────────────────────
          Text('Default Printer',
              style: AppTheme.sectionHeaderStyle(context)),
          const SizedBox(height: AppTheme.spacingSm),
          if (settings.defaultPrinterName != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.print, color: Colors.green),
                title: Text(settings.defaultPrinterName!),
                trailing: IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => settings.clearDefaultPrinter(),
                ),
              ),
            )
          else
            Card(
              child: ListTile(
                leading: const Icon(Icons.print_disabled, color: Colors.grey),
                title: const Text('No default printer'),
                subtitle: const Text('Select a printer below'),
              ),
            ),
          const SizedBox(height: AppTheme.spacingMd),

          // ── Paper Width ──────────────────────────────
          Text('Default Paper Size',
              style: AppTheme.sectionHeaderStyle(context)),
          const SizedBox(height: AppTheme.spacingSm),
          Row(
            children: PaperWidth.values.map((width) {
              final selected = settings.defaultPaperWidth == width;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(width.label),
                    selected: selected,
                    onSelected: (_) => settings.setDefaultPaperWidth(width),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppTheme.spacingMd),

          // ── Default Copies ──────────────────────────
          Text('Default Copies',
              style: AppTheme.sectionHeaderStyle(context)),
          const SizedBox(height: AppTheme.spacingSm),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: settings.defaultCopies > 1
                    ? () => settings.setDefaultCopies(settings.defaultCopies - 1)
                    : null,
              ),
              Text('${settings.defaultCopies}',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: settings.defaultCopies < 5
                    ? () => settings.setDefaultCopies(settings.defaultCopies + 1)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),

          // ── Auto-connect ────────────────────────────
          SwitchListTile(
            title: const Text('Auto-connect on startup'),
            subtitle: const Text(
                'Automatically connect to the default printer when the app starts.'),
            value: settings.autoconnect,
            onChanged: (v) => settings.setAutoconnect(v),
          ),
          const Divider(height: 32),

          // ── Connected Printer ─────────────────────────
          Text('Connected Printer',
              style: AppTheme.sectionHeaderStyle(context)),
          const SizedBox(height: AppTheme.spacingSm),
          if (printCtrl.isConnected)
            Card(
              child: ListTile(
                leading: Container(
                  width: 12, height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.green, shape: BoxShape.circle),
                ),
                title: Text(printCtrl.connectedPrinter!.name),
                subtitle: Text(
                    '${printCtrl.connectedPrinter!.address ?? "-"} • ${printCtrl.connectedPrinter!.paperWidth?.label ?? "Auto"}'),
                trailing: TextButton(
                  onPressed: () => printCtrl.disconnect(),
                  child: const Text('Disconnect'),
                ),
              ),
            )
          else
            const Card(
              child: ListTile(
                leading: Icon(Icons.warning_amber, color: Colors.orange),
                title: Text('No printer connected'),
              ),
            ),
          const SizedBox(height: AppTheme.spacingMd),

          // ── Saved Printers ──────────────────────────
          Text('Saved Printers',
              style: AppTheme.sectionHeaderStyle(context)),
          const SizedBox(height: AppTheme.spacingSm),
          if (settings.savedPrinters.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('No saved printers yet.',
                  style: TextStyle(color: Colors.grey[500])),
            )
          else
            ...settings.savedPrinters.map((printer) => Card(
                  margin: const EdgeInsets.only(bottom: 4),
                  child: ListTile(
                    leading: const Icon(Icons.print),
                    title: Text(printer.name),
                    subtitle: Text(
                        '${printer.address ?? "-"} • ${printer.paperWidth?.label ?? "Auto"}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (settings.defaultPrinterId != printer.id)
                          TextButton(
                            onPressed: () => settings.setDefaultPrinter(printer),
                            child: const Text('Set Default'),
                          ),
                        IconButton(
                          icon: Icon(Icons.delete_outline,
                              size: 18, color: cs.error),
                          onPressed: () => settings.forgetPrinter(printer.id),
                        ),
                      ],
                    ),
                  ),
                )),
          const SizedBox(height: AppTheme.spacingMd),

          // ── Discovered Printers ─────────────────────
          Text('Discovered Printers',
              style: AppTheme.sectionHeaderStyle(context)),
          const SizedBox(height: AppTheme.spacingSm),
          if (printCtrl.discovering)
            const Center(child: CircularProgressIndicator())
          else if (printCtrl.discoveredDevices.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: Text(
                  'No printers found. Tap Scan to search.',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ),
            )
          else
            ...printCtrl.discoveredDevices.map((device) => Card(
                  margin: const EdgeInsets.only(bottom: 4),
                  child: ListTile(
                    leading: const Icon(Icons.bluetooth),
                    title: Text(device.name),
                    subtitle: Text(
                        '${device.address ?? "-"} • ${device.paperWidth?.label ?? "Auto"}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.bluetooth_connected, size: 18),
                          onPressed: () => printCtrl.connect(device),
                          tooltip: 'Connect',
                        ),
                        IconButton(
                          icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                          onPressed: () {
                            settings.savePrinter(device);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${device.name} saved'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          tooltip: 'Save printer',
                        ),
                      ],
                    ),
                  ),
                )),
          const SizedBox(height: AppTheme.spacingMd),

          // ── Reprint Last ──────────────────────────────
          const Divider(),
          Text('Reprint',
              style: AppTheme.sectionHeaderStyle(context)),
          const SizedBox(height: AppTheme.spacingSm),
          if (settings.hasLastPrint)
            Card(
              child: ListTile(
                leading: const Icon(Icons.replay, color: Colors.blue),
                title: Text(
                    'Reprint ${settings.lastPrintType?.label ?? "Document"}'),
                subtitle: const Text('Print the last document again'),
                trailing: FilledButton.tonal(
                  onPressed: () => _reprintLast(settings, printCtrl),
                  child: const Text('Reprint'),
                ),
              ),
            )
          else
            Card(
              child: ListTile(
                leading: const Icon(Icons.history, color: Colors.grey),
                title: const Text('No recent print'),
                subtitle: const Text('Printed documents will appear here'),
              ),
            ),
          const SizedBox(height: AppTheme.spacingMd),

          // ── Print Queue ──────────────────────────────
          if (printCtrl.printQueue.isNotEmpty) ...[
            const Divider(),
            Text('Print Queue',
                style: AppTheme.sectionHeaderStyle(context)),
            const SizedBox(height: AppTheme.spacingSm),
            ...printCtrl.printQueue.map((job) => Card(
                  margin: const EdgeInsets.only(bottom: 4),
                  child: ListTile(
                    leading: _jobIcon(job.status),
                    title: Text(job.documentType.label),
                    subtitle: job.errorMessage != null
                        ? Text(job.errorMessage!,
                            style: TextStyle(color: cs.error, fontSize: 12))
                        : Text(job.status.label,
                            style: TextStyle(
                                color: _jobColor(job.status), fontSize: 12)),
                    trailing: job.status == PrintJobStatus.failed
                        ? IconButton(
                            icon: const Icon(Icons.refresh, size: 18),
                            onPressed: () => printCtrl.retryJob(job.id),
                          )
                        : null,
                  ),
                )),
            const SizedBox(height: AppTheme.spacingSm),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => printCtrl.retryAllFailed(),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retry Failed'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => printCtrl.clearCompleted(),
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text('Clear Done'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _reprintLast(
    PrinterSettingsController settings,
    PrintController printCtrl,
  ) async {
    if (!settings.hasLastPrint || settings.lastPrintData == null) return;

    final type = settings.lastPrintType;
    final data = settings.lastPrintData!;

    bool ok;
    switch (type) {
      case PrintDocumentType.ticket:
        ok = await printCtrl.printTicket(data);
      case PrintDocumentType.cargoReceipt:
        ok = await printCtrl.printCargoReceipt(data);
      case PrintDocumentType.refundReceipt:
        ok = await printCtrl.printRefundReceipt(data);
      case PrintDocumentType.shiftSummary:
        ok = await printCtrl.printShiftSummary(data);
      default:
        ok = false;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Reprint submitted' : 'Print failed'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _jobIcon(PrintJobStatus status) {
    switch (status) {
      case PrintJobStatus.completed:
        return const Icon(Icons.check_circle, color: Colors.green, size: 20);
      case PrintJobStatus.failed:
        return const Icon(Icons.error, color: Colors.red, size: 20);
      case PrintJobStatus.printing:
        return const SizedBox(
          width: 20, height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      default:
        return const Icon(Icons.schedule, color: Colors.grey, size: 20);
    }
  }

  Color? _jobColor(PrintJobStatus status) {
    switch (status) {
      case PrintJobStatus.completed:
        return Colors.green;
      case PrintJobStatus.failed:
        return Colors.red;
      case PrintJobStatus.printing:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
