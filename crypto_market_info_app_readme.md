# Ứng dụng thông tin thị trường tiền mã hóa

Ứng dụng Flutter chỉ đọc dữ liệu thị trường, phát triển theo kiến trúc **MVVM + Dependency Injection (`get_it`) + Provider**.  
Tài liệu này mô tả hiện trạng, chuẩn kiến trúc bắt buộc và kế hoạch chuyển đổi nguồn dữ liệu sang **Binance Spot** *(việc chuyển đổi chưa được triển khai)*.

---

## 1. Kiến trúc hệ thống (MVVM · DI · Provider · ApiEndpoints)

Ứng dụng tuân thủ chặt chẽ luồng dữ liệu một chiều và phân tách trách nhiệm theo mô hình **MVVM**:

```text
View (Widget) ──▶ Provider (ViewModel) ──▶ Repository ──▶ ApiClient / Stream ──▶ Binance / CoinGecko
      ▲                    │                    │
      └── notifyListeners ─┴── Result<T> (Ok/Err)
```

> **Nguyên tắc cốt lõi:** *View chỉ hiển thị – Provider điều phối trạng thái – Repository xử lý dữ liệu & lỗi – Model giữ dữ liệu thuần.*

### Phân tầng & Quy ước bắt buộc

* **Model (`data/models/`):**
  * Chứa các DTO/Model bất biến phản ánh dữ liệu từng nguồn (`TokenModel`, `CoinMarketModel`, và sắp tới là `BinanceTickerModel`, `BinanceKlineModel`).
  * **Không trộn lẫn kiểu dữ liệu giữa các tầng:** Lỗi hiện tại ở token list (nạp `TokenModel` ban đầu rồi ghi đè bằng `CoinMarketModel` khi polling) phải được xử lý dứt điểm bằng một domain model thống nhất trước khi chuyển sang Binance.
* **ApiEndpoints & Network (`core/network/`):**
  * **Tập trung toàn bộ đường dẫn REST và địa chỉ WebSocket Streams tại `ApiEndpoints`** — tuyệt đối không nối chuỗi URL rải rác trong Repository hay Provider.
  * Mọi lời gọi mạng qua `DioApiClient` hoặc kết nối stream đều được bọc bởi Repository và trả về `Result<T>` (`Ok` / `Err`), **không ném (`throw`) exception xuyên qua Repository lên UI**.
* **Dependency Injection (`app/di/service_locator.dart`):**
  * Toàn bộ dependency được khởi tạo và quản lý tập trung qua `get_it`:
    * **`registerLazySingleton`**: `AppConfig`, `DioApiClient`, `LocalStorage`, WebSocket stream client và các `Repository` (`CoinRepository`, `MarketRepository`...) để dùng chung kết nối và cache.
    * **`registerFactory`**: Các `Provider` (ViewModel) đặc thù theo màn hình (ví dụ: chi tiết cặp giao dịch, biểu đồ nến) để đảm bảo mỗi lần mở màn hình/route đều có vòng đời state độc lập, tránh xung đột dữ liệu giữa các cặp coin.
* **Provider / ViewModel (`providers/`):**
  * Kế thừa `ChangeNotifier`, nhận các `Repository` thông qua constructor (được inject bởi `get_it`).
  * Quản lý rõ các trạng thái hiển thị (`loading`, `ready`, `empty`, `error`), điều phối vòng đời kết nối snapshot REST + WebSocket Streams, và tự động hủy subscription khi `dispose()`.
  * View chỉ lắng nghe state qua `context.watch` / `Selector` và kích hoạt hành động qua `context.read`, **không chứa logic gọi API hay tính toán chuyển đổi dữ liệu**.

---

## 2. Hiện trạng hệ thống

* **Tầng dữ liệu & Endpoint:** Mã nguồn hiện tại đang gọi **CoinGecko REST** thông qua `DioApiClient`, `CoinRepository` và `MarketRepository`. Cấu hình môi trường và `ApiEndpoints` vẫn đang trỏ tới CoinGecko.
* **Hạ tầng kiến trúc:** Đã hoàn thiện khung `Provider` (`ChangeNotifier`), DI với `get_it`, điều hướng `go_router`, xử lý lỗi chuẩn hóa qua `Result<T>` và lưu trữ cục bộ bằng `LocalStorage` (cho Watchlist và tùy chọn người dùng).
* **Vấn đề tồn đọng cần sửa:** Bản sửa đang làm ở màn hình token list vẫn gọi CoinGecko, khởi tạo danh sách bằng `TokenModel` nhưng khi polling lại thay thế bằng `CoinMarketModel`. Đây là hai kiểu dữ liệu khác nhau, cần chuẩn hóa lại ở tầng Repository/Model trước khi đưa vào sử dụng hoặc tích hợp Binance.

---

## 3. Mục tiêu chuyển đổi: Chỉ dùng Binance Spot

