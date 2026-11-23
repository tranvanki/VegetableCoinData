import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/network/network_info.dart';
import '../datasource/binance_market_local_data_source.dart';
import '../model/binance_coin.dart';

enum BinanceConnectionStatus { offline, connecting, reconnecting, live }

abstract interface class BinanceMarketRepository {
  Stream<List<BinanceCoin>> get updates;
  Stream<BinanceConnectionStatus> get connectionStatuses;

  /// Returns the persisted snapshot immediately, then refreshes from Binance.
  Future<List<BinanceCoin>> start();

  Future<void> refresh();

  Future<void> stop();
}

/// Combines the local SQLite snapshot with Binance exchange metadata and the
/// public all-market ticker stream. The UI only depends on this repository.
class BinanceMarketRepositoryImpl implements BinanceMarketRepository {
  BinanceMarketRepositoryImpl({
    required BinanceMarketLocalDataSource localDataSource,
    required NetworkInfo networkInfo,
    Dio? dio,
    this.quoteAsset = 'USDT',
    String? tickerStreamUrl,
    WebSocketChannel Function(Uri uri)? channelFactory,
  })  : _localDataSource = localDataSource,
        _networkInfo = networkInfo,
        _dio = dio ?? Dio(),
        _tickerStreamUrl = tickerStreamUrl ?? _defaultTickerStreamUrl,
        _channelFactory = channelFactory ?? WebSocketChannel.connect;

  static const _exchangeInfoUrl =
      'https://data-api.binance.vision/api/v3/exchangeInfo';
  static const _defaultTickerStreamUrl =
      'wss://data-stream.binance.vision/ws/!ticker@arr';

  final BinanceMarketLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;
  final Dio _dio;
  final String quoteAsset;
  final String _tickerStreamUrl;
  final WebSocketChannel Function(Uri uri) _channelFactory;

  final Map<String, BinanceCoin> _coins = {};
  final _updates = StreamController<List<BinanceCoin>>.broadcast();
  final _statuses = StreamController<BinanceConnectionStatus>.broadcast();

  StreamSubscription<bool>? _networkSubscription;
  StreamSubscription<dynamic>? _socketSubscription;
  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  Future<void> _pendingWrite = Future<void>.value();
  Future<List<BinanceCoin>>? _startFuture;
  BinanceConnectionStatus _status = BinanceConnectionStatus.offline;
  bool _online = false;
  bool _stopped = false;
  int _reconnectAttempts = 0;
  int _connectionGeneration = 0;

  @override
  Stream<List<BinanceCoin>> get updates => _updates.stream;

  @override
  Stream<BinanceConnectionStatus> get connectionStatuses => _statuses.stream;

  @override
  Future<List<BinanceCoin>> start() => _startFuture ??= _start();

  Future<List<BinanceCoin>> _start() async {
    _stopped = false;
    // 1. Emit cached SQLite data immediately (offline-first).
    final cached = await _localDataSource.getCoins();
    _coins
      ..clear()
      ..addEntries(cached.map((coin) => MapEntry(coin.symbol, coin)));
    _emitCoins();

    // 2. Listen to network connectivity changes for auto-reconnect.
    _networkSubscription ??= _networkInfo.onStatusChange.listen(
      _setOnline,
      onError: (_) => _setOnline(false),
    );
    final connected = await _networkInfo.isConnected;
    _setOnline(connected);
    return List.unmodifiable(_coins.values);
  }

  @override
  Future<void> refresh() async {
    if (_stopped) return;
    final isOnline = await _networkInfo.isConnected;
    _setOnline(isOnline);
    if (isOnline) {
      unawaited(_refreshExchangeInfo());
      _connect();
    }
  }

  void _setOnline(bool online) {
    if (_stopped) return;
    if (online == _online &&
        (_status != BinanceConnectionStatus.offline || !online)) {
      return;
    }
    _online = online;
    if (!online) {
      _reconnectTimer?.cancel();
      _reconnectTimer = null;
      _connectionGeneration++;
      unawaited(_closeSocket());
      _setStatus(BinanceConnectionStatus.offline);
      return;
    }
    _connect();
    unawaited(_refreshExchangeInfo());
  }

  Future<void> _refreshExchangeInfo() async {
    try {
      final response = await _dio.get<dynamic>(
        _exchangeInfoUrl,
        options: Options(receiveTimeout: const Duration(seconds: 5)),
      );
      final body = response.data;
      if (body is! Map || body['symbols'] is! List) return;
      final refreshed = <String, BinanceCoin>{};
      for (final value in body['symbols'] as List) {
        if (value is! Map ||
            value['status'] != 'TRADING' ||
            value['quoteAsset'] != quoteAsset) {
          continue;
        }
        final base = value['baseAsset'];
        if (base is! String || base.isEmpty) continue;
        final symbol = value['symbol'] as String? ?? '$base$quoteAsset';
        final previous = _coins[symbol];
        refreshed[symbol] = BinanceCoin(
          symbol: symbol,
          baseAsset: base,
          quoteAsset: quoteAsset,
          name: base,
          tradingEnabled: true,
          price: previous?.price,
          change24h: previous?.change24h,
          baseVolume: previous?.baseVolume,
          quoteVolume: previous?.quoteVolume,
          imageUrl: previous?.imageUrl,
          marketCap: previous?.marketCap,
          lastUpdated: previous?.lastUpdated,
        );
      }
      if (refreshed.isEmpty) return;
      _coins.addAll(refreshed);
      _emitCoins();
      _queuePersist(refreshed.values);
    } catch (_) {
      // Offline-first: retain cached coins if exchange info fails.
    }
  }

