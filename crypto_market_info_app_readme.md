# Kiến trúc Đích Binance Trading-Ready (Chuẩn HHM.MobileApp)

Giữ nguyên cấu trúc tầng chuẩn của **HHM.MobileApp** (`app/`, `core/`, `data/`, `providers/`, `services/`, `views/`, `i18n/`) — không tách lại sang `features/` — để nhất quán với nền tảng sẵn có và tối giản chi phí bảo trì.

---

## 1. Đối chiếu HHM.MobileApp vs. Coin App hiện tại

| Thành phần | Chuẩn HHM.MobileApp | Hiện trạng Coin App | Chốt kiến trúc mới |
|---|---|---|---|
| **Bootstrap & Session** | `AppBootstrap` dựng DI + khôi phục phiên trước `runApp` | Chưa có `AuthProvider` / `restoreSession` | Thêm `AuthProvider.restoreSession()` trước `runApp` |
| **Môi trường (`env/`)** | `env/{flavor}.json` gitignored, `USE_MOCK_API=true` | `env/dev.json` nằm trong `pubspec.yaml` assets; chưa gitignore | Gỡ khỏi assets, gitignore `env/*.json`; khôi phục `USE_MOCK_API` + thêm `USE_DEMO_TRADING`, `ENABLE_LIVE_TRADING` |
| **Storage bảo mật** | `LocalStorage`, `SecureStorage`, `TokenStorage` | Thiếu `SecureStorage` & `TokenStorage` | Bổ sung `core/storage/secure_storage.dart` & `token_storage.dart` (`flutter_secure_storage`) |
| **Network & Mock** | `ApiClient`, `DioApiClient`, `AuthInterceptor`, `data/sources/mock/` (`MockApiClient`, `MockFixtures`) | Chỉ 1 `ApiClient`; `AuthInterceptor` chưa gắn; `BinanceMarketRepositoryImpl` tự tạo `Dio()` | Tách `publicApiClient` (CoinGecko/Binance public) + `authApiClient` (`AuthInterceptor` / `MockApiClient` khi `USE_MOCK_API=true`); gom URL về `ApiEndpoints` |
| **Offline-First Sync** | Dự kiến tương lai | Đã có SQLite `binance_market.db` + WS auto-reconnect | Giữ `binance_market.db` cho market; thêm `paper_trading.db` (`demo_accounts`, `demo_positions`, `demo_orders`) |
| **Router 5 Tab & Guard** | `app_routes.dart` (`requiresAuth()`) + `app_router.dart` 5 tab | `MainShell` 5 tab nhưng `AppRouter` 4 nhánh; chưa có `requiresAuth()`; trùng route `/watchlist-select` | Đủ 5 nhánh: `home`, `watchlist`, `market`, `global`, `profile`; thêm `requiresAuth()` & `requiredPermission()` |
| **Repository** | 1 repo / phân hệ | Trùng `/coins/markets` giữa `CoinRepository` & `MarketRepository`; `trading_repository.dart` trống | Chuẩn hóa 5 repo: `BinanceMarketRepository`, `CoinGeckoRepository` (gộp), `AuthRepository`, `TradingRepository`, `SystemRepository` |
| **Quy tắc View** | View không tự tính tiền / không gọi API | `showPaperOrder` tự tính & chỉ bắn SnackBar | `TradingProvider` + `TradingRepository` (`DemoTradingRepository` trước → BFF sau) xử lý preview, số dư, `clientOrderId`, ghi SQLite |

---

## 2. Luồng Dữ liệu & Ranh giới An toàn

```text
View (views/screens/*)
  │ watch / read
  ▼
Provider (providers/* extends BaseViewModel)
  │
  ├── Public Market: BinanceMarketRepository (SQLite + Binance REST/WS + CoinGecko metadata)
  │                  CoinGeckoRepository     (publicApiClient — KHÔNG gắn AuthInterceptor)
  │
  ├── AuthN / AuthZ: AuthRepository          (MockAuthRepository / MockApiClient trước → BFF/OIDC sau)
  │                  TokenStorage            (SecureStorage / flutter_secure_storage)
  │                  AuthorizationPolicy     (guest | demoTrader | verifiedTrader)
  │
  └── Trading:       TradingRepository       (DemoTradingRepository + paper_trading.db trước)
                                             (LiveTradingRepository + authApiClient sau — khóa 4 lớp)
```

