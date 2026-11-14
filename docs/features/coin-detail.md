# Coin Detail

## Workflow
1. Route `/coin/:id` → screen receives `id` → `CoinDetailProvider.init(id)`.
2. VM loads detail and chart in parallel:
   - `GET /coins/{id}?localization=false&tickers=false&community_data=false`.
   - `GET /coins/{id}/market_chart?vs_currency=usd&days={range}`.
3. Each call returns `Result`; failure on chart does not block detail (partial `ready`).
4. `onData` maps JSON → `CoinDetail` / `List<ChartPoint>`; `runInitial` sets state.
5. Range chip (1D / 7D / 30D / 1Y) → `setRange(days)` → refetch chart only.
6. Share button → `ShareService.shareCoin(...)`.
7. On open → `LocalStorage.saveRecentViewedToken(token.toJson())` for the Home list.
8. Pull-to-refresh → reload detail + current chart range.

## Files
| File | Purpose |
|---|---|
| `lib/data/model/crypto/coin_detail.dart` | **Planned.** Description, links, ATH/ATL, supply, image. |
| `lib/data/model/crypto/market_chart.dart` | **Planned.** `ChartPoint(time, price)` + `listFromJson`. |
| `lib/data/repository/coin_repository.dart` | Add `getCoinDetail(id)` and `getMarketChart(id, days)` here. |
| `lib/providers/coin_detail_provider.dart` | **Planned.** Detail + chart + range + state. |
| `lib/views/screens/coin_detail.dart` | **Empty.** Scrollable detail layout. |
| `lib/views/widgets/market_chart.dart` | **Empty.** Chart painter + range chips. |
| `lib/services/shared_service.dart` | `ShareService.shareCoin`, `openExternal`, `openBlockExplorer`. |
| `lib/core/storage/local_storage.dart` | `saveRecentViewedToken`, `getRecentViewedTokensRaw`. |
| `lib/app/router/app_routes.dart` | Add `coinDetail = '/coin'` + `coinDetailPath(id)`. |

## Functions (planned)
| Symbol | Purpose | Logic |
|---|---|---|
| `CoinRepository.getCoinDetail(id)` | Detail | `_api.get('/coins/$id', parser: Parsers.objectOf(CoinDetail.fromJson))`. |
| `CoinRepository.getMarketChart(id, days)` | Chart | Query `vs_currency=usd&days=$days`; parser maps `prices`. |
| `CoinDetailProvider.init(id)` | First load | `Future.wait` detail + default range; `runInitial` on detail. |
| `setRange(days)` | Chart range | Skip same range; `runAction`; replace `_points`. |
| `retryChart()` | Partial failure | Refetch chart only; keep detail. |

## Widgets / Syntax
- `CustomScrollView` + `SliverAppBar` (`expandedHeight`, `FlexibleSpaceBar`).
- `CustomPaint` + `CustomPainter` for the line chart (no chart dependency in `pubspec.yaml`).
- `GestureDetector` / `onHorizontalDragUpdate` + `ValueNotifier<int?>` for crosshair.
- `Wrap` of `ChoiceChip` for ranges.
- `SelectableText` for contract address; `Clipboard.setData`.
- `IconButton(Icons.share_rounded)`; `Icons.open_in_new`.
- Price/percent color: `AppColors.success` / `AppColors.error` by sign.
- `Formatters.price`, `Formatters.compact`, `Formatters.dateTime`.
