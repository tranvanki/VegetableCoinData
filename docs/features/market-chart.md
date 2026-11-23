# Biểu đồ thị trường

## Hiện tại

Tài liệu biểu đồ cũ mô tả một tính năng dự kiến dựa trên CoinGecko
`/coins/{id}/market_chart`; không coi đó là tích hợp Binance đang hoạt động.

## Dự kiến Binance

1. Chọn cặp Spot, khoảng thời gian hiển thị và interval nến; REST
   `/api/v3/klines` tải lịch sử. Giá OHLC là chuỗi, timestamp mặc định ms.
2. Theo dõi `<symbol>@kline_<interval>` để cập nhật nến đang mở. `k.t` xác
   định thời điểm mở; `k.x` cho biết nến đã đóng. Thay nến cùng thời điểm,
   thêm nến mới đúng thứ tự; không thêm trùng.
3. Khi đổi cặp/interval, hủy đăng ký cũ, bỏ response lỗi thời và tải lại.
   Sau reconnect tải lại lịch sử để bù khoảng trống; báo stale khi thất bại.
4. Giới hạn `limit`, dùng `startTime`/`endTime` theo tài liệu Binance khi cần
   lịch sử dài; chuyển đổi timezone ở UI, không đổi ý nghĩa timestamp.

## Hàm dự kiến

- `loadKlines(symbol, interval, ...)`: parse danh sách nến, báo lỗi rõ.
- `applyKline(event)`: kiểm tra symbol/interval và gộp theo thời gian mở.
- `setRange(...)`: ánh xạ range sang interval và thời gian truy vấn hợp lệ.
- `dispose()`: hủy stream, request và tài nguyên widget.

Kiểm thử nến đang mở/đóng, trùng hoặc đến muộn, đổi interval khi request đang
chạy, reconnect, mảng rỗng và chuỗi số không hợp lệ.
