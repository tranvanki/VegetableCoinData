import 'package:flutter_test/flutter_test.dart';
import 'package:hhmmobile/core/network/api_client.dart';
import 'package:hhmmobile/core/network/api_endpoints.dart';
import 'package:hhmmobile/core/result/result.dart';
import 'package:hhmmobile/data/repository/market_repository.dart';

/// ApiClient giả: trả JSON đã cấu hình theo path và chạy parser thật.
class _FakeApiClient extends Fake implements ApiClient {
  final Map<String, Object?> responses = {};
  final List<({String path, Map<String, dynamic>? query})> calls = [];

  @override
  Future<Result<T>> get<T>(
    String path, {
    required JsonParser<T> parser,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    ApiCancelToken? cancelToken,
  }) async {
    calls.add((path: path, query: query));
    return Ok(parser(responses[path]));
  }
}

void main() {
  group('MarketRepository', () {
    late _FakeApiClient api;
    late MarketRepository repository;

    setUp(() {
      api = _FakeApiClient();
      repository = MarketRepository(apiClient: api);
    });

    group('getMarkets', () {
      test('should request sparkline and ids only when asked', () async {
        api.responses[ApiEndpoints.coinMarkets] = <Object>[];

        await repository.getMarkets(sparkline: true, coinIds: ['a', 'b']);
        final query = api.calls.single.query!;

        expect(query['sparkline'], isTrue);
        expect(query['ids'], 'a,b');
        expect(query['per_page'], 2);
      });

      test('should default to no sparkline and 100 per page', () async {
        api.responses[ApiEndpoints.coinMarkets] = <Object>[];

        await repository.getMarkets();
        final query = api.calls.single.query!;

        expect(query['sparkline'], isFalse);
        expect(query['per_page'], 100);
        expect(query.containsKey('ids'), isFalse);
      });
    });

    group('getGlobalStats', () {
      setUp(() {
        api.responses[ApiEndpoints.global] = {
          'data': {
            'active_cryptocurrencies': 17397,
            'markets': 1476,
            'total_market_cap': {'usd': 2.62e12, 'btc': 34570737.2},
            'total_volume': {'usd': 9.5e10},
            'market_cap_percentage': {'btc': 57.9, 'eth': 9.58},
            'market_cap_change_percentage_24h_usd': -1.6,
          },
        };
      });

      test('should unwrap data and expose usd, dominance and change', () async {
        final stats = (await repository.getGlobalStats()).dataOrNull!;

        expect(stats.activeCryptocurrencies, 17397);
        expect(stats.markets, 1476);
        expect(stats.totalMarketCap['usd'], 2.62e12);
        expect(stats.totalVolume['usd'], 9.5e10);
        expect(stats.btcDominance, 57.9);
        expect(stats.ethDominance, 9.58);
        expect(stats.marketCapChangePercentage24hUsd, -1.6);
      });

      test('should serve a repeat call from cache', () async {
        await repository.getGlobalStats();
        await repository.getGlobalStats();

        expect(api.calls, hasLength(1));
      });

      test('should tolerate a missing change field', () async {
        api.responses[ApiEndpoints.global] = {
          'data': {
            'total_market_cap': {'usd': 1}
          },
        };

        final stats = (await repository.getGlobalStats()).dataOrNull!;

        expect(stats.marketCapChangePercentage24hUsd, isNull);
        expect(stats.btcDominance, isNull);
      });
    });

    group('getTrendingCoinIds', () {
      test('should return coin ids in trending order, skipping bad items',
          () async {
        api.responses[ApiEndpoints.trending] = {
          'coins': [
            {
              'item': {'id': 'pepe'}
            },
            {
              'item': {'name': 'no id'}
            },
            {
              'item': {'id': 'bonk'}
            },
          ],
          'nfts': <Object>[],
        };

        final ids = (await repository.getTrendingCoinIds()).dataOrNull;

        expect(ids, ['pepe', 'bonk']);
      });

      test('should return an empty list for an unexpected body', () async {
        api.responses[ApiEndpoints.trending] = 'oops';

        final ids = (await repository.getTrendingCoinIds()).dataOrNull;

        expect(ids, isEmpty);
      });
    });

    group('getCategories', () {
      test('should parse market data and the top 3 coin logos', () async {
        api.responses[ApiEndpoints.coinCategories] = [
          {
            'id': 'layer-1',
            'name': 'Layer 1',
            'market_cap': 1.5e12,
            'market_cap_change_24h': -2.5,
            'top_3_coins': ['u1', 'u2', 'u3'],
            'volume_24h': 4.2e10,
          },
        ];

        final categories = (await repository.getCategories()).dataOrNull!;

        expect(categories.single.name, 'Layer 1');
        expect(categories.single.marketCapChange24h, -2.5);
        expect(categories.single.top3Coins, ['u1', 'u2', 'u3']);
        expect(categories.single.volume24h, 4.2e10);
      });
    });
  });
}
