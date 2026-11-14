import 'dart:async';

import 'package:dio/dio.dart';

import '../../config/app_constants.dart';
import '../../utils/logger.dart';

//ui->provider/repository() ->hybridapiclient(chon live/mock)->dio_apiclient()->dio
//->httpserver
/// Gắn access token và tự làm mới khi gặp 401.
///
/// Chỉ MỘT lần refresh chạy tại một thời điểm; các request 401 khác xếp hàng
/// chờ kết quả rồi phát lại, tránh bão refresh khi mở app nhiều tab dữ liệu.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    //named constructor
    required this.tokenProvider,
    required this.onRefresh,
    required this.onSessionExpired,
    required this.retryClient,
  });

  /// Trả access token hiện tại (null nếu chưa đăng nhập).
  final Future<String?> Function() tokenProvider;

  /// Thực hiện refresh. Trả `true` nếu đã có token mới.
  final Future<bool> Function() onRefresh;

  /// Gọi khi refresh thất bại — AuthProvider sẽ logout và điều hướng về login.
  final void Function() onSessionExpired;

  /// Dio dùng để phát lại request (không gắn lại interceptor này).
  final Dio Function() retryClient;

  /// Prefix công khai — không gắn token và không refresh khi gặp 401.
  ///
  /// Toàn bộ API dữ liệu CoinGecko là public; chỉ các endpoint hệ thống của
  /// app mới cần access token.
  static const Set<String> _publicPrefixes = {
    '/coins',
    '/global',
    '/search',
  };

  bool _isPublic(String path) => _publicPrefixes.any(path.startsWith);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isPublic(options.path)) {
      final storedToken = await tokenProvider();
      if (storedToken != null && storedToken.isNotEmpty) {
        options.headers[AppConstants.headerAuthorization] =
            'Bearer $storedToken';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;
    final path = err.requestOptions.path;

    if (status != 401 ||
        _isPublic(path) ||
        err.requestOptions.extra['__retried'] == true) {
      return handler.next(err);
    }

    AppLogger.w('401 tại $path → thử refresh token', tag: 'Auth');

    bool refreshed = false;
    try {
      refreshed = await onRefresh();
    } catch (e, s) {
      AppLogger.e('Refresh token lỗi', tag: 'Auth', error: e, stackTrace: s);
    }

    if (!refreshed) {
      onSessionExpired();
      return handler.next(err);
    }

    try {
      final token = await tokenProvider();
      if (token == null || token.isEmpty) {
        return handler.next(err);
      }

      final options = err.requestOptions
        ..extra['__retried'] = true
        ..headers[AppConstants.headerAuthorization] = 'Bearer $token';

      final response = await retryClient().fetch<dynamic>(options);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }
}
