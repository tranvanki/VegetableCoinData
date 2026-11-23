# API dữ liệu thị trường Binance Spot — hợp đồng dự kiến

> **Chưa triển khai:** mã ứng dụng vẫn dùng CoinGecko. Tài liệu này xác định
> endpoint cần đánh giá khi chuyển đổi, không khẳng định chúng đã được cấu hình.
> Tham số, trọng số và giới hạn có thể thay đổi; kiểm tra tài liệu Binance trước
> khi phát hành.

## Phân biệt ba giao diện

| Giao diện | Địa chỉ | Vai trò dự kiến |
|---|---|---|
| REST market data | `https://data-api.binance.vision` | Lấy danh sách cặp, snapshot và lịch sử. |
| WebSocket Streams market data | `wss://data-stream.binance.vision` | Nhận các thay đổi giá/nến liên tục. |
| WebSocket API | `wss://ws-api.binance.com:443/ws-api/v3` | Request/response theo `id`; không phải URL của Streams. Không cần cho thiết kế read-only dưới đây. |

Binance cũng công bố `https://api.binance.com` và
`wss://stream.binance.com:443` / `:9443`. Các host `data-*` chỉ dành cho dữ liệu
thị trường; kiểm tra khả năng truy cập tại từng thị trường và môi trường.
Testnet WebSocket API trong [kế hoạch ban đầu](binance_plan.md) là môi trường
khác, không phải nguồn giá production và không tự động thay thế URL Streams.

## REST snapshot và lịch sử

Các ví dụ ghép vào REST base ở trên, không yêu cầu khóa cho dữ liệu công khai.
`symbol` viết hoa và phải tồn tại trong `exchangeInfo`.

| Endpoint | Mục đích | Lưu ý |
|---|---|---|
| `GET /api/v3/exchangeInfo` | Danh mục symbol, `baseAsset`, `quoteAsset`, trạng thái và quy tắc | Không cung cấp danh mục coin toàn cầu hay tên/logo đầy đủ; lọc quyền Spot và trạng thái theo response. |
| `GET /api/v3/ticker/24hr?symbol=BTCUSDT` | Snapshot giá và thống kê 24h của cặp | `priceChangePercent`, `lastPrice`, `volume` (base), `quoteVolume` (quote) là chuỗi số. Không nhầm khối lượng cặp với toàn thị trường. |
| `GET /api/v3/ticker/price?symbol=BTCUSDT` | Snapshot giá mới nhất | Không có % thay đổi 24h. |
| `GET /api/v3/klines?symbol=BTCUSDT&interval=1h&limit=100` | Lịch sử nến | Mỗi phần tử là mảng; thời gian mở tính bằng mili giây, giá OHLC là chuỗi. Giới hạn/phân trang theo tài liệu Binance. |

Có thể lấy nhiều ticker theo tham số Binance hỗ trợ, nhưng trọng số phụ thuộc
số symbol và endpoint. Kiểm tra tài liệu trước khi chọn batch; không gọi
snapshot riêng cho hàng nghìn cặp. Tôn trọng `Retry-After` khi HTTP 429/418,
không retry dồn dập; lỗi và dữ liệu cũ phải được thể hiện rõ.

## WebSocket Streams

- Stream thô: `/ws/<streamName>`, ví dụ
  `wss://data-stream.binance.vision/ws/btcusdt@ticker`.
- Stream kết hợp: `/stream?streams=<stream1>/<stream2>`, ví dụ
  `wss://data-stream.binance.vision/stream?streams=btcusdt@ticker/ethusdt@ticker`.
  Payload kết hợp có dạng `{"stream":"btcusdt@ticker","data":{...}}`.
- Symbol trong **tên stream** viết thường; tên sự kiện và hậu tố phân biệt
  chữ hoa/thường. Symbol trong payload thường viết hoa.

