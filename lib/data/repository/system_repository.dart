import '../../core/config/app_constants.dart';
import '../../core/storage/local_storage.dart';
import '../model/system/remote_config.dart';

/// Cấu hình app đọc từ cache cục bộ.
///
/// CoinGecko không có endpoint cấu hình/phiên bản/thông báo, nên repository
/// này không gọi mạng; lần chạy đầu tiên dùng [RemoteConfig.defaults].
class SystemRepository {
  SystemRepository({required LocalStorage storage}) : _storage = storage;

  final LocalStorage _storage;

  Future<RemoteConfig> fetchConfig() async => cachedConfig();

  RemoteConfig cachedConfig() {
    final cached = _storage.getJson(AppConstants.kRemoteConfigCache);
    return cached == null
        ? RemoteConfig.defaults
        : RemoteConfig.fromJson(cached);
  }
}
