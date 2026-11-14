import 'package:flutter_test/flutter_test.dart';
import 'package:hhmmobile/core/network/api_client.dart';
import 'package:hhmmobile/core/result/result.dart';
import 'package:hhmmobile/data/model/crypto/token_model.dart';
import 'package:hhmmobile/data/repository/coin_repository.dart';

/// Repository giả cho test provider: trả danh sách token đã cấu hình, đếm số
/// lần gọi để kiểm tra cache/tải lại.
class FakeCoinRepository extends Fake implements CoinRepository {
  Result<List<TokenModel>> tokensResult = const Ok(<TokenModel>[]);
  int getTokensCalls = 0;

  @override
  Future<Result<List<TokenModel>>> getTokens({
    bool includePlatforms = true,
    ApiCancelToken? cancelToken,
    bool forceRefresh = false,
  }) async {
    getTokensCalls++;
    return tokensResult;
  }
}

TokenModel token(String id, {String? symbol, String? name}) => TokenModel(
      id: id,
      symbol: symbol ?? id,
      name: name ?? id,
      platforms: const {},
    );
