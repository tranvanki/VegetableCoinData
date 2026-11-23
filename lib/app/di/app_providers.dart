import 'package:hhmmobile/core/storage/local_storage.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../../core/config/app_config.dart';

import '../../providers/app_state_provider.dart';

// import '../../providers/notification_provider.dart';
import '../../providers/global_provider.dart';
import '../../providers/binance_market_view_model.dart';
import '../../providers/market_provider.dart';
import '../../providers/search_provider.dart';
import '../../providers/token_list_provider.dart';
import '../../providers/watchlist_provider.dart';
import '../../services/app_update_service.dart';
import '../../services/deep_link_service.dart';
import '../../services/shared_service.dart';
import 'service_locator.dart';

/// Danh sách provider cấp cho cây widget.
///
/// Phân tầng:
/// - **App-scoped** (`.value` từ get_it): phiên đăng nhập, giỏ hàng, cấu hình,
///   thông báo — phải sống xuyên màn hình.
/// - **Screen-scoped** (`create:` từ factory): ViewModel của từng màn hình.
///   Hiện đặt ở cấp app cho gọn khi dựng khung. Khi một màn hình cần state
///   độc lập (ví dụ mở hai trang chi tiết sản phẩm chồng nhau), bọc riêng
///   màn hình đó bằng `ChangeNotifierProvider(create: (_) => sl<XProvider>())`
///   trong `builder` của route tương ứng và bỏ dòng tương ứng ở đây.
/// - **Service/Repository** (`Provider.value`): để View gọi trực tiếp vài
///   thao tác không cần ViewModel riêng (chia sẻ, mở bản đồ, tra bảo hành).
List<SingleChildWidget> buildAppProviders() => [
      // --- Hạ tầng chỉ đọc ----------------------------------------------
      Provider<AppConfig>.value(value: sl<AppConfig>()),
      Provider<LocalStorage>.value(value: sl<LocalStorage>()),
      Provider<ShareService>.value(value: sl<ShareService>()),
      Provider<AppUpdateService>.value(value: sl<AppUpdateService>()),
      Provider<DeepLinkService>.value(value: sl<DeepLinkService>()),

      // --- App-scoped ----------------------------------------------------
      ChangeNotifierProvider<AppStateProvider>.value(
        value: sl<AppStateProvider>(),
      ),

      // ChangeNotifierProvider<NotificationProvider>.value(
      //   value: sl().get<NotificationProvider>(),
      // ),

      // --- Screen-scoped --------------------------------------------------
      // ChangeNotifierProvider<HomeProvider>(create: (_) => sl<HomeProvider>()),

      // ChangeNotifierProvider<ReviewProvider>(
      //   create: (_) => sl<ReviewProvider>(),
      // ),

      ChangeNotifierProvider<SearchProvider>(
        create: (_) => sl<SearchProvider>(),
      ),

      ChangeNotifierProvider<TokenListProvider>(
        create: (_) => sl<TokenListProvider>(),
      ),
      ChangeNotifierProvider<WatchListProvider>(
        create: (_) => sl<WatchListProvider>(),
      ),
      ChangeNotifierProvider<MarketProvider>(
        create: (_) => sl<MarketProvider>(),
      ),
      ChangeNotifierProvider<GlobalProvider>(
        create: (_) => sl<GlobalProvider>(),
      ),
      ChangeNotifierProvider<BinanceMarketViewModel>(
        create: (_) => sl<BinanceMarketViewModel>(),
      ),
      //changeNotifierProvider<ProductDetailProvider>(
      //create:(_) => sl<ProductDetailProvider> ()),
    ];
