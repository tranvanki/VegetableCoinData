import 'dart:async';

import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../config/app_config.dart';
import '../error/error_mapper.dart';
import '../error/failure.dart';
import '../result/result.dart';
import '../utils/logger.dart';
import 'api_client.dart';
import 'api_response.dart';

/// Cài đặt thật của [ApiClient] trên Dio.
///
/// Trách nhiệm: dựng Dio, chạy request, bóc envelope `{ok,msg,data}`,
/// và quy mọi lỗi về [Failure]. Không chứa logic nghiệp vụ.
class DioApiClient implements ApiClient {
  DioApiClient({
    required AppConfig config,
    Dio? dio,
  })  : _config = config,
        _dio = dio ?? Dio() {
    _dio.options = BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: config.apiTimeout,
      receiveTimeout: config.apiTimeout,
      sendTimeout: config.apiTimeout,
      responseType: ResponseType.json,
      contentType: Headers.jsonContentType,
      headers: const <String, String>{'Accept': 'application/json'},
      // Tự xử lý status thay vì để Dio ném cho mọi mã khác 2xx, vì CoinGecko
      // trả lỗi kèm body cần đọc (429 rate limit, 404 coin không tồn tại).
      validateStatus: (status) => status != null && status < 500,
    );

    // Dio phụ cho AuthInterceptor phát lại request sau khi refresh —
    // không gắn interceptor để tránh đệ quy refresh.
    _retryDio = Dio(_dio.options);
  }

  final AppConfig _config;
  final Dio _dio; // Lưu máy gọi mạng chính
  late final Dio _retryDio; // Lưu máy gọi mạng phu
// Hai hàm "Cửa sổ" (Getters) để bên ngoài có thể lấy máy gọi mạng ra dùng trực tiếp nếu cần.
  Dio get raw => _dio;
  Dio get retryDio => _retryDio;

  /// Gắn interceptor theo thứ tự: thông tin thiết bị, auth, retry, log.
  void addInterceptors(List<Interceptor> interceptors) {
    _dio.interceptors.addAll(interceptors);
    if (_config.enableLogging) {
      // Không in body response: `/coins/list` trả vài MB JSON sẽ làm ngập
      // console. Thông tin đủ dùng nằm ở dòng tóm tắt trong [_logResponse].
      _dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: false,
          responseHeader: false,
          compact: true,
          maxWidth: 120,
        ),
      );
    }
  }

  @override
  Future<Result<T>> get<T>(
    String path, {
    required JsonParser<T> parser,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    ApiCancelToken? cancelToken,
  }) =>
      _send(
        method: 'GET',
        path: path,
        parser: parser,
        query: query,
        headers: headers,
        cancelToken: cancelToken,
      );
  @override
  Future<Result<T>> post<T>(
    String path, {
    required JsonParser<T> parser,
    Object? body,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    ApiCancelToken? cancelToken,
  }) =>
      _send(
        method: 'POST',
        path: path,
        parser: parser,
        body: body,
        query: query,
        headers: headers,
        cancelToken: cancelToken,
      );

  @override
  Future<Result<T>> put<T>(
    String path, {
    required JsonParser<T> parser,
    Object? body,
    Map<String, dynamic>? query,
    ApiCancelToken? cancelToken,
  }) =>
      _send(
        method: 'PUT',
        path: path,
        parser: parser,
        body: body,
        query: query,
        cancelToken: cancelToken,
      );

  @override
  Future<Result<T>> patch<T>(
    String path, {
    required JsonParser<T> parser,
    Object? body,
    Map<String, dynamic>? query,
    ApiCancelToken? cancelToken,
  }) =>
      _send(
        method: 'PATCH',
        path: path,
        parser: parser,
        body: body,
        query: query,
        cancelToken: cancelToken,
      );

  @override
  Future<Result<T>> delete<T>(
    String path, {
    required JsonParser<T> parser,
    Object? body,
    Map<String, dynamic>? query,
    ApiCancelToken? cancelToken,
  }) =>
      _send(
        method: 'DELETE',
        path: path,
        parser: parser,
        body: body,
        query: query,
        cancelToken: cancelToken,
      );

  @override
  Future<Result<T>> upload<T>(
    String path, {
    required JsonParser<T> parser,
    required String filePath,
    String field = 'file',
    Map<String, dynamic>? fields,
    void Function(int sent, int total)? onProgress,
    ApiCancelToken? cancelToken,
  }) async {
    try {
      final form = FormData.fromMap(<String, dynamic>{
        ...?fields,
        field: await MultipartFile.fromFile(filePath),
      });
      final response = await _dio.post<dynamic>(
        path,
        data: form,
        cancelToken: cancelToken,
        onSendProgress: onProgress,
      );
      return _handle(response, parser);
    } catch (e, s) {
      return Err<T>(ErrorMapper.map(e, s));
    }
  }

