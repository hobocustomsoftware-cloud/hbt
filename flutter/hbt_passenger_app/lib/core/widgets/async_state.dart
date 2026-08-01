import 'package:flutter/material.dart';

/// Encapsulates loading / error / action-in-progress state.
///
/// Replaces the pattern of 2–4 separate booleans (`_loading`, `_error`,
/// `_submitting`, `_acting`, `_busy`, `_saving`) with a single object.
///
/// Usage:
/// ```dart
/// final _state = AsyncState();
///
/// Future<void> _load() async {
///   _state.startLoading();
///   try {
///     final data = await api.get(...);
///     _state.doneLoading();
///   } on ApiException catch (e) {
///     _state.fail(e.message);
///   }
/// }
/// ```
class AsyncState {
  bool loading = true;
  bool actionInProgress = false;
  String? error;

  void startLoading() {
    loading = true;
    actionInProgress = false;
    error = null;
  }

  void doneLoading() {
    loading = false;
  }

  void fail(String message) {
    error = message;
    loading = false;
    actionInProgress = false;
  }

  void startAction() {
    actionInProgress = true;
    error = null;
  }

  void doneAction() {
    actionInProgress = false;
  }

  void reset() {
    loading = true;
    actionInProgress = false;
    error = null;
  }
}

/// A builder that receives [AsyncState] and renders loading / error / data.
///
/// Eliminates the if-else chain repeated in every screen:
/// ```dart
/// if (state.loading) return LoadingView();
/// if (state.error != null) return ErrorView(...);
/// return dataView;
/// ```
class AsyncStateBuilder<T> extends StatelessWidget {
  const AsyncStateBuilder({
    super.key,
    required this.state,
    required this.onRetry,
    this.data,
    this.builder,
    this.loading,
    this.error,
  });

  final AsyncState state;
  final VoidCallback onRetry;
  final T? data;
  final Widget Function(T data)? builder;
  final Widget? loading;
  final Widget Function(String error)? error;

  @override
  Widget build(BuildContext context) {
    if (state.loading) {
      return loading ?? const Center(child: CircularProgressIndicator());
    }
    if (state.error != null) {
      if (error != null) return error!(state.error!);
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(state.error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (data != null && builder != null) return builder!(data as T);
    return const SizedBox.shrink();
  }
}
