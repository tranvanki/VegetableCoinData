import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hhmmobile/data/model/binance_coin.dart';
import 'package:hhmmobile/data/repository/binance_market_repository.dart';
import 'package:hhmmobile/providers/base_view_model.dart';
import 'package:hhmmobile/providers/binance_market_view_model.dart';

class FakeBinanceMarketRepository implements BinanceMarketRepository {
  FakeBinanceMarketRepository({
    List<BinanceCoin>? initialCoins,
    this.shouldThrowOnStart = false,
  }) : _coins = initialCoins ?? [];

  final List<BinanceCoin> _coins;
  final bool shouldThrowOnStart;
  final _updatesController = StreamController<List<BinanceCoin>>.broadcast();
  final _statusController =
      StreamController<BinanceConnectionStatus>.broadcast();

  bool refreshed = false;
  bool stopped = false;

  @override
  Stream<List<BinanceCoin>> get updates => _updatesController.stream;

  @override
  Stream<BinanceConnectionStatus> get connectionStatuses =>
      _statusController.stream;

  @override
  Future<List<BinanceCoin>> start() async {
    if (shouldThrowOnStart) {
      throw Exception('Network error');
    }
    return List.unmodifiable(_coins);
  }

  @override
  Future<void> refresh() async {
    refreshed = true;
  }

  @override
  Future<void> stop() async {
    stopped = true;
    await _updatesController.close();
    await _statusController.close();
  }

  void emitUpdates(List<BinanceCoin> coins) {
    _updatesController.add(coins);
  }

  void emitStatus(BinanceConnectionStatus status) {
    _statusController.add(status);
  }
}

void main() {
  late FakeBinanceMarketRepository fakeRepo;
  late BinanceMarketViewModel viewModel;

  final btcCoin = BinanceCoin(
    symbol: 'BTCUSDT',
    baseAsset: 'BTC',
    quoteAsset: 'USDT',
    name: 'Bitcoin',
    tradingEnabled: true,
    price: 65000.0,
    change24h: 3.5,
  );

  final ethCoin = BinanceCoin(
    symbol: 'ETHUSDT',
    baseAsset: 'ETH',
    quoteAsset: 'USDT',
    name: 'Ethereum',
    tradingEnabled: true,
    price: 3400.0,
    change24h: -1.2,
  );

  setUp(() {
    fakeRepo = FakeBinanceMarketRepository(initialCoins: [btcCoin, ethCoin]);
    viewModel = BinanceMarketViewModel(fakeRepo);
  });

  tearDown(() {
    viewModel.dispose();
  });

  test('load populates initial coins and transitions to ready state', () async {
    expect(viewModel.state, ViewState.idle);

    await viewModel.load();

    expect(viewModel.state, ViewState.ready);
    expect(viewModel.coins, hasLength(2));
    expect(viewModel.coins.first.symbol, 'BTCUSDT');
    expect(viewModel.coins.last.symbol, 'ETHUSDT');
  });

  test('setQuery filters coins by symbol and baseAsset', () async {
    await viewModel.load();

    viewModel.setQuery('eth');
    expect(viewModel.coins, hasLength(1));
    expect(viewModel.coins.first.symbol, 'ETHUSDT');

    viewModel.setQuery('BTC');
    expect(viewModel.coins, hasLength(1));
    expect(viewModel.coins.first.symbol, 'BTCUSDT');

    viewModel.setQuery('');
    expect(viewModel.coins, hasLength(2));
  });

  test('realtime stream updates update visible coins list', () async {
    await viewModel.load();

    final updatedBtc = btcCoin.copyWith(price: 66000.0, change24h: 5.0);
    fakeRepo.emitUpdates([updatedBtc, ethCoin]);

    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(viewModel.coins.first.price, 66000.0);
    expect(viewModel.coins.first.change24h, 5.0);
  });

  test('connection status updates update connectionStatus property', () async {
    await viewModel.load();

    fakeRepo.emitStatus(BinanceConnectionStatus.live);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(viewModel.connectionStatus, BinanceConnectionStatus.live);

    fakeRepo.emitStatus(BinanceConnectionStatus.offline);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(viewModel.connectionStatus, BinanceConnectionStatus.offline);
  });

  test('load failure transitions to error state when cache is empty', () async {
    final failingRepo = FakeBinanceMarketRepository(
      initialCoins: [],
      shouldThrowOnStart: true,
    );
    final errorViewModel = BinanceMarketViewModel(failingRepo);

    await errorViewModel.load();

    expect(errorViewModel.state, ViewState.error);
    expect(errorViewModel.failure, isNotNull);

    errorViewModel.dispose();
  });

  test('refresh delegates to repository refresh', () async {
    await viewModel.load();
    await viewModel.refresh();

    expect(fakeRepo.refreshed, isTrue);
  });
}
