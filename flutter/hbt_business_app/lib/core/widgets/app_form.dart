import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

// =============================================================================
//  FORM FIELD WIDGETS
// =============================================================================

/// A standardised [TextFormField] with consistent M3 decoration.
///
/// Eliminates the `TextField(decoration: InputDecoration(labelText: ..., border: OutlineInputBorder()))`
/// pattern repeated dozens of times across the app.
class FormTextField extends StatelessWidget {
  const FormTextField({
    super.key,
    required this.label,
    this.controller,
    this.onChanged,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.autofocus = false,
    this.textInputAction,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final String? hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) => Padding(
        padding: AppTheme.formFieldPadding,
        child: TextFormField(
          controller: controller,
          onChanged: onChanged,
          validator: validator,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: maxLines,
          minLines: minLines,
          maxLength: maxLength,
          enabled: enabled,
          autofocus: autofocus,
          textInputAction: textInputAction,
          onFieldSubmitted: onSubmitted,
          decoration: InputDecoration(
            labelText: label,
            hintText: hintText,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            border: const OutlineInputBorder(),
          ),
        ),
      );
}

/// A standardised [DropdownButtonFormField] wrapped with consistent M3
/// decoration. Works with any type.
///
/// Usage:
/// ```dart
/// FormDropdown<Map<String, dynamic>>(
///   label: 'Passenger',
///   value: selectedPassenger,
///   items: passengers,
///   itemLabel: (p) => p['full_name']?.toString() ?? '-',
///   onChanged: (v) => setState(() => selectedPassenger = v),
/// )
/// ```
class FormDropdown<T> extends StatelessWidget {
  const FormDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    this.onChanged,
    this.validator,
    this.hintText,
    this.prefixIcon,
    this.enabled = true,
    this.useKey = false,
  });

  final String label;
  final T? value;
  final List<T> items;
  final String Function(T item) itemLabel;
  final ValueChanged<T?>? onChanged;
  final FormFieldValidator<T?>? validator;
  final String? hintText;
  final Widget? prefixIcon;
  final bool enabled;
  final bool useKey;

  @override
  Widget build(BuildContext context) => Padding(
        padding: AppTheme.formFieldPadding,
        child: DropdownButtonFormField<T>(
          key: useKey ? ValueKey(value.hashCode) : null,
          initialValue: value,
          items: items.map((item) => DropdownMenuItem(
                value: item,
                child: Text(itemLabel(item)),
              )).toList(),
          onChanged: enabled ? onChanged : null,
          validator: validator,
          decoration: InputDecoration(
            labelText: label,
            hintText: hintText,
            prefixIcon: prefixIcon,
            border: const OutlineInputBorder(),
          ),
        ),
      );
}

/// A grouped row of [ChoiceChip]s for selecting one value from a set.
///
/// Replacement for the seat-selection `Wrap(spacing: 8, children: choices.map(...))`
/// pattern used in counter_booking_page. Works with any type.
class ChoiceChipGroup<T> extends StatelessWidget {
  const ChoiceChipGroup({
    super.key,
    required this.label,
    required this.items,
    required this.itemLabel,
    required this.selected,
    this.onChanged,
    this.available,
    this.wrapSpacing = AppTheme.spacingSm,
    this.wrapRunSpacing = AppTheme.spacingXs,
    this.showLabel = true,
  });

  final String label;
  final List<T> items;
  final String Function(T item) itemLabel;
  final T? selected;
  final ValueChanged<T?>? onChanged;
  final bool Function(T item)? available;
  final double wrapSpacing;
  final double wrapRunSpacing;
  final bool showLabel;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showLabel)
            Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
              child: Text(label,
                  style: AppTheme.sectionHeaderStyle(context)),
            ),
          Wrap(
            spacing: wrapSpacing,
            runSpacing: wrapRunSpacing,
            children: items.map((item) {
              final isAvailable = available?.call(item) ?? true;
              final isSelected = selected == item ||
                  (selected?.hashCode == item.hashCode);
              return ChoiceChip(
                label: Text(itemLabel(item)),
                selected: isSelected,
                onSelected: isAvailable
                    ? (_) => onChanged
                            ?.call(isSelected ? null : item)
                    : null,
              );
            }).toList(),
          ),
        ],
      );
}

/// A row layout for forms with a picker dropdown and an "add" button.
///
/// Replaces the `Row(children: [Expanded(DropdownButtonFormField), IconButton])`
/// pattern used in cargo_acceptance_page for sender/receiver contact pickers.
class ContactPickerRow extends StatelessWidget {
  const ContactPickerRow({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    required this.onCreate,
    this.emptyLabel = 'No items',
    this.useKey = false,
  });

  final String label;
  final Map<String, dynamic>? value;
  final List<Map<String, dynamic>> items;
  final String Function(Map<String, dynamic> item) itemLabel;
  final ValueChanged<Map<String, dynamic>?> onChanged;
  final VoidCallback onCreate;
  final String emptyLabel;
  final bool useKey;

  @override
  Widget build(BuildContext context) => Padding(
        padding: AppTheme.formFieldPadding,
        child: Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<Map<String, dynamic>>(
                key: useKey ? ValueKey(value?['id']) : null,
                initialValue: value,
                items: items.isNotEmpty
                    ? items.map((item) => DropdownMenuItem(
                          value: item,
                          child: Text(
                            itemLabel(item),
                            overflow: TextOverflow.ellipsis,
                          ),
                        )).toList()
                    : [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('No items'),
                        )
                      ],
                onChanged: onChanged,
                decoration: InputDecoration(
                  labelText: label,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacingSm),
            IconButton(
              onPressed: onCreate,
              icon: const Icon(Icons.person_add),
              tooltip: '$label အသစ်',
            ),
          ],
        ),
      );
}

/// A standardised [Form] section header widget.
///
/// Usage:
/// ```dart
/// SectionHeader(label: 'ခရီးသည်')
/// // with action:
/// SectionHeader(
///   label: 'ခရီးသည်',
///   action: IconButton(...),
/// )
/// ```
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.label,
    this.action,
    this.subtitle,
    this.padding,
  });

  final String label;
  final Widget? action;
  final String? subtitle;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Padding(
        padding: padding ?? AppTheme.sectionPadding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTheme.sectionHeaderStyle(context),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding:
                          const EdgeInsets.only(top: AppTheme.spacingXxs),
                      child: Text(
                        subtitle!,
                        style: AppTheme.sectionSubtitleStyle(context),
                      ),
                    ),
                ],
              ),
            ),
            ?action,
          ],
        ),
      );
}

/// A compact section header without padding (for use inside lists/cards).
class InlineSectionHeader extends StatelessWidget {
  const InlineSectionHeader({
    super.key,
    required this.label,
    this.action,
  });

  final String label;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTheme.sectionHeaderStyle(context),
            ),
          ),
          ?action,
        ],
      );
}

/// A two-column label/value layout for forms (not inside InfoCard).
class FormRow extends StatelessWidget {
  const FormRow({
    super.key,
    required this.label,
    required this.child,
    this.labelWidth = 120,
  });

  final String label;
  final Widget child;
  final double labelWidth;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: labelWidth,
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  '$label:',
                  style: AppTheme.dataLabelStyle(context),
                ),
              ),
            ),
            Expanded(child: child),
          ],
        ),
      );
}
