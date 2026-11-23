# Ứng dụng thông tin thị trường tiền mã hóa

Ứng dụng Flutter chỉ đọc dữ liệu thị trường. Tài liệu này mô tả hiện trạng và
kế hoạch chuyển sang **Binance Spot**; việc chuyển đổi **chưa được triển khai**.

## Hiện trạng

- Mã hiện tại dùng CoinGecko REST qua `DioApiClient`, `CoinRepository` và
  `MarketRepository`. `ApiEndpoints` và cấu hình hiện vẫn là CoinGecko.
- Dự án dùng Provider/ChangeNotifier, `get_it`, `go_router` và `Result<T>`.
  Watchlist và một số tùy chọn được lưu cục bộ bằng `LocalStorage`.
- Bản sửa đang làm ở token list vẫn gọi CoinGecko, nạp `TokenModel` rồi thay
  danh sách bằng `CoinMarketModel` khi polling. Đây là hai kiểu khác nhau;
  cần sửa trước khi đưa vào sử dụng.

## Mục tiêu: chỉ Binance

| Nhu cầu | Thiết kế dự kiến | Giới hạn |
|---|---|---|
| Danh sách, tìm kiếm | REST `exchangeInfo`, lọc cặp Spot cục bộ | Là danh sách cặp giao dịch, không phải toàn bộ coin/token. |
| Giá và 24h | REST ticker ban đầu + WebSocket Streams | Giá và khối lượng thuộc một cặp trên Binance, không phải toàn thị trường. |
| Biểu đồ | REST klines + stream kline của cặp | Chỉ có lịch sử giao dịch của cặp trên Binance. |
| Watchlist | Lưu symbol của cặp, nhận ticker tương ứng | Cần chuyển đổi dữ liệu ID CoinGecko cũ, không xóa dữ liệu không ánh xạ được. |
| Vốn hóa, xếp hạng, tỷ trọng BTC, ngành, coin xu hướng | Chưa có nguồn tương đương trong Binance Spot market data | Không giả lập bằng dữ liệu sàn; cần thay đổi hoặc ẩn tính năng. |
| Tên đầy đủ, logo, mô tả, contract, nguồn cung | Chưa có nguồn tương đương trong các endpoint dự kiến | Không hứa thay thế; hiển thị rõ dữ liệu không có. |

USDT không phải USD: nhãn và định dạng phải thể hiện đúng quote asset
(`BTC/USDT`), không tự nhận là giá USD.

## Tài liệu

- [Endpoint và hợp đồng Binance dự kiến](all_api_formatted.md).
- [Kiến trúc repository/provider và vòng đời kết nối](docs/architecture/repositories-providers.md).
- [Danh sách tài liệu chức năng](docs/features/home.md), gồm
  [token list](docs/features/token-list.md), [thị trường](docs/features/market.md),
  [theo dõi](docs/features/watchlist.md), [tìm kiếm](docs/features/search.md),
  [chi tiết](docs/features/coin-detail.md), [biểu đồ](docs/features/market-chart.md),
  [tổng quan](docs/features/global-stats.md) và [điều hướng](docs/features/navigation-shell.md).
- [Kế hoạch ban đầu](binance_plan.md) nói về **WebSocket API** dạng request/response;
  giá đẩy liên tục dùng **WebSocket Streams**, là giao thức/địa chỉ khác.

## Cách chạy và kiểm tra

Cần Flutter SDK tương thích với ràng buộc Dart trong `pubspec.yaml`
(`>=3.6.0 <4.0.0`).

```powershell
flutter pub get
flutter run
flutter analyze
flutter test
```

Sau khi triển khai, kiểm thử snapshot, stream, reconnect, trạng thái mạng và
chuyển dữ liệu watchlist bằng fake server; kiểm tra thực tế trên Android/iOS
và mạng/địa bàn triển khai. Không coi việc có kết nối Internet là bảo đảm
Binance có thể truy cập.

## Nguồn tham khảo

- [Binance Spot WebSocket Streams](https://github.com/binance/binance-spot-api-docs/blob/master/web-socket-streams.md)
- [Binance Spot REST API](https://github.com/binance/binance-spot-api-docs/blob/master/rest-api.md)
- [Binance Spot WebSocket API](https://github.com/binance/binance-spot-api-docs/blob/master/web-socket-api.md)
- [Flutter: giao tiếp WebSocket](https://docs.flutter.dev/cookbook/networking/web-sockets)
