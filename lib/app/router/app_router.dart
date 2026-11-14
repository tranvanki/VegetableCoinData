import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hhmmobile/app/di/service_locator.dart';
import 'package:hhmmobile/core/storage/local_storage.dart';
import 'package:hhmmobile/providers/app_state_provider.dart';
import 'package:hhmmobile/providers/watchlist_provider.dart';
import 'package:hhmmobile/services/navigation_service.dart';
import 'package:hhmmobile/views/screens/watchlist/watchlist_select.dart';
import 'package:provider/provider.dart';
import 'package:hhmmobile/views/screens/globalStats/global_screen.dart';
import 'package:hhmmobile/views/screens/home_screen.dart';
import 'package:hhmmobile/views/screens/main/main_shell.dart';
import 'package:hhmmobile/views/screens/market/market_screen.dart';
import 'package:hhmmobile/views/screens/onBoarding/onboarding_screen.dart';
import 'package:hhmmobile/views/screens/settings/settings_screen.dart';
import 'package:hhmmobile/views/screens/splash/splash_screen.dart';
import 'package:hhmmobile/views/screens/watchlist/watchlist_screen.dart';
import '../../providers/token_list_provider.dart';

import '../../core/config/app_constants.dart';
import 'app_routes.dart';

/// Cấu hình điều hướng toàn app.
///
/// Bốn tab chính (home · watchlist · market · global) nằm trong
/// [StatefulShellRoute.indexedStack] nên mỗi tab giữ stack riêng.
/// Các màn hình đi sâu (chi tiết coin, tìm kiếm...) đẩy lên root navigator
/// để che bottom nav.
class AppRouter {
  const AppRouter._();

  static final GlobalKey<NavigatorState> _shellKey = GlobalKey<NavigatorState>(
    debugLabel: 'shell',
  );

  static GoRouter create({
    required NavigationService navigation,
    required AppStateProvider appState,
    required LocalStorage storage,
  }) {
    final router = GoRouter(
      navigatorKey: navigation.rootNavigatorKey,
      initialLocation: AppRoutes.home,
      debugLogDiagnostics: false,

      // Router rebuild khi trạng thái đăng nhập hoặc cấu hình đổi, để
      // redirect bên dưới chạy lại.
      refreshListenable: Listenable.merge([appState]),

      redirect: (context, state) {
        final location = state.matchedLocation;

        // 1. Bảo trì / bắt buộc cập nhật chặn mọi thứ.
        if (appState.isMaintenance && location != AppRoutes.maintenance) {
          return AppRoutes.maintenance;
        }
        if (!appState.isMaintenance && location == AppRoutes.maintenance) {
          return AppRoutes.home;
        }

        // 2. Onboarding chỉ hiện một lần.
        final seenOnboarding = storage.getBool(AppConstants.kOnboardingSeen);
        if (!seenOnboarding &&
            location != AppRoutes.onboarding &&
            !location.startsWith('/auth')) {
          return AppRoutes.onboarding;
        }

        return null;
      },

      errorBuilder: (context, state) => PlaceholderScreen(
        title: 'Không tìm thấy trang',
        note: 'Đường dẫn ${state.uri} không tồn tại trong ứng dụng.',
      ),

      routes: [
        // ---------------------- Ngoài shell --------------------------
        // Bootstrap đã chờ xong DI và phiên đăng nhập trước `runApp`, nên
        // splash native che toàn bộ giai đoạn đó. Route này giữ lại cho các
        // luồng cần hiện lại màn chờ (ví dụ đăng xuất rồi khởi tạo lại).
        GoRoute(
          path: AppRoutes.splash,
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: AppRoutes.onboarding,
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: AppRoutes.watchlistSelect,
          builder: (context, state) =>
              ChangeNotifierProvider<TokenListProvider>(
            create: (_) => sl<TokenListProvider>(),
            child: const WatchlistSelect(),
          ),
          // Instance riêng để search ở màn chọn không đổi query của Home.
        ),

        GoRoute(
          path: AppRoutes.settings,
          builder: (context, state) => const SettingsScreen(),
        ),

        GoRoute(
          path: AppRoutes.watchlistSelect,
          // Provider sống theo route: mở lại là một danh sách tick mới, đóng
          // màn hình thì dispose luôn (huỷ request còn đang chạy).
          builder: (context, state) =>
              ChangeNotifierProvider<WatchListProvider>(
            create: (_) => sl<WatchListProvider>(),
            child: const WatchlistSelect(),
          ),
        ),

        // GoRoute(
        //   path: AppRoutes.support,
        //   builder: (context, state) => const SupportScreen(),
        // ),

        // GoRoute(
        //   path: AppRoutes.webview,
        //   builder: (context, state) => AppWebViewScreen(
        //     url: state.uri.queryParameters['url'] ?? '',
        //     title: state.uri.queryParameters['title'] ?? '',
        //   ),
        // ),

        // ------------------------- 4 tab chính ------------------------
        // Thứ tự branch PHẢI khớp BottomNavigationBar trong MainShell:
        // 0 home · 1 watchlist · 2 market · 3 global.
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              MainShell(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(
              navigatorKey: _shellKey,
              routes: [
                GoRoute(
                  path: AppRoutes.home,
                  builder: (context, state) => const HomeScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.watchlist,
                  builder: (context, state) => const WatchlistScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.market,
                  builder: (context, state) => const MarketScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.global,
                  builder: (context, state) => const GlobalScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    );

    navigation.attach(router);
    return router;
  }
}
