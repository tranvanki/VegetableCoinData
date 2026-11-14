import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hhmmobile/core/error/failure.dart';
import 'package:hhmmobile/core/result/result.dart';
import 'package:hhmmobile/data/model/system/global_stats.dart';
import 'package:hhmmobile/providers/market_provider.dart';
import 'package:hhmmobile/views/screens/market/market_screen.dart';
import 'package:provider/provider.dart';

import '../../support/fake_market_repository.dart';

void main() {
  group('MarketScreen', () {
    late FakeMarketRepository repository;
    late MarketProvider provider;

    setUp(() {
      repository = FakeMarketRepository()
        ..globalResult = const Ok(
          GlobalStats(
            activeCryptocurrencies: 100,
            markets: 10,
            totalMarketCap: {'usd': 2.62e12},
            totalVolume: {'usd': 9.5e10},
            marketCapPercentage: {},
            marketCapChangePercentage24hUsd: -1.6,
          ),
        )
        ..marketsHandler = (_, coinIds) => Ok(
              coinIds == null
                  ? [
                      coin('btc',
                          rank: 1,
                          price: 65420.5,
                          change24h: -1.6,
                          marketCap: 1.3e12),
                      coin('pi',
                          rank: 81,
                          price: 0.00001234,
                          change24h: 4.5,
                          marketCap: 1.1e4),
                    ]
                  : [coin('pepe', rank: 30, price: 0.5, change24h: 9)],
            );
      provider = MarketProvider(repository: repository);
      addTearDown(provider.dispose);
    });

    Future<void> pumpScreen(
      WidgetTester tester, {
      double width = 360,
      double textScale = 1,
    }) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 800);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ChangeNotifierProvider<MarketProvider>.value(
          value: provider,
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(textScale)),
              child: child!,
            ),
            home: const MarketScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    testWidgets('should show global cards and one row per coin',
        (tester) async {
      await pumpScreen(tester);

      expect(find.text(r'$2.62T'), findsOneWidget);
      expect(find.text(r'$95B'), findsOneWidget);
      expect(find.text('BTC'), findsOneWidget);
      expect(find.text(r'$65,420.50'), findsOneWidget);
      expect(find.text(r'$0.00001234'), findsOneWidget);
      expect(find.text('81'), findsOneWidget);
    });

    testWidgets('should not overflow on a narrow screen with large text',
        (tester) async {
      await pumpScreen(tester, width: 320, textScale: 1.3);

      expect(tester.takeException(), isNull);
      expect(find.text('BTC'), findsOneWidget);
    });

    testWidgets('should show only trending coins after tapping the chip',
        (tester) async {
      repository.trendingResult = const Ok(['pepe']);
      await pumpScreen(tester);

      await tester.tap(find.text('Xu thế'));
      await tester.pump();
      await tester.pump();

      expect(find.text('PEPE'), findsOneWidget);
      expect(find.text('BTC'), findsNothing);
    });

    testWidgets('should reorder rows when a column header is tapped',
        (tester) async {
      await pumpScreen(tester);
      double top(String symbol) => tester.getTopLeft(find.text(symbol)).dy;
      expect(top('BTC'), lessThan(top('PI')));

      await tester.tap(find.text('Giá'));
      await tester.pump();
      expect(top('BTC'), lessThan(top('PI')));

      await tester.tap(find.text('24 giờ'));
      await tester.pump();
      expect(top('PI'), lessThan(top('BTC')));
    });

    testWidgets('should offer a retry when the first load fails',
        (tester) async {
      repository.marketsHandler =
          (_, __) => const Err(Failure.network('Mất kết nối'));

      await pumpScreen(tester);

      expect(find.text('Mất kết nối'), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);
    });
  });
}
