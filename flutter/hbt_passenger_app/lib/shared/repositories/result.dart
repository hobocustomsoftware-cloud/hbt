/// Result type used by repositories.
///
/// Mirrors the backend's success/error semantics: an [Ok] carries a value,
/// an [Err] carries a user-facing message (plus optional technical cause).
/// Screens can pattern-match to render loading/error states without
/// try/catch noise.
sealed class Result<T> {
  const Result();

  /// True when this result is an [Ok].
  bool get isOk => this is Ok<T>;

  /// True when this result is an [Err].
  bool get isErr => this is Err<T>;

  /// The value, or `null` when this is an [Err].
  T? get valueOrNull => switch (this) {
        Ok<T>(:final value) => value,
        Err<T>() => null,
      };

  /// The error message, or `null` when this is an [Ok].
  String? get errorMessage => switch (this) {
        Ok<T>() => null,
        Err<T>(:final message) => message,
      };
}

/// Successful result.
class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;
}

/// Failed result with a user-facing [message] and optional technical [cause].
class Err<T> extends Result<T> {
  const Err(this.message, {this.cause});

  final String message;
  final Object? cause;
}
