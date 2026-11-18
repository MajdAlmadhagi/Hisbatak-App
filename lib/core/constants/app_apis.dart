/// Centralized API endpoint configuration for progressive cloud sync & authentication.
class AppApis {
  AppApis._();

  /// Optional build-time override:
  /// `flutter build apk --dart-define=HISBATAK_API_BASE_URL=https://api.hisbatak.app`
  static const String baseUrl = String.fromEnvironment(
    'HISBATAK_API_BASE_URL',
    defaultValue: '',
  );

  static const Duration requestTimeout = Duration(seconds: 15);

  static bool get isCloudConfigured => baseUrl.trim().isNotEmpty;

  static String _normalizedBase([String? override]) {
    final raw = (override ?? baseUrl).trim();
    return raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
  }

  static String requestOtpUrl([String? override]) =>
      '${_normalizedBase(override)}/v1/auth/otp/request';

  static String verifyOtpUrl([String? override]) =>
      '${_normalizedBase(override)}/v1/auth/otp/verify';

  static String socialAuthUrl([String? override]) =>
      '${_normalizedBase(override)}/v1/auth/social';

  static String claimGuestUrl([String? override]) =>
      '${_normalizedBase(override)}/v1/auth/claim';

  static String syncPushUrl([String? override]) =>
      '${_normalizedBase(override)}/v1/sync/push';

  static String syncPullUrl({String? cursor, String? baseOverride}) {
    final root = '${_normalizedBase(baseOverride)}/v1/sync/pull';
    if (cursor == null || cursor.trim().isEmpty) return root;
    final encoded = Uri.encodeQueryComponent(cursor.trim());
    return '$root?cursor=$encoded';
  }
}
