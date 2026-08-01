import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_form.dart';
import '../../../core/widgets/error_states.dart';
import '../../../shared/models/expense_models.dart';
import '../controllers/expense_controller.dart';

/// Form screen for recording a new expense with trip/vehicle linking.
class ExpenseCreateScreen extends StatefulWidget {
  const ExpenseCreateScreen({super.key, required this.controller});

  final ExpenseController controller;

  @override
  State<ExpenseCreateScreen> createState() => _ExpenseCreateScreenState();
}

class _ExpenseCreateScreenState extends State<ExpenseCreateScreen> {
  final _amountCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _paidToCtrl = TextEditingController();
  final _receiptCtrl = TextEditingController();
  final _vehicleCtrl = TextEditingController();
  final _tripCtrl = TextEditingController();

  ExpenseCategory _category = ExpenseCategory.miscellaneous;
  DateTime _expenseDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _amountCtrl.dispose();
    _descriptionCtrl.dispose();
    _paidToCtrl.dispose();
    _receiptCtrl.dispose();
    _vehicleCtrl.dispose();
    _tripCtrl.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) return;

    final expense = Expense(
      organizationId: '',
      category: _category,
      amount: amount,
      description: _descriptionCtrl.text.trim().isEmpty
          ? null
          : _descriptionCtrl.text.trim(),
      paidTo: _paidToCtrl.text.trim().isEmpty
          ? null
          : _paidToCtrl.text.trim(),
      receiptNumber: _receiptCtrl.text.trim().isEmpty
          ? null
          : _receiptCtrl.text.trim(),
      vehicleId: _vehicleCtrl.text.trim().isEmpty
          ? null
          : _vehicleCtrl.text.trim(),
      tripId: _tripCtrl.text.trim().isEmpty
          ? null
          : _tripCtrl.text.trim(),
      expenseDate: _expenseDate,
    );

    final success = await widget.controller.createExpense(expense);
    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;
    final vehicleGroup = _category.group == ExpenseGroup.vehicle;
    final tripGroup = vehicleGroup || _category == ExpenseCategory.miscellaneous;

    return Scaffold(
      appBar: AppBar(title: const Text('Record Expense')),
      body: SingleChildScrollView(
        padding: AppTheme.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Category ──────────────────────────────────────
            SectionHeader(label: 'Expense Category'),
            const SizedBox(height: AppTheme.spacingSm),
            DropdownButtonFormField<ExpenseCategory>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.category),
                border: OutlineInputBorder(),
              ),
              items: ExpenseCategory.values.map((cat) {
                return DropdownMenuItem(
                  value: cat,
                  child: Text('${cat.label} (${cat.group.label})'),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _category = v);
              },
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // ── Amount & Date ─────────────────────────────────
            SectionHeader(label: 'Amount & Date'),
            FormTextField(
              label: 'Amount (MMK)',
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              prefixIcon: const Icon(Icons.attach_money),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _expenseDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 1)),
                );
                if (picked != null) setState(() => _expenseDate = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Expense Date',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  '${_expenseDate.year}-${_expenseDate.month.toString().padLeft(2, '0')}-${_expenseDate.day.toString().padLeft(2, '0')}',
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // ── Details ───────────────────────────────────────
            SectionHeader(label: 'Details'),
            FormTextField(
              label: 'Description',
              controller: _descriptionCtrl,
              maxLines: 2,
              hintText: 'Optional description',
            ),
            FormTextField(
              label: 'Paid To',
              controller: _paidToCtrl,
              hintText: 'Person or vendor name',
              prefixIcon: const Icon(Icons.person_outline),
            ),
            FormTextField(
              label: 'Receipt Number',
              controller: _receiptCtrl,
              hintText: 'Optional receipt reference',
              prefixIcon: const Icon(Icons.receipt_outlined),
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // ── Vehicle linking ───────────────────────────────
            SectionHeader(
              label: 'Link to Vehicle',
              action: vehicleGroup
                  ? null
                  : const Icon(Icons.info_outline, size: 16, color: Colors.grey),
            ),
            FormTextField(
              label: 'Vehicle ID',
              controller: _vehicleCtrl,
              hintText: 'e.g. VH-001',
              prefixIcon: const Icon(Icons.directions_bus_outlined),
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // ── Trip linking ──────────────────────────────────
            SectionHeader(
              label: 'Link to Trip',
              action: tripGroup
                  ? null
                  : const Icon(Icons.info_outline, size: 16, color: Colors.grey),
            ),
            FormTextField(
              label: 'Trip ID',
              controller: _tripCtrl,
              hintText: 'e.g. T-001',
              prefixIcon: const Icon(Icons.route_outlined),
            ),
            const SizedBox(height: AppTheme.spacingXxl),

            // ── Error ─────────────────────────────────────────
            if (ctrl.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
                child: ErrorCard(message: ctrl.error!),
              ),

            // ── Submit ────────────────────────────────────────
            BusyButton(
              label: 'Record Expense',
              icon: const Icon(Icons.check_circle),
              onPressed:
                  _amountCtrl.text.trim().isNotEmpty ? _submit : null,
              busy: ctrl.submitting,
            ),
          ],
        ),
      ),
    );
  }
}
