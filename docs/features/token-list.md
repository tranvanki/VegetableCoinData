# Danh sách token / cặp giao dịch

## Hiện tại

`TokenListProvider.load()` dùng `CoinRepository.getTokens()` lấy CoinGecko
`/coins/list`; `TokenModel` có ID, tên, symbol và platforms. Tìm kiếm lọc trong
bộ nhớ; repository cache và giới hạn refetch. Màn hình hiện đang được sửa để
hiển thị `CoinMarketModel`, còn polling 20 giây thay danh sách bằng top 250
CoinGecko. Hai kiểu không tương thích: row có thể lỗi khi nhận `TokenModel`,
và danh mục đầy đủ biến thành 250 coin sau polling. Timer hiện chưa được hủy
trong `dispose()`.

## Dự kiến Binance

1. Đổi khái niệm hiển thị sang **cặp Spot**, ví dụ `BTC/USDT`; không gọi là
   danh mục toàn bộ token. Lấy cặp qua REST `exchangeInfo`, lọc theo quote và
   trạng thái giao dịch theo chính sách sản phẩm.
2. Lấy snapshot ticker rồi áp dụng stream vào model cặp có kiểu duy nhất.
   Tìm theo symbol/base/quote cục bộ; không tìm tên đầy đủ nếu không có nguồn.
3. Duy trì danh mục riêng với ticker: không thay toàn bộ danh sách bằng
   event hoặc top 250. Hiển thị giá bằng quote asset; thiếu giá thì hiện `—`.
4. Bộ lọc hạng/vốn hóa hiện tại không có dữ liệu Binance tương đương; bỏ hoặc
   thay bằng tiêu chí được người dùng chấp thuận và ghi rõ đơn vị.
5. Bỏ polling cũ sau khi có stream; xử lý refresh, reconnect, stale và
   dispose theo [kiến trúc](../architecture/repositories-providers.md).

## Hàm liên quan

| Hiện có | Việc chuyển đổi |
|---|---|
| `init()`, `load()`, `refresh()` | Lấy danh mục/snapshot, quản lý trạng thái và lỗi. |
| `setQuery()`, `_applyQuery()` | Lọc model cặp có kiểu ổn định. |
| `_setTokens()`, `_silentRefresh()` | Thay bằng gộp delta theo symbol; không trộn kiểu. |
| `dispose()` | Hủy request, stream, timer và các callback đang chờ. |

Kiểm thử nạp lần đầu, tìm kiếm, cập nhật một cặp không mất cặp khác, refresh,
reconnect và dispose. Chi tiết stream: [API](../../all_api_formatted.md).
