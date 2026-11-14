import '../core/network/api_client.dart';
import '../core/result/result.dart';
import '../data/model/crypto/coin_category.dart';
import '../data/model/crypto/coin_market.dart';
import '../data/model/system/global_stats.dart';
import '../data/repository/market_repository.dart';
import 'base_view_model.dart';

/// Dữ liệu Tab 3. Mỗi phần null nghĩa là request tương ứng lỗi — màn hình
/// vẫn hiển thị phần còn lại (gói Free hay trả 429 lẻ tẻ).
class MarketOverview {
  const MarketOverview({this.global, this.categories, this.movers});

  final GlobalStats? global;

  /// Nhóm ngành lớn nhất theo vốn hoá.
  final List<CoinCategory>? categories;

  /// Coin biến động mạnh nhất 24h (tăng hoặc giảm), kèm sparkline 7 ngày.
  final List<CoinMarketModel>? movers;

  bool get isComplete => global != null && categories != null && movers != null;
}

/// ViewModel Tab 3 "Tổng quan thị trường".
///
/// Gộp 3 nguồn: `/global`, `/coins/categories` và `/coins/markets`
/// (sparkline bật, sắp theo |% 24h| ở phía client).
///
/// Bước sau:
/// - Tin tức và "Tìm hiểu" (UI có 2 tab này) cần nguồn tin — KHÔNG có trong
///   `all_api_formatted.md`; chốt nguồn rồi thêm repository riêng.
/// - Tự làm mới 60s bằng `Timer.periodic` (huỷ ở `dispose`).
class GlobalProvider extends BaseViewModel {
  GlobalProvider({required MarketRepository repository})
      : _repository = repository;

  static const int moversCount = 10;
  static const int categoriesCount = 10;

  final MarketRepository _repository;
  ApiCancelToken? _cancelToken;
  MarketOverview _overview = const MarketOverview();
  bool _initialized = false;

  MarketOverview get overview => _overview;

  Future<void> init() async {
    if (_initialized || isLoading) return;
    await load();
  }

  Future<void> load() async {
    _initialized = true;
    final token = _newToken('reload');
    await runInitial<MarketOverview>(
      () => _fetch(token),
      onData: (data) => _overview = data,
    );
  }

  /// Kéo để làm mới: giữ số liệu cũ, chỉ bật [isBusy].
  Future<void> refresh() async {
    if (isBusy || isLoading) return;
    final token = _newToken('refresh');
    await runAction<MarketOverview>(
      () => _fetch(token),
      onData: (data) => _overview = data,
    );
  }

  ApiCancelToken _newToken(String reason) {
    _cancelToken?.cancel(reason);
    return _cancelToken = ApiCancelToken();
  }

  Future<Result<MarketOverview>> _fetch(ApiCancelToken token) async {
    final (global, categories, markets) = await (
      _repository.getGlobalStats(cancelToken: token),
      _repository.getCategories(cancelToken: token),
      _repository.getMarkets(sparkline: true, cancelToken: token),
    ).wait;

    // Cả ba lỗi mới thay cả màn hình bằng trang lỗi.
    final failure = global.failureOrNull ??
        categories.failureOrNull ??
        markets.failureOrNull;
    if (global.isErr && categories.isErr && markets.isErr && failure != null) {
      return Err(failure);
    }

    final categoryList = categories.dataOrNull;
    final marketList = markets.dataOrNull;
    return Ok(
      MarketOverview(
        global: global.dataOrNull,
        categories: categoryList == null
            ? null
            : List.unmodifiable(categoryList.take(categoriesCount)),
        movers: marketList == null ? null : _topMovers(marketList),
      ),
    );
  }

  static List<CoinMarketModel> _topMovers(List<CoinMarketModel> coins) {
    final withChange =
        coins.where((coin) => coin.priceChangePercentage24h != null).toList()
          ..sort(
            (a, b) => b.priceChangePercentage24h!
                .abs()
                .compareTo(a.priceChangePercentage24h!.abs()),
          );
    return List.unmodifiable(withChange.take(moversCount));
  }

  @override
  void dispose() {
    _cancelToken?.cancel('dispose');
    super.dispose();
  }
}
