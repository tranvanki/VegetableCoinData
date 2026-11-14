import 'package:get_it/get_it.dart';
import 'package:hhmmobile/core/storage/local_storage.dart';

import '../../core/config/app_config.dart';
import '../../core/config/app_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/dio_api_client.dart';

import '../../core/network/interceptors/app_info_interceptor.dart';
import '../../core/network/interceptors/retry_interceptor.dart';
import '../../core/network/network_info.dart';
import '../../core/utils/logger.dart';
import '../../data/repository/coin_repository.dart';
import '../../data/repository/market_repository.dart';
import '../../data/repository/system_repository.dart';
import '../../providers/app_state_provider.dart';
// import '../../providers/notification_provider.dart';
import '../../providers/global_provider.dart';
import '../../providers/market_provider.dart';
import '../../providers/search_provider.dart';
import '../../providers/token_list_provider.dart';
import '../../providers/watchlist_provider.dart';
import '../../services/analytics_service.dart';
import '../../services/app_update_service.dart';
import '../../services/crash_service.dart';
import '../../services/deep_link_service.dart';
import '../../services/device_info_service.dart';
import '../../services/navigation_service.dart';
// import '../../services/push_notification_service.dart';
import '../../services/shared_service.dart';

final GetIt sl = GetIt.instance;
//tiem cac phu thuoc vao cac file can dung
/// Khởi tạo toàn bộ phụ thuộc. Gọi một lần ở [AppBootstrap] trước `runApp`.
///
/// Thứ tự: hạ tầng (config/storage/device) → mạng → repository → service →
/// provider. Không có vòng phụ thuộc: [AuthInterceptor] nhận hàm callback
/// chứ không giữ tham chiếu tới repository.
Future<void> setupDependencies(AppConfig config) async {
  // ----------------------------- Hạ tầng -------------------------------
  sl.registerSingleton<AppConfig>(config);
  AppLogger.enabled = config.enableLogging;

  final localStorage = await LocalStorage.create();
  final deviceInfo = DeviceInfoService(localStorage);
  await deviceInfo.initialize();
  sl.registerSingleton<DeviceInfoService>(deviceInfo);
  sl.registerSingleton<LocalStorage>(localStorage);
  sl.registerSingleton<NetworkInfo>(ConnectivityNetworkInfo());
  sl.registerSingleton<NavigationService>(NavigationService());
  sl.registerLazySingleton<DeepLinkService>(
    () => DeepLinkService(config: config, navigation: sl(), analytics: sl()),
  );
  // ------------------------- Theo dõi & thống kê ------------------------
  // Thay bằng cài đặt Firebase/Sentry thật khi có key — chỗ gọi không đổi.
  sl.registerSingleton<AnalyticsService>(const ConsoleAnalyticsService());
  sl.registerSingleton<CrashService>(const ConsoleCrashService());

  // -------------------------------- Mạng --------------------------------
  // Toàn bộ dữ liệu lấy trực tiếp từ CoinGecko Free API; không có backend
  // trung gian nên không cần lớp định tuyến live/fixture.

  final client = DioApiClient(config: config);
  client.addInterceptors([
    AppInfoInterceptor(
      deviceId: deviceInfo.deviceId,
      platform: deviceInfo.platform,
      appVersion: '${deviceInfo.appVersion}+${deviceInfo.buildNumber}',
      localeProvider: () =>
          localStorage.getString(AppConstants.kLocale) ?? config.defaultLocale,
      requestIdFactory: () =>
          DateTime.now().microsecondsSinceEpoch.toRadixString(36),
    ),
    RetryInterceptor(dio: client.raw),
  ]);
  sl.registerSingleton<ApiClient>(client);

  // ------------------------------ Repository -----------------------------
  sl.registerLazySingleton<SystemRepository>(
    () => SystemRepository(storage: sl()),
  );
  sl.registerLazySingleton<CoinRepository>(
    () => CoinRepository(apiClient: sl()),
  );
  sl.registerLazySingleton<MarketRepository>(
    () => MarketRepository(apiClient: sl()),
  );
  // ------------------------------- Service -------------------------------
  sl.registerLazySingleton<ShareService>(() => ShareService(config));
  sl.registerLazySingleton<AppUpdateService>(() => AppUpdateService(sl()));

  // ------------------------------ Provider -------------------------------
  // App-scoped: sống suốt vòng đời app.
  sl.registerLazySingleton<AppStateProvider>(
    () => AppStateProvider(
      storage: sl(),
      systemRepository: sl(),
      networkInfo: sl(),
    ),
  );
  // 2. Tiêm Repository vào AuthProvider

  // sl.registerLazySingleton<NotificationProvider>(
  //   () => NotificationProvider(repository: sl(), appState: sl()),
  // );

  sl.registerFactory<SearchProvider>(
    () => SearchProvider(coinRepo: sl(), storage: sl(), analytics: sl()),
  );
  sl.registerFactory<TokenListProvider>(
    () => TokenListProvider(repository: sl()),
  );
  sl.registerFactory<WatchListProvider>(
    () => WatchListProvider(repository: sl(), storage: sl()),
  );

  sl.registerFactory<MarketProvider>(() => MarketProvider(repository: sl()));
  sl.registerFactory<GlobalProvider>(() => GlobalProvider(repository: sl()));
}

// ----------------------------- Repository ------------------------------

// sl.registerLazySingleton<PushNotificationService>(
//   () => PushNotificationService(
//     config: config,
//     systemRepository: sl(),
//     navigation: sl(),
//     deepLink: sl(),
//     deviceInfo: sl(),
//   ),
// );

/// Dọn toàn bộ đăng ký — chỉ dùng trong test.
Future<void> resetDependencies() => sl.reset();
