import 'package:hhmmobile/data/model/crypto/coin_market.dart';

class BinanceCoin {
  //9 attributes
  final String symbol;
  final String baseAsset;
  final String quoteAsset;
  final String name;
  final double? price;
  final double? change24h;
  final double? baseVolume;
  final double? quoteVolume;
  final bool tradingEnabled;
  final String? imageUrl;
  final double? marketCap;
  final DateTime? lastUpdated;

  const BinanceCoin(
      {required this.symbol,
      required this.baseAsset,
      required this.quoteAsset,
      required this.name,
      required this.tradingEnabled,
      this.imageUrl,
      this.baseVolume,
      this.change24h,
      this.price,
      this.quoteVolume,
      this.marketCap,
      this.lastUpdated});

  /// Tạo [BinanceCoin] từ [CoinMarketModel] (CoinGecko) để có sẵn
  /// avatar, tên đầy đủ và vốn hóa trước khi nhận tick real-time.
  /// - [market]: Model thị trường từ CoinRepository.getCoin.
  /// - [quoteAsset]: Cặp định giá trên Binance (mặc định 'USDT').
  factory BinanceCoin.fromMarketModel(
    CoinMarketModel market, {
    String quoteAsset = 'USDT',
  }) {
    final base = market.symbol.toUpperCase();
    return BinanceCoin(
      symbol: '$base$quoteAsset',
      baseAsset: base,
      quoteAsset: quoteAsset,
      name: market.name,
      imageUrl: market.image,
      marketCap: market.marketCap,
      price: market.currentPrice,
      change24h: market.priceChangePercentage24h,
      baseVolume: market.totalVolume,
      tradingEnabled: true,
    );
  }
//tách riêng dữ liệu tĩnh từ REST API
  //ko mất thông tin gốc của coin.
//copyWith để tạo ra một bản sao mới. Nó giữ nguyên thông tin tĩnh
  BinanceCoin copyWithTicker(Map<String, dynamic> ticker) {
    final parsedPrice = double.tryParse(ticker['c']?.toString() ?? '');
    double? parsedChange = double.tryParse(ticker['P']?.toString() ?? '');
    if (parsedChange == null && ticker['o'] != null && parsedPrice != null) {
      final open = double.tryParse(ticker['o']?.toString() ?? '');
      if (open != null && open > 0) {
        parsedChange = ((parsedPrice - open) / open) * 100;
      }
    }
    return copyWith(
      price: parsedPrice ?? price,
      change24h: parsedChange ?? change24h,
      baseVolume: double.tryParse(ticker['v']?.toString() ?? '') ?? baseVolume,
      quoteVolume:
          double.tryParse(ticker['q']?.toString() ?? '') ?? quoteVolume,
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(
        (ticker['E'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  BinanceCoin copyWith({
    double? price,
    double? change24h,
    double? baseVolume,
    double? quoteVolume,
    DateTime? lastUpdated,
  }) {
    return BinanceCoin(
      symbol: symbol,
      baseAsset: baseAsset,
      quoteAsset: quoteAsset,
      name: name,
      tradingEnabled: tradingEnabled,
      price: price ?? this.price,
      change24h: change24h ?? this.change24h,
      baseVolume: baseVolume ?? this.baseVolume,
      quoteVolume: quoteVolume ?? this.quoteVolume,
      imageUrl: imageUrl,
      marketCap: marketCap,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  factory BinanceCoin.fromMap(Map<String, Object?> map) => BinanceCoin(
        symbol: map['symbol']! as String,
        baseAsset: map['base_asset']! as String,
        quoteAsset: map['quote_asset']! as String,
        name: map['name']! as String,
        price: (map['price'] as num?)?.toDouble(),
        change24h: (map['change_24h'] as num?)?.toDouble(),
        baseVolume: (map['base_volume'] as num?)?.toDouble(),
        quoteVolume: (map['quote_volume'] as num?)?.toDouble(),
        tradingEnabled: (map['trading_enabled'] as num? ?? 1) == 1,
        imageUrl: map['image_url'] as String?,
        marketCap: (map['market_cap'] as num?)?.toDouble(),
        lastUpdated: map['last_updated'] == null
            ? null
            : DateTime.tryParse(map['last_updated']! as String),
      );

  Map<String, Object?> toMap() => {
        'symbol': symbol,
        'base_asset': baseAsset,
        'quote_asset': quoteAsset,
        'name': name,
        'price': price,
        'change_24h': change24h,
        'base_volume': baseVolume,
        'quote_volume': quoteVolume,
        'trading_enabled': tradingEnabled ? 1 : 0,
        'image_url': imageUrl,
        'market_cap': marketCap,
        'last_updated': lastUpdated?.toIso8601String(),
      };
}
