import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../core/config/app_config.dart';
import '../core/utils/logger.dart';
import '../providers/app_state_provider.dart';

import '../services/crash_service.dart';
import '../services/deep_link_service.dart';
// import '../services/push_notification_service.dart';
import '../app.dart';
import 'di/service_locator.dart';

/// Khởi động app: bắt lỗi toàn cục, dựng DI, khôi phục phiên, rồi `runApp`.
///
/// Nguyên tắc: những việc bắt buộc phải xong trước khi vẽ (DI, phiên đăng
/// nhập) thì `await`; việc còn lại (push, deep link, cấu hình từ xa) chạy
/// nền để thời gian mở app không phụ thuộc mạng.
class AppBootstrap {
  const AppBootstrap._();

  static Future<void> run() async {
    await runZonedGuarded(
      () async {
        WidgetsFlutterBinding.ensureInitialized();

        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);

        // DateFormat với locale 'vi_VN' cần dữ liệu ngày tháng được nạp trước,
        // nếu không mọi chỗ gọi Formatters.date sẽ ném LocaleDataException.
        await initializeDateFormatting('vi_VN');

        final config = AppConfig.fromEnvironment();
        AppLogger.i('Khởi động: $config', tag: 'Bootstrap');

        await setupDependencies(config);

        final crash = sl<CrashService>();
        await crash.initialize();

        // Lỗi trong widget tree → crash reporter thay vì chỉ in ra console.
        FlutterError.onError = (details) {
          FlutterError.presentError(details);
          unawaited(
            crash.recordError(
              details.exception,
              details.stack,
              context: details.context?.toString(),
              fatal: true,
            ),
          );
        };

        // Lỗi ở tầng platform (plugin, isolate chính).
        WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
          unawaited(crash.recordError(error, stack));
          return true;
        };

        AppLogger.onError = (error, stack, {context}) =>
            unawaited(crash.recordError(error, stack, context: context));

        // Bắt buộc xong trước khi vẽ: biết người dùng đã đăng nhập hay chưa,
        // nếu không router sẽ nhấp nháy giữa login và trang chủ.

        runApp(const GeckoApp());

        unawaited(_initBackgroundServices());
      },
      (error, stack) {
        // Lưới cuối: lỗi async không ai bắt.
        AppLogger.e(
          'Lỗi không bắt được',
          tag: 'Bootstrap',
          error: error,
          stackTrace: stack,
        );
        if (sl.isRegistered<CrashService>()) {
          unawaited(sl<CrashService>().recordError(error, stack, fatal: true));
        }
      },
    );
  }

  /// Chạy sau khi UI đã lên — không chặn khung hình đầu tiên.
  static Future<void> _initBackgroundServices() async {
    final appState = sl<AppStateProvider>();

    // Cấu hình từ xa trước: quyết định force-update và các cờ tính năng.
    await appState.loadRemoteConfig();

    await Future.wait([
      sl<DeepLinkService>().initialize(),
    ]);

    // Gắn thông báo với tài khoản nếu đã đăng nhập sẵn.
  }
}
