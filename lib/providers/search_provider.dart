import 'dart:async';

import 'package:hhmmobile/data/repository/coin_repository.dart';
import 'package:hhmmobile/views/screens/token_list.dart';

import '../core/config/app_constants.dart';
import '../core/network/api_client.dart';
import '../core/result/result.dart';
import '../core/storage/local_storage.dart';
import '../core/utils/debouncer.dart';
import '../data/model/crypto/token_model.dart';
import '../services/analytics_service.dart';
import 'base_view_model.dart';

/// Ô tìm kiếm: gợi ý theo thời gian thực + lịch sử tìm kiếm cục bộ.
///
/// Mỗi lần gõ sẽ huỷ request gợi ý trước đó, nên kết quả hiển thị luôn khớp
/// với từ khoá cuối cùng chứ không phải response về sau cùng.
class SearchProvider extends BaseViewModel {
  SearchProvider({
    required CoinRepository coinRepo,
    required LocalStorage storage,
    required AnalyticsService analytics,
  })  : _coinRepo = coinRepo,
        _storage = storage,
        _analytics = analytics;
  final CoinRepository _coinRepo;
  final LocalStorage _storage;
  final AnalyticsService _analytics;

  final Debouncer _debouncer = Debouncer(AppConstants.searchDebounce);

  String _keyword = '';
  List<String> _suggestions = const [];
  ApiCancelToken? _cancelToken;

  String get keyword => _keyword;
  List<String> get suggestions => _suggestions;

  List<String> get recentSearches =>
      _storage.getStringList(AppConstants.kRecentSearch);

  /// Danh sách sản phẩm đã xem gần đây lấy từ hàng đợi LRU cục bộ.
  List<TokenModel> get recentProducts =>
      _storage.getRecentViewedTokensRaw().map(TokenModel.fromJson).toList();

  static const int _maxRecent = 10;

  get cached_token => null;

  void onKeywordChanged(String value) {
    _keyword = value;
    safeNotify();

    if (value.trim().length < 2) {
      _suggestions = const [];
      _cancelToken?.cancel('Từ khoá quá ngắn');
      safeNotify();
      return;
    }

    _debouncer.run(() => unawaited(_fetchSuggestions(value.trim())));
  }

  Future<void> _fetchSuggestions(String value) async {
    _cancelToken?.cancel('Từ khoá mới');
    _cancelToken = ApiCancelToken();

    final result = await _coinRepo.getSearchSuggestions(
      value,
      cancelToken: _cancelToken,
    );

    if (isDisposed) return;
    // Người dùng đã gõ tiếp — bỏ kết quả cũ.
    if (value != _keyword.trim()) return;

    if (result case Ok(:final data)) {
      _suggestions = data;
      safeNotify();
    }
  }

  /// Gọi khi người dùng bấm tìm — lưu lịch sử và bắn analytics.
  Future<void> submit(String value) async {
    final term = value.trim();
    if (term.isEmpty) return;

    final history = [...recentSearches]
      ..remove(term)
      ..insert(0, term);

    await _storage.setStringList(
      AppConstants.kRecentSearch,
      history.take(_maxRecent).toList(),
    );
    unawaited(
      _analytics.logEvent(
        AnalyticsEvents.search,
        parameters: {'search_term': term},
      ),
    );
    safeNotify();
  }

  Future<void> removeRecent(String term) async {
    final history = [...recentSearches]..remove(term);
    await _storage.setStringList(AppConstants.kRecentSearch, history);
    safeNotify();
  }

  Future<void> clearRecent() async {
    await _storage.remove(AppConstants.kRecentSearch);
    safeNotify();
  }

  /// Ghi nhận một sản phẩm đã xem vào hàng đợi LRU cục bộ.
  Future<void> recordViewedToken(token) async {
    await _storage.saveRecentViewedToken(token.toJson());
    safeNotify();
  }

  /// Xoá một sản phẩm khỏi danh sách đã xem.
  Future<void> removeRecentProduct(String productId) async {
    await _storage.removeRecentViewedToken(productId);
    safeNotify();
  }

  /// Xoá toàn bộ lịch sử sản phẩm đã xem.
  Future<void> clearRecentProducts() async {
    await _storage.clearRecentViewedTokens();
    safeNotify();
  }

  @override
  void dispose() {
    _debouncer.dispose();
    _cancelToken?.cancel('Màn hình đã đóng');
    super.dispose();
  }
}
