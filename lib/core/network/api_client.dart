import 'package:dio/dio.dart';

import '../result/result.dart';

/// Re-export để tầng trên không phải import `dio` trực tiếp.
typedef ApiCancelToken = CancelToken;

/// Chuyển JSON thô (Map/List/primitive) thành model.
typedef JsonParser<T> = T Function(Object? json);

/// Kiểu "không có dữ liệu trả về" — dùng thay cho `void` để `Result` vẫn generic.
class Unit {
  const Unit._();
  @override
  String toString() => 'unit';
}

const Unit unit = Unit._();

/// Parser dựng sẵn hay dùng.
class Parsers {
  const Parsers._();

  static Unit unitParser(Object? _) => unit;
  static bool boolParser(Object? json) => json == true || json == 1;
  static String stringParser(Object? json) => json?.toString() ?? '';

  static Map<String, dynamic> mapParser(Object? json) =>
      json is Map<String, dynamic> ? json : <String, dynamic>{};

  /// List của model: `Parsers.listOf(TokenModel.fromJson)`.
  static JsonParser<List<T>> listOf<T>(
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    return (Object? json) {
      if (json is! List) return <T>[];
      return json
          .whereType<Map<String, dynamic>>()
          .map(fromJson)
          .toList(growable: false);
    };
  }

  /// Object đơn: `Parsers.objectOf(CoinDetail.fromJson)`.
  static JsonParser<T> objectOf<T>(
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    return (Object? json) => fromJson(
          json is Map<String, dynamic> ? json : <String, dynamic>{},
        );
  }

  static int intParser(Object? json) {
    if (json is int) return json;
    if (json is String) return int.tryParse(json) ?? 0;
    return 0;
  }
}

/// Hợp đồng gọi HTTP của app. Có hai cài đặt: [DioApiClient] (thật) và
/// [MockApiClient] (fixture cục bộ, dùng khi `AppConfig.useMockApi`).
/// Mọi phương thức trả [Result] — không ném exception ra ngoài.
abstract interface class ApiClient {
  Future<Result<T>> get<T>(
    String path, {
    required JsonParser<T> parser,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    ApiCancelToken? cancelToken,
  });
// tra 1 boc du lieu dang result(ko throw exception)
//result: Lam Hop chua - Ok data vs Failure
//reposit: dinh nghia endpoint nao di voi parser nao de ra kieu dulieu mong muon
  Future<Result<T>> post<T>(
    String path, {
    required JsonParser<T> parser,
    Object? body,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    ApiCancelToken? cancelToken,
  });

  Future<Result<T>> put<T>(
    String path, {
    required JsonParser<T> parser,
    Object? body,
    Map<String, dynamic>? query,
    ApiCancelToken? cancelToken,
  });

  Future<Result<T>> patch<T>(
    String path, {
    required JsonParser<T> parser,
    Object? body,
    Map<String, dynamic>? query,
    ApiCancelToken? cancelToken,
  });

  Future<Result<T>> delete<T>(
    String path, {
    required JsonParser<T> parser,
    Object? body,
    Map<String, dynamic>? query,
    ApiCancelToken? cancelToken,
  });

  /// Upload 1 file (ảnh đại diện, tệp đính kèm...).
  Future<Result<T>> upload<T>(
    String path, {
    required JsonParser<T> parser,
    required String filePath,
    String field = 'file',
    Map<String, dynamic>? fields,
    void Function(int sent, int total)? onProgress,
    ApiCancelToken? cancelToken,
  });
}
