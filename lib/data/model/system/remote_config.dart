import '../../../core/utils/json_x.dart';

/// Cấu hình backend đẩy xuống lúc khởi động: bật/tắt tính năng, chuỗi động,
/// và điều khiển cập nhật phiên bản. Có cache cục bộ để mở app offline vẫn chạy.
class RemoteConfig {
  const RemoteConfig({
    this.features = const {},
    this.strings = const {},
    this.hotline = '',
    this.maintenanceMode = false,
    this.maintenanceMessage = '',
    this.versionGate = const VersionGate(),
  });
  factory RemoteConfig.fromJson(Map<String, dynamic> json) => RemoteConfig(
        features: {
          for (final entry in json.obj(['features']).entries)
            entry.key: entry.value == true || entry.value == 1,
        },
        strings: {
          for (final entry in json.obj(['features']).entries)
            entry.key: '${entry.value}',
        },
        hotline: json.str(['hotline']),
        maintenanceMode: json.flag(['maintenanceMode', 'maintenance']),
        maintenanceMessage: json.str(['maintenanceMessage']),
        versionGate: VersionGate.fromJson(json.obj(['version', 'versionGate'])),
      );
  final Map<String, bool> features;
  final Map<String, String> strings;
  final String hotline;
  final bool maintenanceMode;
  final String maintenanceMessage;
  final VersionGate versionGate;
  static const RemoteConfig defaults = RemoteConfig();

  ///Mặc định `false` — tính năng mới phải được backend bật tường minh.
  bool isEnabled(String key, {bool fallback = false}) =>
      features[key] ?? fallback;
  String string(String key, {String fallback = ''}) => strings[key] ?? fallback;
  Map<String, dynamic> toJson() => {
        'features': features,
        'strings': strings,
        'hotline': hotline,
        'maintenanceMode': maintenanceMode,
        'maintenanceMessage': maintenanceMessage,
        'version': versionGate.toJson(),
      };
}

/// Điều khiển force-update. So sánh theo build number để tránh lệch chuỗi.
class VersionGate {
  const VersionGate({
    this.minSupportedBuild = 0,
    this.latestBuild = 0,
    this.latestVersionName = '',
    this.releaseNote = '',
    this.storeUrlAndroid = '',
    this.storeUrlIos = '',
  });

  factory VersionGate.fromJson(Map<String, dynamic> json) => VersionGate(
        minSupportedBuild: json.intVal(['minSupportedBuild', 'minBuild']),
        latestBuild: json.intVal(['latestBuild']),
        latestVersionName: json.str(['latestVersionName', 'latestVersion']),
        releaseNote: json.str(['releaseNote', 'changelog']),
        storeUrlAndroid: json.str(['storeUrlAndroid', 'androidUrl']),
        storeUrlIos: json.str(['storeUrlIos', 'iosUrl']),
      );

  final int minSupportedBuild;
  final int latestBuild;
  final String latestVersionName;
  final String releaseNote;
  final String storeUrlAndroid;
  final String storeUrlIos;

  /// Build hiện tại thấp hơn mức tối thiểu thì chặn cứng, không cho dùng tiếp.
  bool mustUpdate(int currentBuild) =>
      minSupportedBuild > 0 && currentBuild < minSupportedBuild;

  /// Có bản mới nhưng chưa bắt buộc — chỉ gợi ý, cho phép bỏ qua.
  bool shouldSuggestUpdate(int currentBuild) =>
      latestBuild > currentBuild && !mustUpdate(currentBuild);

  Map<String, dynamic> toJson() => {
        'minSupportedBuild': minSupportedBuild,
        'latestBuild': latestBuild,
        'latestVersionName': latestVersionName,
        'releaseNote': releaseNote,
        'storeUrlAndroid': storeUrlAndroid,
        'storeUrlIos': storeUrlIos,
      };
}
