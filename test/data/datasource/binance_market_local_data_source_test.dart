import 'package:flutter_test/flutter_test.dart';
import 'package:hhmmobile/data/datasource/binance_market_local_data_source.dart';
import 'package:hhmmobile/data/model/binance_coin.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late BinanceMarketLocalDataSource dataSource;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    final database =
        await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    dataSource = BinanceMarketLocalDataSource(database: database);
  });

  tearDown(() async {
    await dataSource.close();
  });

  test('starts with an empty cache', () async {
    expect(await dataSource.getCoins(), isEmpty);
  });

  test('persists and restores coin metadata and market values', () async {
    final coin = BinanceCoin(
      symbol: 'BTCUSDT',
      baseAsset: 'BTC',
      quoteAsset: 'USDT',
      name: 'Bitcoin',
      tradingEnabled: true,
      price: 67234.12,
      change24h: 1.25,
      baseVolume: 120.5,
      quoteVolume: 8100000,
      imageUrl: 'https://example.com/btc.png',
      marketCap: 1300000000000,
      lastUpdated: DateTime.utc(2025, 1, 2, 3, 4, 5),
    );

    await dataSource.upsertCoins([coin]);

    final cached = await dataSource.getCoins();
    expect(cached, hasLength(1));
    expect(cached.single.toMap(), coin.toMap());
  });

  test('upsert replaces a coin with its latest price', () async {
    final first = _coin(price: 100);
    final updated = _coin(price: 120);

    await dataSource.upsertCoins([first]);
    await dataSource.upsertCoins([updated]);

    final cached = await dataSource.getCoins();
    expect(cached, hasLength(1));
    expect(cached.single.price, 120);
  });

  test('getCoin returns the matching coin or null when missing', () async {
    final coin = _coin(price: 2500);
    await dataSource.upsertCoins([coin]);

    final found = await dataSource.getCoin('ETHUSDT');
    expect(found, isNotNull);
    expect(found?.price, 2500);

    final missing = await dataSource.getCoin('NONEXISTENT');
    expect(missing, isNull);
  });

  test('clear deletes all records from database', () async {
    await dataSource.upsertCoins([
      _coin(price: 100),
      BinanceCoin(
        symbol: 'SOLUSDT',
        baseAsset: 'SOL',
        quoteAsset: 'USDT',
        name: 'Solana',
        tradingEnabled: true,
        price: 150,
      ),
    ]);

    expect(await dataSource.getCoins(), hasLength(2));

    await dataSource.clear();
    expect(await dataSource.getCoins(), isEmpty);
  });
}

BinanceCoin _coin({required double price}) => BinanceCoin(
      symbol: 'ETHUSDT',
      baseAsset: 'ETH',
      quoteAsset: 'USDT',
      name: 'Ethereum',
      tradingEnabled: true,
      price: price,
    );
