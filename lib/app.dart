import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:hhmmobile/app/di/app_providers.dart';
import 'package:hhmmobile/app/di/service_locator.dart';
import 'package:hhmmobile/app/router/app_router.dart';
import 'package:hhmmobile/app/theme/app_theme.dart';
import 'package:localization/localization.dart';
import 'package:provider/provider.dart';

import '../core/storage/local_storage.dart';
import '../providers/app_state_provider.dart';

import '../services/navigation_service.dart';

/// Gốc ứng dụng: gắn provider, theme, i18n và router.
class GeckoApp extends StatelessWidget {
  const GeckoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: buildAppProviders(),
      child: const _HhmMaterialApp(),
    );
  }
}

class _HhmMaterialApp extends StatefulWidget {
  const _HhmMaterialApp();

  @override
  State<_HhmMaterialApp> createState() => _HhmMaterialAppState();
}

class _HhmMaterialAppState extends State<_HhmMaterialApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // Router dựng một lần: tạo lại ở build sẽ reset stack điều hướng.
    _router = AppRouter.create(
      navigation: sl<NavigationService>(),
      appState: sl<AppStateProvider>(),
      storage: sl<LocalStorage>(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();

    return MaterialApp.router(
      title: 'COinGecko Mobile',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: appState.themeMode,
      locale: appState.locale,
      supportedLocales: const [Locale('vi', 'VN'), Locale('en', 'US')],
      localizationsDelegates: [
        // Chuỗi i18n nằm ở lib/i18n/*.json, truy cập bằng `'key'.i18n()`
        // — giữ nguyên cách làm quen thuộc từ gs24_gps.
        LocalJsonLocalization.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        // Khoá cỡ chữ hệ thống trong khoảng an toàn: người dùng để 200%
        // vẫn đọc được mà layout giá/nút không vỡ.
        final scale = MediaQuery.textScalerOf(context).clamp(
          minScaleFactor: 0.9,
          maxScaleFactor: 1.3,
        );
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: scale),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
