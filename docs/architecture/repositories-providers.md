# Repositories + Providers — hướng dẫn dựng tính năng MVP

## Kiểm kê hiện trạng

| Lớp | File | Trạng thái |
|---|---|---|
| Repository | `lib/data/repository/coin_repository.dart` | DONE — `getTokens` (cache RAM + throttle 60s), `getSearchSuggestions` (`/search`). |
| Repository | `lib/data/repository/market_repository.dart` | STUB — `getMarkets` ném `UnimplementedError`; `GlobalStat` mới khai báo nửa vời. |
| Repository | `lib/data/repository/system_repository.dart` | Cache-only — đọc `RemoteConfig` từ `LocalStorage`; KHÔNG gọi mạng. |
| Repository | `lib/data/repository/service_repository.dart` | DEAD — toàn bộ comment. Xoá hoặc dựng lại khi cần. |
| Provider | `lib/providers/base_view_model.dart` | DONE — `ViewState`, `runInitial`, `runAction`, `safeNotify`. |
| Provider | `lib/providers/app_state_provider.dart` | DONE — theme/locale/`isOnline`/`notificationBadge`/config. |
| Provider | `lib/providers/token_list_provider.dart` | DONE. |
| Provider | `lib/providers/search_provider.dart` | DONE. |
| DI | `lib/app/di/service_locator.dart` | Đã đăng ký `ApiClient`, `SystemRepository`, `CoinRepository`, `AppStateProvider`, `SearchProvider`, `TokenListProvider`. **CHƯA** có `MarketRepository` và các provider mới. |

Còn thiếu cho MVP: implement `MarketRepository.getMarkets`, thêm `getGlobalStats`, tạo `MarketProvider` / `GlobalProvider` / `WatchlistProvider` / `CoinDetailProvider`, và đăng ký chúng vào DI.

## Khuôn Repository

Mọi repository: nhận `ApiClient` qua constructor, trả `Result<T>`, không ném ngoại lệ, parser truyền vào `ApiClient.get`.

```dart
class MarketRepository {
  MarketRepository({required ApiClient apiClient}) : _api = apiClient;
  final ApiClient _api;

  Future<Result<List<CoinMarketModel>>> getMarkets({
    String vsCurrency = 'usd',
    int page = 1,
    List<String>? coinIds,
    ApiCancelToken? cancelToken,
  }) =>
      _api.get(
        ApiEndpoints.coinMarkets,
        query: {
          'vs_currency': vsCurrency,
          'order': 'market_cap_desc',
          'per_page': 100,
          'page': page,
          'price_change_percentage': '24h',
          if (coinIds != null && coinIds.isNotEmpty) 'ids': coinIds.join(','),
        },
        cancelToken: cancelToken,
        parser: Parsers.listOf(CoinMarketModel.fromJson),
      );

  /// /global trả {data: {...}} — bóc lớp `data` bằng parser riêng.
  Future<Result<GlobalStats>> getGlobalStats({ApiCancelToken? cancelToken}) =>
      _api.get(
        ApiEndpoints.global,
        cancelToken: cancelToken,
        parser: (json) => GlobalStats.fromJson(
          (json as Map)['data'] as Map<String, dynamic>,
        ),
      );
}
```

Quy tắc cache: endpoint nặng, không phân trang (`/coins/list`) → cache RAM + throttle giống `CoinRepository`. Endpoint phân trang (`/coins/markets`) → không cache, phân trang bằng `page`. Endpoint nhẹ (`/global`) → cache RAM ngắn + poll 60s ở provider.

## Khuôn Provider

Kế thừa `BaseViewModel`; `runInitial` cho trạng thái cả màn hình, `runAction` cho thao tác nền; giữ `ApiCancelToken` và huỷ ở `dispose`.

