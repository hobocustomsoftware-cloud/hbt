import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_form.dart';
import '../../../core/widgets/error_states.dart';
import '../../../core/widgets/loading.dart';
import '../../../shared/models/shift_models.dart';
import '../controllers/shift_controller.dart';

/// Screen shown when no active shift exists.
///
/// Staff selects a branch, a counter, enters opening cash,
/// verifies the printer, and checks connectivity before starting
/// their shift.
class ShiftOpenScreen extends StatefulWidget {
  const ShiftOpenScreen({super.key, required this.controller});

  final ShiftController controller;

  @override
  State<ShiftOpenScreen> createState() => _ShiftOpenScreenState();
}

class _ShiftOpenScreenState extends State<ShiftOpenScreen> {
  final _openingCashCtrl = TextEditingController();
  String? _selectedBranchId;
  String? _selectedCounterId;
  String? _counterError;
  bool _printerChecked = false;
  bool _connectivityChecked = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    widget.controller.loadBranches();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _openingCashCtrl.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _startShift() async {
    final cash = double.tryParse(_openingCashCtrl.text.trim());
    if (cash == null) return;
    await widget.controller.openShift(
      branchId: _selectedBranchId!,
      counterId: _selectedCounterId!,
      openingCash: cash,
      printerChecked: _printerChecked,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;

    return Scaffold(
      appBar: AppBar(title: const Text('Open Counter')),
      body: SingleChildScrollView(
        padding: AppTheme.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Branch selection ───────────────────────────────
            SectionHeader(label: 'Branch'),
            if (ctrl.loadingBranches)
              const InlineLoading()
            else
              FormDropdown<String>(
                label: 'Select Branch',
                value: _selectedBranchId,
                items: ctrl.branches.map((b) => b.id).toList(),
                itemLabel: (id) => ctrl.branches
                        .firstWhere((b) => b.id == id,
                            orElse: () => Branch(
                                id: id,
                                code: '',
                                name: id))
                        .name,
                onChanged: (v) {
                  setState(() {
                    _selectedBranchId = v;
                    _selectedCounterId = null;
                    _counterError = null;
                  });
                  if (v != null) ctrl.loadCounters(v);
                },
                prefixIcon: const Icon(Icons.business),
              ),

            // ── Counter selection ──────────────────────────────
            if (_selectedBranchId != null) ...[
              const SizedBox(height: AppTheme.spacingMd),
              SectionHeader(label: 'Counter'),
              if (ctrl.loadingCounters)
                const InlineLoading()
              else ...[
                FormDropdown<String>(
                  label: 'Select Counter',
                  value: _selectedCounterId,
                  items: ctrl.counters.map((c) => c.id).toList(),
                  itemLabel: (id) => ctrl.counters
                          .firstWhere((c) => c.id == id,
                              orElse: () => Counter(
                                  id: id,
                                  branchId: '',
                                  code: id))
                          .displayName ??
                      ctrl.counters
                          .firstWhere((c) => c.id == id,
                              orElse: () => Counter(
                                  id: id,
                                  branchId: '',
                                  code: id))
                          .code,
                  onChanged: (v) =>
                      setState(() => _selectedCounterId = v),
                  prefixIcon: const Icon(Icons.point_of_sale),
                ),
                if (_counterError != null)
                  Padding(
                    padding:
                        const EdgeInsets.only(top: AppTheme.spacingXs),
                    child: Text(
                      _counterError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ],

            const SizedBox(height: AppTheme.spacingXl),

            // ── Opening cash ───────────────────────────────────
            SectionHeader(label: 'Opening Balance'),
            FormTextField(
              label: 'Opening Cash (MMK)',
              controller: _openingCashCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              prefixIcon: const Icon(Icons.monetization_on_outlined),
            ),

            const SizedBox(height: AppTheme.spacingXl),

            // ── Pre-checks ─────────────────────────────────────
            SectionHeader(label: 'Pre-shift Checks'),
            CheckboxListTile(
              title: const Text('Printer is working'),
              subtitle: const Text('Verify thermal printer is online'),
              value: _printerChecked,
              onChanged: (v) =>
                  setState(() => _printerChecked = v ?? false),
              secondary: Icon(
                _printerChecked
                    ? Icons.print
                    : Icons.print_disabled,
                color: _printerChecked ? Colors.green : Colors.grey,
              ),
              controlAffinity: ListTileControlAffinity.trailing,
            ),
            CheckboxListTile(
              title: const Text('Connectivity'),
              subtitle: Text(
                ctrl.hasActiveShift
                    ? 'Online'
                    : 'Checking…',
              ),
              value: _connectivityChecked,
              onChanged: (v) =>
                  setState(() => _connectivityChecked = v ?? false),
              secondary: Icon(
                _connectivityChecked
                    ? Icons.cloud_done
                    : Icons.cloud_off,
                color: _connectivityChecked
                    ? Colors.green
                    : Colors.grey,
              ),
              controlAffinity: ListTileControlAffinity.trailing,
            ),

            const SizedBox(height: AppTheme.spacingXxl),

            // ── Error ──────────────────────────────────────────
            if (ctrl.error != null)
              Padding(
                padding:
                    const EdgeInsets.only(bottom: AppTheme.spacingMd),
                child: ErrorCard(message: ctrl.error!),
              ),

            // ── Start button ───────────────────────────────────
            BusyButton(
              label: 'Start Shift',
              icon: const Icon(Icons.play_arrow),
              onPressed: _selectedBranchId != null &&
                      _selectedCounterId != null &&
                      _openingCashCtrl.text.trim().isNotEmpty &&
                      _printerChecked
                  ? _startShift
                  : null,
              busy: ctrl.opening,
            ),
          ],
        ),
      ),
    );
  }
}
