import 'package:flutter/material.dart';

/// Standard cancel + confirm [AlertDialog] helper.
///
/// Replaces the 5-line `showDialog` + `AlertDialog` + `TextButton("မလုပ်တော့ပါ")`
/// + `FilledButton("သိမ်းမည်")` pattern repeated in every form-based dialog.
///
/// Usage:
/// ```dart
/// final result = await AppDialog.showForm<String>(
///   context,
///   title: 'Create Passenger',
///   cancelLabel: 'မလုပ်တော့ပါ',
///   confirmLabel: 'သိမ်းမည်',
///   builder: (setValue) => [
///     TextField(...),
///   ],
/// );
/// ```
class AppDialog {
  AppDialog._();

  /// Show a form dialog with cancel/confirm buttons.
  ///
  /// Returns the value passed to [setValue] when confirmed, or `null` when
  /// cancelled. Children are built by [builder] which receives a callback
  /// to set the return value before closing.
  static Future<T?> showForm<T>(
    BuildContext context, {
    required String title,
    String? content,
    required List<Widget> Function(ValueChanged<T> setValue) builder,
    String cancelLabel = 'မလုပ်တော့ပါ',
    String confirmLabel = 'သိမ်းမည်',
  }) =>
      showDialog<T>(
        context: context,
        builder: (ctx) {
          T? result;
          return AlertDialog(
            title: Text(title),
            content: content != null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...builder((value) => result = value),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: builder((value) => result = value),
                  ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(cancelLabel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, result),
                child: Text(confirmLabel),
              ),
            ],
          );
        },
      );

  /// Simple info/confirmation dialog with a single action button.
  static Future<void> showInfo(
    BuildContext context, {
    required String title,
    required String content,
    String actionLabel = 'Close',
  }) =>
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(actionLabel),
            ),
          ],
        ),
      );

  /// Simple item selection dialog (wraps [SimpleDialog]).
  ///
  /// Each item is rendered via [itemBuilder] and returns its value on tap.
  static Future<T?> showPicker<T>(
    BuildContext context, {
    required String title,
    required List<T> items,
    required Widget Function(T item) itemBuilder,
    String emptyLabel = 'No items available.',
  }) =>
      showDialog<T>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: Text(title),
          children: items.isEmpty
              ? [
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No items available.'),
                  ),
                ]
              : items
                  .map((item) => SimpleDialogOption(
                        onPressed: () => Navigator.pop(ctx, item),
                        child: itemBuilder(item),
                      ))
                  .toList(),
        ),
      );
}
