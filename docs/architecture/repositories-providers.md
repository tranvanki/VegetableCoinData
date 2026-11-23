# Repository và Provider: chuẩn bị Binance Spot

## Trạng thái

Hiện tại `CoinRepository`, `MarketRepository`, `ApiClient` và `ApiEndpoints`
đang gọi CoinGecko. Các provider `TokenListProvider`, `MarketProvider`,
`GlobalProvider`, `WatchListProvider` và `SearchProvider` đã có trong mã.
Không có service Binance trong kiến trúc hiện tại. Các tên và bước dưới đây
là thiết kế dự kiến, không phải API đã tồn tại.

## Luồng dữ liệu dự kiến

`View → Provider → Repository → REST client / WebSocket service`.

1. REST lấy `exchangeInfo` và snapshot ticker cho tập cặp cần hiển thị.
2. Repository chuẩn hóa symbol, base/quote asset, giá và thời điểm cập nhật
   thành model **cặp giao dịch** có kiểu rõ ràng. Không trộn `TokenModel` với
   `CoinMarketModel` trong `List<dynamic>`.
3. Một service chia sẻ kết nối Streams; repository/provider đăng ký các symbol
   cần thiết và nhận thay đổi. Lớp View không tự mở socket.
4. Gộp từng cập nhật theo symbol vào snapshot, không thay cả danh sách bằng
   mảng delta. Điều phối snapshot và sự kiện đang đến để dữ liệu mới không bị
   ghi đè bởi snapshot cũ.
5. Provider giữ trạng thái kết nối, dữ liệu và lỗi; phân biệt loading, lỗi,
   dữ liệu cũ, reconnecting và live. Giới hạn tần suất notify/rebuild nếu cần.
6. Chia sẻ kết nối có chủ sở hữu rõ ràng; tránh nhiều provider mở kết nối
   trùng. Dispose hủy subscription/timer/request; đóng socket khi không còn
   người dùng. Không nhận callback sau dispose.

## Quyết định cần thực hiện

- Chọn quote asset, tập cặp Spot, thứ tự hiển thị và chính sách khi không có
  giao dịch. Không khẳng định USDT bằng USD.
- Xác định chiến lược snapshot + stream, đồng bộ sau reconnect, xử lý dữ liệu
  thiếu hoặc sai thứ tự và timestamp; tránh hứa bảo đảm không mất cập nhật khi
  chưa có cơ chế xác minh.
- Bảo toàn watchlist ID CoinGecko cũ; ánh xạ chỉ khi có bằng chứng duy nhất,
  lưu bản gốc và cho người dùng xử lý trường hợp mơ hồ/không tồn tại.
- Bỏ hoặc thiết kế lại tính năng không có nguồn Binance, không gán volume của
  một sàn thành vốn hóa/khối lượng toàn cầu.
- Cấu hình riêng REST và Streams; khi triển khai thêm hằng vào
  `lib/core/network/api_endpoints.dart` mà không phá các call site trước khi
  chúng được chuyển đổi. Không lưu khóa API trong app cho dữ liệu công khai.
- Cân nhắc `web_socket_channel` theo hướng dẫn Flutter; package này chưa được
  khai báo trực tiếp trong `pubspec.yaml`. Kiểm tra ping/pong native, lifecycle
  và khả năng hỗ trợ web trước khi chọn giải pháp.

## Hàm cần thiết kế và kiểm thử

| Chức năng dự kiến | Hợp đồng |
|---|---|
| Lấy danh sách cặp | Trả dữ liệu có kiểu; lọc Spot/trạng thái và quote bằng trường thực từ `exchangeInfo`. |
| Lấy snapshot ticker | Batch phù hợp trọng số; lỗi REST qua `Result`/`Failure`, tôn trọng 429/418 và `Retry-After`. |
| Theo dõi/hủy theo dõi | Gộp thay đổi subscription, kiểm tra ack/lỗi, không vượt giới hạn Streams. |
| Gộp cập nhật | Chỉ thay ticker của symbol tương ứng; xử lý số dạng chuỗi, dữ liệu thiếu và sự kiện cũ. |
| Ngắt/kết nối lại | Backoff + jitter, phục hồi subscription, đồng bộ snapshot, báo stale; giới hạn retry. |
| Đóng | Hủy tài nguyên và request đang chờ, kể cả khi init chưa hoàn tất. |

Kiểm thử bằng giả lập REST/socket: parse hợp lệ/không hợp lệ, delta không đầy
đủ, response chậm, lỗi/ack, reconnect, background/resume, dispose, rate limit,
và chuyển đổi watchlist không mất dữ liệu. Kiểm tra tích hợp trên thiết bị
trước khi bỏ CoinGecko.

Chi tiết endpoint: [tài liệu API](../../all_api_formatted.md).
