/// Snapshot toàn thị trường từ `GET /global`.
class GlobalStats {
  const GlobalStats({
    required this.activeCryptocurrencies,
    required this.markets,
    required this.totalMarketCap,
    required this.totalVolume,
    required this.marketCapPercentage,
    this.marketCapChangePercentage24hUsd,
  });

  /// [json] là cả body `{ "data": { ... } }` của CoinGecko.
  factory GlobalStats.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    return GlobalStats(
      activeCryptocurrencies:
          (data['active_cryptocurrencies'] as num?)?.toInt() ?? 0,
      markets: (data['markets'] as num?)?.toInt() ?? 0,
      totalMarketCap: _doubleMap(data['total_market_cap']),
      totalVolume: _doubleMap(data['total_volume']),
      marketCapPercentage: _doubleMap(data['market_cap_percentage']),
      marketCapChangePercentage24hUsd:
          (data['market_cap_change_percentage_24h_usd'] as num?)?.toDouble(),
    );
  }

  final int activeCryptocurrencies;
  final int markets;

  /// Theo mã tiền tệ (`usd`, `btc`, ...).
  final Map<String, double> totalMarketCap;
  final Map<String, double> totalVolume;

  /// Tỷ trọng vốn hoá theo coin (`btc`, `eth`, ...), đơn vị %.
  final Map<String, double> marketCapPercentage;

  /// Chỉ có theo USD. Không có trong `all_api_formatted.md` nhưng CoinGecko
  /// vẫn trả; null nếu thiếu.
  final double? marketCapChangePercentage24hUsd;

  double? get btcDominance => marketCapPercentage['btc'];
  double? get ethDominance => marketCapPercentage['eth'];

  static Map<String, double> _doubleMap(Object? value) {
    if (value is! Map) return const {};
    return {
      for (final entry in value.entries)
        if (entry.value is num)
          entry.key.toString(): (entry.value as num).toDouble(),
    };
  }
}
