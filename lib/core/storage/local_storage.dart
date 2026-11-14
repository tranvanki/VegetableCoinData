import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_constants.dart';
import '../utils/logger.dart';

/// Bọc SharedPreferences cho dữ liệu KHÔNG nhạy cảm (cài đặt, cache nhẹ,
/// watchlist khách, coin đã xem). Access token luôn đi qua `SecureStorage`.
///
/// Tương đương `shared_service.dart` của gs24_gps nhưng có typing và
/// không nuốt lỗi im lặng.
class LocalStorage {
  LocalStorage(this._prefs);

  final SharedPreferences _prefs;

  static Future<LocalStorage> create() async =>
      LocalStorage(await SharedPreferences.getInstance());
//get data
  String? getString(String key) => _prefs.getString(key);
//set data
  Future<bool> setString(String key, String value) =>
      _prefs.setString(key, value);

  bool getBool(String key, {bool defaultValue = false}) =>
      _prefs.getBool(key) ?? defaultValue;

  Future<bool> setBool(String key, {required bool value}) =>
      _prefs.setBool(key, value);

  int getInt(String key, {int defaultValue = 0}) =>
      _prefs.getInt(key) ?? defaultValue;

  Future<bool> setInt(String key, int value) => _prefs.setInt(key, value);

  double getDouble(String key, {double defaultValue = 0}) =>
      _prefs.getDouble(key) ?? defaultValue;

  /// Trả bản copy growable: prefs trả `const []` khi chưa có giá trị, mà
  /// `const []` thì không thêm/xoá được — các hàm watchlist bên dưới mutate.
  List<String> getStringList(String key) =>
      List.of(_prefs.getStringList(key) ?? const []);

  Future<bool> setStringList(String key, List<String> value) =>
      _prefs.setStringList(key, value);

  /// Đọc object JSON. Trả `null` nếu chưa có hoặc dữ liệu hỏng (và dọn luôn
  /// bản hỏng để lần sau không lặp lại lỗi).
  Map<String, dynamic>? getJson(String key) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      AppLogger.w('JSON hỏng tại khoá $key, đã xoá', tag: 'Storage');
      unawaitedRemove(key);
      return null;
    }
  }

  Future<bool> setJson(String key, Map<String, dynamic> value) =>
      _prefs.setString(key, jsonEncode(value));

  List<Map<String, dynamic>> getJsonList(String key) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded.whereType<Map<String, dynamic>>().toList();
    } catch (_) {
      AppLogger.w('JSON list hỏng tại khoá $key, đã xoá', tag: 'Storage');
      unawaitedRemove(key);
      return const [];
    }
  }

  Future<bool> setJsonList(String key, List<Map<String, dynamic>> value) =>
      _prefs.setString(key, jsonEncode(value));

  bool contains(String key) => _prefs.containsKey(key);

  Future<bool> remove(String key) => _prefs.remove(key);

  void unawaitedRemove(String key) {
    // ignore: discarded_futures
    _prefs.remove(key);
  }

  /// Xoá dữ liệu phiên người dùng nhưng GIỮ cài đặt app (ngôn ngữ, theme,
  /// onboarding) — dùng khi đăng xuất.
  Future<void> clearUserScoped(Set<String> keepKeys) async {
    final keys = _prefs.getKeys().where((k) => !keepKeys.contains(k)).toList();
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }

  /// Đọc danh sách coin đã xem gần đây từ hàng đợi LRU.
  List<Map<String, dynamic>> getRecentViewedTokensRaw() =>
      getJsonList(AppConstants.kRecentViewedCoins);

  /// Lưu coin vào hàng đợi LRU cục bộ (đưa lên đầu, loại bỏ bản ghi trùng,
  /// cắt đuôi nếu vượt quá [maxEntries]).
  Future<bool> saveRecentViewedToken(
    Map<String, dynamic> tokenJson, {
    int maxEntries = 12,
    String idField = 'id',
  }) async {
    final targetId = tokenJson[idField]?.toString();
    final list = getRecentViewedTokensRaw()
        .where(
            (item) => targetId == null || item[idField]?.toString() != targetId)
        .toList();
    list.insert(0, tokenJson);
    final trimmed = list.take(maxEntries).toList();
    return setJsonList(AppConstants.kRecentViewedCoins, trimmed);
  }

  /// Xoá một coin khỏi danh sách đã xem gần đây theo id.
  Future<bool> removeRecentViewedToken(
    String tokenId, {
    String idField = 'id',
  }) async {
    final list = getRecentViewedTokensRaw()
        .where((item) => item[idField]?.toString() != tokenId)
        .toList();
    return setJsonList(AppConstants.kRecentViewedCoins, list);
  }

  /// Xoá toàn bộ lịch sử coin đã xem.
  Future<bool> clearRecentViewedTokens() =>
      remove(AppConstants.kRecentViewedCoins);

  Future<bool> clearAll() => _prefs.clear();

  // ---------------------------- Watchlist -------------------------------
  static const String _kWatchlistIds = 'watchlist_coin_ids';

  List<String> getWatchlistIds() => getStringList(_kWatchlistIds);

  bool isInWatchlist(String coinId) => getWatchlistIds().contains(coinId);

  /// Đảo trạng thái watchlist. Trả `true` nếu vừa thêm, `false` nếu vừa xoá.
  Future<bool> toggleWatchlist(String coinId) async {
    final list = getWatchlistIds();
    final exists = list.contains(coinId);

    if (exists) {
      list.remove(coinId);
    } else {
      list.add(coinId);
    }

    final saved = await setStringList(_kWatchlistIds, list);
    return saved ? !exists : exists;
  }

  /// Thêm nhiều id một lượt, bỏ qua id đã có. Trả `false` nếu ghi thất bại.
  Future<bool> addWatchlistIds(Iterable<String> coinIds) async {
    final list = getWatchlistIds();
    for (final coinId in coinIds.where((id) => !list.contains(id))) {
      list.add(coinId);
    }
    return setStringList(_kWatchlistIds, list);
  }
}
