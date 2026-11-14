# Global Stats (tab "Tổng quan thị trường")

Screen: `lib/views/screens/globalStats/global_screen.dart`.
Provider: `lib/providers/global_provider.dart` (`GlobalProvider`, `MarketOverview`).
Repository: `MarketRepository` (`getGlobalStats`, `getCategories`, `getMarkets`) — KHÔNG dùng `SystemRepository`
(chỉ đọc cache `RemoteConfig`, không gọi mạng).
Khuôn dựng: xem `docs/architecture/repositories-providers.md`.

## Workflow
1. Screen mở → `GlobalProvider.init()` → `runInitial`; loading.
2. `_fetch` gọi song song 3 endpoint: `GET /global`, `GET /coins/categories`, `GET /coins/markets?sparkline=true`.
3. `/global` parse bởi `GlobalStats.fromJson` (bóc lớp `data`); cache RAM 60s trong repository.
4. "Biến động hôm nay" = 10 coin có |`price_change_percentage_24h`| lớn nhất, sắp ở phía client
   (CoinGecko không sắp theo % 24h). Sparkline là 7 ngày.
5. Nhóm ngành = 10 nhóm đầu của `/coins/categories` (đã sắp theo vốn hoá).
6. Một request lỗi → khối tương ứng bị ẩn + dòng "Một số mục chưa tải được"; cả ba lỗi → `ErrorView`.
7. Pull-to-refresh → `refresh()` (`runAction`), giữ số liệu cũ khi lỗi.

## Files
| File | Purpose |
|---|---|
| `lib/data/model/system/global_stats.dart` | `GlobalStats` (vốn hoá, khối lượng theo tiền tệ, tỷ trọng, % 24h USD). |
| `lib/data/model/crypto/coin_category.dart` | `CoinCategory` (vốn hoá, % 24h, logo 3 coin đầu). |
| `lib/data/repository/market_repository.dart` | `getGlobalStats`, `getCategories`, `getMarkets`. |
| `lib/core/network/api_endpoints.dart` | `global`, `coinCategories`, `coinMarkets`. |
| `lib/providers/global_provider.dart` | Gộp 3 nguồn thành `MarketOverview`. |
| `lib/views/widgets/sparkline.dart` | Biểu đồ nhỏ 7 ngày. |

## Bước sau
- Văn bản tổng quan vĩ mô (nút Expand), thanh "Tin tức"/"Tìm hiểu", tiêu đề/đoạn trích tin trên thẻ coin:
  cần nguồn tin — KHÔNG có trong `all_api_formatted.md`.
- Chạm thẻ coin/nhóm ngành → màn chi tiết (chưa có route).
- Tự làm mới 60s (`Timer.periodic`, huỷ ở `dispose`).
