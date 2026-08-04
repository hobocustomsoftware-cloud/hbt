import 'package:flutter/material.dart';

import '../theme/hbt_tokens.dart';

// =============================================================================
//  DIALOG VARIANTS
// =============================================================================

/// Standard dialog helpers that replace the repeated `showDialog` + `AlertDialog`
/// + `TextButton("မလုပ်တော့ပါ")` + `FilledButton("သိမ်းမည်")` pattern.
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
    bool confirmDestructive = false,
  }) =>
      showDialog<T>(
        context: context,
        builder: (ctx) {
          T? result;
          return AlertDialog(
            title: Text(title),
            content: content != null
                ? SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(content),
                        const SizedBox(height: HbtSpacing.md),
                        ...builder((value) => result = value),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: builder((value) => result = value),
                    ),
                  ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(cancelLabel),
              ),
              FilledButton(
                style: confirmDestructive
                    ? FilledButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.error,
                      )
                    : null,
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
    IconData? icon,
  }) =>
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              if (icon != null) ...[
                Icon(icon),
                const SizedBox(width: HbtSpacing.sm),
              ],
              Text(title),
            ],
          ),
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
                  Padding(
                    padding: const EdgeInsets.all(HbtSpacing.xxl),
                    child: Text(emptyLabel),
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

  /// Confirmation dialog with cancel + confirm (y/n).
  ///
  /// Returns `true` if confirmed, `false` or `null` if cancelled.
  static Future<bool?> confirm(
    BuildContext context, {
    required String title,
    required String content,
    String cancelLabel = 'မလုပ်တော့ပါ',
    String confirmLabel = 'အတည်ပြုမည်',
    bool destructive = false,
  }) =>
      showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(cancelLabel),
            ),
            FilledButton(
              style: destructive
                  ? FilledButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).colorScheme.error,
                    )
                  : null,
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(confirmLabel),
            ),
          ],
        ),
      );

  /// Single text field dialog (quick input prompt).
  ///
  /// Returns the entered text on confirm, or `null` on cancel.
  static Future<String?> showTextField(
    BuildContext context, {
    required String title,
    required String label,
    int maxLines = 1,
    String? initialValue,
    String? hintText,
    String cancelLabel = 'မလုပ်တော့ပါ',
    String confirmLabel = 'အတည်ပြုမည်',
  }) {
    final controller = TextEditingController(text: initialValue);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          maxLines: maxLines,
          autofocus: true,
          decoration: InputDecoration(
            labelText: label,
            hintText: hintText,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(cancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(confirmLabel),
          ),
        ],
      ),
    ).then((result) {
      controller.dispose();
      return result;
    });
  }

  /// Multi-field form dialog.
  ///
  /// Returns a `Map<String, String>` keyed by field names, or `null` on cancel.
  static Future<Map<String, String>?> showMultiField(
    BuildContext context, {
    required String title,
    required List<DialogField> fields,
    String cancelLabel = 'မလုပ်တော့ပါ',
    String confirmLabel = 'အတည်ပြုမည်',
  }) {
    final controllers =
        fields.map((f) => TextEditingController(text: f.initialValue ?? '')).toList();
    return showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < fields.length; i++) ...[
                if (i > 0) const SizedBox(height: HbtSpacing.md),
                TextField(
                  controller: controllers[i],
                  maxLines: fields[i].maxLines,
                  keyboardType: fields[i].keyboardType,
                  decoration: InputDecoration(
                    labelText: fields[i].label,
                    hintText: fields[i].hintText,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(cancelLabel),
          ),
          FilledButton(
            onPressed: () {
              final result = <String, String>{};
              for (var i = 0; i < fields.length; i++) {
                result[fields[i].key] = controllers[i].text.trim();
              }
              Navigator.pop(ctx, result);
            },
            child: Text(confirmLabel),
          ),
        ],
      ),
    ).then((result) {
      for (final c in controllers) {
        c.dispose();
      }
      return result;
    });
  }

  /// A success confirmation overlay dialog (green check + message).
  static Future<void> showSuccess(
    BuildContext context, {
    required String title,
    required String message,
    String actionLabel = 'ပြန်သွားမည်',
    VoidCallback? onAction,
  }) =>
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: HbtIconSize.lg,
              ),
              const SizedBox(height: HbtSpacing.md),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: HbtSpacing.sm),
              Text(
                message,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: HbtSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    onAction?.call();
                  },
                  child: Text(actionLabel),
                ),
              ),
            ],
          ),
        ),
      );
}

/// Configuration for a single field inside [AppDialog.showMultiField].
class DialogField {
  const DialogField({
    required this.key,
    required this.label,
    this.initialValue,
    this.hintText,
    this.maxLines = 1,
    this.keyboardType,
  });

  final String key;
  final String label;
  final String? initialValue;
  final String? hintText;
  final int maxLines;
  final TextInputType? keyboardType;
}
