# Sơ đồ dự án

Các sơ đồ mô tả **mã hiện tại**, không phải kế hoạch chuyển đổi. Ứng dụng
đang có hai luồng dữ liệu thị trường: Binance cho màn hình Home và CoinGecko
cho danh sách/thị trường/tổng quan/watchlist. Một số màn hình chi tiết và giao
dịch vẫn là giao diện minh hoạ.

## Use case

```mermaid
flowchart LR
    user[Người dùng]
    binanceRest[Binance REST API]
    binanceStream[Binance WebSocket Stream]
    coinGecko[CoinGecko REST API]
    local[(Lưu trữ trên thiết bị)]

    subgraph app[Ứng dụng Flutter]
        home((Xem cặp Binance<br/>và giá trực tiếp))
        pairSearch((Tìm cặp theo symbol))
        pairDetail((Mở trang chi tiết cặp<br/>UI minh hoạ))
        market((Xem thị trường<br/>lọc, sắp xếp, phân trang))
        trending((Xem coin thịnh hành))
        overview((Xem thống kê toàn cầu,<br/>ngành và biến động))
        watchlist((Quản lý watchlist<br/>thêm, xoá, xem giá))
        discover((Tải và lọc danh sách token))
        search((Nhận gợi ý tìm kiếm))
        preferences((Đổi ngôn ngữ,<br/>giao diện và onboarding))
        demoOrder((Mở form mua/bán demo))
    end

    user --> home
    user --> pairSearch
    user --> pairDetail
    user --> market
    user --> trending
    user --> overview
    user --> watchlist
    user --> discover
    user --> search
    user --> preferences
    user --> demoOrder

    home --> binanceRest
    home --> binanceStream
    home --> local
    home -. metadata .-> coinGecko
    market --> coinGecko
    trending --> coinGecko
    overview --> coinGecko
    watchlist --> coinGecko
    watchlist --> local
    discover --> coinGecko
    search --> coinGecko
    preferences --> local
    pairDetail -. giá được truyền từ màn Home .-> home
```

`Mở form mua/bán demo` không thực hiện lệnh Binance. Watchlist lưu CoinGecko ID
ở SharedPreferences; nó không dùng cặp Binance được lưu trong SQLite.

## Class diagram

```mermaid
classDiagram
    class BinanceHomeScreen
    class MarketScreen
    class GlobalScreen
    class WatchlistScreen

    class BinanceMarketViewModel
    class MarketProvider
    class GlobalProvider
    class WatchListProvider
    class SearchProvider
    class TokenListProvider

    class BinanceMarketRepository {
        <<interface>>
        +start()
        +refresh()
        +stop()
        +updates
        +connectionStatuses
    }
    class BinanceMarketRepositoryImpl
    class CoinRepository
    class MarketRepository
    class SystemRepository

    class BinanceMarketLocalDataSource {
        +getCoins()
        +getCoin(symbol)
        +upsertCoins(coins)
        +clear()
    }
    class ApiClient {
        <<interface>>
    }
    class DioApiClient
    class NetworkInfo
    class LocalStorage

    class BinanceCoin {
        +symbol: String
        +baseAsset: String
        +quoteAsset: String
        +price: double?
        +change24h: double?
        +baseVolume: double?
        +quoteVolume: double?
        +tradingEnabled: bool
        +marketCap: double?
    }
    class CoinMarketModel {
        +id: String
        +symbol: String
        +name: String
        +currentPrice: double?
        +marketCap: double?
        +marketCapRank: int?
    }
    class CoinCategory
    class GlobalStats
    class TokenModel

    BinanceHomeScreen --> BinanceMarketViewModel : observes
    MarketScreen --> MarketProvider : observes
    GlobalScreen --> GlobalProvider : observes
    WatchlistScreen --> WatchListProvider : observes

    BinanceMarketViewModel --> BinanceMarketRepository : uses
    MarketProvider --> MarketRepository : uses
    GlobalProvider --> MarketRepository : uses
    WatchListProvider --> MarketRepository : loads prices
    WatchListProvider --> LocalStorage : saves IDs
    SearchProvider --> CoinRepository : suggestions
    SearchProvider --> LocalStorage : history
    TokenListProvider --> CoinRepository : token data

    BinanceMarketRepositoryImpl ..|> BinanceMarketRepository
    BinanceMarketRepositoryImpl --> BinanceMarketLocalDataSource : cache
    BinanceMarketRepositoryImpl --> NetworkInfo : connectivity
    BinanceMarketRepositoryImpl --> CoinRepository : optional metadata
    BinanceMarketRepositoryImpl --> BinanceCoin : emits
    BinanceMarketLocalDataSource --> BinanceCoin : maps SQLite rows

    CoinRepository --> ApiClient : requests
    MarketRepository --> ApiClient : requests
    SystemRepository --> LocalStorage : reads config
    DioApiClient ..|> ApiClient

    CoinRepository ..> TokenModel : parses
    CoinRepository ..> CoinMarketModel : parses
    MarketRepository ..> CoinMarketModel : parses
    MarketRepository ..> CoinCategory : parses
    MarketRepository ..> GlobalStats : parses
```

`CoinMarketModel`, `CoinCategory`, `GlobalStats` và `TokenModel` là model của
dữ liệu API; chúng không phải các bảng trong SQLite. `BinanceCoin` là model
cho snapshot Binance cục bộ.

## ERD lưu trữ cục bộ

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
```

SQLite hiện chỉ tạo bảng `binance_coins`; `base_asset` có index nhưng không có
foreign key. Dữ liệu còn lại được lưu riêng bằng SharedPreferences, không phải
bảng quan hệ:

| Khoá | Dữ liệu |
|---|---|
| `watchlist_coin_ids` | Danh sách CoinGecko ID được theo dõi |
| `coingecko.recent_search` | Lịch sử từ khoá tìm kiếm |
| `coingecko.recent_viewed` | Danh sách token xem gần đây dạng JSON |
| `coingecko.locale`, `coingecko.theme_mode` | Tuỳ chọn ngôn ngữ và giao diện |
| `coingecko.onboarding_seen` | Trạng thái onboarding |
| `coingecko.remote_config` | Cấu hình cache cục bộ |
| `coingecko.device_id` | Mã thiết bị |

Không có tài khoản người dùng, danh mục đầu tư, lệnh giao dịch hay quan hệ
foreign key được lưu trong cơ sở dữ liệu hiện tại.
