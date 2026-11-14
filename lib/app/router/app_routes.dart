/// Tên và đường dẫn route. Luôn điều hướng bằng hằng số ở đây, không gõ
/// chuỗi path rải rác trong màn hình.
class AppRoutes {
  const AppRoutes._();

  // --- Khởi động ---------------------------------------------------------
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String maintenance = '/maintenance';
  static const String forceUpdate = '/force-update';

  // --- Xác thực ----------------------------------------------------------
  static const String login = '/auth/login';

  // --- Tab chính (StatefulShellRoute) ------------------------------------
  // Thứ tự dưới đây PHẢI khớp thứ tự item trong BottomNavigationBar của
  // MainShell: 0 home · 1 watchlist · 2 market · 3 global.
  static const String home = '/home';
  static const String watchlist = '/watchlist';
  static const String market = '/market';
  static const String global = '/global';

  /// Màn chọn nhiều coin thêm vào tab Theo dõi — nằm ngoài shell để che
  /// bottom nav, không dùng path lồng trong `/watchlist` của branch.
  static const String watchlistSelect = '/watchlist-select';

  // --- Route cũ / deep link (giữ lại, chưa dùng trong shell) --------------
  static const String catalog = '/catalog';
  static const String cart = '/cart';
  static const String notifications = '/notifications';
  static const String account = '/account';
  static const String chart = '/chart';

  // --- Mua sắm -----------------------------------------------------------
  static const String search = '/search';
  static const String productList = '/products';
  static const String productDetail = '/product';
  static const String flashSale = '/flash-sale';

  // --- Thanh toán --------------------------------------------------------
  static const String checkout = '/checkout';
  static const String checkoutAddress = '/checkout/address';
  static const String payment = '/checkout/payment';
  static const String orderSuccess = '/checkout/success';

  // --- Đơn hàng ----------------------------------------------------------
  static const String orders = '/orders';
  static const String orderDetail = '/orders/detail';
  static const String orderLookup = '/orders/lookup';

  // --- Tài khoản ---------------------------------------------------------
  static const String member = '/member';
  static const String profile = '/account/profile';
  static const String addressBook = '/account/addresses';
  static const String addressEdit = '/account/addresses/edit';
  static const String rank = '/account/rank';
  static const String vouchers = '/account/vouchers';
  static const String wishlist = '/account/wishlist';
  static const String settings = '/account/settings';

  // --- Dịch vụ -----------------------------------------------------------
  static const String reviewCreate = '/review/create';
  static const String memberComment = 'comment';
  static const String warranty = '/warranty';
  static const String storeLocator = '/stores';
  static const String support = '/support';

  // --- Khác --------------------------------------------------------------
  static const String webview = '/webview';
  static const String productReviews = '/product/reviews';

  //---Member
  static const memberOverview = '/member';
  static const memberHistory = '/member/history';
  static const memberProfile = '/member/profile';
  static const memberComments = '/member/comments';
  static const memberReviews = '/member/reviews';

  // ---------------------- Dựng path có tham số ---------------------------

  static String coinMarketPath(String vsCurrency) => '$market/$vsCurrency';

  // static String coinMarketPath({String? vsCurrency, String? symbol}) {
  //   final params = <String, String>{
  //     if (categorySlug != null && categorySlug.isNotEmpty)
  //       'category': categorySlug,
  //     if (keyword != null && keyword.isNotEmpty) 'q': keyword,
  //   };
  //   if (params.isEmpty) return productList;
  //   final query = params.entries
  //       .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
  //       .join('&');
  //   return '$productList?$query';
  // }

  //
  static String productReviewsPath(String productId) =>
      '$productReviews/$productId';
  //ProductReviewsScreen get all review
  /// [orderCode] là `Order.UID` mà `GET /api/order/list` trả về.
  static String orderDetailPath(String orderCode) => '$orderDetail/$orderCode';

  static String orderSuccessPath(String orderUid) => '$orderSuccess/$orderUid';

  static String reviewCreatePath(String productId) =>
      '$reviewCreate/$productId';

  static String webviewPath(String url, {String title = ''}) =>
      '$webview?url=${Uri.encodeComponent(url)}'
      '${title.isEmpty ? '' : '&title=${Uri.encodeComponent(title)}'}';
}
