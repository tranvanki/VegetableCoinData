import 'dart:async';

import '../core/error/failure.dart';
import '../data/model/binance_coin.dart';
import '../data/repository/binance_market_repository.dart';
import 'base_view_model.dart';

/// MVVM ViewModel for the Binance market screen.
class BinanceMarketViewModel extends BaseViewModel {
  BinanceMarketViewModel(this._repository);

  final BinanceMarketRepository _repository;
  StreamSubscription<List<BinanceCoin>>? _updatesSubscription;
  StreamSubscription<BinanceConnectionStatus>? _statusSubscription;
  List<BinanceCoin> _allCoins = const [];
  List<BinanceCoin> _visibleCoins = const [];
  String _query = '';
  BinanceConnectionStatus _connectionStatus =
      BinanceConnectionStatus.connecting;
  bool _started = false;

  List<BinanceCoin> get coins => _visibleCoins;
  BinanceConnectionStatus get connectionStatus => _connectionStatus;
  String get query => _query;

  Future<void> load() async {
    if (_started || isDisposed) return;
    _started = true;
    setState(ViewState.loading);
    _updatesSubscription = _repository.updates.listen(_onCoinsUpdated);
    _statusSubscription = _repository.connectionStatuses.listen((status) {
      _connectionStatus = status;
      safeNotify();
    });
    try {
      final cached = await _repository.start();
      if (isDisposed) return;
      _allCoins = cached;
      _applyQuery();
      setState(cached.isEmpty ? ViewState.empty : ViewState.ready);
    } catch (error) {
      if (isDisposed) return;
      setFailure(
        Failure.unknown(error.toString(), cause: error),
        asScreenError: _allCoins.isEmpty,
      );
    }
  }

  Future<void> refresh() async {
    if (isDisposed) return;
    try {
      await _repository.refresh();
    } catch (error) {
      if (isDisposed) return;
      setFailure(
        Failure.unknown(error.toString(), cause: error),
        asScreenError: false,
      );
    }
  }

  void _onCoinsUpdated(List<BinanceCoin> coins) {
    if (isDisposed) return;
    _allCoins = coins;
    _applyQuery();
    if (state == ViewState.loading) {
      setState(coins.isEmpty ? ViewState.empty : ViewState.ready);
    } else {
      safeNotify();
    }
  }

  void setQuery(String value) {
    _query = value.trim().toUpperCase();
    _applyQuery();
    safeNotify();
  }

  void _applyQuery() {
    if (_query.isEmpty) {
      _visibleCoins = List.unmodifiable(_allCoins);
    } else {
      _visibleCoins = List.unmodifiable(_allCoins.where((coin) =>
          coin.symbol.contains(_query) || coin.baseAsset.contains(_query)));
    }
  }

  @override
  void dispose() {
    unawaited(_updatesSubscription?.cancel());
    unawaited(_statusSubscription?.cancel());
    unawaited(_repository.stop());
    super.dispose();
  }
}
