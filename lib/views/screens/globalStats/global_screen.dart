import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_dimens.dart';
import '../../../core/utils/extensions/context_x.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/model/crypto/coin_category.dart';
import '../../../data/model/crypto/coin_market.dart';
import '../../../data/model/system/global_stats.dart';
import '../../../providers/base_view_model.dart';
import '../../../providers/global_provider.dart';
import '../../widgets/coin_logo.dart';
import '../../widgets/common/app_widget.dart';
import '../../widgets/price_change.dart';
import '../../widgets/sparkline.dart';
import '../../widgets/state/state_views.dart';

/// Tab 3 — "Tổng quan thị trường" (Insights) trong [MainShell].
///
/// Dữ liệu (qua [GlobalProvider] → `MarketRepository`, tải song song):
/// - `/global` → khối tổng quan: vốn hoá, khối lượng, số coin/sàn, BTC/ETH.
/// - `/coins/categories` → nhóm ngành lớn nhất kèm biến động 24h.
/// - `/coins/markets?sparkline=true` → "Biến động hôm nay": 10 coin có
///   |% 24h| lớn nhất, sắp ở phía client; sparkline là 7 ngày.
///
/// Mỗi khối tự ẩn khi request của nó lỗi; chỉ khi cả ba lỗi mới hiện trang lỗi.
///
/// Bước sau:
/// - Văn bản tổng quan vĩ mô (nút Expand), thanh "Tin tức"/"Tìm hiểu" và
///   tiêu đề/đoạn trích tin trên từng thẻ biến động: cần nguồn tin, KHÔNG có
///   trong `all_api_formatted.md`. [_Tag] hiện chỉ có hạng vốn hoá.
/// - Chạm thẻ coin/nhóm ngành để mở chi tiết (route và `CoinDetail` chưa có).
/// - Tự làm mới 60s (xem ghi chú ở [GlobalProvider]).
class GlobalScreen extends StatefulWidget {
  const GlobalScreen({super.key});

  @override
  State<GlobalScreen> createState() => _GlobalScreenState();
}

class _GlobalScreenState extends State<GlobalScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(context.read<GlobalProvider>().init());
    });
  }

  Future<void> _refresh(GlobalProvider viewModel) async {
    await viewModel.refresh();
    if (!mounted) return;
    context.showFailure(viewModel.failure);
    viewModel.clearFailure();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GlobalProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tổng quan thị trường'),
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
        child: switch (viewModel.state) {
          ViewState.idle ||
          ViewState.loading =>
            const LoadingView(message: 'Đang tải tổng quan thị trường...'),
          ViewState.error =>
            ErrorView(failure: viewModel.failure, onRetry: viewModel.load),
          ViewState.empty => EmptyView(
              icon: Icons.public_rounded,
              message: 'Chưa có dữ liệu thị trường.',
              actionLabel: 'Tải lại',
              onAction: viewModel.load,
            ),
          ViewState.ready => RefreshIndicator(
              onRefresh: () => _refresh(viewModel),
              child: _Content(overview: viewModel.overview),
            ),
        },
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.overview});

  final MarketOverview overview;

  @override
  Widget build(BuildContext context) {
    final global = overview.global;
    final categories = overview.categories;
    final movers = overview.movers;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      children: [
        if (!overview.isComplete)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Text(
              'Một số mục chưa tải được. Kéo xuống để thử lại.',
              style: context.textStyles.bodySmall,
            ),
          ),
        if (global != null) _OverviewCard(global: global),
        if (categories != null && categories.isNotEmpty) ...[
          const SectionHeader(title: 'Nhóm ngành nổi bật'),
          for (final category in categories) _CategoryTile(category: category),
        ],
        if (movers != null && movers.isNotEmpty) ...[
          const SectionHeader(
            title: 'Biến động hôm nay',
            subtitle: 'Biểu đồ nhỏ thể hiện 7 ngày gần nhất',
          ),
          for (final coin in movers) _MoverCard(coin: coin),
        ],
      ],
    );
  }
}

/// Thẻ viền dùng chung cho mọi khối của màn hình.
class _BorderedCard extends StatelessWidget {
  const _BorderedCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppWidget(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.xs,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      border: Border.all(
        color: context.isDarkMode ? AppColors.dividerDark : AppColors.divider,
      ),
      child: child,
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.global});

  final GlobalStats global;

  @override
  Widget build(BuildContext context) {
    final btc = global.btcDominance;
    final eth = global.ethDominance;
    return _BorderedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Metric(
                  label: 'Vốn hóa toàn cầu',
                  value: Formatters.usdCompact(global.totalMarketCap['usd']),
                  change: global.marketCapChangePercentage24hUsd,
                ),
              ),
              Expanded(
                child: _Metric(
                  label: 'Khối lượng 24h',
                  value: Formatters.usdCompact(global.totalVolume['usd']),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Metric(
                  label: 'Coin đang hoạt động',
                  value: Formatters.number(global.activeCryptocurrencies),
                ),
              ),
              Expanded(
                child: _Metric(
                  label: 'Sàn giao dịch',
                  value: Formatters.number(global.markets),
                ),
              ),
            ],
          ),
          if (btc != null) ...[
            const SizedBox(height: AppSpacing.lg),
            _DominanceBar(label: 'BTC', percent: btc),
          ],
          if (eth != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _DominanceBar(label: 'ETH', percent: eth),
          ],
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, this.change});

  final String label;
  final String value;
  final double? change;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.textStyles.bodySmall),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          value,
          style: context.textStyles.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (change != null) PriceChange(value: change),
      ],
    );
  }
}

class _DominanceBar extends StatelessWidget {
  const _DominanceBar({required this.label, required this.percent});

  final String label;
  final double percent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Tỷ trọng $label',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textStyles.bodySmall,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '${percent.toStringAsFixed(1)}%',
              style: context.textStyles.labelMedium,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: LinearProgressIndicator(
            value: (percent / 100).clamp(0, 1),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category});

  final CoinCategory category;

  @override
  Widget build(BuildContext context) {
    return _BorderedCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.titleSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    for (final url in category.top3Coins)
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.xs),
                        child: CoinLogo(imageUrl: url, symbol: '', size: 20),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Formatters.usdCompact(category.marketCap),
                style: context.textStyles.titleSmall,
              ),
              PriceChange(
                value: category.marketCapChange24h,
                style: context.textStyles.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MoverCard extends StatelessWidget {
  const _MoverCard({required this.coin});

  final CoinMarketModel coin;

  @override
  Widget build(BuildContext context) {
    final rank = coin.marketCapRank;
    return _BorderedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CoinLogo(imageUrl: coin.image, symbol: coin.symbol, size: 40),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      coin.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.titleSmall,
                    ),
                    Wrap(
                      spacing: AppSpacing.sm,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          Formatters.usd(coin.currentPrice),
                          style: context.textStyles.bodySmall,
                        ),
                        PriceChange(
                          value: coin.priceChangePercentage24h,
                          style: context.textStyles.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Sparkline(prices: coin.sparklineIn7d?.price ?? const []),
            ],
          ),
          if (rank != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _Tag(text: '#$rank'),
          ],
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? AppColors.surfaceVariantDark
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Text(text, style: context.textStyles.labelSmall),
      ),
    );
  }
}
