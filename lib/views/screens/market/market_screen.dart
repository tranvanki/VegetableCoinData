import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_dimens.dart';
import '../../../core/utils/extensions/context_x.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/model/crypto/coin_market.dart';
import '../../../data/model/system/global_stats.dart';
import '../../../providers/base_view_model.dart';
import '../../../providers/market_provider.dart';
import '../../widgets/coin_logo.dart';
import '../../widgets/common/app_widget.dart';
import '../../widgets/price_change.dart';
import '../../widgets/state/state_views.dart';

/// Tab 1 — "Tiền mã hoá" (Markets) trong [MainShell].
///
/// Dữ liệu (qua [MarketProvider] → `MarketRepository`):
/// - `/global` → hai thẻ vốn hoá và khối lượng 24h.
/// - `/coins/markets` → bảng xếp hạng, phân trang 100 coin/trang.
/// - `/search/trending` → chip "Xu thế" (sau đó lấy giá bằng `ids=`).
///
/// Bước sau:
/// - Chạm một hàng để mở chi tiết coin: route `/coins/:id` và `CoinDetail`
///   chưa dựng ([_CoinRow] chưa có `onTap`).
/// - Chip "Trên chuỗi": dùng `/onchain/networks/trending_pools`, dữ liệu là
///   pool chứ không phải coin nên cần model và hàng riêng.
/// - Sparkline trong hai thẻ thống kê: cần lịch sử vốn hoá toàn cầu, không
///   có trong `all_api_formatted.md`. Thẻ thứ 3 ("Tóm tắt") cũng chưa có nguồn.
/// - Nút lọc/tinh chỉnh nâng cao và đổi tiền tệ hiển thị (USD/BTC/VND).
class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  /// Còn cách đáy danh sách bao nhiêu px thì nạp trang kế tiếp.
  static const double _loadMoreExtent = 400;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(context.read<MarketProvider>().init());
    });
  }

  Future<void> _refresh(MarketProvider viewModel) async {
    await viewModel.refresh();
    if (!mounted) return;
    context.showFailure(viewModel.failure);
    viewModel.clearFailure();
  }

  bool _onScroll(ScrollNotification notification, MarketProvider viewModel) {
    if (notification.metrics.extentAfter < _loadMoreExtent) {
      unawaited(viewModel.loadMore());
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MarketProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tiền mã hóa'),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            onPressed: viewModel.isBusy || viewModel.isLoading
                ? null
                : () => _refresh(viewModel),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => _refresh(viewModel),
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) =>
                _onScroll(notification, viewModel),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.screenPadding),
                    child: _GlobalStatsRow(global: viewModel.global),
                  ),
                ),
                SliverToBoxAdapter(child: _FilterBar(viewModel: viewModel)),
                SliverToBoxAdapter(child: _TableHeader(viewModel: viewModel)),
                ..._bodySlivers(viewModel),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _bodySlivers(MarketProvider viewModel) {
    return switch (viewModel.state) {
      ViewState.idle || ViewState.loading => const [
          SliverFillRemaining(
            hasScrollBody: false,
            child: LoadingView(message: 'Đang tải thị trường...'),
          ),
        ],
      ViewState.error => [
          SliverFillRemaining(
            hasScrollBody: false,
            child: ErrorView(
              failure: viewModel.failure,
              onRetry: viewModel.load,
            ),
          ),
        ],
      ViewState.empty => [
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyView(
              icon: Icons.local_fire_department_rounded,
              title: 'Chưa có dữ liệu',
              message: viewModel.filter == MarketFilter.trending
                  ? 'Hiện chưa có coin nào đang thịnh hành.'
                  : 'CoinGecko trả về danh sách rỗng.',
              actionLabel: 'Tải lại',
              onAction: viewModel.load,
            ),
          ),
        ],
      ViewState.ready => [
          SliverList.separated(
            itemCount: viewModel.coins.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) =>
                _CoinRow(coin: viewModel.coins[index]),
          ),
          SliverToBoxAdapter(child: _ListFooter(viewModel: viewModel)),
        ],
    };
  }
}

class _GlobalStatsRow extends StatelessWidget {
  const _GlobalStatsRow({required this.global});

  final GlobalStats? global;

