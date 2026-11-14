import 'package:flutter_test/flutter_test.dart';
import 'package:hhmmobile/core/error/failure.dart';
import 'package:hhmmobile/core/result/result.dart';
import 'package:hhmmobile/data/model/crypto/coin_market.dart';
import 'package:hhmmobile/providers/base_view_model.dart';
import 'package:hhmmobile/providers/market_provider.dart';

import '../support/fake_market_repository.dart';

void main() {
  group('MarketProvider', () {
    late FakeMarketRepository repository;
    late MarketProvider provider;

    List<CoinMarketModel> page(int page, int count) => [
          for (var i = 0; i < count; i++)
            coin('p${page}c$i', rank: (page - 1) * MarketProvider.pageSize + i),
        ];

    setUp(() {
      repository = FakeMarketRepository();
      provider = MarketProvider(repository: repository);
      addTearDown(provider.dispose);
    });

    List<String> ids() => provider.coins.map((c) => c.id).toList();

    group('load', () {
      test('should become ready with the fetched coins', () async {
        repository.marketsHandler =
            (_, __) => Ok([coin('a', rank: 1), coin('b', rank: 2)]);

        await provider.load();

        expect(provider.state, ViewState.ready);
        expect(ids(), ['a', 'b']);
      });

      test('should become empty when the market list is empty', () async {
        await provider.load();

        expect(provider.state, ViewState.empty);
      });

      test('should show the error screen when the first load fails', () async {
        repository.marketsHandler =
            (_, __) => const Err(Failure.network('offline'));

        await provider.load();

        expect(provider.state, ViewState.error);
        expect(provider.failure?.message, 'offline');
      });

      test('should expose global stats without affecting the table', () async {
        repository.marketsHandler = (_, __) => Ok([coin('a', rank: 1)]);

        await provider.load();
        await pumpEventQueue();

        expect(provider.global, same(emptyGlobal));
      });

      test('should stay ready when only the global request fails', () async {
        repository.globalResult = const Err(Failure.network('offline'));
        repository.marketsHandler = (_, __) => Ok([coin('a', rank: 1)]);

        await provider.load();
        await pumpEventQueue();

        expect(provider.state, ViewState.ready);
        expect(provider.global, isNull);
      });
    });

    group('setSort', () {
      setUp(() async {
        repository.marketsHandler = (_, __) => Ok([
              coin('a', rank: 1, price: 10, change24h: -1),
              coin('b', rank: 2, price: 50, change24h: 5),
              coin('c', rank: 3, price: 1),
            ]);
        await provider.load();
      });

      test('should order by rank ascending by default', () {
        expect(ids(), ['a', 'b', 'c']);
      });

      test('should order a new column descending, then flip on repeat', () {
        provider.setSort(MarketSort.price);
        expect(ids(), ['b', 'a', 'c']);

        provider.setSort(MarketSort.price);
        expect(ids(), ['c', 'a', 'b']);
      });

      test('should keep coins without data last in both directions', () {
        provider.setSort(MarketSort.change24h);
        expect(ids(), ['b', 'a', 'c']);

        provider.setSort(MarketSort.change24h);
        expect(ids(), ['a', 'b', 'c']);
      });

      test('should not call the network when sorting', () {
        final callsBefore = repository.marketCalls.length;

        provider.setSort(MarketSort.marketCap);

        expect(repository.marketCalls, hasLength(callsBefore));
      });
    });

    group('setFilter', () {
      test('should load trending ids then fetch prices for exactly those ids',
          () async {
        repository.trendingResult = const Ok(['b', 'a']);
        repository.marketsHandler = (_, coinIds) => Ok([
              for (final id in coinIds ?? const <String>[])
                coin(id, rank: id == 'a' ? 1 : 2),
            ]);

        await provider.setFilter(MarketFilter.trending);

        expect(repository.marketCalls.single.coinIds, ['b', 'a']);
        expect(ids(), ['a', 'b']);
        expect(provider.hasMore, isFalse);
      });

      test('should become empty without a price request when nothing trends',
          () async {
        repository.trendingResult = const Ok(<String>[]);

        await provider.setFilter(MarketFilter.trending);

        expect(provider.state, ViewState.empty);
        expect(repository.marketCalls, isEmpty);
      });

      test('should surface a trending failure as the error screen', () async {
        repository.trendingResult = const Err(Failure.network('offline'));

        await provider.setFilter(MarketFilter.trending);

        expect(provider.state, ViewState.error);
      });

      test('should drop the previous filter table when the new one fails',
          () async {
        repository.marketsHandler = (_, __) => Ok([coin('a', rank: 1)]);
        await provider.load();
        repository.trendingResult = const Err(Failure.network('offline'));

        await provider.setFilter(MarketFilter.trending);

        expect(provider.coins, isEmpty);
      });
    });

    group('loadMore', () {
      test('should append the next page and stop after a short page', () async {
        repository.marketsHandler = (pageNumber, _) => Ok(
            page(pageNumber, pageNumber == 1 ? MarketProvider.pageSize : 30));
        await provider.load();
        expect(provider.hasMore, isTrue);

        await provider.loadMore();

        expect(provider.coins, hasLength(MarketProvider.pageSize + 30));
        expect(provider.hasMore, isFalse);

        await provider.loadMore();
        expect(repository.marketCalls.map((c) => c.page), [1, 2]);
      });

      test('should stop auto-loading after a failure until retried', () async {
        var failNextPage = true;
        repository.marketsHandler = (pageNumber, _) {
          if (pageNumber == 2 && failNextPage) {
            return const Err(Failure.network('offline'));
          }
          return Ok(page(pageNumber, MarketProvider.pageSize));
        };
        await provider.load();

        await provider.loadMore();
        expect(provider.loadMoreFailed, isTrue);
        expect(provider.state, ViewState.ready);
        expect(provider.failure, isNull);

        await provider.loadMore();
        expect(repository.marketCalls.where((c) => c.page == 2), hasLength(1));

        failNextPage = false;
        await provider.retryLoadMore();
        expect(provider.loadMoreFailed, isFalse);
        expect(provider.coins, hasLength(MarketProvider.pageSize * 2));
      });
    });

    group('refresh', () {
      test('should keep the old table when refresh fails', () async {
        repository.marketsHandler = (_, __) => Ok([coin('a', rank: 1)]);
        await provider.load();
        repository.marketsHandler =
            (_, __) => const Err(Failure.network('offline'));

        await provider.refresh();

        expect(provider.state, ViewState.ready);
        expect(ids(), ['a']);
        expect(provider.failure?.message, 'offline');
      });
    });
  });
}
