# Danh sách theo dõi

## Hiện tại

`WatchListProvider` đọc và lưu CoinGecko coin ID qua `LocalStorage`, lấy giá
bằng `MarketRepository.getMarkets(coinIds: ...)`. Màn hình và màn chọn coin
đã có; giá vẫn là snapshot CoinGecko. `toggleCoin`, `addCoin`, `removeCoin`,
`load` và `refresh` là các phương thức hiện có.

## Dự kiến Binance

1. Mỗi mục theo dõi phải xác định một **cặp**, ví dụ `BTCUSDT`, thay vì ID
   coin. Lấy thông tin cặp hợp lệ từ `exchangeInfo`, lấy ticker snapshot rồi
   cập nhật bằng stream; vẫn lưu danh sách cục bộ.
2. Thiết kế migration có phiên bản: giữ nguyên dữ liệu cũ; chỉ tự ánh xạ khi
   có ánh xạ được kiểm chứng duy nhất và quote được chọn rõ ràng. Không suy
   đoán từ symbol trùng tên. Mục mơ hồ, không niêm yết hoặc thiếu cặp phải
   được giữ lại và cho người dùng chọn/xử lý; lỗi lưu không được xóa bản gốc.
3. Khi thêm/bỏ mục, cập nhật subscription theo tập cặp thực sự cần; không làm
   mất kết nối của màn hình khác cùng dùng service. Bị hủy niêm yết phải hiện
   rõ trạng thái, không âm thầm xóa.
4. Hiện `—` hoặc trạng thái stale khi chưa có giá; không biến giá thiếu thành
   0. Ghi rõ USDT/quote thay vì hiển thị mặc định là USD.

## Hàm cần điều chỉnh

`init()`/`load()` đọc và chuyển đổi dữ liệu an toàn; `toggleCoin()`/`addCoin()`
và `removeCoin()` cập nhật cặp + lưu trữ; `refresh()` đồng bộ snapshot;
`dispose()` hủy subscription thuộc provider. Tên cụ thể có thể thay đổi khi
thiết kế model.

Kiểm thử dữ liệu cũ, trùng symbol, cặp không khả dụng, lưu thất bại, thêm/bỏ,
reconnect và việc nhiều màn hình cùng theo dõi một cặp.
