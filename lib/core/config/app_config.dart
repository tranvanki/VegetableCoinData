import 'package:hhmmobile/core/config/app_flavour.dart';

/// Cấu hình toàn app, nạp 1 lần lúc bootstrap từ `--dart-define`.
///
/// Không đặt secret thật trong code. Giá trị thật nằm ở `env/{flavor}.json`
/// (gitignored) và truyền vào qua `--dart-define-from-file`.
class AppConfig {
  const AppConfig({
    required this.flavor,
    required this.apiBaseUrl,
    required this.webBaseUrl,
    required this.cdnBaseUrl,
    required this.apiTimeout,
    required this.enableLogging,
    required this.sentryDsn,
    required this.defaultLocale,
  });

  /// Đọc toàn bộ cấu hình từ compile-time environment.
  factory AppConfig.fromEnvironment() {
    const flavorKey = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
    final flavor = AppFlavor.fromKey(flavorKey);

    return AppConfig(
      flavor: flavor,
      apiBaseUrl: const String.fromEnvironment('API_BASE_URL',
          defaultValue: 'https://api.coingecko.com/api/v3'),
      webBaseUrl: const String.fromEnvironment(
        'WEB_BASE_URL',
        defaultValue: 'https://api.coingecko.com',
      ),
      cdnBaseUrl: const String.fromEnvironment(
        'CDN_BASE_URL',
        defaultValue: 'https://coin-images.coingecko.com/',
      ),
      apiTimeout: const Duration(
        seconds: int.fromEnvironment('API_TIMEOUT_SECONDS', defaultValue: 30),
      ),

      // Khi cần tắt fixture: --dart-define=USE_MOCK_API=false
      // useMockApi: const bool.fromEnvironment(
      //   'USE_MOCK_API',
      //   defaultValue: !bool.fromEnvironment('dart.vm.product'),
      // ),
      enableLogging: const bool.fromEnvironment(
        'ENABLE_LOGGING',
        defaultValue: !bool.fromEnvironment('dart.vm.product'),
      ),

      sentryDsn: const String.fromEnvironment('SENTRY_DSN'),
      defaultLocale: const String.fromEnvironment(
        'DEFAULT_LOCALE',
        defaultValue: 'vi_VN',
      ),
    );
  }

  final AppFlavor flavor;

  /// Base URL CoinGecko API. Luôn kết thúc KHÔNG có `/`.
  final String apiBaseUrl;

  /// Base URL web CoinGecko - dùng cho share link và deep link.
  final String webBaseUrl;

  final String cdnBaseUrl;
  final Duration apiTimeout;

  // /// Bật thì toàn bộ repository đọc từ [MockApiClient] - dev UI không cần backend.
  // final bool useMockApi;

  final bool enableLogging;

  final String sentryDsn;
  final String defaultLocale;

  bool get isProd => flavor.isProd;
  bool get hasCrashConfig => sentryDsn.isNotEmpty;

  @override
  String toString() => 'AppConfig(flavor: ${flavor.key}, api: $apiBaseUrl)';
}
