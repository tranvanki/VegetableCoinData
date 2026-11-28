import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hhmmobile/app/di/service_locator.dart';
import 'package:hhmmobile/app/router/app_routes.dart';
import 'package:hhmmobile/app/theme/app_dimens.dart';
import 'package:hhmmobile/core/utils/extensions/context_x.dart';
import 'package:hhmmobile/core/utils/formatters.dart';
import 'package:hhmmobile/data/model/crypto/coin_market.dart';
import 'package:hhmmobile/data/repository/market_repository.dart';
import 'package:hhmmobile/views/widgets/price_change.dart';

class CoinDetailScreen extends StatefulWidget {
  const CoinDetailScreen({
    super.key,
    required this.coinId,
    this.initialCoin,
  });
  final String coinId;
  final CoinMarketModel? initialCoin;
  @override
  State<CoinDetailScreen> createState() => _CoinDetailState();
}

class _CoinDetailState extends State<CoinDetailScreen> {
  CoinMarketModel? _coin;
  bool _loading = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _coin = widget.initialCoin;
    if (_coin == null && widget.coinId.isNotEmpty) {
      _fetchCoin();
    }
  }

  Future<void> _fetchCoin() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await sl<MarketRepository>().getMarkets(
      coinIds: [widget.coinId],
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      final list = result.dataOrNull;
      if (list != null && list.isNotEmpty) {
        _coin = list.first;
      } else {
        _error =
            result.failureOrNull?.message ?? 'Không tìm thấy dữ liệu coin.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final coin = _coin;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
          title: Text(coin != null
              ? '${coin.symbol.toUpperCase()}/USD'
              : widget.coinId)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : coin == null
              ? Center(
                  child: Text(_error ?? 'Không có dữ liệu'),
                )
              : _CoinDetailBody(coin: coin),
    );
  }
}

// Trong _buildDetailBody:
// - Giá: Formatters.usd(coin.currentPrice)
// - 24h %: PriceChange(value: coin.priceChangePercentage24h)
// - Cao 24h: Formatters.usd(coin.high24h)
// - Thấp 24h: Formatters.usd(coin.low24h)
// - KL 24h: Formatters.usdCompact(coin.totalVolume)
class _CoinDetailBody extends StatelessWidget {
  const _CoinDetailBody({required this.coin});

  final CoinMarketModel coin;
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(Formatters.usd(coin.currentPrice),
                        style: textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        )),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              PriceChange(
                value: coin.priceChangePercentage24h,
                style: textTheme.titleSmall,
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({
    required this.label,
    required this.value,
  });
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: context.textStyles.labelSmall),
        Text(value, style: context.textStyles.bodySmall)
      ],
    );
  }
}
