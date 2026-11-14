/// Hằng số dùng chung. Khoá lưu trữ gom hết ở đây để tránh gõ lặp chuỗi.
class AppConstants {
  const AppConstants._();
  // --- HTTP header ------------------------------------------------------
  static const String headerAuthorization = 'Authorization';
  static const String headerDeviceId = 'X-Device-Id';
  static const String headerPlatform = 'X-Platform';
  static const String headerAppVersion = 'X-App-Version';
  static const String headerRequestId = 'X-Request-Id';
  static const String headerLocale = 'X-Locale';

  // --- Quy ước nghiệp vụ ------------------------------------------------
  static const int defaultPageSize = 20;
  static const int maxWatchlistSize = 10;
  static const int otpLength = 6;
  static const Duration otpResendCooldown = Duration(seconds: 60);
  static const Duration searchDebounce = Duration(milliseconds: 400);
  static const Duration cacheTtlShort = Duration(minutes: 5);
  static const Duration cacheTtlLong = Duration(hours: 6);
  //-----SharedPreference------//
  static const kRecentViewedCoins = 'coingecko.recent_viewed';
  static const kLocale = 'coingecko.locale';
  static const kThemeMode = 'coingecko.theme_mode';
  static const kNotificationBadge = 'coingecko.notification';
  static const kRemoteConfigCache = 'coingecko.remote_config';
  static const kDeviceId = 'coingecko.device_id';
  static const kRecentSearch = 'coingecko.recent_search';
  static const kOnboardingSeen = 'coingecko.onboarding_seen';
}
