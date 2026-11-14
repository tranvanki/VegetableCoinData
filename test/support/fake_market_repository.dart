import 'package:flutter_test/flutter_test.dart';
import 'package:hhmmobile/core/network/api_client.dart';
import 'package:hhmmobile/core/result/result.dart';
import 'package:hhmmobile/data/model/crypto/coin_market.dart';
import 'package:hhmmobile/data/model/crypto/coin_category.dart';
import 'package:hhmmobile/data/model/system/global_stats.dart';
import 'package:hhmmobile/data/repository/market_repository.dart';

/// Repository giả cho test provider: trả kết quả đã cấu hình, ghi lại lời gọi.
class FakeMarketRepository extends Fake implements MarketRepository {
  Result<GlobalStats> globalResult = Ok(emptyGlobal);
  Result<List<String>> trendingResult = const Ok(<String>[]);
  Result<List<CoinCategory>> categoriesResult = const Ok(<CoinCategory>[]);

  /// Quyết định kết quả cho mỗi lần gọi `getMarkets`.
  Result<List<CoinMarketModel>> Function(int page, List<String>? coinIds)
      marketsHandler = (_, __) => const Ok(<CoinMarketModel>[]);

  final List<({int page, List<String>? coinIds, bool sparkline})> marketCalls =
      [];

  @override
  Future<Result<List<CoinMarketModel>>> getMarkets({
    String vsCurrency = 'usd',
    int page = 1,
    int perPage = 100,
    bool sparkline = false,
    List<String>? coinIds,
    ApiCancelToken? cancelToken,
  }) async {
    marketCalls.add((page: page, coinIds: coinIds, sparkline: sparkline));
    return marketsHandler(page, coinIds);
  }

  @override
  Future<Result<GlobalStats>> getGlobalStats({
    ApiCancelToken? cancelToken,
  }) async =>
      globalResult;

  @override
  Future<Result<List<String>>> getTrendingCoinIds({
    ApiCancelToken? cancelToken,
  }) async =>
      trendingResult;

  @override
  Future<Result<List<CoinCategory>>> getCategories({
    ApiCancelToken? cancelToken,
  }) async =>
      categoriesResult;
}

const GlobalStats emptyGlobal = GlobalStats(
  activeCryptocurrencies: 0,
  markets: 0,
  totalMarketCap: {},
  totalVolume: {},
  marketCapPercentage: {},
);

CoinMarketModel coin(
  String id, {
  int? rank,
  double? price,
  double? change24h,
  double? marketCap,
}) =>
    CoinMarketModel(
      id: id,
      symbol: id,
      name: id,
      image: '',
      currentPrice: price,
      marketCap: marketCap,
      marketCapRank: rank,
      priceChangePercentage24h: change24h,
      lastUpdated: DateTime(2026),
    );
