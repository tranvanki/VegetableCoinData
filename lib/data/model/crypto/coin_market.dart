import 'dart:convert';

List<CoinMarketModel> coinMarketModelFromJson(String str) =>
    List<CoinMarketModel>.from(
        json.decode(str).map((x) => CoinMarketModel.fromJson(x)));

String coinMarketModelToJson(List<CoinMarketModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class CoinMarketModel {
  final String id;
  final String symbol;
  final String name;
  final String image;
  final double? currentPrice;
  final double? marketCap;
  final int? marketCapRank;
  final double? fullyDilutedValuation;
  final double? totalVolume;
  final double? high24h;
  final double? low24h;
  final double? priceChange24h;
  final double? priceChangePercentage24h;
  final double? marketCapChange24h;
  final double? marketCapChangePercentage24h;
  final double? circulatingSupply;
  final double? totalSupply;
  final double? maxSupply;
  final double? ath;
  final double? athChangePercentage;
  final DateTime? athDate;
  final double? atl;
  final double? atlChangePercentage;
  final DateTime? atlDate;
  final Roi? roi;
  final DateTime lastUpdated;
  final int? marketCapRankWithRehypothecated;
  final SparklineIn7d? sparklineIn7d;
  final double? priceChangePercentage1hInCurrency;
  final double? priceChangePercentage24hInCurrency;
  final double? priceChangePercentage7dInCurrency;
  final double? priceChangePercentage14dInCurrency;
  final double? priceChangePercentage30dInCurrency;
  final double? priceChangePercentage200dInCurrency;
  final double? priceChangePercentage1yInCurrency;

  const CoinMarketModel({
    required this.id,
    required this.symbol,
    required this.name,
    required this.image,
    this.currentPrice,
    this.marketCap,
    this.marketCapRank,
    this.fullyDilutedValuation,
    this.totalVolume,
    this.high24h,
    this.low24h,
    this.priceChange24h,
    this.priceChangePercentage24h,
    this.marketCapChange24h,
    this.marketCapChangePercentage24h,
    this.circulatingSupply,
    this.totalSupply,
    this.maxSupply,
    this.ath,
    this.athChangePercentage,
    this.athDate,
    this.atl,
    this.atlChangePercentage,
    this.atlDate,
    this.roi,
    required this.lastUpdated,
    this.marketCapRankWithRehypothecated,
    this.sparklineIn7d,
    this.priceChangePercentage1hInCurrency,
    this.priceChangePercentage24hInCurrency,
    this.priceChangePercentage7dInCurrency,
    this.priceChangePercentage14dInCurrency,
    this.priceChangePercentage30dInCurrency,
    this.priceChangePercentage200dInCurrency,
    this.priceChangePercentage1yInCurrency,
  });

  // Đây chính là hàm map dữ liệu bắt buộc phải có để truyền vào Parsers của ApiClient
  factory CoinMarketModel.fromJson(Map<String, dynamic> json) {
    return CoinMarketModel(
      id: json['id'] as String,
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      image: json['image'] as String,
      currentPrice: (json['current_price'] as num?)?.toDouble(),
      marketCap: (json['market_cap'] as num?)?.toDouble(),
      marketCapRank: (json['market_cap_rank'] as num?)?.toInt(),
      fullyDilutedValuation:
          (json['fully_diluted_valuation'] as num?)?.toDouble(),
      totalVolume: (json['total_volume'] as num?)?.toDouble(),
      high24h: (json['high_24h'] as num?)?.toDouble(),
      low24h: (json['low_24h'] as num?)?.toDouble(),
      priceChange24h: (json['price_change_24h'] as num?)?.toDouble(),
      priceChangePercentage24h:
          (json['price_change_percentage_24h'] as num?)?.toDouble(),
      marketCapChange24h: (json['market_cap_change_24h'] as num?)?.toDouble(),
      marketCapChangePercentage24h:
          (json['market_cap_change_percentage_24h'] as num?)?.toDouble(),
      circulatingSupply: (json['circulating_supply'] as num?)?.toDouble(),
      totalSupply: (json['total_supply'] as num?)?.toDouble(),
      maxSupply: (json['max_supply'] as num?)?.toDouble(),
      ath: (json['ath'] as num?)?.toDouble(),
      athChangePercentage: (json['ath_change_percentage'] as num?)?.toDouble(),
      athDate: json['ath_date'] != null
          ? DateTime.tryParse(json['ath_date'] as String)
          : null,
      atl: (json['atl'] as num?)?.toDouble(),
      atlChangePercentage: (json['atl_change_percentage'] as num?)?.toDouble(),
      atlDate: json['atl_date'] != null
          ? DateTime.tryParse(json['atl_date'] as String)
          : null,
      roi: json['roi'] != null
          ? Roi.fromJson(json['roi'] as Map<String, dynamic>)
          : null,
      lastUpdated: DateTime.parse(json['last_updated'] as String),
      marketCapRankWithRehypothecated:
          (json['market_cap_rank_with_rehypothecated'] as num?)?.toInt(),
      sparklineIn7d: json['sparkline_in_7d'] != null
          ? SparklineIn7d.fromJson(
              json['sparkline_in_7d'] as Map<String, dynamic>)
          : null,
      priceChangePercentage1hInCurrency:
          (json['price_change_percentage_1h_in_currency'] as num?)?.toDouble(),
      priceChangePercentage24hInCurrency:
          (json['price_change_percentage_24h_in_currency'] as num?)?.toDouble(),
      priceChangePercentage7dInCurrency:
          (json['price_change_percentage_7d_in_currency'] as num?)?.toDouble(),
      priceChangePercentage14dInCurrency:
          (json['price_change_percentage_14d_in_currency'] as num?)?.toDouble(),
      priceChangePercentage30dInCurrency:
          (json['price_change_percentage_30d_in_currency'] as num?)?.toDouble(),
      priceChangePercentage200dInCurrency:
          (json['price_change_percentage_200d_in_currency'] as num?)
              ?.toDouble(),
      priceChangePercentage1yInCurrency:
          (json['price_change_percentage_1y_in_currency'] as num?)?.toDouble(),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symbol': symbol,
      'name': name,
      'image': image,
      'current_price': currentPrice,
      'market_cap': marketCap,
      'market_cap_rank': marketCapRank,
      'fully_diluted_valuation': fullyDilutedValuation,
      'total_volume': totalVolume,
      'high_24h': high24h,
      'low_24h': low24h,
      'price_change_24h': priceChange24h,
      'price_change_percentage_24h': priceChangePercentage24h,
      'market_cap_change_24h': marketCapChange24h,
      'market_cap_change_percentage_24h': marketCapChangePercentage24h,
      'circulating_supply': circulatingSupply,
      'total_supply': totalSupply,
      'max_supply': maxSupply,
      'ath': ath,
      'ath_change_percentage': athChangePercentage,
      'ath_date': athDate?.toIso8601String(),
      'atl': atl,
      'atl_change_percentage': atlChangePercentage,
      'atl_date': atlDate?.toIso8601String(),
      'roi': roi?.toJson(),
      'last_updated': lastUpdated.toIso8601String(),
      'market_cap_rank_with_rehypothecated': marketCapRankWithRehypothecated,
      'sparkline_in_7d': sparklineIn7d?.toJson(),
      'price_change_percentage_1h_in_currency':
          priceChangePercentage1hInCurrency,
      'price_change_percentage_24h_in_currency':
          priceChangePercentage24hInCurrency,
      'price_change_percentage_7d_in_currency':
          priceChangePercentage7dInCurrency,
      'price_change_percentage_14d_in_currency':
          priceChangePercentage14dInCurrency,
      'price_change_percentage_30d_in_currency':
          priceChangePercentage30dInCurrency,
      'price_change_percentage_200d_in_currency':
          priceChangePercentage200dInCurrency,
      'price_change_percentage_1y_in_currency':
          priceChangePercentage1yInCurrency,
    };
  }
}

class Roi {
  final double times;
  final String currency;
  final double percentage;

  Roi({
    required this.times,
    required this.currency,
    required this.percentage,
  });

  factory Roi.fromJson(Map<String, dynamic> json) {
    return Roi(
      times: (json['times'] as num).toDouble(),
      currency: json['currency'] as String,
      percentage: (json['percentage'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'times': times,
      'currency': currency,
      'percentage': percentage,
    };
  }
}

class SparklineIn7d {
  final List<double> price;

  SparklineIn7d({
    required this.price,
  });

  factory SparklineIn7d.fromJson(Map<String, dynamic> json) {
    return SparklineIn7d(
      price: (json['price'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'price': price,
    };
  }
}
