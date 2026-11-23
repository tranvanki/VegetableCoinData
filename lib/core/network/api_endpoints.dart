/// Bản đồ đường dẫn API CoinGecko. Đây là NƠI DUY NHẤT chứa path —
/// repository không tự nối chuỗi.
///
/// Chỉ khai báo endpoint có thật trong CoinGecko v3; app không có backend
/// riêng nên không còn nhóm `/system/*`.
class ApiEndpoints {
  const ApiEndpoints._();

  static const String coinsList = '/coins/list';
  static const String search = '/search';
  // Lấy danh sách cặp và trạng thái giao dịch
  static const String exchangeInfor =
      'https://data-api.binance.vision/api/v3/exchangeInfo';
  // --- Tab 1 "Tiền mã hoá" (MarketScreen) ----------------------------------
  /// Bảng xếp hạng coin; `ids=` để lọc theo danh sách (Xu thế, Theo dõi).
  static const String coinMarkets = '/coins/markets';

  /// Thẻ vốn hoá / khối lượng 24h toàn thị trường.
  static const String global = '/global';

  /// Bộ lọc "Xu thế": top coin được tìm kiếm nhiều nhất trong 24h.
  static const String trending = '/search/trending';

  // --- Tab 2 "Theo dõi" (WatchlistScreen) ----------------------------------
  // Giá danh mục dùng `coinMarkets` với `ids=`. `simplePrice` là phương án
  // nhẹ hơn khi chỉ cần giá để định giá danh mục (số lượng × giá).
  static const String simplePrice = '/simple/price';

  // --- Tab 3 "Tổng quan thị trường" (GlobalScreen) -------------------------
  /// Nhóm ngành kèm vốn hoá, biến động 24h và 3 coin đầu.
  /// "Biến động hôm nay" dùng lại `coinMarkets` + `global`.
  static const String coinCategories = '/coins/categories';

  static String coinDetail(String coinId) => '/coins/$coinId';
  static String marketChart(String coinId) => '/coins/$coinId/market_chart';
}
