import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/result/result.dart';
import '../model/crypto/coin_market.dart';
import '../model/crypto/token_model.dart';

/// Nguồn dữ liệu token từ CoinGecko.
class CoinRepository {
  CoinRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  // Vùng nhớ tạm lưu Cache tại Repository (tồn tại suốt vòng đời app)
  List<TokenModel>? _cachedTokens;
  DateTime? _cachedAt;

  /// Khoảng tối thiểu giữa hai lần gọi mạng cho danh sách token.
  ///
  /// `/coins/list` không có phân trang hay delta API nên mỗi lần gọi thật tải
  /// lại toàn bộ ~22k token; chặn refresh dồn dập để không đốt rate limit 429.
  static const Duration _minRefetch = Duration(seconds: 60);

  //------------------Filter junk coins---------------------
  Future<Result<List<CoinMarketModel>>> getTopMarket({
    ApiCancelToken? cancelToken,
  }) =>
      getCoin(perPage: 250, page: 1, cancelToken: cancelToken);

  /// `GET /coins/list` — toàn bộ token CoinGecko đang theo dõi.
  ///
  /// Endpoint trả một mảng phẳng (không phân trang), mỗi phần tử là
  /// `TokenModel`. Parser chạy trong [ApiClient] nên lỗi parse được đổi
  /// thành [Failure] thay vì ném ra ngoài.
  Future<Result<List<TokenModel>>> getTokens(
      {bool includePlatforms = true,
      ApiCancelToken? cancelToken,
      bool forceRefresh = false}) async {
    final cached = _cachedTokens;
    if (cached != null && cached.isNotEmpty) {
      final fetchedAt = _cachedAt;
      final stillFresh = fetchedAt != null &&
          DateTime.now().difference(fetchedAt) < _minRefetch;
      // Có cache: trả cache luôn, trừ khi refresh và cache đã quá cũ.
      if (!forceRefresh || stillFresh) return Ok(cached);
    }
    // Nếu CHƯA CÓ CACHE -> Gọi API lên Server để lấy dữ liệu lần đầu
    final result = await _api.get<List<TokenModel>>(
      ApiEndpoints.coinsList,
      parser: Parsers.listOf(TokenModel.fromJson),
      query: {'include_platform': includePlatforms},
      cancelToken: cancelToken,
    );
    // Lưu vào cache nếu API chạy thành công
    if (result.isOk && result.dataOrNull != null) {
      _cachedTokens = result.dataOrNull;
      _cachedAt = DateTime.now();
    }
    return result;
  }

  //coinMarkets - | **Bảng giá thị trường** | `GET /coins/markets`
  // Lấy danh sách Top coin theo vốn hóa, giá thực, biến động 24h
  // Sửa kiểu trả về từ Result<CoinMarketModel> thành Result<List<CoinMarketModel>>
  Future<Result<List<CoinMarketModel>>> getCoin({
    String vsCurrency = 'usd',
    int page = 1,
    int perPage = 100,
    bool sparkline = false,
    ApiCancelToken? cancelToken,
  }) async {
    // Khai báo rõ generic <List<CoinMarketModel>> giống hàm getTokens bên trên
    final ok = await _api.get<List<CoinMarketModel>>(
      ApiEndpoints.coinMarkets,
      parser: Parsers.listOf(CoinMarketModel.fromJson),
      query: {
        'vs_currency': vsCurrency,
        'order': 'market_cap_desc',
        'per_page': perPage,
        'page': page,
        'sparkline': sparkline, // Dùng biến truyền vào thay vì hardcode false
        'price_change_percentage': '24h',
      },
      cancelToken: cancelToken,
    );
    return ok;
  }

//searchSugesttion cho search function
  /// Gợi ý từ khoá khi gõ ở ô tìm kiếm. [cancelToken] để huỷ request cũ
  /// khi người dùng gõ tiếp.
  Future<Result<List<String>>> getSearchSuggestions(
    String keyword, {
    ApiCancelToken? cancelToken,
  }) =>
      _api.get(
        ApiEndpoints.search,
        query: {'query': keyword},
        cancelToken: cancelToken,
        parser: (json) {
          if (json is! Map) return <String>[];
          final coins = json['coins'];
          if (coins is! List) return <String>[];
          return coins
              .whereType<Map<String, dynamic>>()
              .map((coin) => coin['name']?.toString() ?? '')
              .where((name) => name.isNotEmpty)
              .toList(growable: false);
        },
      );
}