| Stream | Dữ liệu | Nhịp công bố |
|---|---|---|
| `<symbol>@ticker` | Thống kê 24h rolling, gồm `c` giá cuối, `P` % thay đổi và `q` khối lượng quote | 1 giây |
| `!miniTicker@arr` | Mảng mini ticker các symbol **có thay đổi**, không phải snapshot đầy đủ | 1 giây |
| `<symbol>@kline_<interval>` | Cập nhật nến hiện tại; `k.t` thời gian mở, `k.c` giá đóng, `k.x` nến đã đóng | 1 giây với `1s`, 2 giây với các interval khác |

Với mini ticker, `c` là giá đóng gần nhất, `o` là giá mở 24h rolling, `v` là
khối lượng base và `q` là khối lượng quote. Không có trường `P`; nếu tính
`(c - o) / o * 100`, phải kiểm tra giá mở hợp lệ và khác 0. Ticker stream
không đại diện cho ngày UTC cố định. Timestamps mặc định là mili giây.

Có thể đăng ký động qua cùng kết nối:

```json
{"method":"SUBSCRIBE","params":["btcusdt@ticker"],"id":1}
```

Phản hồi `{"result":null,"id":1}` xác nhận lệnh thành công; phân biệt phản
hồi/lỗi điều khiển với sự kiện thị trường. `UNSUBSCRIBE` dùng cùng cấu trúc.
Chỉ cập nhật symbol có trong sự kiện, không xóa các symbol vắng mặt.

## Giới hạn và vòng đời

- Kết nối Streams có thời hạn 24 giờ; xử lý `serverShutdown`, ngắt mạng và
  kết nối lại có backoff + jitter, tránh tạo nhiều kết nối đồng thời.
- Server gửi ping mỗi 20 giây; phải trả pong có cùng payload trong vòng một
  phút. Kiểm chứng hành vi tự động của client trên từng nền tảng; không nhầm
  ping/pong frame với thông điệp JSON.
- Tối đa 5 thông điệp **đến server** mỗi giây mỗi kết nối, tính cả ping, pong
  và JSON điều khiển; tối đa 1024 stream/kết nối và 300 lần thử kết nối mỗi
  5 phút mỗi IP. Gộp lệnh đăng ký và dự phòng cho pong.
- Khi resume/reconnect: khôi phục subscriptions, lấy lại snapshot và đồng bộ
  sự kiện; xử lý sự kiện đến trong lúc snapshot đang tải theo thứ tự/version
  có thể xác minh, không ghi đè giá mới bằng snapshot cũ. Cho biết dữ liệu cũ
  hoặc mất kết nối.
- Đóng stream/subscription, timer và kết nối đúng vòng đời; không cập nhật
  provider sau dispose. Cân nhắc tạm dừng khi app background và kết nối lại
  khi foreground; phải kiểm tra thực tế với giới hạn hệ điều hành.

## Khác biệt so với CoinGecko

CoinGecko ID như `bitcoin` không phải Binance symbol như `BTCUSDT`; symbol
asset có thể trùng, đổi tên hoặc không có cặp được chọn. Không ghép chuỗi mù
để di chuyển watchlist. Không có endpoint tương đương `/global`,
`/coins/categories`, `/search/trending` hoặc `/coins/{id}` trong bộ market
data này. Không thể suy ra vốn hóa, thứ hạng, xu hướng tìm kiếm hay tỷ trọng
toàn cầu từ volume giao dịch Binance.

## Nguồn chính thức

- [Binance Spot Streams: payload, giới hạn và subscriptions](https://github.com/binance/binance-spot-api-docs/blob/master/web-socket-streams.md)
- [Binance Spot REST: exchangeInfo, ticker, klines và giới hạn](https://github.com/binance/binance-spot-api-docs/blob/master/rest-api.md)
- [Binance Spot WebSocket API](https://github.com/binance/binance-spot-api-docs/blob/master/web-socket-api.md)
- [Flutter WebSocket cookbook](https://docs.flutter.dev/cookbook/networking/web-sockets)
