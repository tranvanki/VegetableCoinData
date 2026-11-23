# Điều hướng

## Hiện tại

`AppRouter` dùng `StatefulShellRoute.indexedStack` với bốn nhánh theo thứ tự:
`/home`, `/watchlist`, `/market`, `/global`. `MainShell` và router phải giữ
thứ tự tab đồng nhất. Có route chọn watchlist và cài đặt ngoài shell.

## Chuẩn bị Binance

- Chuyển tab không tự tạo thêm kết nối socket cho mỗi lần build; chủ sở hữu
  service và subscriptions được mô tả trong
  [kiến trúc](../architecture/repositories-providers.md).
- Indexed stack có thể giữ các màn hình sống khi tab bị ẩn; quyết định rõ
  subscription nào tiếp tục chạy và hủy khi không còn người dùng.
- Màn toàn cầu cần quyết định ẩn hoặc thiết kế lại vì dữ liệu Binance Spot
  không tương đương. Việc đổi số lượng/thứ tự tab phải cập nhật router và
  thanh điều hướng đồng bộ.
- Route chi tiết cặp là dự kiến; xác thực symbol và mã hóa tham số khi bổ
  sung. Không xem route chi tiết CoinGecko là đã tồn tại.
- Kiểm thử điều hướng giữa tab, vào/ra màn chọn, vòng đời provider và
  foreground/background; tránh đóng socket dùng chung quá sớm.
