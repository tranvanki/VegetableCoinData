import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hhmmobile/core/error/failure.dart';
import 'package:hhmmobile/core/result/result.dart';
import 'package:hhmmobile/data/model/crypto/coin_category.dart';
import 'package:hhmmobile/data/model/system/global_stats.dart';
import 'package:hhmmobile/providers/global_provider.dart';
import 'package:hhmmobile/views/screens/globalStats/global_screen.dart';
import 'package:hhmmobile/views/widgets/sparkline.dart';
import 'package:provider/provider.dart';

import '../../support/fake_market_repository.dart';

void main() {
  group('GlobalScreen', () {
    late FakeMarketRepository repository;
    late GlobalProvider provider;

    setUp(() {
      repository = FakeMarketRepository()
        ..globalResult = const Ok(
          GlobalStats(
            activeCryptocurrencies: 17397,
            markets: 1476,
            totalMarketCap: {'usd': 2.62e12},
            totalVolume: {'usd': 9.5e10},
            marketCapPercentage: {'btc': 57.9, 'eth': 9.6},
            marketCapChangePercentage24hUsd: -1.6,
          ),
        )
        ..categoriesResult = const Ok([
          CoinCategory(
            id: 'layer-1',
            name: 'Layer 1',
            marketCap: 1.5e12,
            marketCapChange24h: 2.5,
          ),
        ])
        ..marketsHandler = (_, __) => Ok([
              coin('zec', rank: 11, price: 400, change24h: -14.3),
              coin('lit', rank: 77, price: 2, change24h: 10.3),
            ]);
      provider = GlobalProvider(repository: repository);
      addTearDown(provider.dispose);
    });

    Future<void> pumpScreen(
      WidgetTester tester, {
      double width = 360,
      double textScale = 1,
    }) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 2000);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ChangeNotifierProvider<GlobalProvider>.value(
          value: provider,
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(textScale)),
              child: child!,
            ),
            home: const GlobalScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    testWidgets('should show overview, categories and movers', (tester) async {
      await pumpScreen(tester);

      expect(find.text(r'$2.62T'), findsOneWidget);
      expect(find.text('Tỷ trọng BTC'), findsOneWidget);
      expect(find.text('Nhóm ngành nổi bật'), findsOneWidget);
      expect(find.text('Layer 1'), findsOneWidget);
      expect(find.text('Biến động hôm nay'), findsOneWidget);
      expect(find.text('zec'), findsOneWidget);
      expect(find.byType(Sparkline), findsNWidgets(2));
    });

    testWidgets('should not overflow on a narrow screen with large text',
        (tester) async {
      await pumpScreen(tester, width: 320, textScale: 1.3);

      expect(tester.takeException(), isNull);
      expect(find.text('Biến động hôm nay'), findsOneWidget);
    });

    testWidgets('should hide a failed section and tell the user',
        (tester) async {
      repository.categoriesResult = const Err(Failure.network('offline'));

      await pumpScreen(tester);

      expect(find.text('Nhóm ngành nổi bật'), findsNothing);
      expect(find.text('Biến động hôm nay'), findsOneWidget);
      expect(find.textContaining('Một số mục chưa tải được'), findsOneWidget);
    });
  });
}
