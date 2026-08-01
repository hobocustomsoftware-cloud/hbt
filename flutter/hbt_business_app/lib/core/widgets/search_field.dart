import 'package:flutter/material.dart';

/// A standard search text field with debounce support.
///
/// The current apps don't have client-side search yet (list filtering is
/// server-side via API calls), but this widget provides the standardised
/// search input for future use.
class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    this.controller,
    this.onChanged,
    this.hintText = 'Search…',
    this.autofocus = false,
  });

  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String hintText;
  final bool autofocus;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          autofocus: autofocus,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      );
}

/// A simple status filter dropdown / popup menu.
///
/// Used in trip_list_page for the filter popup. Standardising the pattern
/// for reuse across other filtered lists.
class StatusFilterChip extends StatelessWidget {
  const StatusFilterChip({
    super.key,
    required this.current,
    required this.options,
    this.onChanged,
    this.allLabel = 'All',
  });

  final String? current;
  final List<String> options;
  final ValueChanged<String?>? onChanged;
  final String allLabel;

  @override
  Widget build(BuildContext context) => Chip(
        avatar: const Icon(Icons.filter_alt, size: 16),
        label: Text(current != null ? 'Status: $current' : allLabel),
        onDeleted: current != null ? () => onChanged?.call(null) : null,
      );
}
