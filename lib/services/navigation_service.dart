import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Điều hướng từ nơi không có BuildContext (deep link, push notification,
/// interceptor hết phiên).
///
/// Router được gắn vào lúc dựng app; trước đó các yêu cầu điều hướng được
/// xếp hàng và chạy ngay khi router sẵn sàng — push mở app từ trạng thái
/// nguội vẫn tới đúng màn hình.
class NavigationService {
  GoRouter? _router;
  final List<void Function(GoRouter router)> _pending = [];

  GlobalKey<NavigatorState> get rootNavigatorKey => _rootNavigatorKey;
  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');

  BuildContext? get context => _rootNavigatorKey.currentContext;

  void attach(GoRouter router) {
    _router = router;
    for (final action in _pending) {
      action(router);
    }
    _pending.clear();
  }

  void _run(void Function(GoRouter router) action) {
    final router = _router;
    if (router == null) {
      _pending.add(action);
      return;
    }
    action(router);
  }

  /// Thay màn hình hiện tại (dùng cho tab, deep link vào trang chính).
  void go(String location, {Object? extra}) =>
      _run((router) => router.go(location, extra: extra));

  /// Chồng màn hình mới lên stack.
  void push(String location, {Object? extra}) =>
      _run((router) => router.push(location, extra: extra));

  void replace(String location, {Object? extra}) =>
      _run((router) => router.replace(location, extra: extra));

  void pop<T>([T? result]) => _run((router) {
        if (router.canPop()) router.pop(result);
      });

  /// Thoát hết các màn hình chồng và về [location].
  void goAndClear(String location) => _run((router) {
        while (router.canPop()) {
          router.pop();
        }
        router.go(location);
      });

  String get currentLocation =>
      _router?.routerDelegate.currentConfiguration.uri.toString() ?? '';
}
