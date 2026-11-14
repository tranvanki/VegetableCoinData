import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hhmmobile/core/utils/extensions/context_x.dart';
import 'package:hhmmobile/providers/token_list_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_dimens.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/model/crypto/coin_market.dart';
import '../../../providers/base_view_model.dart';
import '../../../providers/watchlist_provider.dart';
import '../../widgets/state/state_views.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  final Set<String> _selectedIds = {};
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<TokenListProvider>().init();
    });
  }

  Future<void> _refresh(WatchListProvider viewModel) async {
    await viewModel.refresh();
    _showFailure(viewModel);
  }

  void _toggle(String id) {
    setState(() {
      if (!_selectedIds.remove(id)) {
        _selectedIds.add(id);
      }
    });
  }

  void _save() async {
    final watchlist = context.read<WatchListProvider>();
    final ok = await watchlist.addCoin(_selectedIds.toList());
    if (!mounted) return;

    if (!ok) {
      context.showFailure(watchlist.failure);
      watchlist.clearFailure();
      return;
    }
    context.pop();
  }

  Future<void> _removeCoin(
    WatchListProvider viewModel,
    String coinId,
  ) async {
    await viewModel.removeCoin(coinId);
    _showFailure(viewModel);
  }

  void _showFailure(WatchListProvider viewModel) {
    final failure = viewModel.failure;
    if (!mounted || failure == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(failure.message)),
    );
    viewModel.clearFailure();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<WatchListProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Theo dõi'),
        actions: [
          IconButton(
            tooltip: 'Thêm coin theo dõi',
            onPressed: () => context.push(AppRoutes.watchlistSelect),
            icon: const Icon(Icons.add_rounded),
          ),
          IconButton(
            tooltip: 'Làm mới',
            onPressed: viewModel.isBusy || viewModel.isLoading
                ? null
                : () => _refresh(viewModel),
            icon: viewModel.isBusy
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: switch (viewModel.state) {
          ViewState.idle ||
          ViewState.loading =>
            const LoadingView(message: 'Đang tải danh sách theo dõi...'),
          ViewState.error => ErrorView(
              failure: viewModel.failure,
              onRetry: viewModel.load,
            ),
          ViewState.empty => _emptyView(viewModel),
          ViewState.ready => _coinList(viewModel),
        },
      ),
    );
  }

  Widget _emptyView(WatchListProvider viewModel) {
    final hasSavedCoins = viewModel.watchlistIds.isNotEmpty;
    return EmptyView(
      icon: hasSavedCoins ? Icons.cloud_off_rounded : Icons.star_border_rounded,
      title: hasSavedCoins ? 'Chưa có dữ liệu giá' : 'Danh sách đang trống',
      message: hasSavedCoins
          ? 'Không nhận được dữ liệu cho các coin đang theo dõi. Hãy thử tải lại.'
          : 'Thêm coin bằng biểu tượng ngôi sao trong danh sách token.',
      actionLabel: hasSavedCoins ? 'Thử lại' : 'Tìm coin',
      onAction: () {
        if (hasSavedCoins) {
          viewModel.load();
        } else {
          context.push(AppRoutes.watchlistSelect);
        }
      },
    );
  }

  Widget _coinList(WatchListProvider viewModel) {
    final coins = viewModel.market;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.sm,
            AppSpacing.screenPadding,
            AppSpacing.md,
          ),
          child: Text('${coins.length} coin đang theo dõi'),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _refresh(viewModel),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                0,
                AppSpacing.screenPadding,
                AppSpacing.xxl,
              ),
              itemCount: coins.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) => _WatchlistCoinTile(
                coin: coins[index],
                onRemove: () => _removeCoin(viewModel, coins[index].id),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WatchlistCoinTile extends StatelessWidget {
  const _WatchlistCoinTile({required this.coin, required this.onRemove});

  final CoinMarketModel coin;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final change = coin.priceChangePercentage24h;
    final price = coin.currentPrice;
    final rank = coin.marketCapRank;
    final changeColor = change == null
        ? theme.colorScheme.onSurfaceVariant
        : change >= 0
            ? AppColors.success
            : AppColors.error;
    final priceFormat = NumberFormat.currency(
      locale: 'en_US',
      symbol: '\$',
      decimalDigits: price != null && price >= 1 ? 2 : 8,
    );

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            _CoinAvatar(coin: coin),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coin.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '${coin.symbol.toUpperCase()}${rank != null && rank > 0 ? ' · #$rank' : ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    'Vốn hóa ${Formatters.compact(coin.marketCap)} USD',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price == null ? '—' : priceFormat.format(price),
                  style: theme.textTheme.titleSmall,
                ),
                Text(
                  change == null ? '—' : Formatters.percentChange(change),
                  style:
                      theme.textTheme.bodySmall?.copyWith(color: changeColor),
                ),
                SizedBox(
                  height: 32,
                  child: IconButton(
                    tooltip: 'Bỏ theo dõi ${coin.name}',
                    onPressed: onRemove,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    icon:
                        const Icon(Icons.star_rounded, color: AppColors.accent),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CoinAvatar extends StatelessWidget {
  const _CoinAvatar({required this.coin});

  final CoinMarketModel coin;

  @override
  Widget build(BuildContext context) {
    if (coin.image.isEmpty) return _fallback(context);
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: coin.image,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        placeholder: (_, __) => _fallback(context),
        errorWidget: (_, __, ___) => _fallback(context),
      ),
    );
  }

  Widget _fallback(BuildContext context) => CircleAvatar(
        radius: 20,
        child: Text(
          coin.symbol.isEmpty ? '?' : coin.symbol.substring(0, 1).toUpperCase(),
          style: Theme.of(context).textTheme.labelMedium,
        ),
      );
}
