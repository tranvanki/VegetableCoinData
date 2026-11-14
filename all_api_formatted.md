# CoinGecko & Onchain (GeckoTerminal) API Reference

Tài liệu tổng hợp toàn bộ danh sách endpoint của **CoinGecko API** và **Onchain / GeckoTerminal API**, kèm mô tả và cấu trúc dữ liệu (Response Data) trả về đặc trưng của từng endpoint.

> **65 endpoint** · 15 nhóm

## Mục lục

- [1. Price (Giá cả)](#1-price-giá-cả) — 2 endpoint
- [2. Search & ID Map (Tìm kiếm & Ánh xạ ID)](#2-search--id-map-tìm-kiếm--ánh-xạ-id) — 5 endpoint
- [3. Coins (Thông tin & Thị trường Coin)](#3-coins-thông-tin--thị-trường-coin) — 5 endpoint
- [4. Coin Charts (Biểu đồ lịch sử)](#4-coin-charts-biểu-đồ-lịch-sử) — 5 endpoint
- [5. Categories (Danh mục Coin)](#5-categories-danh-mục-coin) — 2 endpoint
- [6. RWA (Tài sản thực được token hóa)](#6-rwa-tài-sản-thực-được-token-hóa) — 5 endpoint
- [7. Exchanges (Sàn giao dịch Spot)](#7-exchanges-sàn-giao-dịch-spot) — 5 endpoint
- [8. Derivatives (Sàn & Hợp đồng Phái sinh)](#8-derivatives-sàn--hợp-đồng-phái-sinh) — 4 endpoint
- [9. Public Treasury (Kho bạc Công ty đại chúng & Chính phủ)](#9-public-treasury-kho-bạc-công-ty-đại-chúng--chính-phủ) — 5 endpoint
- [10. NFTs](#10-nfts) — 3 endpoint
- [11. Trending, Global & Utility (Xu hướng, Toàn cầu & Tiện ích)](#11-trending-global--utility-xu-hướng-toàn-cầu--tiện-ích) — 5 endpoint
- [12. Onchain / GeckoTerminal API (Dữ liệu DEX & Mạng lưới)](#12-onchain--geckoterminal-api-dữ-liệu-dex--mạng-lưới)
  - [12.1. Onchain Price & Search](#121-onchain-price--search) — 4 endpoint
  - [12.2. Onchain Pools (Thanh khoản)](#122-onchain-pools-thanh-khoản) — 6 endpoint
  - [12.3. New & Trending Pools](#123-new--trending-pools) — 4 endpoint
  - [12.4. Onchain Tokens & Charts](#124-onchain-tokens--charts) — 5 endpoint

---

## 1. Price (Giá cả)

### `GET /simple/price`

Lấy giá của một hoặc nhiều coin theo ID, symbol hoặc tên.

**Dữ liệu trả về:** Object map theo `coin_id`:

```json
{
  "bitcoin": {
    "usd": 65000,
    "usd_24h_change": 2.5,
    "usd_market_cap": ...,
    "last_updated_at": ...
  }
}
```

### `GET /simple/token_price/{id}`

Lấy giá token theo địa chỉ contract trên một mạng lưới (`id` là asset platform).

**Dữ liệu trả về:** Object map theo `contract_address` (chữ thường):

```json
{ "0x...": { "usd": 1.0, "usd_24h_vol": ... } }
```

---

## 2. Search & ID Map (Tìm kiếm & Ánh xạ ID)

### `GET /search`

Tìm kiếm coin, danh mục (categories), sàn giao dịch và NFT trên CoinGecko.

**Dữ liệu trả về:** Object chứa các mảng: `coins` (`id`, `name`, `symbol`, `market_cap_rank`, `thumb`), `exchanges`, `categories`, `nfts`.

### `GET /coins/list`

Lấy toàn bộ danh sách coin được hỗ trợ kèm ID, tên và ký hiệu.

**Dữ liệu trả về:** Mảng JSON:

```json
[{ "id": "bitcoin", "symbol": "btc", "name": "Bitcoin", "platforms": { ... } }]
```

### `GET /asset_platforms`

Lấy danh sách tất cả mạng lưới blockchain được hỗ trợ.

**Dữ liệu trả về:** Mảng JSON:

```json
[{ "id": "ethereum", "chain_identifier": 1, "name": "Ethereum", "shortname": "" }]
```

### `GET /token_lists/{asset_platform_id}/all.json`

Danh sách đầy đủ token trên một mạng theo chuẩn Ethereum Token List.

**Dữ liệu trả về:** JSON chuẩn TokenList:

```json
{
  "name": "...",
  "tokens": [
    {
      "chainId": 1,
      "address": "0x...",
      "name": "...",
      "symbol": "...",
      "decimals": 18,
      "logoURI": "..."
    }
  ]
}
```

### `GET /simple/supported_vs_currencies`

Lấy danh sách các đồng tiền tệ đối chiếu (fiat/crypto) được hỗ trợ.

**Dữ liệu trả về:** Mảng chuỗi ký hiệu:

```json
["btc", "eth", "usd", "vnd", ...]
```

---

## 3. Coins (Thông tin & Thị trường Coin)

### `GET /coins/markets`

Lấy danh sách coin kèm giá, vốn hóa, khối lượng và biến động 24h.

**Dữ liệu trả về:** Mảng Object `CoinMarket`: `id`, `symbol`, `name`, `image`, `current_price`, `market_cap`, `market_cap_rank`, `total_volume`, `high_24h`, `low_24h`, `price_change_percentage_24h`, `sparkline_in_7d`.

### `GET /coins/{id}`

Lấy toàn bộ metadata và dữ liệu thị trường chi tiết của một coin.

**Dữ liệu trả về:** Object chi tiết: `id`, `symbol`, `name`, `description`, `links` (website, social), `image`, `market_data` (giá theo nhiều tiền tệ, ATH, ATL, nguồn cung), `tickers`.

### `GET /coins/{id}/contract/{contract_address}`

Lấy toàn bộ metadata và dữ liệu thị trường theo mạng và địa chỉ contract.

**Dữ liệu trả về:** Cấu trúc tương tự `GET /coins/{id}`.

### `GET /coins/{id}/tickers`

Lấy danh sách các cặp giao dịch (tickers) của coin trên cả sàn CEX và DEX.

**Dữ liệu trả về:**

```json
{
  "name": "Bitcoin",
  "tickers": [
    {
      "base": "BTC",
      "target": "USDT",
      "market": { "name": "Binance" },
      "last": 65000,
      "volume": ...,
      "trust_score": "green"
    }
  ]
}
```

### `GET /coins/{id}/history`

Lấy dữ liệu lịch sử (giá, vốn hóa, volume 24h) tại một ngày cụ thể (`dd-mm-yyyy`).

**Dữ liệu trả về:**

```json
{
  "id": "bitcoin",
  "market_data": {
    "current_price": { ... },
    "market_cap": { ... },
    "total_volume": { ... }
  }
}
```

---

## 4. Coin Charts (Biểu đồ lịch sử)

### `GET /coins/{id}/market_chart`

Dữ liệu biểu đồ lịch sử (giá, vốn hóa, volume 24h) theo số ngày.

**Dữ liệu trả về:** Object chứa 3 mảng cặp `[timestamp_ms, value]`: `prices`, `market_caps`, `total_volumes`.

### `GET /coins/{id}/market_chart/range`

Dữ liệu biểu đồ lịch sử trong khoảng thời gian từ `from` đến `to` (UNIX timestamp).

**Dữ liệu trả về:** Tương tự `/market_chart`:

```json
{ "prices": [[ts, price], ...], "market_caps": [...], "total_volumes": [...] }
```

### `GET /coins/{id}/contract/{contract_address}/market_chart`

Dữ liệu biểu đồ lịch sử theo mạng lưới và địa chỉ contract.

**Dữ liệu trả về:** Tương tự `/market_chart`.

### `GET /coins/{id}/contract/{contract_address}/market_chart/range`

Dữ liệu biểu đồ lịch sử trong khoảng thời gian theo địa chỉ contract.

**Dữ liệu trả về:** Tương tự `/market_chart`.

### `GET /coins/{id}/ohlc`

Dữ liệu nến OHLC (Open, High, Low, Close) theo ID coin.

**Dữ liệu trả về:** Mảng 2 chiều các cây nến:

```json
[[timestamp_ms, open, high, low, close], ...]
```

---

## 5. Categories (Danh mục Coin)

### `GET /coins/categories/list`

Lấy danh sách ID và tên của tất cả danh mục coin.

**Dữ liệu trả về:** Mảng JSON:

```json
[{ "category_id": "layer-1", "name": "Layer 1 (L1)" }]
```

### `GET /coins/categories`

Lấy tất cả danh mục kèm dữ liệu thị trường (vốn hóa, volume).

**Dữ liệu trả về:** Mảng JSON:

```json
[
  {
    "id": "layer-1",
    "name": "...",
    "market_cap": ...,
    "market_cap_change_24h": ...,
    "top_3_coins": ["url1", "url2", "url3"],
    "volume_24h": ...
  }
]
```

---

## 6. RWA (Tài sản thực được token hóa)

### `GET /rwas/list`

Danh sách tất cả RWA được hỗ trợ kèm ID, tên và ký hiệu.

**Dữ liệu trả về:** Mảng JSON:

```json
[{ "id": "...", "name": "...", "symbol": "..." }]
```

### `GET /rwas/markets`

Danh sách RWA kèm giá, vốn hóa, volume và dữ liệu thị trường.

**Dữ liệu trả về:** Mảng Object thị trường RWA (tương tự cấu trúc `/coins/markets`).

### `GET /rwas/{id}`

Lấy toàn bộ metadata, dữ liệu thị trường và các token thuộc một RWA.

**Dữ liệu trả về:** Object chi tiết RWA, thông tin tài sản cơ sở và danh sách token liên quan.

### `GET /rwas/issuers/list`

Danh sách các tổ chức phát hành RWA được hỗ trợ (ID và tên).

**Dữ liệu trả về:** Mảng JSON:

```json
[{ "id": "...", "name": "..." }]
```

### `GET /rwas/issuers/{id}`

Dữ liệu thị trường và danh sách token của một tổ chức phát hành RWA.

**Dữ liệu trả về:** Object thông tin nhà phát hành kèm mảng danh sách token RWA do tổ chức đó phát hành.

---

## 7. Exchanges (Sàn giao dịch Spot)

### `GET /exchanges/list`

Lấy danh sách ID và tên tất cả sàn giao dịch.

**Dữ liệu trả về:** Mảng JSON:

```json
[{ "id": "binance", "name": "Binance" }]
```

### `GET /exchanges`

Lấy danh sách sàn giao dịch kèm dữ liệu xếp hạng và volume.

**Dữ liệu trả về:** Mảng JSON:

```json
[
  {
    "id": "binance",
    "name": "Binance",
    "year_established": 2017,
    "country": "...",
    "trust_score": 10,
    "trade_volume_24h_btc": ...
  }
]
```

### `GET /exchanges/{id}`

Lấy thông tin chi tiết sàn giao dịch và top 100 cặp giao dịch (tickers).

**Dữ liệu trả về:** Object thông tin sàn (`name`, `trust_score`, `links`, `trade_volume_24h_btc`) + mảng `tickers` (tối đa 100).

### `GET /exchanges/{id}/tickers`

Lấy danh sách cặp giao dịch của một sàn (có phân trang).

**Dữ liệu trả về:**

```json
{ "name": "Binance", "tickers": [...] }
```

### `GET /exchanges/{id}/volume_chart`

Dữ liệu biểu đồ khối lượng giao dịch lịch sử của sàn tính theo BTC.

**Dữ liệu trả về:** Mảng 2 chiều:

```json
[[timestamp_ms, "volume_in_btc"], ...]
```

---

## 8. Derivatives (Sàn & Hợp đồng Phái sinh)

### `GET /derivatives/exchanges/list`

Danh sách ID và tên các sàn phái sinh.

**Dữ liệu trả về:** Mảng JSON:

```json
[{ "id": "binance_futures", "name": "Binance (Futures)" }]
```

### `GET /derivatives`

Lấy tất cả tickers phái sinh (perpetuals & futures) trên các sàn.

**Dữ liệu trả về:** Mảng JSON:

```json
[
  {
    "market": "Binance (Futures)",
    "symbol": "BTCUSDT",
    "index_id": "BTC",
    "price": "65000",
    "funding_rate": 0.0001,
    "open_interest": ...,
    "volume_24h": ...
  }
]
```

### `GET /derivatives/exchanges`

Danh sách các sàn phái sinh kèm dữ liệu (Open Interest, volume 24h).

**Dữ liệu trả về:** Mảng JSON:

```json
[
  {
    "name": "...",
    "id": "...",
    "open_interest_btc": ...,
    "trade_volume_24h_btc": ...,
    "number_of_perpetual_pairs": ...
  }
]
```

### `GET /derivatives/exchanges/{id}`

Dữ liệu chi tiết một sàn phái sinh và các cặp hợp đồng của sàn đó.

**Dữ liệu trả về:** Object thông tin sàn phái sinh kèm mảng `tickers`.

---

## 9. Public Treasury (Kho bạc Công ty đại chúng & Chính phủ)

### `GET /entities/list`

Danh sách các thực thể (công ty, chính phủ) sở hữu crypto.

**Dữ liệu trả về:** Mảng JSON:

```json
[{ "id": "strategy", "name": "Strategy", "symbol": "MSTR", "country": "US" }]
```

### `GET /{entity}/public_treasury/{coin_id}`

Thống kê lượng nắm giữ của công ty (`companies`) hoặc chính phủ (`governments`) theo coin.

**Dữ liệu trả về:**

```json
{
  "total_holdings": ...,
  "total_value_usd": ...,
  "market_cap_dominance": ...,
  "companies": [
    {
      "name": "...",
      "symbol": "...",
      "total_holdings": ...,
      "total_entry_value_usd": ...
    }
  ]
}
```

### `GET /public_treasury/{entity_id}`

Thống kê danh mục crypto nắm giữ của một tổ chức cụ thể theo ID.

**Dữ liệu trả về:** Object thông tin tổ chức và danh sách chi tiết các loại coin đang nắm giữ.

### `GET /public_treasury/{entity_id}/{coin_id}/holding_chart`

Biểu đồ lịch sử lượng nắm giữ một coin của một tổ chức.

**Dữ liệu trả về:** Mảng chuỗi thời gian thể hiện số lượng coin và giá trị USD nắm giữ qua từng mốc thời gian.

### `GET /public_treasury/{entity_id}/transaction_history`

Lịch sử giao dịch mua/bán crypto của một tổ chức.

**Dữ liệu trả về:** Mảng lịch sử giao dịch: ngày giao dịch, loại coin, số lượng thay đổi, giá trị giao dịch.

---

## 10. NFTs

### `GET /nfts/list`

Danh sách tất cả bộ sưu tập NFT được hỗ trợ.

**Dữ liệu trả về:** Mảng JSON:

```json
[
  {
    "id": "pudgy-penguins",
    "contract_address": "0x...",
    "name": "Pudgy Penguins",
    "asset_platform_id": "ethereum",
    "symbol": "PPG"
  }
]
```

### `GET /nfts/{id}`

Dữ liệu chi tiết bộ sưu tập NFT (giá sàn, volume 24h, vốn hóa) theo ID.

**Dữ liệu trả về:** Object: `id`, `name`, `floor_price` (`native_currency`, `usd`), `market_cap`, `volume_24h`, `number_of_unique_addresses`, `total_supply`.

### `GET /nfts/{asset_platform_id}/contract/{contract_address}`

Dữ liệu chi tiết bộ sưu tập NFT theo mạng và địa chỉ contract.

**Dữ liệu trả về:** Cấu trúc tương tự `GET /nfts/{id}`.

---

## 11. Trending, Global & Utility (Xu hướng, Toàn cầu & Tiện ích)

### `GET /search/trending`

Top coin, NFT và danh mục được tìm kiếm nhiều nhất trong 24h qua.

**Dữ liệu trả về:**

```json
{
  "coins": [
    {
      "item": {
        "id": "...",
        "name": "...",
        "symbol": "...",
        "market_cap_rank": ...,
        "data": { "price": ..., "price_change_percentage_24h": ... }
      }
    }
  ],
  "nfts": [...],
  "categories": [...]
}
```

### `GET /global`

Dữ liệu tổng quan toàn thị trường crypto.

**Dữ liệu trả về:**

```json
{
  "data": {
    "active_cryptocurrencies": ...,
    "markets": ...,
    "total_market_cap": { "usd": ... },
    "total_volume": { "usd": ... },
    "market_cap_percentage": { "btc": 54.2, "eth": 16.5 }
  }
}
```

### `GET /global/decentralized_finance_defi`

Dữ liệu tổng quan thị trường DeFi (vốn hóa DeFi, tỷ lệ thống trị).

**Dữ liệu trả về:**

```json
{
  "data": {
    "defi_market_cap": "...",
    "eth_market_cap": "...",
    "defi_to_eth_ratio": "...",
    "trading_volume_24h": "...",
    "defi_dominance": "...",
    "top_coin_name": "..."
  }
}
```

### `GET /exchange_rates`

Tỷ giá quy đổi từ 1 BTC sang các loại tiền tệ khác.

**Dữ liệu trả về:**

```json
{
  "rates": {
    "usd": { "name": "US Dollar", "unit": "$", "value": 65000, "type": "fiat" },
    "vnd": { ... }
  }
}
```

### `GET /ping`

Kiểm tra trạng thái hoạt động của máy chủ API CoinGecko.

**Dữ liệu trả về:**

```json
{ "gecko_says": "(V3) To the Moon!" }
```

## 12. Onchain / GeckoTerminal API (Dữ liệu DEX & Mạng lưới)

> **Lưu ý chung về định dạng dữ liệu Onchain:** Các endpoint `/onchain/...` đều trả về theo chuẩn JSON:API Specification, bao gồm khối gốc `"data"` (chứa `id`, `type`, `attributes`, `relationships`) và khối `"included"` (nếu có).

---

### 12.1. Onchain Price & Search

#### `GET /onchain/simple/networks/{network}/token_price/{addresses}`

Lấy giá token theo địa chỉ contract trên một mạng lưới DEX.

**Dữ liệu trả về:**

```json
{
  "data": {
    "type": "simple_token_price",
    "attributes": { "token_prices": { "0x...": "1.2345" } }
  }
}
```

#### `GET /onchain/search/pools`

Tìm kiếm pool thanh khoản theo địa chỉ pool, tên token, ký hiệu hoặc contract.

**Dữ liệu trả về:** Mảng `data` các đối tượng pool kèm `attributes` (tên cặp, giá, thanh khoản, volume 24h).

#### `GET /onchain/networks`

Danh sách tất cả mạng blockchain được hỗ trợ trên GeckoTerminal.

**Dữ liệu trả về:** Mảng `data` các network: `id` (vd: `"eth"`, `"solana"`, `"bsc"`), `attributes` (`name`, `coingecko_asset_platform_id`).

#### `GET /onchain/networks/{network}/dexes`

Danh sách các sàn DEX được hỗ trợ trên một mạng lưới cụ thể.

**Dữ liệu trả về:** Mảng `data` các dex: `id` (vd: `"uniswap_v3"`), `attributes` (`name`).

---

### 12.2. Onchain Pools (Thanh khoản)

#### `GET /onchain/networks/{network}/pools/{address}`

Lấy thông tin chi tiết một pool theo mạng và địa chỉ pool.

**Dữ liệu trả về:** Object pool: `base_token_price_usd`, `quote_token_price_usd`, `fdv_usd`, `market_cap_usd`, `price_change_percentage` (m5, h1, h6, h24), transactions, `volume_usd`, `reserve_in_usd`.

#### `GET /onchain/networks/{network}/pools/multi/{addresses}`

Lấy thông tin nhiều pool cùng lúc (tối đa 30 địa chỉ cách nhau dấu phẩy).

**Dữ liệu trả về:** Mảng `data` các object pool có cấu trúc như trên.

#### `GET /onchain/networks/{network}/pools/{pool_address}/info`

Lấy metadata của các token trong pool (ảnh, mô tả, mạng xã hội).

**Dữ liệu trả về:** Mảng `data` các token trong pool kèm `image_url`, websites, `discord_url`, `telegram_handle`, `twitter_handle`.

#### `GET /onchain/networks/{network}/pools`

Top các pool thanh khoản hàng đầu trên một mạng lưới.

**Dữ liệu trả về:** Mảng `data` các object pool.

#### `GET /onchain/networks/{network}/dexes/{dex}/pools`

Top các pool thanh khoản hàng đầu trên một mạng và một sàn DEX cụ thể.

**Dữ liệu trả về:** Mảng `data` các object pool.

#### `GET /onchain/networks/{network}/tokens/{token_address}/pools`

Top các pool thanh khoản chứa một địa chỉ token cụ thể.

**Dữ liệu trả về:** Mảng `data` các object pool giao dịch token đó.

---

### 12.3. New & Trending Pools

#### `GET /onchain/networks/new_pools`

Danh sách các pool vừa được tạo mới nhất trên toàn bộ các mạng.

**Dữ liệu trả về:** Mảng `data` các object pool kèm `pool_created_at`.

#### `GET /onchain/networks/{network}/new_pools`

Danh sách các pool vừa được tạo mới nhất trên một mạng cụ thể.

**Dữ liệu trả về:** Mảng `data` các object pool kèm `pool_created_at`.

#### `GET /onchain/networks/trending_pools`

Danh sách các pool đang thịnh hành (trending) trên toàn bộ các mạng.

**Dữ liệu trả về:** Mảng `data` các object pool.

#### `GET /onchain/networks/{network}/trending_pools`

Danh sách các pool đang thịnh hành trên một mạng cụ thể.

**Dữ liệu trả về:** Mảng `data` các object pool.

---

### 12.4. Onchain Tokens & Charts

#### `GET /onchain/networks/{network}/tokens/{address}`

Dữ liệu onchain của một token theo địa chỉ contract trên mạng.

**Dữ liệu trả về:** Object token: `name`, symbol, decimals, `total_supply`, `price_usd`, `fdv_usd`, `total_reserve_in_usd`, `volume_usd`, `top_pools`.

#### `GET /onchain/networks/{network}/tokens/multi/{addresses}`

Dữ liệu onchain của nhiều token cùng lúc theo địa chỉ contract.

**Dữ liệu trả về:** Mảng `data` các object token.

#### `GET /onchain/networks/{network}/tokens/{address}/info`

Metadata của token (tên, ký hiệu, CoinGecko ID, links mạng xã hội).

**Dữ liệu trả về:** Object token: address, `name`, symbol, `image_url`, `coingecko_coin_id`, websites, socials, `gt_score`.

#### `GET /onchain/tokens/info_recently_updated`

100 token vừa được cập nhật thông tin metadata gần nhất trên toàn mạng.

**Dữ liệu trả về:** Mảng `data` các object token info.

#### `GET /onchain/networks/{network}/pools/{pool_address}/ohlcv/{timeframe}`

Dữ liệu biểu đồ nến OHLCV của một pool (timeframe: day, hour, minute).

**Dữ liệu trả về:**

```json
{
  "data": {
    "attributes": {
      "ohlcv_list": [[timestamp_sec, open, high, low, close, volume], ...]
    }
  }
}
```
