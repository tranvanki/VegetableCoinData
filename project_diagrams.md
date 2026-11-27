# Sơ đồ Dự án (Chuẩn HHM · Binance Trading-Ready)

Tách rõ **Phần 1: Hiện trạng mã nguồn** và **Phần 2: Kiến trúc Đích (Safe Demo Mock First + AuthN/AuthZ Mock trên cấu trúc tầng HHM)**.

---

## Phần 1: Hiện trạng (As-Is)

```mermaid
flowchart LR
    user["Người dùng"]
    binance["Binance REST + WS Stream"]
    coingecko["CoinGecko REST API"]
    local[("SQLite binance_coins + SharedPreferences")]

    subgraph app["Ứng dụng Flutter (Hiện trạng)"]
        home(("Tab 0: BinanceHomeScreen"))
        detail(("CoinDetail + showPaperOrder tạm"))
        watchlist(("Tab 1: WatchlistScreen"))
        market(("Tab 2: MarketScreen"))
        global(("Tab 3: GlobalScreen"))
    end

    user --> home
    user --> detail
    user --> watchlist
    user --> market
    user --> global

    home --> binance
    home --> local
    home -. "metadata (WIP)" .-> coingecko
    watchlist --> coingecko
    watchlist --> local
    market --> coingecko
    global --> coingecko
```

---

## Phần 2: Kiến trúc Đích (HHM Layer-First · Trading-Ready)

### 2.1 Trust Boundary & Use Case

```mermaid
flowchart LR
    guest["Guest"]
    demo["Demo Trader (Mock Auth)"]
    verified["Verified Trader (Future Live)"]

    subgraph publicZone["PublicApiClient (Không AuthInterceptor)"]
        binance["Binance Spot REST + WS"]
        coingecko["CoinGecko REST"]
    end

    subgraph localZone["Lưu trữ cục bộ thiết bị"]
        secure[("SecureStorage + TokenStorage")]
        marketDb[("SQLite: binance_market.db")]
        demoDb[("SQLite: paper_trading.db")]
        prefs[("LocalStorage / SharedPreferences")]
    end

    subgraph authZone["AuthApiClient (AuthInterceptor / MockApiClient)"]
        mockApi["MockApiClient + MockFixtures (Mặc định)"]
        bff["Auth & Trading BFF (Tương lai - Server giữ Exchange Keys)"]
    end

    subgraph app["5 Tab Shell + Auth/Trading"]
        t0(("Tab 0-3: Market, Binance, Watchlist, Global"))
        t4(("Tab 4: Profile, Login, Role Mock, Settings"))
        trade(("Demo Paper Order + Order History"))
        live(("Live Order - Khóa 4 lớp"))
    end

    guest --> t0
    guest --> t4
    demo --> t0
    demo --> t4
    demo --> trade
    verified --> trade
    verified -. "Chỉ mở khi đủ 4 điều kiện" .-> live

    t0 --> binance
    t0 --> coingecko
    t0 --> marketDb
    t0 --> prefs
    t4 --> secure
    t4 --> mockApi
    t4 -. "USE_MOCK_API=false" .-> bff
    trade --> demoDb
    trade -. "Giá live" .-> marketDb
    live -. "Future LiveTradingRepository" .-> bff
```

### 2.2 Class Diagram (Theo đúng thư mục `core/` · `data/` · `providers/` · `views/`)

