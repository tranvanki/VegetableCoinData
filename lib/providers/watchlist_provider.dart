import 'package:hhmmobile/core/network/api_client.dart';
import 'package:hhmmobile/core/error/failure.dart';
import 'package:hhmmobile/core/storage/local_storage.dart';
import 'package:hhmmobile/data/model/crypto/coin_market.dart';
import 'package:hhmmobile/data/repository/market_repository.dart';
import 'package:hhmmobile/providers/base_view_model.dart';
// import '../data/model/crypto/coin_market.dart';

/// ViewModel Tab 2 "Theo dõi": giá và biến động 24h của các coin đã gắn sao.
///
/// Nguồn giá: `/coins/markets?ids=` qua [MarketRepository.getMarkets]. Danh
/// sách id lưu cục bộ ở [LocalStorage].
///
/// Bước sau (UI "My Portfolio" có nhiều hơn danh sách theo dõi hiện tại):
/// - Nhiều danh mục (tạo/đổi tên/xoá/chuyển) và số lượng nắm giữ mỗi coin,
///   lưu cục bộ bằng [LocalStorage] (chưa có backend).
/// - Định giá danh mục = số lượng × giá. Chỉ cần giá nên dùng được
///   `/simple/price` (`ApiEndpoints.simplePrice`) thay cho `/coins/markets`.
/// - Chọn cặp tiền hiển thị (BTC/USD), nút thêm coin (+), các tab
///   Phân tích / Thông tin chi tiết.
class WatchListProvider extends BaseViewModel {
  WatchListProvider({
    required MarketRepository repository,
    required LocalStorage storage,
  })  : _repository = repository,
        _storage = storage,
        _watchlistIds = List.unmodifiable(storage.getWatchlistIds());

  final MarketRepository _repository;
  final LocalStorage _storage;
  List<CoinMarketModel> _market = const [];
  List<String> _watchlistIds = const [];
  ApiCancelToken? _cancelToken;

  List<CoinMarketModel> get market => _market;
  List<String> get watchlistIds => _watchlistIds;
  bool isWatching(String coinId) => _watchlistIds.contains(coinId);

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized || isLoading) return;
    await load();
  }

  Future<void> load() async {
    _initialized = true;
    _watchlistIds = List.unmodifiable(_storage.getWatchlistIds());
    if (_watchlistIds.isEmpty) {
      _market = const [];
      setState(ViewState.empty);
      return;
    }

    _cancelToken?.cancel('reload');
    final cancelToken = ApiCancelToken();
    _cancelToken = cancelToken;
    await runInitial<List<CoinMarketModel>>(
      () => _repository.getMarkets(
        coinIds: _watchlistIds,
        cancelToken: cancelToken,
      ),
      onData: _setMarket,
      isEmpty: (data) => data.isEmpty,
    );
  }

  Future<void> refresh() async {
    if (_watchlistIds.isEmpty || isBusy) return;
    _cancelToken?.cancel('refresh');
    final cancelToken = ApiCancelToken();
    _cancelToken = cancelToken;
    await runAction<List<CoinMarketModel>>(
      () => _repository.getMarkets(
        coinIds: _watchlistIds,
        cancelToken: cancelToken,
      ),
      onData: (data) {
        _setMarket(data);
        setState(_market.isEmpty ? ViewState.empty : ViewState.ready);
      },
    );
  }

  Future<bool> removeCoin(String coinId) async {
    if (!_watchlistIds.contains(coinId)) return false;
    return toggleCoin(coinId);
  }

  Future<bool> toggleCoin(String coinId) async {
    final wasWatching = _storage.isInWatchlist(coinId);
    final isWatchingNow = await _storage.toggleWatchlist(coinId);
    if (isWatchingNow == wasWatching) {
      setFailure(
        const Failure.business('Không thể cập nhật danh sách theo dõi.'),
        asScreenError: false,
      );
      return false;
    }

    _watchlistIds = List.unmodifiable(
      _storage.getWatchlistIds(),
    );
    if (isWatchingNow) {
      safeNotify();
      if (_initialized) await refresh();
      return true;
    }

    _market = List.unmodifiable(_market.where((coin) => coin.id != coinId));
    if (_initialized) {
      setState(_market.isEmpty ? ViewState.empty : ViewState.ready);
    } else {
      safeNotify();
    }
    return true;
  }

//Function save coin
  Future<bool> addCoin(List<String> coinIds) async {
    if (coinIds.isEmpty) return false;

    final saved = await _storage.addWatchlistIds(coinIds);

    if (!saved) {
      setFailure(
        const Failure.business('Không thể lưu danh sách theo dõi.'),
        asScreenError: false,
      );
      return false;
    }
    _watchlistIds = List.unmodifiable(_storage.getWatchlistIds());
    safeNotify();

    if (_initialized) await refresh();
    return true;
  }

  void _setMarket(List<CoinMarketModel> data) {
    final byId = {for (final coin in data) coin.id: coin};
    _market = List.unmodifiable(
      _watchlistIds.map((id) => byId[id]).whereType<CoinMarketModel>(),
    );
  }

  @override
  void dispose() {
    _cancelToken?.cancel('dispose');
    super.dispose();
  }
}
