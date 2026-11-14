import 'dart:async';

import '../core/network/api_client.dart';
import '../core/result/result.dart';
import '../data/model/crypto/coin_market.dart';
import '../data/model/system/global_stats.dart';
import '../data/repository/market_repository.dart';
import 'base_view_model.dart';

/// Bộ lọc chip của Tab 1.
///
/// Bước sau: thêm `onchain` ("Trên chuỗi") — cần nguồn khác
/// (`/onchain/networks/trending_pools` trả về pool, không phải coin) nên
/// phải có model và hàng riêng, đừng trộn vào bảng coin.
enum MarketFilter { all, trending }

/// Cột sắp xếp của bảng — khớp 4 tiêu đề cột trên UI.
enum MarketSort { rank, price, change24h, marketCap }

/// ViewModel Tab 1 "Tiền mã hoá": thẻ thống kê toàn cầu + bảng coin.
///
/// Sắp xếp chạy cục bộ trên dữ liệu đã tải (CoinGecko không sắp theo giá
/// hay % 24h), nên đổi cột không tốn request.
class MarketProvider extends BaseViewModel {
  MarketProvider({required MarketRepository repository})
      : _repository = repository;

  static const int pageSize = 100;

  final MarketRepository _repository;
  ApiCancelToken? _cancelToken;

  GlobalStats? _global;
  List<CoinMarketModel> _fetched = const [];
  List<CoinMarketModel> _coins = const [];
  MarketFilter _filter = MarketFilter.all;
  MarketSort _sort = MarketSort.rank;
  bool _ascending = true;
  int _page = 1;
  bool _hasMore = false;
  bool _loadMoreFailed = false;
  bool _initialized = false;

  // Bước sau: đổi tiền tệ hiển thị (usd/vnd/btc) — thêm `vsCurrency` vào
  // provider, lưu LocalStorage, truyền xuống getMarkets và Formatters.
  // Hiện cố định USD.

  /// Null khi chưa tải xong hoặc `/global` lỗi — thẻ hiện "—".
  GlobalStats? get global => _global;

  /// Danh sách đã áp dụng sắp xếp.
  List<CoinMarketModel> get coins => _coins;
  MarketFilter get filter => _filter;
  MarketSort get sort => _sort;
  bool get ascending => _ascending;
  bool get hasMore => _hasMore;
  bool get loadMoreFailed => _loadMoreFailed;

  Future<void> init() async {
    if (_initialized || isLoading) return;
    await load();
  }

  /// Nạp lần đầu / thử lại: loading → ready / empty / error.
  Future<void> load() async {
    _initialized = true;
    final token = _newToken('reload');
    unawaited(_loadGlobal(token));
    await runInitial<List<CoinMarketModel>>(
      () => _fetchFirstPage(token),
      onData: (data) => _setCoins(data, page: 1),
      isEmpty: (data) => data.isEmpty,
    );
  }

  /// Kéo để làm mới: giữ bảng cũ, chỉ bật [isBusy].
  Future<void> refresh() async {
    if (isBusy || isLoading) return;
    final token = _newToken('refresh');
    unawaited(_loadGlobal(token));
    await runAction<List<CoinMarketModel>>(
      () => _fetchFirstPage(token),
      onData: (data) {
        _setCoins(data, page: 1);
        setState(_coins.isEmpty ? ViewState.empty : ViewState.ready);
      },
    );
  }

  /// Nạp trang kế tiếp (chỉ bộ lọc Tất cả). Gọi khi cuộn gần cuối.
  ///
  /// Lỗi thì đặt [loadMoreFailed] và dừng tự nạp tiếp (tránh dồn request khi
  /// bị 429) cho tới khi người dùng bấm thử lại bằng [retryLoadMore].
  Future<void> loadMore() async {
    final token = _cancelToken;
    if (token == null || isBusy || !isReady || !_hasMore || _loadMoreFailed) {
      return;
    }
    final nextPage = _page + 1;
    final ok = await runAction<List<CoinMarketModel>>(
      () => _repository.getMarkets(
        page: nextPage,
        perPage: pageSize,
        cancelToken: token,
      ),
      onData: (data) => _setCoins([..._fetched, ...data], page: nextPage),
    );
    if (!ok && failure != null) {
      _loadMoreFailed = true;
      clearFailure();
    }
  }

  Future<void> retryLoadMore() {
    _loadMoreFailed = false;
    return loadMore();
  }

  Future<void> setFilter(MarketFilter filter) async {
    if (_filter == filter) return;
    _filter = filter;
    // Bỏ bảng của bộ lọc cũ để không hiện nhầm khi bộ lọc mới đang tải/lỗi.
    _fetched = const [];
    _coins = const [];
    await load();
  }

  /// Bấm lại cùng cột thì đảo chiều. Cột mới: hạng tăng dần, còn lại giảm dần.
  void setSort(MarketSort sort) {
    if (_sort == sort) {
      _ascending = !_ascending;
    } else {
      _sort = sort;
      _ascending = sort == MarketSort.rank;
    }
    _coins = _sorted(_fetched);
    safeNotify();
  }

  ApiCancelToken _newToken(String reason) {
    _cancelToken?.cancel(reason);
    return _cancelToken = ApiCancelToken();
  }

  /// Thẻ tổng quan chỉ là phụ: lỗi thì giữ giá trị cũ, không đổi trạng thái
  /// cả màn hình.
  Future<void> _loadGlobal(ApiCancelToken token) async {
    final result = await _repository.getGlobalStats(cancelToken: token);
    final data = result.dataOrNull;
    if (isDisposed || data == null) return;
    _global = data;
    safeNotify();
  }

  Future<Result<List<CoinMarketModel>>> _fetchFirstPage(
    ApiCancelToken token,
  ) async {
    if (_filter == MarketFilter.all) {
      return _repository.getMarkets(perPage: pageSize, cancelToken: token);
    }

    final ids = await _repository.getTrendingCoinIds(cancelToken: token);
    final failure = ids.failureOrNull;
    if (failure != null) return Err(failure);
    final trendingIds = ids.getOrElse(const []);
    if (trendingIds.isEmpty) return const Ok(<CoinMarketModel>[]);
    return _repository.getMarkets(coinIds: trendingIds, cancelToken: token);
  }

  void _setCoins(List<CoinMarketModel> data, {required int page}) {
    _page = page;
    _loadMoreFailed = false;
    _fetched = List.unmodifiable(data);
    _hasMore = _filter == MarketFilter.all && data.length >= page * pageSize;
    _coins = _sorted(_fetched);
  }

  List<CoinMarketModel> _sorted(List<CoinMarketModel> source) {
    final list = [...source]..sort(_compare);
    return List.unmodifiable(list);
  }

  int _compare(CoinMarketModel a, CoinMarketModel b) {
    final x = _sortKey(a);
    final y = _sortKey(b);
    // Thiếu dữ liệu luôn xuống cuối, bất kể chiều sắp xếp.
    if (x == null && y == null) return 0;
    if (x == null) return 1;
    if (y == null) return -1;
    return _ascending ? x.compareTo(y) : y.compareTo(x);
  }

  double? _sortKey(CoinMarketModel coin) => switch (_sort) {
        MarketSort.rank => coin.marketCapRank?.toDouble(),
        MarketSort.price => coin.currentPrice,
        MarketSort.change24h => coin.priceChangePercentage24h,
        MarketSort.marketCap => coin.marketCap,
      };

  @override
  void dispose() {
    _cancelToken?.cancel('dispose');
    super.dispose();
  }
}
