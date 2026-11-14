import 'package:hhmmobile/data/model/crypto/coin_market.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/result/result.dart';
import '../model/crypto/coin_category.dart';
import '../model/system/global_stats.dart';

class MarketRepository {
  MarketRepository({
    required ApiClient apiClient,
  }) : _api = apiClient;
  final ApiClient _api;

  // Tab 1 và Tab 3 cùng đọc /global; cache RAM ngắn để chuyển tab không gọi
  // lại và không đốt rate limit 429 của gói Free.
  static const Duration _globalTtl = Duration(seconds: 60);
  GlobalStats? _cachedGlobal;
  DateTime? _globalCachedAt;

  /// Lấy danh sách thị trường tiền điện tử
  /// [vsCurrency] mặc định là 'usd'
  /// [coinIds] danh sách các coin cần lấy (ví dụ: ['bitcoin', 'ethereum'])
  /// [sparkline] kèm `sparkline_in_7d` — nặng (~168 điểm/coin), chỉ bật khi
  /// màn hình thật sự vẽ biểu đồ nhỏ.
  Future<Result<List<CoinMarketModel>>> getMarkets({
    String vsCurrency = 'usd',
    int page = 1,
    int perPage = 100,
    bool sparkline = false,
    List<String>? coinIds,
    ApiCancelToken? cancelToken,
  }) {
    final queryParams = <String, dynamic>{
      'vs_currency': vsCurrency,
      'order': 'market_cap_desc',
      'per_page': coinIds?.length ?? perPage,
      'page': page,
      'sparkline': sparkline,
      'price_change_percentage': '24h',
    };
    if (coinIds != null && coinIds.isNotEmpty) {
      queryParams['ids'] = coinIds.join(',');
    }

    return _api.get<List<CoinMarketModel>>(
      ApiEndpoints.coinMarkets,
      query: queryParams,
      cancelToken: cancelToken,
      parser: Parsers.listOf(CoinMarketModel.fromJson),
    );
  }

  /// `GET /global` — vốn hoá, khối lượng và tỷ trọng BTC/ETH toàn thị trường.
  Future<Result<GlobalStats>> getGlobalStats({
    ApiCancelToken? cancelToken,
  }) async {
    final cached = _cachedGlobal;
    final cachedAt = _globalCachedAt;
    if (cached != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < _globalTtl) {
      return Ok(cached);
    }

    final result = await _api.get<GlobalStats>(
      ApiEndpoints.global,
      cancelToken: cancelToken,
      parser: Parsers.objectOf(GlobalStats.fromJson),
    );
    final data = result.dataOrNull;
    if (data != null) {
      _cachedGlobal = data;
      _globalCachedAt = DateTime.now();
    }
    return result;
  }

  /// `GET /search/trending` — chỉ lấy `id` coin theo thứ tự thịnh hành.
  /// Dữ liệu giá đầy đủ lấy tiếp bằng [getMarkets] với `coinIds`.
  Future<Result<List<String>>> getTrendingCoinIds({
    ApiCancelToken? cancelToken,
  }) =>
      _api.get<List<String>>(
        ApiEndpoints.trending,
        cancelToken: cancelToken,
        parser: (json) {
          if (json is! Map) return <String>[];
          final coins = json['coins'];
          if (coins is! List) return <String>[];
          return coins
              .whereType<Map>()
              .map((entry) => (entry['item'] as Map?)?['id']?.toString() ?? '')
              .where((id) => id.isNotEmpty)
              .toList(growable: false);
        },
      );

  /// `GET /coins/categories` — mặc định đã sắp theo vốn hoá giảm dần.
  Future<Result<List<CoinCategory>>> getCategories({
    ApiCancelToken? cancelToken,
  }) =>
      _api.get<List<CoinCategory>>(
        ApiEndpoints.coinCategories,
        cancelToken: cancelToken,
        parser: Parsers.listOf(CoinCategory.fromJson),
      );
}
