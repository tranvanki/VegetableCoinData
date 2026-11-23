# Thị trường

## Hiện tại

`MarketScreen` dùng `MarketProvider` và `MarketRepository` để lấy thị trường,
thẻ toàn cầu và xu hướng CoinGecko. Bảng có sort cục bộ và phân trang; đây
không phải dữ liệu Binance.

## Dự kiến Binance

- Bảng hiển thị cặp Spot và giá theo quote asset, % 24h rolling và khối lượng
  base/quote được ghi đơn vị. Lấy snapshot REST và nhận ticker stream.
- `exchangeInfo` không cung cấp trang xếp hạng theo vốn hóa; phân trang
  CoinGecko hiện tại không thể chuyển nguyên trạng. Có thể phân trang **hiển
  thị cục bộ** sau khi nạp tập cặp phù hợp, không giả làm phân trang API.
- Bỏ hoặc ẩn cột hạng/vốn hóa, chip xu hướng tìm kiếm và thẻ toàn cầu cho tới
  khi có quyết định sản phẩm. Có thể đề xuất sắp xếp theo giá, % hoặc volume
  của cùng quote, nhưng không gọi đó là vốn hóa/xu hướng toàn thị trường.
- Cập nhật theo symbol và giới hạn rebuild; hiển thị trạng thái stale/lỗi.

## Hàm cần thay đổi

| Hiện có | Hướng chuyển đổi |
|---|---|
| `MarketProvider.init()`, `load()`, `refresh()` | Nạp cặp/snapshot và đăng ký ticker; không dùng `/global`. |
| `setSort()`, `_sorted()` | Chỉ sort theo trường có thật, so sánh volume đúng đơn vị. |
| `setFilter()` | Bỏ bộ lọc `trending` nếu không có nguồn tương đương. |
| `loadMore()`, `retryLoadMore()` | Thiết kế lại theo phân trang UI, không giả định Binance có `page`. |
| `dispose()` | Giải phóng subscription/kết nối theo quyền sở hữu. |

Kiểm thử sort, số thiếu, các quote khác nhau, delta từng cặp và reconnect.
