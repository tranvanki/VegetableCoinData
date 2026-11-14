# Watchlist (tab "Theo dõi")

Screen: `lib/views/screens/watchlist/watchlist_screen.dart` (hiện là skeleton).
Provider: `WatchlistProvider` (mới). Nguồn: `CoinRepository` + `LocalStorage`
(không backend — danh bạ follow lưu cục bộ).
Khuôn dựng: xem `docs/architecture/repositories-providers.md`.

## Workflow
1. Người dùng bấm sao ở một hàng token (tab Home) → `WatchlistProvider.toggleFollow(id)`.
2. Danh bạ id follow lưu `LocalStorage` (khối `coingecko.watchlist`).
3. Tab Theo dõi mở → `WatchlistProvider.init()` đọc danh bạ → nếu rỗng → `empty`.
4. Không rỗng → `CoinRepository`/`MarketRepository.getMarkets(coinIds: ids)` lấy giá + 24h.
5. `runInitial` → `ready`; hiển thị danh sách theo thứ tự người dùng sắp xếp.
6. Kéo-thả đổi thứ tự → `reorder(...)` ghi lại `LocalStorage`.
7. Swipe trái / chế độ sửa → `remove(id)`; badge sao ở Home đồng bộ qua provider.

## Files
| File | Purpose |
|---|---|
| `lib/views/screens/watchlist/watchlist_screen.dart` | Skeleton tab 1; sẽ thành `ReorderableListView` danh sách follow. |
| `lib/providers/watchlist_provider.dart` | Danh bạ id, list `CoinMarketModel`, toggle/reorder/remove. |
| `lib/data/repository/coin_repository.dart` | Cung cấp token; cache RAM. |
| `lib/data/repository/market_repository.dart` | `getMarkets(coinIds:)` cho giá/24h của danh bạ. |
| `lib/core/storage/local_storage.dart` | Lưu `coingecko.watchlist` + thứ tự. |

## Functions (cần dựng)
| Symbol | Purpose | Logic |
|---|---|---|
| `WatchlistProvider.init()` | Nạp danh bạ | Đọc `LocalStorage`; rỗng → `empty`; không → `load()`. |
| `toggleFollow(id)` | Thêm/bỏ follow | Cập nhật set id; ghi storage; notify. |
| `load()` | Lấy giá | `runInitial(repo.getMarkets(coinIds: ids))`. |
| `reorder(from, to)` | Sắp xếp | Đổi thứ tự mảng; ghi storage; notify. |
| `remove(id)` | Xoá | Bỏ id; ghi storage; `load()` lại nếu cần. |

## Widgets / Syntax
- `ReorderableListView` + `onReorder`; handle kéo `ReorderableDragStartListener`.
- `Dismissible` cho swipe xoá.
- Tái dùng hàng token của `token_list.dart` + nút sao trạng thái.
- `EmptyView` mời quay lại tab Home bấm sao khi chưa follow gì.
