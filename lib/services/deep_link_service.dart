import 'dart:async';

import 'package:app_links/app_links.dart';

import '../app/router/app_routes.dart';
import '../core/config/app_config.dart';
import '../core/utils/logger.dart';
import 'analytics_service.dart';
import 'navigation_service.dart';

/// Nhận deep link (`hhm://...`) và universal link (`https://hoanghamobile.com/...`)
/// rồi quy về route trong app.
///
/// vào màn hình gốc, còn lại rơi về WebView để không bao giờ dẫn người dùng
/// tới ngõ cụt.

class DeepLinkService {
  DeepLinkService({
    required AppConfig config,
    required NavigationService navigation,
    required AnalyticsService analytics,
    AppLinks? appLinks,
  })  : _config = config,
        _navigation = navigation,
        _analytics = analytics,
        _appLinks = appLinks ?? AppLinks();

  final AppConfig _config;
  final NavigationService _navigation;
  final AnalyticsService _analytics;
  final AppLinks _appLinks;

  StreamSubscription<Uri>? _subscription;

  /// Lắng nghe link lúc app đang chạy, và xử lý luôn link đã mở app.
  Future<void> initialize() async {
    _subscription = _appLinks.uriLinkStream.listen(
      handleUri,
      onError: (Object e, StackTrace s) => AppLogger.e('Deep link lỗi',
          tag: 'DeepLink', error: e, stackTrace: s),
    );

    final initial = await _appLinks.getInitialLink();
    if (initial != null) handleUri(initial);
  }

  void handleUri(Uri uri) {
    AppLogger.i('Nhận deep link: $uri', tag: 'DeepLink');
    final route = resolve(uri);
    if (route == null) return;

    unawaited(
      _analytics.logEvent(
        AnalyticsEvents.notificationOpen,
        parameters: {'link': uri.toString(), 'route': route},
      ),
    );
    _navigation.push(route);
  }

  /// Quy URI về route trong app. Trả `null` khi link không thuộc HHM.
  ///
  /// Tách riêng khỏi [handleUri] để test được mà không cần plugin.
  String? resolve(Uri uri) {
    final isAppScheme = uri.scheme == 'hhm';
    final isWebLink = uri.host.contains('hoanghamobile.com');
    if (!isAppScheme && !isWebLink) return null;

    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    // Với `hhm://product/abc`, host chính là phần "product".
    final parts =
        isAppScheme && uri.host.isNotEmpty ? [uri.host, ...segments] : segments;

    if (parts.isEmpty) return AppRoutes.home;

    switch (parts.first) {
      case 'coin list' || 'Dong COin':
        if (parts.length < 2) return AppRoutes.home;
        return AppRoutes.coinMarketPath(parts[1]);

      case 'market' || 'Thi Truong':
        if (parts.length < 2) return AppRoutes.catalog;
        return AppRoutes.coinMarketPath(parts[1]);

      case 'search' || 'tim-kiem':
        return AppRoutes.coinMarketPath(
          uri.queryParameters['q'] ?? '',
        );

      case 'notifications' || 'thong-bao':
        return AppRoutes.notifications;
      case 'charts' || 'Bieu DO':
        return AppRoutes.webview;
      default:
        // Link web lạ (landing page, tin tức...) — mở trong WebView.
        return isWebLink ? AppRoutes.webviewPath(uri.toString()) : null;
    }
  }

  /// Dựng link chia sẻ ra ngoài — luôn dùng URL web để người chưa cài app
  /// vẫn mở được.
  String shareLinkForProduct(String slug) => '${_config.webBaseUrl}/$slug';

  Future<void> dispose() async {
    await _subscription?.cancel();
  }
}
