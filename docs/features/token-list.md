# Token List

## Workflow
1. `TokenList` mounts → post-frame calls `TokenListProvider.init()`.
2. `init()` skips when `_initialized` or already loading; otherwise `load()`.
3. `load()` → `runInitial` sets `ViewState.loading`.
4. `CoinRepository.getTokens()` → `ApiClient.get(ApiEndpoints.coinsList)` with `Parsers.listOf(TokenModel.fromJson)`.
5. `DioApiClient` calls `GET {baseUrl}/coins/list?include_platform=true`; HTTP/parse errors → `Failure`, never thrown.
6. `onData`: copy list, sort by `name`, store `_tokens`, recompute `_filtered`; `runInitial` settles on `ready` or `empty`.
7. Search field → `Debouncer(400ms)` → `setQuery()` → in-memory filter on `name | symbol | id` → `notifyListeners`.
8. Pull-to-refresh or refresh button → `refresh()` → `load(isRefresh: true)`; `CoinRepository` trả cache RAM nếu bản cache chưa quá 60s (chặn refresh dồn dập), quá thì mới gọi lại `/coins/list`; failure → snackbar via `context.showFailure`.
9. Row tap → `onTokenTap(token)`; parent screen decides the route.
10. Screen dispose → `CancelToken.cancel('dispose')`.

## Files
| File | Purpose |
|---|---|
| `lib/data/model/crypto/token_model.dart` | DTO: `id`, `symbol`, `name`, `platforms`; `fromJson`, `toJson`. |
| `lib/data/repository/coin_repository.dart` | Wraps `/coins/list`; RAM cache + 60s refetch throttle; returns `Result<List<TokenModel>>`. |
| `lib/providers/base_view_model.dart` | `ViewState`, `runInitial`, `runAction`, `safeNotify`, `failure`. |
| `lib/providers/token_list_provider.dart` | Owns list, filtered list, query, load/refresh/init. |
| `lib/views/screens/token_list.dart` | Header, search, list, loading/error/empty states. |
| `lib/views/widgets/state/state_views.dart` | `LoadingView`, `ErrorView`, `EmptyView`, `ShimmerBox`. |
| `lib/views/widgets/common/app_widget.dart` | `AppWidget`: Material card + InkWell + border. |
| `lib/core/utils/debouncer.dart` | `Debouncer`: cancels pending filter on each keystroke. |
| `lib/core/utils/formatters.dart` | `Formatters.number` for the count badge. |

## Functions
| Symbol | Purpose | Logic |
|---|---|---|
| `TokenListProvider.init()` | First load | `_initialized || isLoading` → return; else `load()`. |
| `load()` | Whole-screen state | `runInitial(repo.getTokens)`, `isEmpty = data.isEmpty`. |
| `refresh()` | Background refresh | `runAction`; `onData: _setTokens`; `ViewState` unchanged. |
| `setQuery(String)` | Filter | trim + lowercase; same value → return; rebuild `_filtered`; notify. |
| `_setTokens(List)` | Normalize | copy, sort `name`, assign `_tokens`, recompute `_filtered`. |
| `_applyQuery()` | Filter predicate | `contains` on lowercased `name`, `symbol`, `id`. |
| `dispose()` | Cancel in-flight | `cancelToken.cancel('dispose')`, then `super.dispose()`. |
| `_TokenListState._refresh()` | Refresh + report | `await vm.refresh()`; show + clear `failure`. |

## Wiring
```dart
// service_locator.dart
sl.registerLazySingleton<CoinRepository>(
  () => CoinRepository(apiClient: sl<ApiClient>()),
);
sl.registerFactory<TokenListProvider>(
  () => TokenListProvider(repository: sl()),
);

// app_providers.dart
ChangeNotifierProvider<TokenListProvider>(create: (_) => sl<TokenListProvider>()),

// router branch
GoRoute(path: AppRoutes.tokenList, builder: (_, __) => const TokenList()),
```

## Widgets / Syntax
- `StatefulWidget` + `WidgetsBinding.instance.addPostFrameCallback` for first provider call.
- `context.watch<T>()` (rebuild) vs `context.read<T>()` (one-shot).
- `TextField` + `TextEditingController`; `onChanged` → debounce; `onSubmitted` → flush.
- `InputDecoration(prefixIcon:, suffixIcon:)`.
- `RefreshIndicator` + `ListView.separated` + `AlwaysScrollableScrollPhysics`.
- `Column` + `Expanded`; `Row` + `Spacer`.
- Exhaustive `switch` on `ViewState`.
- `Container` + `BoxDecoration(shape: BoxShape.circle)` for the symbol avatar.
- `context.textStyles`, `context.isDarkMode`, `context.showFailure` from `ContextX`.