  void _connect() {
    if (_stopped || !_online || _channel != null) return;
    _reconnectTimer?.cancel();
    final generation = ++_connectionGeneration;
    _setStatus(_reconnectAttempts == 0
        ? BinanceConnectionStatus.connecting
        : BinanceConnectionStatus.reconnecting);
    try {
      final channel = _channelFactory(Uri.parse(_tickerStreamUrl));
      _channel = channel;
      channel.ready.then((_) {
        if (generation == _connectionGeneration && !_stopped) {
          _reconnectAttempts = 0;
          _setStatus(BinanceConnectionStatus.live);
        }
      }).catchError((Object _) => _connectionLost(generation));

      _socketSubscription = channel.stream.listen(
        (message) => _handleTickerMessage(message),
        onError: (Object _) => _connectionLost(generation),
        onDone: () => _connectionLost(generation),
        cancelOnError: false,
      );
    } catch (_) {
      _connectionLost(generation);
    }
  }

  void _handleTickerMessage(dynamic message) {
    if (message is! String) return;
    try {
      final decoded = jsonDecode(message);
      final rows = decoded is List
          ? decoded
          : decoded is Map && decoded['data'] is List
              ? decoded['data'] as List
              : decoded is Map && decoded['data'] is Map
                  ? [decoded['data']]
                  : decoded is Map && decoded.containsKey('s')
                      ? [decoded]
                      : const <dynamic>[];

      final changed = <BinanceCoin>[];
      for (final raw in rows) {
        if (raw is! Map) continue;
        final value = raw is Map<String, dynamic>
            ? raw
            : Map<String, dynamic>.from(raw);
        final symbol = value['s'] as String?;
        if (symbol == null || !symbol.endsWith(quoteAsset)) continue;

        var coin = _coins[symbol];
        if (coin == null) {
          final base = symbol.substring(0, symbol.length - quoteAsset.length);
          if (base.isEmpty) continue;
          coin = BinanceCoin(
            symbol: symbol,
            baseAsset: base,
            quoteAsset: quoteAsset,
            name: base,
            tradingEnabled: true,
          );
        }

        final updated = coin.copyWithTicker(value);
        _coins[symbol] = updated;
        changed.add(updated);
      }
      if (changed.isEmpty) return;
      _emitCoins();
      _queuePersist(changed);
    } on FormatException {
      // Ignore malformed frames and keep the stream alive.
    }
  }

  void _queuePersist(Iterable<BinanceCoin> coins) {
    final snapshot = List<BinanceCoin>.of(coins);
    _pendingWrite = _pendingWrite
        .then((_) => _localDataSource.upsertCoins(snapshot))
        .catchError((Object _) {});
  }

  void _connectionLost(int generation) {
    if (_stopped || generation != _connectionGeneration) return;
    _channel = null;
    unawaited(_socketSubscription?.cancel());
    _socketSubscription = null;
    if (!_online) {
      _setStatus(BinanceConnectionStatus.offline);
      return;
    }
    _setStatus(BinanceConnectionStatus.reconnecting);
    final seconds = (1 << _reconnectAttempts.clamp(0, 5)).clamp(1, 30);
    _reconnectAttempts++;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: seconds), _connect);
  }

  Future<void> _closeSocket() async {
    await _socketSubscription?.cancel();
    _socketSubscription = null;
    final channel = _channel;
    _channel = null;
    await channel?.sink.close();
  }

  void _emitCoins() {
    if (_updates.isClosed) return;
    final values = _coins.values.toList(growable: false)
      ..sort((a, b) => a.symbol.compareTo(b.symbol));
    _updates.add(List.unmodifiable(values));
  }

  void _setStatus(BinanceConnectionStatus status) {
    if (_status == status || _statuses.isClosed) return;
    _status = status;
    _statuses.add(status);
  }

  @override
  Future<void> stop() async {
    if (_stopped) return;
    _stopped = true;
    _startFuture = null;
    _online = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _networkSubscription?.cancel();
    _networkSubscription = null;
    _connectionGeneration++;
    await _closeSocket();
    await _pendingWrite;
    await _updates.close();
    await _statuses.close();
    await _localDataSource.close();
    _dio.close();
  }
}
