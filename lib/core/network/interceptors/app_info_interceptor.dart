import 'package:dio/dio.dart';

import '../../config/app_constants.dart';

/// Gắn header định danh thiết bị/phiên bản cho MỌI request — backend dùng để
/// phân tích, force-update và điều tra sự cố theo `X-Request-Id`.
class AppInfoInterceptor extends Interceptor {
  AppInfoInterceptor({
    required this.deviceId,
    required this.platform,
    required this.appVersion,
    required this.localeProvider,
    required this.requestIdFactory,
  });

  final String deviceId;
  final String platform;
  final String appVersion;
  final String Function() localeProvider;
  final String Function() requestIdFactory;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers[AppConstants.headerDeviceId] = deviceId;
    options.headers[AppConstants.headerPlatform] = platform;
    options.headers[AppConstants.headerAppVersion] = appVersion;
    options.headers[AppConstants.headerLocale] = localeProvider();
    options.headers[AppConstants.headerRequestId] = requestIdFactory();
    handler.next(options);
  }
}
