# Search

## Workflow
1. Search screen opens → `SearchProvider.init()` → reads recent queries from `LocalStorage`.
2. User types → `Debouncer(400ms)` → `search(query)` cancels the previous request via `CancelToken`.
3. Empty query → show recent searches + trending; no API call.
4. Query non-empty → `GET /search?query={q}`.
5. Response maps `coins[]` → `TokenSearchResult(id, name, symbol, thumb, marketCapRank)`.
6. `runAction` (not `runInitial`): keep the field and old results; `isBusy` drives the inline spinner.
7. Submit or tap a result → save query to recent list → route `/coin/:id`.
8. Rate limit (429) → `FailureKind.rateLimited`; show `ErrorView(compact)` with retry.
9. Clearing the field cancels in-flight request and restores recents.

## Files
| File | Purpose |
|---|---|
| `lib/views/widgets/search.dart` | **Empty.** Search field, recents, results. |
| `lib/providers/search_provider.dart` | **Missing** (imported by `app_providers.dart`). Query, results, recents, state. |
| `lib/core/utils/debouncer.dart` | `Debouncer.run`, `flush`, `cancel`. |
| `lib/core/network/api_endpoints.dart` | `search = '/search'`; gợi ý dùng cùng endpoint với `?query={q}`. |
| `lib/data/model/crypto/token_search_result.dart` | **Planned.** Result DTO. |
| `lib/core/storage/local_storage.dart` | Recent list via `getStringList` / `setStringList`. |
| `lib/views/widgets/state/state_view.dart` | `EmptyView`, `ErrorView(compact)`, `LoadingView`. |

## Functions (planned)
| Symbol | Purpose | Logic |
|---|---|---|
| `SearchProvider.search(String)` | Query | Trim; empty → cancel + clear; else cancel old token, new `CancelToken`, `runAction`. |
| `_onQueryChanged(String)` | Field event | Update `_query`; debounce in the view, not the VM. |
| `addRecent(String)` | Persist | Deduplicate, insert at 0, cap 10, `setStringList`. |
| `clearRecent()` | Reset | `remove(key)`, notify. |
| `selectResult(TokenSearchResult)` | Navigate | Save recent; return result to the view. |
| `dispose()` | Cleanup | Cancel token, debouncer owned by view. |

## Widgets / Syntax
- `TextField` + `FocusNode(autofocus: true)`; `TextInputAction.search`.
- `Debouncer(AppConstants.searchDebounce)`.
- `ListView.builder` for results; `ListTile` with `AppNetworkImage(radius: AppRadius.pill)`.
- `Wrap` of `ActionChip` for recent/trending queries.
- `Stack` with a linear `LinearProgressIndicator` while `isBusy`.
- `AnimatedSwitcher` between recents / results / empty.
- `context.showFailure` for snackbar errors.
