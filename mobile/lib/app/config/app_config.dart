class AppConfig {
  /// Base URL for the ENGIVAULT Mobile API v1.
  /// Configurable via `--dart-define=API_BASE_URL=https://...`
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api/mobile/v1',
  );

  static const String appName = 'ENGIVAULT';
  static const String appTagline = 'KTU Learning. Simplified.';
  static const String brandOrganization = 'FOLE';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);
}
