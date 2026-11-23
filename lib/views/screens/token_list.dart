import 'package:flutter/material.dart';
import 'package:hhmmobile/core/result/result.dart';
import 'package:hhmmobile/data/model/crypto/coin_market.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimens.dart';
import '../../core/config/app_constants.dart';
import '../../core/utils/debouncer.dart';
import '../../core/utils/extensions/context_x.dart';
import '../../core/utils/formatters.dart';
import '../../data/model/crypto/token_model.dart';
import '../../providers/base_view_model.dart';
import '../../providers/token_list_provider.dart';
import '../../providers/watchlist_provider.dart';
import '../widgets/common/app_widget.dart';
import '../widgets/state/state_views.dart';

/// Màn danh sách token CoinGecko.
///
/// Tải toàn bộ `/coins/list` một lần, tìm kiếm lọc cục bộ, kéo xuống để làm
/// mới. Widget chỉ đọc trạng thái từ [TokenListProvider] — không tự gọi API.
class TokenList extends StatefulWidget {
  const TokenList({super.key, this.onTokenTap});

  /// Mở chi tiết token ở tầng gọi (screen/router).
  final ValueChanged<TokenModel>? onTokenTap;

  @override
  State<TokenList> createState() => _TokenListState();
}

class _TokenListState extends State<TokenList> {
  final TextEditingController _search = TextEditingController();
  final Debouncer _debounce = Debouncer(AppConstants.searchDebounce);

  @override
  void initState() {
    super.initState();
    // Provider chưa sẵn sàng trong initState, đợi frame đầu.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<TokenListProvider>().init();
    });
  }

  @override
  void dispose() {
    _debounce.dispose();
    _search.dispose();
    super.dispose();
  }

  void _clearSearch(TokenListProvider provider) {
    _debounce.cancel();
    _search.clear();
    provider.setQuery('');
  }

  Future<void> _refresh(TokenListProvider provider) async {
    await provider.refresh();
    if (!mounted) return;
    final failure = provider.failure;
    if (failure != null) {
      context.showFailure(failure);
      provider.clearFailure();
    }
  }

  Future<void> _toggleWatchlist(
    WatchListProvider watchlist,
    String coinId,
  ) async {
    final wasWatching = watchlist.isWatching(coinId);
    final succeeded = await watchlist.toggleCoin(coinId);
    if (!mounted) return;
    final failure = watchlist.failure;
    final message = failure?.message ??
        (succeeded
            ? wasWatching
                ? 'Đã bỏ coin khỏi danh sách theo dõi.'
                : 'Đã thêm coin vào danh sách theo dõi.'
            : 'Không thể cập nhật danh sách theo dõi.');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    if (failure != null) watchlist.clearFailure();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TokenListProvider>();
    final watchlist = context.watch<WatchListProvider>();
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _buildHeader(context, provider),
          Expanded(child: _buildBody(context, provider, watchlist)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, TokenListProvider provider) {
    final chipColor = context.isDarkMode
        ? AppColors.primary.withValues(alpha: 0.18)
        : AppColors.primaryLight;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.md,
        AppSpacing.screenPadding,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Token', style: context.textStyles.headlineMedium),
              const SizedBox(width: AppSpacing.sm),
              if (provider.totalCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: chipColor,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    '${Formatters.number(provider.totalCount)} token',
                    style: context.textStyles.labelSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const Spacer(),
              IconButton(
                tooltip: 'Làm mới',
                onPressed: provider.isBusy ? null : () => _refresh(provider),
                icon: provider.isBusy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _search,
            textInputAction: TextInputAction.search,
            onChanged: (value) => _debounce.run(() => provider.setQuery(value)),
            onSubmitted: (value) {
              _debounce.cancel();
              provider.setQuery(value);
            },
            decoration: InputDecoration(
              hintText: 'Tìm theo tên, mã hoặc id',
              prefixIcon:
                  const Icon(Icons.search_rounded, size: AppSizes.iconMd),
              suffixIcon: provider.hasQuery
                  ? IconButton(
                      tooltip: 'Xoá tìm kiếm',
                      onPressed: () => _clearSearch(provider),
                      icon: const Icon(Icons.close_rounded),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    TokenListProvider provider,
    WatchListProvider watchlist,
  ) {
    switch (provider.state) {
      case ViewState.idle:
      case ViewState.loading:
        return const LoadingView(message: 'Đang tải danh sách token...');

      case ViewState.error:
        return ErrorView(failure: provider.failure, onRetry: provider.load);

      case ViewState.empty:
        return EmptyView(
          title: 'Không có token',
          message: 'CoinGecko trả về danh sách rỗng.',
          icon: Icons.currency_bitcoin_rounded,
          actionLabel: 'Tải lại',
          onAction: provider.load,
        );

      case ViewState.ready:
        final tokens = provider.tokens;
        if (tokens.isEmpty) {
          return EmptyView(
            title: 'Không tìm thấy',
            message: 'Không có token khớp "${provider.query}".',
            icon: Icons.search_off_rounded,
            actionLabel: 'Xoá tìm kiếm',
            onAction: () => _clearSearch(provider),
          );
        }
        return RefreshIndicator(
          onRefresh: () => _refresh(provider),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.xs,
              AppSpacing.screenPadding,
              AppSpacing.xxl,
            ),
            itemCount: tokens.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final token = tokens[index];
              return _TokenTile(
                coin: token,
                isWatchlisted: watchlist.isWatching(token.id),
                onWatchlistTap: () => _toggleWatchlist(watchlist, token.id),
                onTap: widget.onTokenTap == null
                    ? null
                    : () => widget.onTokenTap!(token),
              );
            },
          ),
        );
    }
  }
}

class _TokenTile extends StatelessWidget {
  const _TokenTile({
    required this.coin,
    required this.isWatchlisted,
    required this.onWatchlistTap,
    this.onTap,
  });

  final CoinMarketModel coin;
  final bool isWatchlisted;
  final VoidCallback onWatchlistTap;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pct = coin.priceChangePercentage24h ?? 0;
    final color = pct >= 0 ? AppColors.success : AppColors.error;
    return AppWidget(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      border: Border.all(
        color: context.isDarkMode ? AppColors.dividerDark : AppColors.divider,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '#${coin.marketCapRank ?? '-'}',
              style: context.textStyles.labelSmall,
            ),
          ),
          CircleAvatar(
            radius: 16,
            backgroundImage: NetworkImage(coin.image),
            backgroundColor: Colors.transparent,
          ),
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
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${coin.symbol.toUpperCase()} · ${coin.id}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.bodySmall,
                ),
              ],
            ),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('\$${Formatters.number(coin.currentPrice ?? 0)}',
                style: context.textStyles.titleSmall),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text('${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(2)}%',
                  style: context.textStyles.labelSmall?.copyWith(color: color)),
            ),
          ]),
          IconButton(
            tooltip: isWatchlisted ? 'Bỏ theo dõi' : 'Thêm vào theo dõi',
            onPressed: onWatchlistTap,
            icon: Icon(
              isWatchlisted ? Icons.star_rounded : Icons.star_outline_rounded,
              color: isWatchlisted ? AppColors.accent : null,
            ),
          ),
          if (onTap != null)
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textDisabled,
            ),
        ],
      ),
    );
  }
}
