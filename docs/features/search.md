# Tìm kiếm

## Hiện tại

`SearchProvider` gọi CoinGecko `/search` để lấy gợi ý tên; debounce và hủy
request cũ, lưu lịch sử qua `LocalStorage`. Token list cũng lọc cục bộ theo
tên, symbol, ID CoinGecko.

## Dự kiến Binance

- Lấy danh sách cặp Spot từ `exchangeInfo`, tìm cục bộ theo `symbol`,
  `baseAsset`, `quoteAsset`; không mô tả đây là tìm mọi token hay tên đầy đủ.
- Lọc theo chính sách quote/trạng thái đã chọn, giới hạn kết quả hiển thị và
  debounce để tránh xử lý lặp trên danh sách lớn.
- Giữ lịch sử tìm kiếm cũ an toàn; từ khóa cũ có thể không có kết quả trong
  danh mục cặp mới. Điều hướng bằng symbol của cặp khi có màn chi tiết.
- Hiển thị loading/error khi chưa tải được danh mục; kết quả rỗng không có
  nghĩa API đã lỗi. Không dùng `/search/trending` sau khi bỏ CoinGecko.

## Hàm liên quan

`onKeywordChanged()` thay gợi ý CoinGecko bằng lọc danh mục đã tải;
`submit()`, `removeRecent()`, `clearRecent()` tiếp tục quản lý lịch sử.
Khi bổ sung tác vụ bất đồng bộ, bỏ kết quả cũ và hủy khi dispose.
Kiểm thử chữ hoa/thường, nhiều cặp cùng base, dữ liệu rỗng và lỗi tải.
