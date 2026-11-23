import 'package:flutter/material.dart';
import 'package:hhmmobile/core/utils/formatters.dart';
import 'package:provider/provider.dart';

import '../../data/repository/binance_market_repository.dart';
import '../../providers/base_view_model.dart';
import '../../providers/binance_market_view_model.dart';

class BinanceHomeScreen extends StatefulWidget {
  const BinanceHomeScreen({super.key});

  @override
  State<BinanceHomeScreen> createState() => _BinanceHomeScreenState();
}

class _BinanceHomeScreenState extends State<BinanceHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<BinanceMarketViewModel>().load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BinanceMarketViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Binance Market'),
        actions: [
          _buildStatusBadge(provider.connectionStatus),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: provider.setQuery,
              decoration: const InputDecoration(
                hintText: 'Tìm BTC, ETH, SOL...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          if (provider.connectionStatus == BinanceConnectionStatus.offline)
            Container(
              width: double.infinity,
              color: Colors.orange.shade800,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
              child: const Text(
                'Ngoại tuyến - Đang hiển thị dữ liệu lưu trong máy',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            )
          else if (provider.connectionStatus ==
              BinanceConnectionStatus.reconnecting)
            Container(
              width: double.infinity,
              color: Colors.blue.shade700,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
              child: const Text(
                'Đang tự động kết nối lại...',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          if (provider.isLoading) const LinearProgressIndicator(),
          if (provider.state == ViewState.error)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Không tải được danh sách: ${provider.failure?.message ?? "Lỗi không xác định"}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: provider.refresh,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            )
          else if (provider.coins.isEmpty && !provider.isLoading)
            const Expanded(
              child: Center(
                child: Text('Không có dữ liệu'),
              ),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: provider.refresh,
                child: ListView.builder(
                  itemCount: provider.coins.length,
                  itemBuilder: (context, index) {
                    final coin = provider.coins[index];
                    final change = coin.change24h;
                    final changeColor =
                        (change ?? 0) >= 0 ? Colors.green : Colors.red;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.transparent,
                        backgroundImage: coin.imageUrl != null
                            ? NetworkImage(coin.imageUrl!)
                            : null,
                        child: coin.imageUrl == null
                            ? Text(coin.baseAsset)
                            : null,
                      ),
                      title: Text(coin.baseAsset),
                      subtitle: Text(
                        '${coin.symbol} • Vốn hóa: ${Formatters.usdCompact(coin.marketCap)}',
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            Formatters.usd(coin.price),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            change == null
                                ? '—'
                                : '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%',
                            style: TextStyle(
                              color: changeColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BinanceConnectionStatus status) {
    final (label, color) = switch (status) {
      BinanceConnectionStatus.live => ('Live', Colors.green),
      BinanceConnectionStatus.connecting => ('Kết nối...', Colors.amber),
      BinanceConnectionStatus.reconnecting => ('Thử lại...', Colors.blue),
      BinanceConnectionStatus.offline => ('Offline', Colors.grey),
    };

    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