  @override
  Widget build(BuildContext context) {
    final stats = global;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _StatCard(
              title: 'Giá trị vốn hóa thị trường toàn cầu',
              value: Formatters.usdCompact(stats?.totalMarketCap['usd']),
              change: stats?.marketCapChangePercentage24hUsd,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _StatCard(
              title: 'Khối lượng trong 24h',
              value: Formatters.usdCompact(stats?.totalVolume['usd']),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value, this.change});

  final String title;
  final String value;
  final double? change;

  @override
  Widget build(BuildContext context) {
    return AppWidget(
      color: context.isDarkMode
          ? AppColors.surfaceVariantDark
          : AppColors.surfaceVariant,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.textStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: context.textStyles.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          if (change != null) PriceChange(value: change),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.viewModel});

  final MarketProvider viewModel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Wrap(
        spacing: AppSpacing.sm,
        children: [
          ChoiceChip(
            label: const Text('Tất cả'),
            selected: viewModel.filter == MarketFilter.all,
            onSelected: (_) => viewModel.setFilter(MarketFilter.all),
          ),
          ChoiceChip(
            avatar: const Icon(Icons.local_fire_department_rounded, size: 18),
            label: const Text('Xu thế'),
            selected: viewModel.filter == MarketFilter.trending,
            onSelected: (_) => viewModel.setFilter(MarketFilter.trending),
          ),
        ],
      ),
    );
  }
}

/// Độ rộng/tỷ lệ cột dùng chung cho tiêu đề và hàng để hai bên luôn thẳng cột.
class _Columns {
  const _Columns._();

  static const double rank = 36;
  static const int coinFlex = 5;
  static const int priceFlex = 4;
  static const int changeFlex = 3;
  static const int capFlex = 4;
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({required this.viewModel});

  final MarketProvider viewModel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Row(
        children: [
          SizedBox(
            width: _Columns.rank,
            child: _SortHeader(
              label: '#',
              sort: MarketSort.rank,
              viewModel: viewModel,
              alignment: Alignment.centerLeft,
            ),
          ),
          Expanded(
            flex: _Columns.coinFlex,
            child: Text('Đồng tiền', style: context.textStyles.labelSmall),
          ),
          Expanded(
            flex: _Columns.priceFlex,
            child: _SortHeader(
              label: 'Giá',
              sort: MarketSort.price,
              viewModel: viewModel,
            ),
          ),
          Expanded(
            flex: _Columns.changeFlex,
            child: _SortHeader(
              label: '24 giờ',
              sort: MarketSort.change24h,
              viewModel: viewModel,
            ),
          ),
          Expanded(
            flex: _Columns.capFlex,
            child: _SortHeader(
              label: 'Vốn hóa',
              sort: MarketSort.marketCap,
              viewModel: viewModel,
            ),
          ),
        ],
      ),
    );
  }
}

class _SortHeader extends StatelessWidget {
  const _SortHeader({
    required this.label,
    required this.sort,
    required this.viewModel,
    this.alignment = Alignment.centerRight,
  });

  final String label;
  final MarketSort sort;
  final MarketProvider viewModel;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final isActive = viewModel.sort == sort;
    return InkWell(
      onTap: () => viewModel.setSort(sort),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Align(
          alignment: alignment,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: context.textStyles.labelSmall?.copyWith(
                    fontWeight: isActive ? FontWeight.w700 : null,
                  ),
                ),
                if (isActive)
                  Icon(
                    viewModel.ascending
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    size: 12,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CoinRow extends StatelessWidget {
  const _CoinRow({required this.coin});

  final CoinMarketModel coin;

  @override
  Widget build(BuildContext context) {
    final small = context.textStyles.bodySmall;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          SizedBox(
            width: _Columns.rank,
            child: Text('${coin.marketCapRank ?? '—'}', style: small),
          ),
          Expanded(
            flex: _Columns.coinFlex,
            child: Row(
              children: [
                CoinLogo(imageUrl: coin.image, symbol: coin.symbol, size: 24),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        coin.symbol.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textStyles.titleSmall,
                      ),
                      Text(
                        coin.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: small,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: _Columns.priceFlex,
            child: _NumberCell(text: Formatters.usd(coin.currentPrice)),
          ),
          Expanded(
            flex: _Columns.changeFlex,
            child: Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: PriceChange(
                  value: coin.priceChangePercentage24h,
                  style: small,
                ),
              ),
            ),
          ),
          Expanded(
            flex: _Columns.capFlex,
            child: _NumberCell(text: Formatters.usdCompact(coin.marketCap)),
          ),
        ],
      ),
    );
  }
}

class _NumberCell extends StatelessWidget {
  const _NumberCell({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(text, style: context.textStyles.bodySmall),
      ),
    );
  }
}

class _ListFooter extends StatelessWidget {
  const _ListFooter({required this.viewModel});

  final MarketProvider viewModel;

  @override
  Widget build(BuildContext context) {
    final child = viewModel.loadMoreFailed
        ? TextButton.icon(
            onPressed: viewModel.retryLoadMore,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Không tải thêm được. Thử lại'),
          )
        : viewModel.isBusy
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Center(child: child),
    );
  }
}
