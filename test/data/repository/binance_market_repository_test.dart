import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hhmmobile/core/network/network_info.dart';
import 'package:hhmmobile/data/datasource/binance_market_local_data_source.dart';
import 'package:hhmmobile/data/model/binance_coin.dart';
import 'package:hhmmobile/data/repository/binance_market_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class FakeNetworkInfo implements NetworkInfo {
  FakeNetworkInfo({bool initial = true}) : _connected = initial;

  bool _connected;
  final _controller = StreamController<bool>.broadcast();

  @override
  Future<bool> get isConnected async => _connected;

  @override
  Stream<bool> get onStatusChange => _controller.stream;

  void setConnected(bool value) {
    _connected = value;
    _controller.add(value);
  }

  void dispose() {
    _controller.close();
  }
}

class TestWebSocketChannel extends StreamChannelMixin<dynamic>
    implements WebSocketChannel {
  TestWebSocketChannel({
    StreamController<dynamic>? incomingController,
    StreamController<dynamic>? outgoingController,
  })  : _incoming = incomingController ?? StreamController<dynamic>.broadcast(),
        _outgoing = outgoingController ?? StreamController<dynamic>.broadcast();

  final StreamController<dynamic> _incoming;
  final StreamController<dynamic> _outgoing;
  final Completer<void> _readyCompleter = Completer<void>()..complete();

  @override
  Future<void> get ready => _readyCompleter.future;

  @override
  Stream<dynamic> get stream => _incoming.stream;

  @override
  WebSocketSink get sink => _TestWebSocketSink(_outgoing, _incoming);

  @override
  String? get protocol => null;

  @override
  int? get closeCode => null;

  @override
  String? get closeReason => null;

  void addIncoming(dynamic message) {
    _incoming.add(message);
  }

  void addError(Object error) {
    _incoming.addError(error);
  }

  void closeIncoming() {
    _incoming.close();
  }
}

class _TestWebSocketSink implements WebSocketSink {
  _TestWebSocketSink(this._outgoing, this._incoming);

  final StreamController<dynamic> _outgoing;
  final StreamController<dynamic> _incoming;

  @override
  void add(dynamic data) => _outgoing.add(data);

  @override
  void addError(Object error, [StackTrace? stackTrace]) =>
      _outgoing.addError(error, stackTrace);

  @override
  Future<void> addStream(Stream<dynamic> stream) => _outgoing.addStream(stream);

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {
    await _incoming.close();
    await _outgoing.close();
  }

  @override
  Future<void> get done => _outgoing.done;
}

void main() {
  late BinanceMarketLocalDataSource localDataSource;
  late FakeNetworkInfo fakeNetworkInfo;
  late TestWebSocketChannel fakeChannel;
  late BinanceMarketRepositoryImpl repository;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    localDataSource = BinanceMarketLocalDataSource(database: db);
    fakeNetworkInfo = FakeNetworkInfo(initial: true);
    fakeChannel = TestWebSocketChannel();

    repository = BinanceMarketRepositoryImpl(
      localDataSource: localDataSource,
      networkInfo: fakeNetworkInfo,
      channelFactory: (_) => fakeChannel,
    );
  });

  tearDown(() async {
    await repository.stop();
    fakeNetworkInfo.dispose();
  });

  test('offline-first: returns and emits cached sqlite coins immediately on start',
      () async {
    final cachedCoin = BinanceCoin(
      symbol: 'BTCUSDT',
      baseAsset: 'BTC',
      quoteAsset: 'USDT',
      name: 'Bitcoin',
      tradingEnabled: true,
      price: 65000.0,
      change24h: 2.5,
    );
    await localDataSource.upsertCoins([cachedCoin]);

    final received = <List<BinanceCoin>>[];
    repository.updates.listen(received.add);

    final initial = await repository.start();

    expect(initial, hasLength(1));
    expect(initial.first.symbol, 'BTCUSDT');
    expect(initial.first.price, 65000.0);

    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(received, isNotEmpty);
    expect(received.first.first.symbol, 'BTCUSDT');
  });

  test('realtime: processes websocket ticker frame and saves to local database',
      () async {
    await repository.start();

    final updates = <List<BinanceCoin>>[];
    repository.updates.listen(updates.add);

    // Simulate Binance ticker stream payload
    final tickerPayload = jsonEncode([
      {
        'e': '24hrTicker',
        's': 'ETHUSDT',
        'c': '3400.50',
        'P': '5.20',
        'v': '15000',
        'q': '51000000',
        'E': DateTime.now().millisecondsSinceEpoch,
      }
    ]);

    fakeChannel.addIncoming(tickerPayload);

    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(updates, isNotEmpty);
    final eth = updates.last.firstWhere((c) => c.symbol == 'ETHUSDT');
    expect(eth.price, 3400.50);
    expect(eth.change24h, 5.20);

    // Verify it was persisted to SQLite localDB
    final inDb = await localDataSource.getCoin('ETHUSDT');
    expect(inDb, isNotNull);
    expect(inDb?.price, 3400.50);
  });

  test('auto-reconnect: updates status to offline when network drops and reconnects when back',
      () async {
    final statuses = <BinanceConnectionStatus>[];
    repository.connectionStatuses.listen(statuses.add);

    await repository.start();
    await Future<void>.delayed(const Duration(milliseconds: 10));

    // Simulate losing internet
    fakeNetworkInfo.setConnected(false);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(statuses, contains(BinanceConnectionStatus.offline));

    // Simulate internet restored
    fakeNetworkInfo.setConnected(true);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(
      statuses.any((s) =>
          s == BinanceConnectionStatus.connecting ||
          s == BinanceConnectionStatus.reconnecting ||
          s == BinanceConnectionStatus.live),
      isTrue,
    );
  });

  test('auto-reconnect: reconnects with reconnecting status when socket closes',
      () async {
    final statuses = <BinanceConnectionStatus>[];
    repository.connectionStatuses.listen(statuses.add);

    await repository.start();
    await Future<void>.delayed(const Duration(milliseconds: 10));

    // Simulate socket disconnected while network is still online
    fakeChannel.closeIncoming();
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(statuses, contains(BinanceConnectionStatus.reconnecting));
  });
}
