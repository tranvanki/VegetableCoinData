import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hhmmobile/data/model/crypto/coin_market.dart';
import 'package:hhmmobile/views/widgets/common/app_widget.dart';
import 'package:hhmmobile/views/widgets/state/state_views.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/app_dimens.dart';
import '../../../providers/app_state_provider.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;
  void _onTap(BuildContext context, int index) {
    // Bấm lại tab đang mở thì về đầu stack của tab đó.
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    return Scaffold(
      body: Column(
        children: [
          if (!appState.isOnline) const OfflineBanner(),
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => _onTap(context, index),
        items: [
          //Home Screen
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Trang chủ',
          ),
          //token list screen
          // 2. Giỏ token / Watchlist (Dùng icon sao hoặc bookmark trực quan hơn giỏ hàng e-commerce)
          const BottomNavigationBarItem(
            icon: Icon(Icons.star_outline_rounded),
            activeIcon: Icon(Icons.star_rounded),
            label: 'Theo dõi',
          ),

          // 3. Tổng quan thị trường (Dùng icon biểu đồ tài chính thay vì giỏ hàng)
          const BottomNavigationBarItem(
            icon: Icon(Icons.show_chart_outlined),
            activeIcon: Icon(Icons.insights_rounded),
            label: 'Chart Thị trường',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.four_g_plus_mobiledata),
            activeIcon: Icon(Icons.public_rounded),
            label: 'Chỉ số toàn cầu',
          ),
        ],
      ),
    );
  }
}

/// Màn hình tạm cho các route đã khai báo nhưng chưa dựng UI.
/// Giữ lại để router không bao giờ trả về trang trắng trong lúc phát triển.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    super.key,
    required this.title,
    this.note = 'Màn hình này đang chờ phát triển.',
  });
  final String? title;
  final String note;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(note),
      ),
      body: Padding(
        padding: const EdgeInsetsGeometry.all(AppSpacing.screenPadding),
        child: EmptyView(
          title: title,
          message: note,
          icon: Icons.construction_rounded,
        ),
      ),
    );
  }
}
