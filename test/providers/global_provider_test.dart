import 'package:flutter_test/flutter_test.dart';
import 'package:hhmmobile/core/error/failure.dart';
import 'package:hhmmobile/core/result/result.dart';
import 'package:hhmmobile/data/model/crypto/coin_category.dart';
import 'package:hhmmobile/providers/base_view_model.dart';
import 'package:hhmmobile/providers/global_provider.dart';

import '../support/fake_market_repository.dart';

void main() {
  group('GlobalProvider', () {
    late FakeMarketRepository repository;
    late GlobalProvider provider;

    setUp(() {
      repository = FakeMarketRepository();
      provider = GlobalProvider(repository: repository);
      addTearDown(provider.dispose);
    });

    test('should request sparkline data for the movers', () async {
      await provider.load();

      expect(repository.marketCalls.single.sparkline, isTrue);
    });

    test('should pick the biggest 24h moves in either direction', () async {
      repository.marketsHandler = (_, __) => Ok([
            coin('flat', change24h: 0.1),
            coin('drop', change24h: -14.3),
            coin('none'),
            coin('pump', change24h: 10.3),
          ]);

      await provider.load();

      expect(
        provider.overview.movers!.map((c) => c.id),
        ['drop', 'pump', 'flat'],
      );
    });

    test('should limit movers and categories to the configured counts',
        () async {
      repository.marketsHandler = (_, __) => Ok([
            for (var i = 0; i < 50; i++) coin('c$i', change24h: i.toDouble()),
          ]);
      repository.categoriesResult = Ok([
        for (var i = 0; i < 40; i++) CoinCategory(id: 'k$i', name: 'k$i'),
      ]);

      await provider.load();

      expect(provider.overview.movers, hasLength(GlobalProvider.moversCount));
      expect(
        provider.overview.categories,
        hasLength(GlobalProvider.categoriesCount),
      );
    });

    test('should show what loaded when one request fails', () async {
      repository.categoriesResult = const Err(Failure.network('offline'));
      repository.marketsHandler = (_, __) => Ok([coin('a', change24h: 1)]);

      await provider.load();

      expect(provider.state, ViewState.ready);
      expect(provider.overview.global, isNotNull);
      expect(provider.overview.categories, isNull);
      expect(provider.overview.movers, hasLength(1));
      expect(provider.overview.isComplete, isFalse);
    });

    test('should show the error screen only when every request fails',
        () async {
      const failure = Failure.network('offline');
      repository.globalResult = const Err(failure);
      repository.categoriesResult = const Err(failure);
      repository.marketsHandler = (_, __) => const Err(failure);

      await provider.load();

      expect(provider.state, ViewState.error);
      expect(provider.failure?.message, 'offline');
    });

    test('should keep the previous overview when refresh fails entirely',
        () async {
      repository.marketsHandler = (_, __) => Ok([coin('a', change24h: 1)]);
      await provider.load();
      const failure = Failure.network('offline');
      repository.globalResult = const Err(failure);
      repository.categoriesResult = const Err(failure);
      repository.marketsHandler = (_, __) => const Err(failure);

      await provider.refresh();

      expect(provider.state, ViewState.ready);
      expect(provider.overview.movers, hasLength(1));
    });
  });
}
