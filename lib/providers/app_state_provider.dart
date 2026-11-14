import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hhmmobile/data/model/system/remote_config.dart';
import 'package:hhmmobile/data/repository/system_repository.dart';
import '../core/config/app_constants.dart';
import '../core/network/network_info.dart';
import '../core/storage/local_storage.dart';

/// Trạng thái toàn cục không thuộc màn hình nào: theme, ngôn ngữ, kết nối
/// mạng, cấu hình từ xa, badge giỏ hàng/thông báo.

class AppStateProvider extends ChangeNotifier {
  AppStateProvider({
    required LocalStorage storage,
    required SystemRepository systemRepository,
    required NetworkInfo networkInfo,
  })  : _storage = storage,
        _system = systemRepository,
        _network = networkInfo {
    _themeMode = _readThemeMode();
    _locale = _readLocale();
    _config = _system.cachedConfig();
    _watchConnectivity();
  }
  final LocalStorage _storage;
  final SystemRepository _system;
  final NetworkInfo _network;

  StreamSubscription<bool>? _connectivitySub;

  late ThemeMode _themeMode;
  late Locale _locale;
  late RemoteConfig _config;
  bool _isOnline = true;
  int _notificationBadge = 0;

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  RemoteConfig get config => _config;
  bool get isOnline => _isOnline;
  int get notificationBadge => _notificationBadge;

  bool get isMaintenance => _config.maintenanceMode;
  bool isFeatureEnabled(String key) => _config.isEnabled(key);

  // ---------------------------- Cấu hình --------------------------------

  /// Nạp cấu hình từ backend. Lỗi thì giữ bản cache — không chặn khởi động.
  Future<void> loadRemoteConfig() async {
    _config = await _system.fetchConfig();

    notifyListeners();
  }
  // ----------------------------- Giao diện ------------------------------

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await _storage.setString(AppConstants.kThemeMode, mode.name);
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    await _storage.setString(
      AppConstants.kLocale,
      '${locale.languageCode}_${locale.countryCode ?? ''}',
    );
  }

  void setNotification(int value) {
    if (_notificationBadge == value) return;
    _notificationBadge = value;
    notifyListeners();

    // ignore: discarded_futures
    _storage.setInt(AppConstants.kNotificationBadge, value);
  }
  // ---------------------------- Kết nối ---------------------------------

  void _watchConnectivity() {
    // ignore: discarded_futures
    _network.isConnected.then((value) {
      _isOnline = value;
      notifyListeners();
    });
    _connectivitySub = _network.onStatusChange.listen((online) {
      if (_isOnline == online) return;
      _isOnline = online;
      notifyListeners();
    });
  }

  ThemeMode _readThemeMode() {
    final raw = _storage.getString(AppConstants.kThemeMode);
    return ThemeMode.values.firstWhere(
      (m) => m.name == raw,
      // Mặc định SÁNG chứ không theo hệ thống: nhận diện HHM là nền trắng,
      // ảnh sản phẩm từ CDN cũng nền trắng nên chế độ tối trông vỡ. Người dùng
      // vẫn tự đổi được ở màn hình Cài đặt.
      orElse: () => ThemeMode.light,
    );
  }

  Locale _readLocale() {
    final raw = _storage.getString(AppConstants.kLocale) ?? 'vi_VN';
    final parts = raw.split('_');
    return Locale(parts.first, parts.length > 1 ? parts[1] : null);
  }

  @override
  void dispose() {
    // ignore: discarded_futures
    _connectivitySub?.cancel();
    super.dispose();
  }
}
