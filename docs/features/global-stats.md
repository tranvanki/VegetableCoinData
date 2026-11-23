# Tổng quan thị trường

## Hiện tại

`GlobalProvider` và `MarketRepository` dùng CoinGecko `/global`,
`/coins/categories` và `/coins/markets` cho vốn hóa, thống kê, nhóm ngành và
biến động. Đây là dữ liệu toàn thị trường theo nguồn CoinGecko, không phải
thống kê Binance.

## Sau khi chuyển chỉ Binance

Binance Spot market data trong phạm vi kế hoạch không cung cấp thay thế tương
đương cho tổng vốn hóa toàn cầu, BTC dominance, phân loại ngành, xếp hạng vốn
hóa hay coin xu hướng tìm kiếm. Không cộng vốn hóa giả hoặc gắn nhãn khối
lượng một sàn là toàn cầu. Ẩn/đánh dấu không khả dụng các khối này cho đến
khi có quyết định sản phẩm.

Nếu sản phẩm muốn thay màn bằng **tổng quan Binance Spot**, cần phê duyệt rõ
phạm vi cặp, quote, cách tính và nhãn. Tổng quote volume chỉ có nghĩa khi cùng
đơn vị, không đại diện toàn thị trường; nhiều cặp có thể trùng base asset.
Đây là thay đổi chức năng, không phải thay endpoint tương đương.

## Hàm cần đánh giá

`GlobalProvider.init()`, `refresh()` và các hàm tổng hợp đang phụ thuộc
CoinGecko cần được bỏ hoặc thiết kế lại theo sản phẩm được chọn. Kiểm thử
không hiển thị số toàn cầu sai và xử lý lỗi từng nguồn khi tính năng mới được
phê duyệt.
