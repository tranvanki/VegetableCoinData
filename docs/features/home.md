# Home

## Workflow
1. `HomeScreen` builds → reads `AppStateProvider` (online, config) and `HomeProvider`.
2. `HomeProvider.init()` → `runInitial` loading.
3. Parallel fetch: global snapshot + top markets + recently viewed (local) + trending search.
4. Sections render independently: one failure shows an inline `ErrorView(compact: true)`; the rest still render.
5. Recent viewed read from `LocalStorage.getRecentViewedTokensRaw()` — no network.
6. Tap a coin → `/coin/:id`; tap "Xem tất cả" → token list / market route.
7. Pull-to-refresh → `refresh()` → `runAction`; keeps old sections while reloading.
8. Offline banner comes from `MainShell` via `AppStateProvider.isOnline` — Home does not own it.

## Files
| File | Purpose |
|---|---|
| `lib/views/screens/home_screen.dart` | **Empty.** Section composition. |
| `lib/providers/home_provider.dart` | **Missing.** Aggregate state for the sections. |
| `lib/data/repository/market_repository.dart` | `getMarkets()` for top coins (TODO). |
| `lib/data/repository/system_repository.dart` | Config/global calls. |
| `lib/core/storage/local_storage.dart` | `getRecentViewedTokensRaw()`, `saveRecentViewedToken()`. |
| `lib/views/widgets/common/app_widget.dart` | `SectionHeader`, `AppNetworkImage`, `AppWidget`. |
| `lib/views/widgets/state/state_view.dart` | `LoadingView`, `ErrorView(compact)`, `EmptyView`, `OfflineBanner`. |
| `lib/providers/app_state_provider.dart` | Connectivity, theme, remote config. |

## Functions (planned)
| Symbol | Purpose | Logic |
|---|---|---|
| `HomeProvider.init()` | First load | `Future.wait` global + markets; recent viewed is sync. |
| `HomeProvider.refresh()` | Reload | `runAction`; replace sections on success. |
| `HomeProvider._loadRecent()` | Local list | Map raw JSON → `TokenModel`; cap 12. |
| `HomeScreen._openCoin(TokenModel)` | Navigate | `context.push('/coin/${token.id}')`. |
| `HomeScreen._buildSections()` | Layout | One `SliverList` per section; skip empty sections. |

## Widgets / Syntax
- `CustomScrollView` + `SliverToBoxAdapter` / `SliverList`.
- `SectionHeader(title, subtitle, onMore)` for each block.
- `GridView`/`SizedBox` horizontal `ListView` for top coins.
- Pull-to-refresh via `RefreshIndicator`.
- `context.watch<AppStateProvider>()` for the offline state.
- `context.push` from `go_router`.
- `Formatters.compact` / `Formatters.number`.
