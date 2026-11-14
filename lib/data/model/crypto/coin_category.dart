/// Nhóm ngành coin từ `GET /coins/categories`.
class CoinCategory {
  const CoinCategory({
    required this.id,
    required this.name,
    this.marketCap,
    this.marketCapChange24h,
    this.top3Coins = const [],
    this.volume24h,
  });

  factory CoinCategory.fromJson(Map<String, dynamic> json) {
    final top3 = json['top_3_coins'];
    return CoinCategory(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      marketCap: (json['market_cap'] as num?)?.toDouble(),
      marketCapChange24h: (json['market_cap_change_24h'] as num?)?.toDouble(),
      top3Coins: top3 is List
          ? top3.whereType<String>().toList(growable: false)
          : const [],
      volume24h: (json['volume_24h'] as num?)?.toDouble(),
    );
  }

  final String id;
  final String name;
  final double? marketCap;

  /// Biến động vốn hoá 24h, đơn vị %.
  final double? marketCapChange24h;

  /// URL logo của 3 coin lớn nhất trong nhóm.
  final List<String> top3Coins;
  final double? volume24h;
}
