import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../model/binance_coin.dart';

/// SQLite cache for Binance trading pairs and their most recent market values.
class BinanceMarketLocalDataSource {
  BinanceMarketLocalDataSource({Database? database, String? databasePath})
      : _database = database != null
            ? _initProvidedDatabase(database)
            : _openDatabase(databasePath);

  static const _databaseName = 'binance_market.db';
  static const _table = 'binance_coins';

  final Future<Database> _database;

  static Future<void> createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_table (
        symbol TEXT PRIMARY KEY,
        base_asset TEXT NOT NULL,
        quote_asset TEXT NOT NULL,
        name TEXT NOT NULL,
        price REAL,
        change_24h REAL,
        base_volume REAL,
        quote_volume REAL,
        trading_enabled INTEGER NOT NULL,
        image_url TEXT,
        market_cap REAL,
        last_updated TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_binance_coins_base_asset ON $_table(base_asset)',
    );
  }

  static Future<Database> _initProvidedDatabase(Database db) async {
    await createSchema(db);
    return db;
  }

  static Future<Database> _openDatabase(String? databasePath) async {
    final path =
        databasePath ?? p.join(await getDatabasesPath(), _databaseName);
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, _) => createSchema(db),
      onOpen: (db) => createSchema(db),
    );
  }

  Future<List<BinanceCoin>> getCoins() async {
    final db = await _database;
    final rows = await db.query(_table, orderBy: 'symbol ASC');
    return rows.map(BinanceCoin.fromMap).toList(growable: false);
  }

  Future<BinanceCoin?> getCoin(String symbol) async {
    final db = await _database;
    final rows = await db.query(
      _table,
      where: 'symbol = ?',
      whereArgs: [symbol],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return BinanceCoin.fromMap(rows.first);
  }

  Future<void> upsertCoins(Iterable<BinanceCoin> coins) async {
    final snapshot = coins.toList(growable: false);
    if (snapshot.isEmpty) return;
    final db = await _database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final coin in snapshot) {
        batch.insert(
          _table,
          coin.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> clear() async {
    final db = await _database;
    await db.delete(_table);
  }

  Future<void> close() async => (await _database).close();
}
