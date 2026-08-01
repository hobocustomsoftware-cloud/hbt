class AppConfig {
  const AppConfig._();

  static const apiBaseUrl = String.fromEnvironment(
    'HBT_API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api/v1',
  );

  /// Idle-session lock timeout in minutes (`--dart-define`).
  /// `0` disables the guard (dev convenience). Default: 15.
  static const int idleTimeoutMinutes = int.fromEnvironment(
    'HBT_IDLE_TIMEOUT_MINUTES',
    defaultValue: 15,
  );
}
