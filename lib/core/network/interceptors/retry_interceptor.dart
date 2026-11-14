import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';

import '../../utils/logger.dart';

/// Thử lại các request đọc (GET) khi lỗi mạng tạm thời hoặc 5xx,
/// backoff luỹ thừa có jitter. Không bao giờ retry POST/PUT/DELETE để
/// tránh ghi dữ liệu hai lần.
class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    required this.dio,
    this.maxRetries = 2,
    this.baseDelay = const Duration(milliseconds: 400),
  });

  final Dio dio;
  final int maxRetries;
  final Duration baseDelay;
  final Random _random = Random();

  static const String _attemptKey = '__retry_attempt';

  bool _isRetryable(DioException err) {
    if (err.requestOptions.method.toUpperCase() != 'GET') return false;
    if (err.type == DioExceptionType.cancel) return false;

    final status = err.response?.statusCode;
    if (status != null) return status >= 500 && status != 501;

    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.connectionError;
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final attempt = (err.requestOptions.extra[_attemptKey] as int?) ?? 0;

    if (attempt >= maxRetries || !_isRetryable(err)) {
      return handler.next(err);
    }

    final delayMs = baseDelay.inMilliseconds * pow(2, attempt).toInt() +
        _random.nextInt(200);
    AppLogger.d(
      'Retry ${attempt + 1}/$maxRetries sau ${delayMs}ms: ${err.requestOptions.path}',
      tag: 'Http',
    );
    await Future<void>.delayed(Duration(milliseconds: delayMs));

    final options = err.requestOptions..extra[_attemptKey] = attempt + 1;
    try {
      final response = await dio.fetch<dynamic>(options);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }
}
