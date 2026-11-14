import '../core/utils/logger.dart';

/// Tên sự kiện dùng chung — khai báo tập trung để tránh mỗi nơi gõ một kiểu,
/// vì báo cáo marketing phụ thuộc đúng chuỗi này.
class AnalyticsEvents {
  const AnalyticsEvents._();

  static const String appOpen = 'app_open';

  static const String search = 'search';

  static const String shareProduct = 'share';
  static const String notificationOpen = 'notification_open';
}

/// Hợp đồng analytics. Cài đặt thật (Firebase/Filum/AppsFlyer) gắn vào sau mà
/// không phải sửa chỗ gọi — xem docs/03-integrations/filum.md bên backend.
abstract interface class AnalyticsService {
  Future<void> logEvent(String name,
      {Map<String, Object?> parameters = const {}});
  Future<void> setUserId(String? userId);
  Future<void> setUserProperty(String name, String? value);
  Future<void> logScreenView(String screenName);
}

/// Cài đặt mặc định: chỉ ghi log. Dùng ở dev và làm fallback khi chưa cấu hình
/// SDK thật, để chỗ gọi không bao giờ phải kiểm tra null.
class ConsoleAnalyticsService implements AnalyticsService {
  const ConsoleAnalyticsService();

  @override
  Future<void> logEvent(
    String name, {
    Map<String, Object?> parameters = const {},
  }) async {
    AppLogger.d('event: $name $parameters', tag: 'Analytics');
  }

  @override
  Future<void> setUserId(String? userId) async {
    AppLogger.d('userId: $userId', tag: 'Analytics');
  }

  @override
  Future<void> setUserProperty(String name, String? value) async {
    AppLogger.d('property: $name = $value', tag: 'Analytics');
  }

  @override
  Future<void> logScreenView(String screenName) async {
    AppLogger.d('screen: $screenName', tag: 'Analytics');
  }
}

/// Gộp nhiều backend analytics thành một (ví dụ Firebase + Filum).
class CompositeAnalyticsService implements AnalyticsService {
  const CompositeAnalyticsService(this._delegates);

  final List<AnalyticsService> _delegates;

  @override
  Future<void> logEvent(
    String name, {
    Map<String, Object?> parameters = const {},
  }) async {
    for (final delegate in _delegates) {
      await delegate.logEvent(name, parameters: parameters);
    }
  }

  @override
  Future<void> setUserId(String? userId) async {
    for (final delegate in _delegates) {
      await delegate.setUserId(userId);
    }
  }

  @override
  Future<void> setUserProperty(String name, String? value) async {
    for (final delegate in _delegates) {
      await delegate.setUserProperty(name, value);
    }
  }

  @override
  Future<void> logScreenView(String screenName) async {
    for (final delegate in _delegates) {
      await delegate.logScreenView(screenName);
    }
  }
}
