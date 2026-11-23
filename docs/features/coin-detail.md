# Chi tiết cặp giao dịch

## Hiện tại

Chi tiết coin và route chi tiết chưa được nối như một tính năng hoàn chỉnh.
Thiết kế CoinGecko cũ dùng `/coins/{id}` và `/market_chart`; không xem là API
Binance hiện hữu.

## Dự kiến Binance

- Nếu xây dựng màn chi tiết, định danh bằng symbol cặp Spot được xác thực
  trong `exchangeInfo`, ví dụ `BTCUSDT`; hiển thị `BTC/USDT`.
- Snapshot 24h lấy từ `/api/v3/ticker/24hr`, giá live từ ticker stream;
  biểu đồ dùng [klines](market-chart.md).
- Tên đầy đủ, logo, mô tả, website, contract, cung, ATH/ATL và vốn hóa toàn
  cầu không có nguồn tương đương trong bộ endpoint dự kiến. Ẩn/đánh dấu
  không có dữ liệu, không điền 0 hoặc suy ra từ một cặp.
- Chia sẻ/deep link cần thiết kế lại để dùng định danh cặp; không dùng URL
  CoinGecko như thể là URL Binance.

## Hàm dự kiến

`init(symbol)` kiểm tra cặp và nạp snapshot; `setRange()` tải nến; xử lý
ticker gộp theo symbol; `refresh()` đồng bộ; `dispose()` giải phóng tài nguyên.
Kiểm thử symbol không hợp lệ, cặp ngừng giao dịch, lỗi một phần và điều hướng.
