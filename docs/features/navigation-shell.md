# Navigation Shell

## Workflow
1. `GoRouter` root → `initialLocation: AppRoutes.home`.
2. `StatefulShellRoute.indexedStack` builds `MainShell` with `StatefulNavigationShell`.
3. Bốn branch, mỗi branch giữ `Navigator` riêng; đổi tab giữ nguyên scroll/state.
4. `BottomNavigationBar.onTap` → `navigationShell.goBranch(index, initialLocation: index == currentIndex)`.
5. `MainShell` đọc `AppStateProvider.isOnline`; offline → `OfflineBanner` trên nội dung branch.
6. Route sâu (`/coin/:id`, `/search`) đẩy lên root navigator → che bottom bar.
7. Bấm lại tab đang mở → `initialLocation: true` pop về gốc branch.
8. Redirect (`maintenance`, onboarding) chạy trước khi shell dựng.

## Bốn tab (thứ tự PHẢI khớp `branches`)

| # | Nhãn bottom nav | Route | Screen | Trạng thái |
|---|---|---|---|---|
| 0 | Trang chủ | `AppRoutes.home` | `home_screen.dart` → `TokenList` | DONE |
| 1 | Theo dõi | `AppRoutes.watchlist` | `watchlist/watchlist_screen.dart` | Skeleton |
| 2 | Chart Thị trường | `AppRoutes.market` | `market/market_screen.dart` | Skeleton |
| 3 | Chỉ số toàn cầu | `AppRoutes.global` | `globalStats/global_screen.dart` | Skeleton |

Screen skeleton hiện `EmptyView` giữ chỗ; danh mục tính năng chi tiết nằm trong doc-comment đầu mỗi file screen.

## Files
| File | Purpose |
|---|---|
| `lib/views/screens/main/main_shell.dart` | `Scaffold` + `BottomNavigationBar` 4 mục + offline banner + `PlaceholderScreen`. |
| `lib/app/router/app_router.dart` | `GoRouter`, `StatefulShellRoute`, 4 branch, redirect. |
| `lib/app/router/app_routes.dart` | Hằng path tab (`home`, `watchlist`, `market`, `global`) + path builder. |
| `lib/providers/app_state_provider.dart` | `isOnline` cho banner; theme/locale/config. |
| `lib/views/widgets/state/state_views.dart` | `OfflineBanner`, `EmptyView`, `ShimmerBox`. |

## Functions
| Symbol | Purpose | Logic |
|---|---|---|
| `MainShell._onTap(context, index)` | Đổi tab | `goBranch`; trùng index → `initialLocation: true` pop về gốc. |
| `AppRouter.create(...)` | Router factory | `refreshListenable: Listenable.merge([appState])`; đăng ký 4 branch; `navigation.attach(router)`. |
| `redirect(context, state)` | Guards | Maintenance → `/maintenance`; onboarding một lần. |
| `PlaceholderScreen` | Route lỗi / chưa dựng | `AppBar` + `EmptyView(construction)`; dùng làm `errorBuilder`. |

## Rules
- `BottomNavigationBar.items.length` == `StatefulShellRoute.branches.length`; lệch là `currentIndex` out of range → crash khi bấm tab.
- Thêm tab = thêm 1 `StatefulShellBranch` + 1 item, cùng thứ tự, và 1 hằng trong `AppRoutes`.
- Screen mới đặt trong thư mục con theo feature (`watchlist/`, `market/`, `globalStats/`, `coin/`); import router trỏ đúng đường dẫn đó.
- Route sâu đặt NGOÀI shell để che bottom bar.
- Không hardcode path trong screen; dùng `AppRoutes`.

## Widgets / Syntax
- `StatefulShellRoute.indexedStack(builder:, branches:)`.
- `StatefulNavigationShell` (`currentIndex`, `goBranch`).
- `StatefulShellBranch(navigatorKey:, routes:)`.
- `Scaffold(body:, bottomNavigationBar:)`; `Column` + `Expanded(child: navigationShell)` để chồng banner.
- `context.watch<AppStateProvider>()` cho banner reactive.
