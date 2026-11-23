import 'dart:async';

import 'package:hhmmobile/data/model/crypto/coin_market.dart';

import '../core/network/api_client.dart';

import '../data/repository/coin_repository.dart';
import 'base_view_model.dart';

/// ViewModel của màn Token List.
///
/// Chỉ nạp một lần rồi lọc cục bộ: `/coins/list` trả vài chục nghìn phần tử,
/// gọi lại API cho từng ký tự tìm kiếm sẽ đốt rate limit của CoinGecko.
class TokenListProvider extends BaseViewModel {
  TokenListProvider({required CoinRepository repository})
      : _repository = repository;

  final CoinRepository _repository;

  ApiCancelToken? _cancelToken;
  List<dynamic> _tokens = const [];
  List<dynamic> _filtered = const [];
  String _query = '';
  bool _initialized = false;

  /// Danh sách sau khi lọc theo [query].
  List<dynamic> get tokens => _filtered;

  /// Toàn bộ token đã tải — dùng cho badge đếm.
  List<dynamic> get allTokens => _tokens;

  int get totalCount => _tokens.length;
  String get query => _query;
  bool get hasQuery => _query.isNotEmpty;

  static const int _topRank = 250;
  static const double _minVolumeUsd = 1000000;
  static const Duration _pollInterval = Duration(seconds: 20);
  bool _hideJunk = true;
  bool get hideJunk => _hideJunk;

  void toggleHideJunk(bool value) {
    if (_hideJunk == value) return;
    _hideJunk = value;
    _filtered = _applyQuery();
    safeNotify();
  }

  /// Gọi khi màn hình mở. Đã có dữ liệu thì không gọi lại API.
  Future<void> init() async {
    if (_initialized || isLoading) return;
    await load();
    _initialized = true;
    _startPolling();
  }

  /// Nạp lần đầu: loading → ready / empty / error.
  /// Nạp lần đầu: loading → ready / empty / error.
  Future<void> load({bool isRefresh = false}) async {
    _cancelToken?.cancel('reload');
    final cancelToken = ApiCancelToken();
    _cancelToken = cancelToken;

    // Khai báo rõ ràng kiểu dữ liệu trả về cho hàm runInitial
    await runInitial(
      () => _repository.getTokens(
        cancelToken: cancelToken,
        forceRefresh: isRefresh,
      ),
      onData: (data) => _setTokens(data),
      isEmpty: (data) => data.isEmpty,
      keepDataOnError: _tokens.isNotEmpty,
    );
  }

  /// Kéo xuống để làm mới: giữ danh sách cũ, chỉ bật [isBusy].
  /// Lỗi hiển thị bằng snackbar, không thay cả màn hình.
  // Future<void> refresh() async {
  //   if (isBusy) return;
  //   final cancelToken = ApiCancelToken();
  //   _cancelToken = cancelToken;

  //   await runAction(
  //     () => _repository.getTokens(cancelToken: cancelToken),
  //     onData: _setTokens,
  //   );
  // }
  /// Kéo xuống để làm mới danh sách đơn giản bằng cách tái sử dụng hàm [load].
  Future<void> refresh() => load(isRefresh: true);

  /// Lọc theo tên, mã hoặc id. Chạy đồng bộ trên dữ liệu trong bộ nhớ.
  void setQuery(String value) {
    final next = value.trim().toLowerCase();
    if (next == _query) return;
    _query = next;
    _filtered = _applyQuery();
    safeNotify();
  }

  void _setTokens(List<dynamic> data) {
    final sorted = [...data]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    _tokens = List.unmodifiable(sorted);
    _filtered = _applyQuery();
  }

//_isQUanlity + ?? to chekc null
  bool _isQuanlity(CoinMarketModel c) =>
      (c.marketCapRank ?? 1 << 30) <= _topRank &&
      (c.totalVolume ?? 0) > _minVolumeUsd;

  List<dynamic> _applyQuery() {
    Iterable<dynamic> list = _tokens;
    if (_hideJunk) {
      // Token-list results do not include market data; apply this filter only
      // to market results, where rank and volume are available.
      list = list.where((c) => c is! CoinMarketModel || _isQuanlity(c));
    }
    if (_query.isNotEmpty) {
      list = list.where((c) =>
          c.name.toLowerCase().contains(_query) ||
          c.symbol.toLowerCase().contains(_query) ||
          c.id.toLowerCase().contains(_query));
    }
    return List.unmodifiable(list);
  }

  @override
  void dispose() {
    _cancelToken?.cancel('dispose');
    super.dispose();
  }

  //-----Real-time updates every 20 seconds--------//
  Timer? _timer;

  void _startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(_pollInterval, (_) => _silentRefresh());
  }

  bool _polling = false;
  Future<void> _silentRefresh() async {
    if (_polling || isLoading || isBusy) return;
    _polling = true;
    try {
      final result = await _repository.getTopMarket();
      final data = result.dataOrNull;
      if (result.isOk && data != null && data.isNotEmpty) {
        _setTokens(data); // update data only
        safeNotify(); // state stays ViewState.ready, so there is no loading flicker
      }
    } finally {
      _polling = false;
    }
  }
}