```mermaid
classDiagram
    class BinanceHomeScreen
    class CoinDetail
    class LoginScreen
    class ProfileScreen
    class OrderHistoryScreen

    class AuthProvider {
        +AuthSession? session
        +UserRole role
        +bool isAuthenticated
        +restoreSession()
        +login()
        +logout()
        +switchMockRole()
    }
    class TradingProvider {
        +TradingMode mode
        +DemoAccount? account
        +List~Position~ positions
        +List~OrderRecord~ orders
        +previewOrder()
        +placeOrder()
        +resetDemoAccount()
    }
    class BinanceMarketViewModel

    class AuthRepository {
        <<interface>>
    }
    class TradingRepository {
        <<interface>>
    }
    class BinanceMarketRepository {
        <<interface>>
    }
    class CoinGeckoRepository

    class TokenStorage
    class SecureStorage
    class MockApiClient
    class PaperTradingLocalDataSource
    class BinanceMarketLocalDataSource
    class PublicApiClient
    class AuthApiClient

    LoginScreen --> AuthProvider
    ProfileScreen --> AuthProvider
    ProfileScreen --> TradingProvider
    OrderHistoryScreen --> TradingProvider
    CoinDetail --> TradingProvider
    BinanceHomeScreen --> BinanceMarketViewModel

    AuthProvider --> AuthRepository
    AuthRepository --> TokenStorage
    AuthRepository --> MockApiClient : USE_MOCK_API=true
    AuthRepository --> AuthApiClient : USE_MOCK_API=false
    TokenStorage --> SecureStorage

    TradingProvider --> TradingRepository
    TradingProvider --> AuthProvider : AuthZ check
    TradingProvider --> BinanceMarketRepository : live price
    TradingRepository --> PaperTradingLocalDataSource : Demo mode
    TradingRepository --> AuthApiClient : Future Live BFF

    BinanceMarketViewModel --> BinanceMarketRepository
    BinanceMarketRepository --> BinanceMarketLocalDataSource
    BinanceMarketRepository --> CoinGeckoRepository : metadata
    CoinGeckoRepository --> PublicApiClient
```

### 2.3 Sequence: Đặt lệnh Paper Trading An Toàn

```mermaid
sequenceDiagram
    actor User
    participant UI as CoinDetail / showPaperOrder
    participant Auth as AuthProvider (AuthN/AuthZ)
    participant VM as TradingProvider
    participant Repo as TradingRepository (Demo)
    participant DB as paper_trading.db

    User->>UI: Nhấn Mua/Bán + nhập số lượng
    UI->>Auth: Kiểm tra isAuthenticated & canTradeDemo
    alt Guest
        Auth-->>UI: Chưa đăng nhập
        UI-->>User: Điều hướng /auth/login
    else DemoTrader
        UI->>VM: previewOrder(symbol, side, qty)
        VM-->>UI: Tổng tiền + kiểm tra số dư + nhãn DEMO
        User->>UI: Xác nhận "LỆNH DEMO - KHÔNG TIỀN THẬT"
        UI->>VM: placeOrder(request + clientOrderId)
        VM->>Repo: placeOrder(request)
        Repo->>DB: Transaction: check idempotency + cập nhật số dư/vị thế + lưu lệnh
        DB-->>Repo: OrderRecord (mode: demo, status: filled)
        Repo-->>VM: Ok(OrderRecord)
        VM-->>UI: Cập nhật ví & lịch sử Demo
    end
```

### 2.4 ERD SQLite Cục bộ

```mermaid
erDiagram
    BINANCE_COINS {
        TEXT symbol PK
        TEXT base_asset
        TEXT quote_asset
        TEXT name
        REAL price
        REAL change_24h
        REAL base_volume
        REAL quote_volume
        INTEGER trading_enabled
        TEXT image_url
        REAL market_cap
        TEXT last_updated
    }

    DEMO_ACCOUNTS {
        TEXT user_id PK
        TEXT quote_asset
        REAL available_balance
        REAL initial_balance
        TEXT updated_at
    }

    DEMO_POSITIONS {
        TEXT user_id PK
        TEXT symbol PK
        TEXT base_asset
        REAL quantity
        REAL avg_entry_price
        TEXT updated_at
    }

    DEMO_ORDERS {
        TEXT client_order_id PK
        TEXT user_id FK
        TEXT symbol
        TEXT side
        TEXT order_type
        TEXT execution_mode
        REAL quantity
        REAL executed_price
        REAL total_quote
        REAL fee_quote
        TEXT status
        TEXT created_at
    }

    DEMO_ACCOUNTS ||--o{ DEMO_POSITIONS : "owns"
    DEMO_ACCOUNTS ||--o{ DEMO_ORDERS : "places"
```

| Kho lưu trữ | Dữ liệu |
|---|---|
| `binance_market.db` (SQLite) | `binance_coins` (offline-first Binance snapshot) |
| `paper_trading.db` (SQLite) | `demo_accounts`, `demo_positions`, `demo_orders` |
| `SecureStorage` (`flutter_secure_storage`) | `access_token`, `refresh_token`, `token_expires_at`, `mock_role` |
| `LocalStorage` (`SharedPreferences`) | `watchlist_coin_ids`, `locale`, `theme_mode`, `onboarding_seen`, `remote_config`, `device_id` |
