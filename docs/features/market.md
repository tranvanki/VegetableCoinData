# Market (tab "Chart Thị trường")

Screen: `lib/views/screens/market/market_screen.dart` (đã dựng: thẻ toàn cầu, chip Tất cả/Xu thế, bảng sắp xếp được, phân trang).
Repository: `lib/data/repository/market_repository.dart` (`getMarkets`, `getGlobalStats`, `getTrendingCoinIds`, `getCategories`).
Provider: `lib/providers/market_provider.dart` (`MarketProvider`).
Khuôn dựng: xem `docs/architecture/repositories-providers.md`.

## Workflow
1. Screen mở → `MarketProvider.init()` → `runInitial` → loading; song song `_loadGlobal` nạp `/global` (lỗi thì thẻ hiện `—`, không đổi trạng thái màn hình).
2. `MarketRepository.getMarkets(vsCurrency, page, perPage, sparkline, coinIds)` dựng query.
3. `ApiClient.get(ApiEndpoints.coinMarkets)` với `Parsers.listOf(CoinMarketModel.fromJson)`.
4. `GET /coins/markets?vs_currency=usd&order=market_cap_desc&per_page=100&page=1&price_change_percentage=24h`.
5. VM giữ trang trong RAM; `ready | empty | error`.
6. Sort cục bộ (hạng, giá, 24h, vốn hoá) — không gọi lại mạng; bấm lại cột để đảo chiều.
7. Cuộn cách đáy < 400px → `loadMore()`; chặn bằng `isBusy` + `hasMore`. Lỗi → `loadMoreFailed` + nút "Thử lại" (không tự gọi lại, tránh dồn request khi 429).
8. Pull-to-refresh → `refresh()` giữ hàng cũ tới khi có response.
9. Chip "Xu thế" → `getTrendingCoinIds()` rồi `getMarkets(coinIds:)`; không phân trang.
10. HTTP 429 → `FailureKind.rateLimited`.

## Bước sau
- Chạm hàng → chi tiết coin (`/coins/:id`, chưa có route/`CoinDetail`).
- Chip "Trên chuỗi" (`/onchain/networks/trending_pools`, dữ liệu là pool).
- Sparkline trong thẻ thống kê + thẻ "Tóm tắt": không có nguồn trong `all_api_formatted.md`.
- Đổi tiền tệ hiển thị (USD/BTC/VND), lọc nâng cao.

## Files
| File | Purpose |
|---|---|
| `lib/data/model/crypto/coin_market.dart` | DTO `CoinMarketModel`: id, symbol, giá, vốn hoá, hạng, biến động 24h và sparkline. |
| `lib/data/repository/market_repository.dart` | `getMarkets`, `getGlobalStats` (cache 60s), `getTrendingCoinIds`, `getCategories`. |
| `lib/core/network/api_endpoints.dart` | `coinMarkets`, `global`, `trending`. |
| `lib/providers/market_provider.dart` | Page, list, filter, sort, load/refresh/loadMore. |
| `lib/views/screens/market/market_screen.dart` | Tab 1: thẻ toàn cầu + chip + bảng. |
| `lib/views/widgets/state/state_views.dart` | Loading, error, empty. |

## Functions
| Symbol | Purpose | Logic |
|---|---|---|
| `MarketRepository.getMarkets()` | Fetch page | Dựng query; `_api.get(..., parser: Parsers.listOf(CoinMarketModel.fromJson))`. |
| `MarketProvider.init()` | Nạp lần đầu | `load()` một lần. |
| `setFilter(MarketFilter)` | Tất cả / Xu thế | Xoá bảng cũ, `load()`. |
| `setSort(MarketSort)` | Sắp xếp | Sort bản sao cục bộ; cột mới: hạng tăng dần, còn lại giảm dần; thiếu dữ liệu xuống cuối. |
| `loadMore()` / `retryLoadMore()` | Phân trang | `page+1`; dừng khi trang ngắn hơn `pageSize`; lỗi thì chờ thử lại. |
| `refresh()` | Pull-to-refresh | `runAction`; giữ bảng cũ khi lỗi. |

## Widgets / Syntax
- `CustomScrollView` + `SliverList.separated`; `NotificationListener<ScrollNotification>` để nạp thêm.
- `ChoiceChip` cho bộ lọc; tiêu đề cột là `InkWell` để sắp xếp.
- `FittedBox(scaleDown)` cho ô số để không tràn khi chữ lớn.
- Màu theo dấu: `PriceChange` (mũi tên + màu `AppColors.success`/`error`).
