/// Build-time configuration. Values come from `--dart-define-from-file=env/dev.json`
/// (mirrors matchmate_flutter's Env; admin runs in a browser, not an emulator, so the
/// default points straight at localhost).
abstract final class Env {
  /// Base URL of the Spring Boot API.
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );
}
