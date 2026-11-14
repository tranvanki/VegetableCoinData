# CryptoCoin.MobileApp

Ứng dụng di động (Flutter) cung cấp thông tin thị trường Bitcoin và tiền điện tử thời gian thực, sử dụng hoàn toàn **Free CoinGecko API**.

Kiến trúc chuẩn **MVVM + Provider**, không sử dụng cơ sở dữ liệu cục bộ (No DB/SQL), áp dụng Dependency Injection bằng `get_it`, định tuyến bằng `go_router`, và mọi lệnh gọi mạng trả về `Result<T>` để xử lý lỗi an toàn.

> **View chỉ hiển thị – Provider điều phối – Repository gọi CoinGecko API – Model giữ dữ liệu.**

---

## 1. Scope & Phạm vi dự án

- **Chỉ đọc và hiển thị (Read-only):** Lấy dữ liệu thông tin thị trường, danh sách coin, giá thời gian thực, và biểu đồ lịch sử để hiển thị cho người dùng.
- **Nguồn dữ liệu duy nhất:** Kết nối trực tiếp tới **CoinGecko Free REST API** (`https://api.coingecko.com/api/v3`), không thông qua Backend Intermediate/BFF.
- **Không lưu trữ cơ sở dữ liệu (No DB/SQL):** Không sử dụng SQLite, Hive, Isar hay bất kỳ cơ sở dữ liệu quan hệ/phi quan hệ nào. Dữ liệu được quản lý hoàn toàn trên bộ nhớ tạm (In-Memory State) và polling cập nhật trực tiếp từ API.

---

## 2. Kiến trúc & Công nghệ

- **Framework:** Flutter 3.32+ / Dart 3.6+
- **Pattern:** MVVM (Model - View - ViewModel) + Provider (`MultiProvider` / `ChangeNotifier`)
- **Dependency Injection (DI):** `get_it` làm Service Locator chính
- **Navigation:** `go_router` hỗ trợ định tuyến khai báo và truyền tham số (ví dụ: chuyển từ danh sách tới chi tiết coin)
- **Networking:** `dio` với cấu hình Interceptor, Debouncer, xử lý timeout và tỷ lệ giới hạn (Rate Limit 429) của CoinGecko Free Tier
- **Error Handling:** Pattern `Result<T>` (`Ok` / `Err`) loại bỏ ngoại lệ `throw` xuyên suốt các tầng ứng dụng

---

## 3. Cấu trúc thư mục

```text
lib/
├─ main.dart                  # Khởi chạy ứng dụng và bootstrap DI
├─ app/
│  ├─ app.dart                # MaterialApp.router + Theme (Dark/Light crypto) + i18n
│  ├─ app_bootstrap.dart      # runZonedGuarded, đăng ký DI, khởi tạo dịch vụ
│  ├─ di/
│  │  ├─ service_locator.dart # Đăng ký get_it cho Repository, DioApiClient và ViewModel
│  │  └─ app_providers.dart   # Cấu hình MultiProvider toàn cục
│  ├─ router/
│  │  └─ app_router.dart      # Định tuyến go_router (Home Market -> Coin Detail -> Search)
│  └─ theme/                  # Bảng màu tài chính (Xanh tăng/Đỏ giảm), Typography, CardTheme
├─ core/
│  ├─ config/                 # AppConfig, AppConstants (API Base URL, Polling Interval)
│  ├─ error/                  # Failure, FailureKind, ErrorMapper (Xử lý lỗi API 429 Rate Limit, 500, Mất mạng)
│  ├─ network/                # ApiClient, DioApiClient, CoinGecko Endpoints
│  ├─ result/                 # Result<T> (Ok / Err functional pattern)
│  └─ utils/                  # Logger, Currency/Percent Formatters ($#,##0.00, +/-%), Debouncer
├─ data/
│  ├─ models/                 # DTOs (CoinModel, MarketChartModel, GlobalStatsModel, CoinDetailModel)
│  └─ repositories/           # CryptoRepository (thực thi gọi CoinGecko API)
├─ providers/                 # ViewModel (ChangeNotifier), kế thừa BaseViewModel (MarketProvider, CoinDetailProvider)
├─ views/
│  ├─ screens/                # Màn hình danh sách thị trường, chi tiết coin, tìm kiếm
│  └─ widgets/                # Widget dùng chung (Card coin, biểu đồ mini sparkline, trạng thái loading/error/empty)
└─ i18n/                      # File ngôn ngữ (vi_VN.json, en_US.json)
```

---

## 4. Hướng dẫn chạy dự án

### Yêu cầu môi trường
- **Flutter SDK:** 3.32.0 trở lên
- **Dart SDK:** 3.6.0 trở lên

### Lệnh chạy ứng dụng

1. Tải các gói phụ thuộc:
```powershell
flutter pub get
```

2. Chạy ứng dụng ở chế độ Debug:
```powershell
flutter run
```

3. Kiểm tra mã nguồn và chạy Test:
```powershell
flutter analyze
flutter test
```

4. Biệt dịch Release:
```powershell
# Chạy cho Android
flutter build apk --release

# Chạy cho iOS (Yêu cầu macOS & Xcode)
flutter build ipa --release
```

---

## 5. Tích hợp CoinGecko API

Ứng dụng sử dụng các endpoint miễn phí từ CoinGecko:

| Chức năng | Endpoint | Mô tả |
| --- | --- | --- |
| **Danh Sách Token** | `GET /coins/list` | danh sách các coin/token  |
| **Bảng giá thị trường** | `GET /coins/markets` | Lấy danh sách Top coin theo vốn hóa, giá thực, biến động 24h |
| **Chi tiết Đồng coin** | `GET /coins/{id}` | Lấy thông tin chi tiết, tổng cung, vốn hóa, giá cao/thấp 24h |
| **Biểu đồ lịch sử** | `GET /coins/{id}/market_chart` | Lấy dữ liệu giá biến động theo các mốc (1 ngày, 7 ngày, 30 ngày) |
| **Tìm kiếm Coin** | `GET /search` | Tìm kiếm coin/token theo tên hoặc mã symbol (`?query=`) |
| **Xu hướng** | `GET /search/trending` | Top coin đang được tìm kiếm nhiều |
| **Toàn cảnh thị trường** | `GET /global` | Vốn hóa, khối lượng và tỷ trọng BTC toàn thị trường |


---

## 6. Quy ước Mã nguồn & Xử lý Lỗi

- **Không dùng `throw`:** Các hàm tại Repository luôn trả về `Result<T>`. Ví dụ: `Result<List<CoinModel>>`.
- **Định dạng hiển thị:** Tất cả giá trị tiền tệ và phần trăm phải dùng định dạng chuẩn trong `core/utils/formatters.dart` (Ví dụ: `$65,420.50`, `+3.45%`).
- **Xử lý Rate Limit (429):** Free API của CoinGecko có giới hạn lượt gọi (10-30 req/phút). `ErrorMapper` sẽ chuyển đổi lỗi 429 thành thông báo tiếng Việt gợi ý người dùng đợi trước khi làm mới.