### Quy ước bắt buộc
1. **Không `throw` qua Repository:** Mọi repo trả `Result<T>` (`Ok` / `Err(Failure)`).
2. **Không bao giờ gắn `AuthInterceptor` vào client gọi CoinGecko/Binance public.**
3. **AuthZ 2 lớp:** Kiểm tra quyền cả ở `GoRouter.redirect` (`requiresAuth()`) và ở `TradingProvider`/`TradingRepository`.
4. **Live Trading khóa 4 lớp:** `ENABLE_LIVE_TRADING=true` + `RemoteConfig.isEnabled('live_trading')` + `UserRole.verifiedTrader` (`tradeLive`) + xác nhận lệnh kèm `clientOrderId`.
5. **Không đóng vĩnh viễn Singleton từ Factory:** `BinanceMarketViewModel.dispose()` chỉ hủy stream subscription của chính nó, không đóng DB/`StreamController` của singleton `BinanceMarketRepository`.

---

## 3. Kế hoạch Refactor theo Mốc Nhỏ

| Mốc | Công việc chính | Lợi ích | Rủi ro | Bảo toàn hành vi |
|---|---|---|---|---|
| **Mốc 1: Sửa lỗi WIP & bảo mật `env/`** | Sửa import `WatchlistSelect` + xóa route trùng ở `app_router.dart`; nối nhánh 5 `Profile`; sửa `BinanceCoin.copyWithTicker` không xóa `name`; sửa merge CoinGecko trong `BinanceMarketRepositoryImpl` (`continue` + `updated.add`); sửa `WatchlistScreen.initState` → `WatchListProvider.init()`; gỡ `env/dev.json` khỏi `pubspec.yaml` & gitignore `env/*.json` | Hết lỗi compile/crash, hiện đúng logo/tên coin, Watchlist hoạt động, không đóng gói env vào app | Thấp | `flutter analyze` + `flutter test` + test mới cho `copyWithTicker` & merge metadata |
| **Mốc 2: Chuẩn hóa dữ liệu thị trường** | Sửa `TokenListProvider` (bỏ `dynamic`, bỏ polling ghi đè kiểu, hủy `Timer`); gộp `CoinRepository` + `MarketRepository`; đưa URL Binance vào `ApiEndpoints`; chuẩn `USDT` trên Binance Home; nối `AppImageCacheManager` vào `CoinLogo` | Hết crash `TypeError` sau 20s, hết rò rỉ timer, 1 nguồn CoinGecko duy nhất | Trung bình | Cập nhật DI & fakes trong `test/support/`, chạy toàn bộ test |
| **Mốc 3: AuthN / AuthZ Mock** | Hoàn thiện `SecureStorage`, `TokenStorage`, `MockApiClient`, `MockFixtures`, `AuthRepository`, `AuthProvider`, `LoginScreen`, `ProfileScreen`; tách `publicApiClient` vs `authApiClient` (`AuthInterceptor`); thêm `requiresAuth()` vào `AppRoutes` & `AppRouter` | Có đăng nhập/đăng xuất/đổi role mock (`guest` / `demoTrader` / `verifiedTrader`) & route guard sẵn sàng cho BFF/OIDC | Trung bình | `guest` vẫn xem đầy đủ 4 tab thị trường; chỉ chặn giao dịch/lịch sử lệnh; viết unit test AuthZ |
| **Mốc 4: Safe Demo / Paper Trading** | Hoàn thiện `TradingModels`, `PaperTradingLocalDataSource` (`paper_trading.db`), `TradingRepository` + `DemoTradingRepository`, `TradingProvider`, `OrderHistoryScreen`; nối `CoinDetail` (truyền đủ `change24h`, `volume`) + `showPaperOrder` vào `TradingProvider` với xác nhận `DEMO` & `clientOrderId` | Đặt lệnh ảo có số dư, vị thế, lịch sử lệnh lưu SQLite nguyên tử; không gửi lệnh thật | Trung bình | Test transaction mua/bán, thiếu số dư, trùng `clientOrderId`, guest bị chặn, live mode luôn khóa |
| **Mốc 5: Dọn mã thừa HHM cũ** | Xóa file trùng/chết (`device_id_service.dart`, `state_view.dart`, `service_repository.dart`, `crypto_price.dart`, `home_screen.dart`, `search.dart`, route e-commerce thừa, package thừa trong `pubspec.yaml`) | Codebase sạch, giảm kích thước build | Thấp | Xác minh bằng `flutter analyze` + `flutter test` sau khi dọn |
| **Mốc 6: Cắm BFF / Live Ready** | Đổi `USE_MOCK_API=false` cho `authApiClient`, nối `OidcAuthService` / `RemoteAuthRepository` và `LiveTradingRepository` (qua BFF, không giữ secret sàn trên app) + kiểm thử tích hợp `flutter_driver` | Chuyển mock → thật chỉ qua DI & config, không sửa UI/Provider | Cao (cần audit BFF) | Giữ `ENABLE_LIVE_TRADING=false` cho tới khi qua kiểm thử E2E & bảo mật |