//collect all informations,send and catch error
  Future<Result<T>> _send<T>({
    required String method,
    required String path,
    required JsonParser<T> parser,
    Object? body,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    ApiCancelToken? cancelToken,
  }) async {
    try {
      //response để hứng kết quả trả về từ server
      // Phải dùng dynamic: request<String> khiến Dio trả nguyên chuỗi JSON,
      // parser sẽ không thấy List/Map và trả về rỗng.
      final response = await _dio.request<dynamic>(
        path,
        data: body,
        queryParameters: query,
        cancelToken: cancelToken,
        options: Options(method: method, headers: headers),
      );
      _logResponse(method, path, response);
      return _handle(response, parser);
    } catch (e, s) {
      final failure = ErrorMapper.map(e, s);
      if (failure.shouldReport) {
        AppLogger.e(
          '$method $path thất bại',
          tag: 'Http',
          error: e,
          stackTrace: s,
        );
      }
      return Err<T>(failure);
    }
  }

  /// Một dòng tóm tắt mỗi response: method, path, status và kích thước body.
  /// Đếm phần tử/khoá thay vì nối chuỗi toàn bộ body để không tốn bộ nhớ.
  void _logResponse(String method, String path, Response<dynamic> response) {
    if (!_config.enableLogging) return;
    final body = response.data;
    final size = switch (body) {
      final List<dynamic> list => '${list.length} phần tử',
      final Map<String, dynamic> map => '${map.length} khoá',
      null => 'rỗng',
      final Object other => '${other.toString().length} ký tự',
    };
    AppLogger.d(
      '$method $path → ${response.statusCode ?? 0} ($size)',
      tag: 'Http',
    );
  }

  /// Chuyển HTTP response thành [Result]: kiểm tra status, bóc envelope,
  /// rồi parse. Lỗi parse được coi là lỗi server (contract lệch).
  Result<T> _handle<T>(Response<dynamic> response, JsonParser<T> parser) {
    final status = response.statusCode ?? 0;
    final body = response.data;

    if (status < 200 || status >= 300) {
      return Err<T>(
        ErrorMapper.map(
          DioException.badResponse(
            statusCode: status,
            requestOptions: response.requestOptions,
            response: response,
          ),
        ),
      );
    }

    if (ApiEnvelope.looksLikeEnvelope(body)) {
      final envelope = ApiEnvelope.fromJson(body as Map<String, dynamic>);
      if (!envelope.ok) {
        return Err<T>(
          Failure(
            kind: FailureKind.business,
            message: envelope.message ?? 'Yêu cầu không thực hiện được.',
            code: envelope.code,
            statusCode: status,
          ),
        );
      }
      return _parse(envelope.data, parser, response);
    }

    return _parse(body, parser, response);
  }

  Result<T> _parse<T>(
    Object? data,
    JsonParser<T> parser,
    Response<dynamic> response,
  ) {
    try {
      return Ok<T>(parser(data));
    } catch (e, s) {
      AppLogger.e(
        'Parse lỗi tại ${response.requestOptions.path}',
        tag: 'Http',
        error: e,
        stackTrace: s,
      );
      return Err<T>(
        Failure(
          kind: FailureKind.server,
          message: 'Dữ liệu trả về không đúng định dạng.',
          statusCode: response.statusCode,
          cause: e,
          stackTrace: s,
        ),
      );
    }
  }
}
