import 'dart:io';

import 'package:hhmmobile/data/model/system/remote_config.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/utils/logger.dart';

import 'device_info_service.dart';

enum UpdateRequirement {
  /// Đang dùng bản mới nhất hoặc đủ mới.
  none,

  /// Có bản mới, chỉ gợi ý — cho phép bỏ qua.
  optional,

  /// Build hiện tại dưới mức tối thiểu — chặn, bắt buộc cập nhật.
  forced,
}
/// Quyết định có phải cập nhật app hay không, dựa trên [VersionGate] từ
/// remote config. So sánh theo build number để không lệ thuộc cách đặt tên
/// phiên bản.
class AppUpdateService {
  AppUpdateService(this._deviceInfo);

  final DeviceInfoService _deviceInfo;

  UpdateRequirement evaluate(VersionGate gate) {
    final current = _deviceInfo.buildNumber;
    if (gate.mustUpdate(current)) return UpdateRequirement.forced;
    if (gate.shouldSuggestUpdate(current)) return UpdateRequirement.optional;
    return UpdateRequirement.none;
  }

  String storeUrl(VersionGate gate) =>
      Platform.isIOS ? gate.storeUrlIos : gate.storeUrlAndroid;

  /// Mở trang store. Trả `false` nếu không mở được để UI báo lại.
  Future<bool> openStore(VersionGate gate) async {
    final url = storeUrl(gate);
    if (url.isEmpty) return false;

    final uri = Uri.tryParse(url);
    if (uri == null) return false;

    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      AppLogger.w('Không mở được store: $e', tag: 'Update');
      return false;
    }
  }
}
