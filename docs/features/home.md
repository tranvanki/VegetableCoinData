# Trang chủ

## Hiện tại

Điều hướng hiện dùng `HomeScreen` và `TokenList`; dữ liệu token/giá vẫn từ
CoinGecko. Một số mô tả Home trước đây chỉ là kế hoạch, không nên coi các
section hay `HomeProvider` là đã hoàn thành.

## Dự kiến Binance

- Hiển thị cặp Spot theo quote đã chọn từ `exchangeInfo`, snapshot giá và
  cập nhật stream. Tìm kiếm, nhãn giá và xử lý thiếu dữ liệu theo
  [token list](token-list.md).
- Các mục toàn cầu/xu hướng CoinGecko không có nguồn tương đương trong phạm
  vi Binance Spot; không tái hiện bằng giá trị suy đoán.
- Dữ liệu đã xem/lịch sử cũ cần được bảo toàn khi đổi từ coin ID sang symbol
  cặp; không tự gán cặp khi ánh xạ không rõ ràng.
- Khi không kết nối hoặc stream bị ngắt, giữ dữ liệu cũ có nhãn stale và cho
  phép thử lại; không báo live khi chưa đồng bộ thành công.

## Hàm cần điều chỉnh

Các hàm `TokenListProvider.init()`, `load()`, `refresh()` và `dispose()` cần
chuyển theo [kiến trúc](../architecture/repositories-providers.md).
Kiểm thử chuyển tab, foreground/background và dữ liệu cũ trong lưu trữ.

## Tài liệu chức năng

[Thị trường](market.md) · [Theo dõi](watchlist.md) · [Tìm kiếm](search.md) ·
[Chi tiết](coin-detail.md) · [Biểu đồ](market-chart.md) ·
[Tổng quan](global-stats.md) · [Điều hướng](navigation-shell.md).
