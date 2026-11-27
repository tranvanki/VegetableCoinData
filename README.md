# Crypto Market & Trading-Ready App (Binance + CoinGecko)

Ứng dụng Flutter theo dõi thị trường tiền mã hóa (Binance Spot real-time + CoinGecko metadata/overview) theo khung kiến trúc chuẩn của **HHM.MobileApp** (**MVVM + Provider + `get_it` + `go_router` + `Result<T>`**), mở rộng cho:
- **Offline-first sync** (SQLite + WebSocket auto-reconnect).
- **Safe Demo / Paper Trading trước** (`USE_DEMO_TRADING=true`, khóa mặc định giao dịch thật).
- **AuthN / AuthZ Mock trước** (`USE_MOCK_API=true`, sẵn sàng cắm BFF / OIDC).

> **View chỉ hiển thị – Provider điều phối – Repository gọi API/SQLite – Model giữ dữ liệu.**

---

## 1. Cấu trúc thư mục (Chuẩn HHM, không tách `features/`)

```text
lib/
├─ main.dart                        # chỉ gọi AppBootstrap.run()
├─ app.dart                         # GeckoApp (MaterialApp.router + theme + i18n)
├─ app/
│  ├─ app_boostrap.dart             # runZonedGuarded, DI, restoreSession, crash handler
│  ├─ di/
│  │  ├─ service_locator.dart       # get_it: publicApiClient, authApiClient, repos, VMs
│  │  └─ app_providers.dart         # MultiProvider (AppState, Auth, Trading, 5 tabs)
│  ├─ router/
│  │  ├─ app_routes.dart            # path constants + requiresAuth() + requiredPermission()
│  │  └─ app_router.dart            # go_router, shell 5 tab, AuthN/AuthZ redirect guard
│  └─ theme/                        # màu, khoảng cách, ThemeData sáng/tối
├─ core/
│  ├─ config/                       # AppConfig, AppFlavor, AppConstants
│  ├─ error/                        # Failure, FailureKind, ErrorMapper
│  ├─ network/                      # ApiClient, DioApiClient, interceptors, ApiEndpoints
│  ├─ result/                       # Result<T> (Ok/Err)
│  ├─ storage/                      # LocalStorage, SecureStorage, TokenStorage, ImageCache
│  └─ utils/                        # logger, formatters, validators, json_x, debouncer, jwt
├─ data/
│  ├─ datasource/                   # SQLite: binance_market.db & paper_trading.db
│  ├─ sources/mock/                 # MockApiClient + MockFixtures (Auth & Demo Trading)
│  ├─ model/                        # binance, crypto, auth, trading, system
│  └─ repository/                   # binance_market, coingecko/market, auth, trading, system
├─ providers/                       # BaseViewModel + Auth, Trading, BinanceMarket, Market, Global, Watchlist
├─ services/                        # analytics, crash, deep_link, device_info, navigation, share, update
├─ views/
│  ├─ screens/                      # auth, binance_home, coin, watchlist, market, globalStats, trading, profile, settings, onBoarding, main
│  └─ widgets/                      # coin_logo, price_change, sparkline, state_views, coin/show_order, market/market_overview, watchlist/watchlist_select
└─ i18n/                            # vi_VN.json, en_US.json
```

---

## 2. Nguyên tắc An toàn Giao dịch & Bảo mật

1. **Mock / Demo mặc định:** `USE_MOCK_API=true`, `USE_DEMO_TRADING=true`, `ENABLE_LIVE_TRADING=false`. Mọi màn giao dịch gắn nhãn `DEMO / PAPER`.
2. **Không giữ secret sàn trong client:** Không đưa `env/*.json` vào `pubspec.yaml` assets và phải gitignore `env/*.json` (chỉ commit `*.example.json`). Giao dịch thật sau này chỉ đi qua **Trading BFF** đã xác thực.
3. **Tách 2 HTTP Client:** `publicApiClient` (CoinGecko & Binance public — **không** gắn `AuthInterceptor`) và `authApiClient` (Auth & Trading BFF — gắn `AuthInterceptor` + `TokenStorage`).
4. **View không tự chốt lệnh:** Mọi kiểm tra quyền (`guest` / `demoTrader` / `verifiedTrader`), kiểm tra số dư, giá stale, chống gửi trùng (`clientOrderId`) nằm ở `TradingProvider` / `TradingRepository`.
5. **Khóa kép Live Trading:** Chỉ mở khi đồng thời có `ENABLE_LIVE_TRADING=true` + `RemoteConfig.isEnabled('live_trading')` + quyền `tradeLive` + xác nhận 2 bước.

---

## 3. Biến môi trường (`--dart-define-from-file`)

Chỉ liệt kê **tên biến** (giá trị thật nằm ở `env/{flavor}.json`, không commit):
`FLAVOR`, `API_BASE_URL`, `TRADING_API_BASE_URL`, `WEB_BASE_URL`, `CDN_BASE_URL`, `API_TIMEOUT_SECONDS`, `USE_MOCK_API`, `USE_DEMO_TRADING`, `ENABLE_LIVE_TRADING`, `ENABLE_LOGGING`, `SENTRY_DSN`, `DEFAULT_LOCALE`.

```powershell
flutter pub get
flutter run --dart-define-from-file=env/dev.json
flutter analyze
flutter test
```

## 4. Tài liệu

- [Kiến trúc Chi tiết & Kế hoạch Refactor](crypto_market_info_app_readme.md)
- [Sơ đồ Hệ thống (As-Is & Target)](project_diagrams.md)
- [Hợp đồng Binance Spot Market Data](all_api_formatted.md)
- [Ghi chú Binance WebSocket API](binance_plan.md)