Khi chuyển sang Binance Spot, các cấu hình endpoint sẽ được tách riêng trong `ApiEndpoints` (tách biệt **REST API** cho dữ liệu snapshot ban đầu và **WebSocket Streams** cho luồng giá đẩy liên tục), giữ nguyên interface phía View và cấu trúc Provider.

| Nhu cầu | Thiết kế dự kiến (Repository & ApiEndpoints) | Giới hạn dữ liệu (Xử lý ở Model / View) |
| :--- | :--- | :--- |
| **Danh sách, tìm kiếm** | Gọi REST `exchangeInfo`, lưu cache cục bộ và lọc danh sách cặp Spot trong Repository. | Chỉ là danh sách **cặp giao dịch** trên Binance, không phải toàn bộ coin/token trên thị trường. |
| **Giá và biến động 24h** | Nạp snapshot qua REST ticker ban đầu + lắng nghe cập nhật qua **WebSocket Streams** trong Provider. | Giá và khối lượng thuộc một cặp cụ thể trên Binance, không phản ánh toàn thị trường. |
| **Biểu đồ (Chart)** | Nạp lịch sử qua REST `klines` + nối tiếp nến thời gian thực qua stream `kline` của cặp. | Chỉ có lịch sử giao dịch của cặp đó trên sàn Binance. |
| **Watchlist** | Lưu `symbol` của cặp (ví dụ `BTCUSDT`) vào `LocalStorage`, đăng ký nhận ticker tương ứng. | Cần bước migration dữ liệu ID CoinGecko cũ; **không xóa** các mục cũ không ánh xạ được. |
| **Vốn hóa, xếp hạng, tỷ trọng BTC, ngành, coin xu hướng** | Chưa có nguồn tương đương trong Binance Spot market data. | Không giả lập bằng dữ liệu sàn; cần thay đổi thiết kế hoặc ẩn tính năng trên UI. |
| **Tên đầy đủ, logo, mô tả, contract, nguồn cung** | Chưa có nguồn tương đương trong các endpoint dự kiến của `ApiEndpoints`. | Không hứa hẹn dữ liệu thay thế; hiển thị rõ trạng thái không có dữ liệu. |

> **Lưu ý hiển thị tiền tệ:** `USDT` không phải `USD`. Nhãn và formatter trên View/Model phải thể hiện đúng quote asset (ví dụ: `BTC/USDT`), tuyệt đối không tự gắn nhãn là giá USD.

---

## 4. Tài liệu chi tiết

* [Endpoint và hợp đồng Binance dự kiến (`ApiEndpoints`)](all_api_formatted.md)
* [Kiến trúc Repository / Provider và vòng đời kết nối](docs/architecture/repositories-providers.md)
* [Kế hoạch ban đầu (`binance_plan.md`)](binance_plan.md) — *Lưu ý: kế hoạch cũ đề cập **WebSocket API** dạng request/response; luồng giá đẩy liên tục thực tế sẽ dùng **WebSocket Streams** (giao thức và base URL khác biệt trong `ApiEndpoints`).*
* **Danh sách tài liệu chức năng:**
  * [Trang chủ (Home)](docs/features/home.md) · [Token List](docs/features/token-list.md) · [Thị trường (Market)](docs/features/market.md)
  * [Theo dõi (Watchlist)](docs/features/watchlist.md) · [Tìm kiếm (Search)](docs/features/search.md) · [Chi tiết cặp (Coin Detail)](docs/features/coin-detail.md)
  * [Biểu đồ (Market Chart)](docs/features/market-chart.md) · [Tổng quan (Global Stats)](docs/features/global-stats.md) · [Điều hướng (Navigation Shell)](docs/features/navigation-shell.md)

---

## 5. Cách chạy và kiểm thử

Yêu cầu Flutter SDK tương thích với ràng buộc Dart trong `pubspec.yaml` (`>=3.6.0 <4.0.0`).

```powershell
flutter pub get
flutter run
flutter analyze
flutter test
```

### Quy trình kiểm thử sau khi triển khai
* **Kiểm thử tầng dữ liệu & Provider:** Dùng fake server / mock repository (inject qua `get_it`) để test đồng bộ snapshot REST + WebSocket stream, cơ chế reconnect, mất kết nối mạng và migration dữ liệu Watchlist từ CoinGecko sang Binance symbol.
* **Kiểm thử thực tế:** Chạy trên thiết bị Android/iOS thật và kiểm tra trực tiếp tại hạ tầng mạng/địa bàn triển khai (không mặc định có kết nối Internet là có thể truy cập được endpoint của Binance).

---

## 6. Nguồn tham khảo

* [Binance Spot WebSocket Streams](https://github.com/binance/binance-spot-api-docs/blob/master/web-socket-streams.md)
* [Binance Spot REST API](https://github.com/binance/binance-spot-api-docs/blob/master/rest-api.md)
* [Binance Spot WebSocket API](https://github.com/binance/binance-spot-api-docs/blob/master/web-socket-api.md)
* [Flutter Cookbook: Giao tiếp WebSocket](https://docs.flutter.dev/cookbook/networking/web-sockets)