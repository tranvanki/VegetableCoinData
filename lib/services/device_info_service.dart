import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../core/config/app_constants.dart';
import '../core/storage/local_storage.dart';

/// Thông tin thiết bị và phiên bản app, nạp một lần lúc bootstrap.
///
/// `deviceId` là UUID tự sinh và lưu cục bộ — KHÔNG dùng IMEI/AndroidID để
/// tránh vi phạm chính sách store; chỉ cần ổn định trong một lần cài đặt.
class DeviceInfoService {
  DeviceInfoService(this._storage);

  final LocalStorage _storage;

  late final String deviceId;
  late final String platform;
  late final String deviceModel;
  late final String osVersion;
  late final String appVersion;
  late final int buildNumber;
  late final String packageName;

  Future<void> initialize() async {
    final package = await PackageInfo.fromPlatform();
    appVersion = package.version;
    buildNumber = int.tryParse(package.buildNumber) ?? 0;
    packageName = package.packageName;

    platform =
        Platform.isIOS ? 'ios' : (Platform.isAndroid ? 'android' : 'other');

    final plugin = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final info = await plugin.androidInfo;
      deviceModel = '${info.manufacturer} ${info.model}';
      osVersion =
          'Android ${info.version.release} (SDK ${info.version.sdkInt})';
    } else if (Platform.isIOS) {
      final info = await plugin.iosInfo;
      deviceModel = info.utsname.machine;
      osVersion = '${info.systemName} ${info.systemVersion}';
    } else {
      deviceModel = 'unknown';
      osVersion = Platform.operatingSystemVersion;
    }

    deviceId =
        _storage.getString(AppConstants.kDeviceId) ?? _generateDeviceId();
  }

  String _generateDeviceId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    final id = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    // ignore: discarded_futures
    _storage.setString(AppConstants.kDeviceId, id);
    return id;
  }

  /// Chuỗi gọn để đính kèm báo cáo lỗi và phiếu hỗ trợ.
  String get summary =>
      '$deviceModel | $osVersion | v$appVersion ($buildNumber)';
}
