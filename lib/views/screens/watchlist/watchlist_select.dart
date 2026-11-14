import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hhmmobile/app/theme/app_colors.dart';
import 'package:hhmmobile/app/theme/app_dimens.dart';
import 'package:hhmmobile/core/utils/extensions/context_x.dart';
import 'package:hhmmobile/data/model/crypto/token_model.dart';
import 'package:hhmmobile/providers/base_view_model.dart';
import 'package:hhmmobile/providers/watchlist_provider.dart';
import 'package:hhmmobile/views/widgets/state/state_views.dart';
import 'package:provider/provider.dart';
import 'package:hhmmobile/providers/token_list_provider.dart';

/// Danh sách coin để chọn cho watchlist.
///
/// [TokenListProvider] tải và lọc coin; các tick chọn là state cục bộ.
/// [WatchListProvider.addCoin] lưu toàn bộ selection khi bấm Thêm.
class WatchlistSelect extends StatefulWidget {
  const WatchlistSelect({super.key});

  @override
  State<WatchlistSelect> createState() => _WatchlistSelectState();
}

class _WatchlistSelectState extends State<WatchlistSelect> {
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    // Provider chưa sẵn sàng trong initState, đợi frame đầu.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<TokenListProvider>().init();
    });
  }

  void _toggle(String id) {
    setState(() {
      if (!_selectedIds.add(id)) {
        _selectedIds.remove(id);
      }
    });
  }

  Future<void> _save() async {
    final watchlist = context.read<WatchListProvider>();
    final ok = await watchlist.addCoin(_selectedIds.toList());
    if (!mounted) return;
    if (!ok) {
      context.showFailure(watchlist.failure);
      watchlist.clearFailure();
      return;
    }
    // Ghi xong mới đóng: quay lại tab "Theo dõi" là đã có giá của coin mới.
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TokenListProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Chọn coin theo dõi')),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: TextField(
                onChanged: provider.setQuery,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Tìm coin',
                ),
              ),
            ),
            Expanded(child: _body(provider)),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  // Chưa chọn coin nào thì khoá nút.
                  onPressed: _selectedIds.isEmpty ? null : _save,
                  child: Text(
                    'Thêm ${_selectedIds.length} coin vào watchlist',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(TokenListProvider provider) {
    return switch (provider.state) {
      ViewState.idle ||
      ViewState.loading =>
        const LoadingView(message: 'Đang tải danh sách coin...'),
      ViewState.error => ErrorView(
          failure: provider.failure,
          onRetry: provider.load,
        ),
      ViewState.empty => const EmptyView(
          title: 'Không có coin',
          message: 'CoinGecko trả về danh sách rỗng.',
          icon: Icons.currency_bitcoin_rounded,
        ),
      ViewState.ready => _coinList(provider),
    };
  }

  Widget _coinList(TokenListProvider provider) {
    final coins = provider.tokens;
    if (coins.isEmpty) {
      return const EmptyView(
        title: 'Không tìm thấy',
        message: 'Không có coin nào khớp từ khoá.',
        icon: Icons.search_off_rounded,
      );
    }

    return ListView.builder(
      itemCount: coins.length,
      itemBuilder: (_, i) {
        final coin = coins[i];
        return CoinSelectTile(
          coin: coin,
          selected: _selectedIds.contains(coin.id),
          onTap: () => _toggle(coin.id),
        );
      },
    );
  }
}

class CoinSelectTile extends StatelessWidget {
  const CoinSelectTile({
    super.key,
    required this.coin,
    required this.selected,
    required this.onTap,
  });

  final TokenModel coin;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final symbol = coin.symbol.toUpperCase();

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        child: Text(symbol.isEmpty ? '?' : symbol.substring(0, 1)),
      ),
      title: Text(symbol),
      subtitle: Text(coin.name),
      trailing: Icon(
        selected
            ? Icons.check_circle_rounded
            : Icons.add_circle_outline_rounded,
        color: selected ? AppColors.accent : null,
      ),
    );
  }
}
