import 'dart:io';

import 'package:dio/dio.dart';

import 'failure.dart';

/// Quy mọi lỗi tầng dưới (Dio, socket, parse) về [Failure] đã có thông điệp
/// tiếng Việt. Đây là nơi DUY NHẤT biết đến `DioException`.
class ErrorMapper {
  const ErrorMapper._();

  static Failure map(Object error, [StackTrace? stackTrace]) {
    if (error is Failure) return error;
    if (error is DioException) return _fromDio(error, stackTrace);
    if (error is SocketException) {
      return Failure.network(
        'Không có kết nối mạng. Vui lòng kiểm tra lại Wi-Fi hoặc 3G/4G.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
    if (error is FormatException) {
      return Failure(
        kind: FailureKind.server,
        message: 'Dữ liệu trả về không hợp lệ.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
    return Failure.unknown(
      'Đã có lỗi xảy ra. Vui lòng thử lại.',
      cause: error,
      stackTrace: stackTrace,
    );
  }

  static Failure _fromDio(DioException e, StackTrace? stackTrace) {
    final status = e.response?.statusCode;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      // Hết hạn khi Dio chuyển đổi body — với người dùng cũng là "chậm quá".
      case DioExceptionType.transformTimeout:
        return Failure(
          kind: FailureKind.network,
          message: 'Kết nối quá hạn. Vui lòng thử lại.',
          cause: e,
          stackTrace: stackTrace,
        );
      case DioExceptionType.connectionError:
        return Failure(
          kind: FailureKind.network,
          message: 'Không thể kết nối tới máy chủ. Kiểm tra kết nối mạng.',
          cause: e,
          stackTrace: stackTrace,
        );
      case DioExceptionType.cancel:
        return Failure(
          kind: FailureKind.cancelled,
          message: 'Yêu cầu đã bị huỷ.',
          cause: e,
          stackTrace: stackTrace,
        );
      case DioExceptionType.badCertificate:
        return Failure(
          kind: FailureKind.network,
          message: 'Chứng chỉ bảo mật không hợp lệ.',
          cause: e,
          stackTrace: stackTrace,
        );
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        break;
    }

    final body = e.response?.data;
    final serverMessage = _extractMessage(body);
    final fieldErrors = _extractFieldErrors(body);
    final code = _extractCode(body);

    final kind = switch (status) {
      401 || 403 => FailureKind.unauthorized,
      404 => FailureKind.notFound,
      400 || 422 => FailureKind.validation,
      429 => FailureKind.rateLimited,
      final int s when s >= 500 => FailureKind.server,
      _ => FailureKind.unknown,
    };

    return Failure(
      kind: kind,
      message: serverMessage ?? _defaultMessage(kind),
      code: code,
      statusCode: status,
      fieldErrors: fieldErrors,
      cause: e,
      stackTrace: stackTrace,
    );
  }

  static String _defaultMessage(FailureKind kind) => switch (kind) {
        FailureKind.unauthorized =>
          'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
        FailureKind.notFound => 'Không tìm thấy dữ liệu.',
        FailureKind.validation => 'Dữ liệu chưa hợp lệ. Vui lòng kiểm tra lại.',
        FailureKind.rateLimited =>
          'Bạn thao tác quá nhanh. Vui lòng thử lại sau ít phút.',
        FailureKind.server => 'Máy chủ đang bận. Vui lòng thử lại sau.',
        _ => 'Đã có lỗi xảy ra. Vui lòng thử lại.',
      };

  /// Envelope lỗi thường dùng khoá chữ thường `{ok, msg, data}`; đồng thời
  /// chấp nhận các tên phổ biến khác để không vỡ khi API đổi contract.
  static String? _extractMessage(Object? body) {
    if (body is! Map) return null;
    for (final key in const ['msg', 'message', 'Message', 'error', 'title']) {
      final value = body[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  static String? _extractCode(Object? body) {
    if (body is! Map) return null;
    final value = body['code'] ?? body['errorCode'] ?? body['Code'];
    return value?.toString();
  }

  static Map<String, String> _extractFieldErrors(Object? body) {
    if (body is! Map) return const {};
    // Định dạng ProblemDetails của ASP.NET: { "errors": { "Phone": ["..."] } }
    final errors = body['errors'] ?? body['Errors'];
    if (errors is! Map) return const {};
    final result = <String, String>{};
    errors.forEach((key, value) {
      final field = key.toString();
      if (value is List && value.isNotEmpty) {
        result[field] = value.first.toString();
      } else if (value is String) {
        result[field] = value;
      }
    });
    return result;
  }
}
