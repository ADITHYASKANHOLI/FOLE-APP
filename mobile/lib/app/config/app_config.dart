class AppConfig {
  static const String _rawBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api/mobile/v1',
  );

  /// Normalized base URL for the ENGIVAULT Mobile API v1.
  /// Configurable via `--dart-define=API_BASE_URL=https://...` or `--dart-define=API_BASE_URL=http://<mac-ip>:3000`
  /// Automatically ensures trailing `/api/mobile/v1` is present without duplication.
  static String get apiBaseUrl {
    final clean = _rawBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    if (clean.endsWith('/api/mobile/v1')) {
      return clean;
    }
    return '$clean/api/mobile/v1';
  }

  static const String appName = 'ENGIVAULT';
  static const String appTagline = 'KTU Learning. Simplified.';
  static const String brandOrganization = 'FOLE';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);
}