```dart
class MarketProvider extends BaseViewModel {
  MarketProvider({required MarketRepository repository}) : _repo = repository;
  final MarketRepository _repo;

  List<CoinMarketModel> _markets = const [];
  int _page = 1;
  String _vs = 'usd';
  ApiCancelToken? _cancelToken;

  List<CoinMarketModel> get markets => _markets;
  bool get hasMore => _markets.length % 100 == 0 && _markets.isNotEmpty;

  Future<void> init() async {
    if (isLoading || _markets.isNotEmpty) return;
    await load();
  }

  Future<void> load() async {
    _cancelToken?.cancel('reload');
    final token = ApiCancelToken();
    _cancelToken = token;
    _page = 1;
    await runInitial<List<CoinMarketModel>>(
      () => _repo.getMarkets(vsCurrency: _vs, page: 1, cancelToken: token),
      onData: (d) => _markets = List.unmodifiable(d),
      isEmpty: (d) => d.isEmpty,
      keepDataOnError: _markets.isNotEmpty,
    );
  }

  Future<void> loadMore() async {
    if (isBusy || !hasMore) return;
    final ok = await runAction(
      () => _repo.getMarkets(vsCurrency: _vs, page: _page + 1),
      onData: (d) {
        _page += 1;
        _markets = List.unmodifiable([..._markets, ...d]);
      },
    );
    if (!ok && failure != null) clearFailure(); // snackbar, không đổi màn hình
  }

  @override
  void dispose() {
    _cancelToken?.cancel('dispose');
    super.dispose();
  }
}
```

## Đăng ký DI

```dart
// service_locator.dart — repository là lazySingleton, provider là factory
sl.registerLazySingleton<MarketRepository>(
  () => MarketRepository(apiClient: sl()),
);
sl.registerFactory<MarketProvider>(() => MarketProvider(repository: sl()));
sl.registerFactory<GlobalProvider>(() => GlobalProvider(repository: sl()));
sl.registerFactory<WatchlistProvider>(
  () => WatchlistProvider(coinRepo: sl(), storage: sl()),
);

// app_providers.dart — phơi provider cho cây widget
ChangeNotifierProvider<MarketProvider>(create: (_) => sl<MarketProvider>()),
ChangeNotifierProvider<GlobalProvider>(create: (_) => sl<GlobalProvider>()),
```

Provider chỉ sống ở một màn hình thì bọc `ChangeNotifierProvider(create:)` trong `builder` của route đó thay vì đặt ở `app_providers.dart`.

## Ánh xạ tính năng MVP → screen → provider → repository → endpoint

| Tính năng | Screen | Provider | Repository | Endpoint | Model | Trạng thái |
|---|---|---|---|---|---|---|
| Danh sách token + tìm lọc | `home_screen.dart` + `token_list.dart` | `TokenListProvider` | `CoinRepository` | `/coins/list` | `TokenModel` | DONE |
| Gợi ý tìm kiếm | ô search trong `token_list.dart` | `SearchProvider` | `CoinRepository.getSearchSuggestions` | `/search` | `List<String>` | DONE |
| Tab 1 Theo dõi | `watchlist/watchlist_screen.dart` | `WatchlistProvider` (mới) | `CoinRepository` + `LocalStorage` | `/coins/markets?ids=` | `CoinMarketModel` | TODO |
| Tab 2 Chart Thị trường | `market/market_screen.dart` | `MarketProvider` | `MarketRepository.getMarkets` | `/coins/markets` | `CoinMarketModel` | DONE |
| Tab 3 Chỉ số toàn cầu | `globalStats/global_screen.dart` | `GlobalProvider` | `MarketRepository.getGlobalStats` | `/global`, `/coins/categories`, `/coins/markets` | `GlobalStats`, `CoinCategory` | DONE |
| Chi tiết coin | `coin/coin_detail.dart` | `CoinDetailProvider` (mới) | `CoinRepository` | `/coins/:id`, `/coins/:id/market_chart` | `CoinDetail`, `ChartPoint` | TODO |

## Quy ước bắt buộc

- Repository trả `Result<T>`; lỗi HTTP/parse thành `Failure`, không ném ra ngoài.
- Hằng endpoint chỉ khai báo trong `lib/core/network/api_endpoints.dart`.
- Provider không gọi `ApiClient` trực tiếp — luôn qua repository.
- Màn hình chỉ đọc `state`/`failure`/getter; mọi thay đổi đi qua phương thức provider.
- Huỷ `ApiCancelToken` ở `dispose` để tránh setState sau dispose.
- 429 (rate limit) → `FailureKind.rateLimited`; không auto-refresh dồn dập.
