/// Phân loại lỗi để UI quyết định cách hiển thị (toast / trang lỗi / điều hướng).
enum FailureKind {
  /// Mất mạng, DNS, timeout kết nối.
  network,

  /// Server trả 5xx hoặc body không parse được.
  server,

  /// 401/403 - token hết hạn hoặc không đủ quyền.
  unauthorized,

  /// 400/422 - sai dữ liệu đầu vào, kèm [Failure.fieldErrors].
  validation,

  /// 404.
  notFound,

  /// 429 - bị rate limit (OTP, tìm kiếm...).
  rateLimited,

  /// Người dùng huỷ (đóng sheet thanh toán, huỷ chọn ảnh...).
  cancelled,

  /// Lỗi nghiệp vụ do backend chủ động trả (`ok: false`).
  business,

  unknown,
}

/// Lỗi đã được chuẩn hoá, an toàn để hiển thị cho người dùng.
///
/// Mọi `throw` của tầng dưới phải được map về đây trước khi lên ViewModel —
/// ViewModel và View không bao giờ thấy `DioException`.
class Failure implements Exception {
  const Failure({
    required this.kind,
    required this.message,
    this.code,
    this.statusCode,
    this.fieldErrors = const {},
    this.cause,
    this.stackTrace,
  });

  const Failure.network(this.message, {this.cause, this.stackTrace})
      : kind = FailureKind.network,
        code = null,
        statusCode = null,
        fieldErrors = const {};

  const Failure.unknown(this.message, {this.cause, this.stackTrace})
      : kind = FailureKind.unknown,
        code = null,
        statusCode = null,
        fieldErrors = const {};

  const Failure.business(this.message, {this.code})
      : kind = FailureKind.business,
        statusCode = null,
        fieldErrors = const {},
        cause = null,
        stackTrace = null;

  final FailureKind kind;

  /// Thông điệp tiếng Việt, đã sẵn sàng hiển thị.
  final String message;

  /// Mã lỗi nghiệp vụ của backend (nếu có), ví dụ `OTP_LIMIT_EXCEEDED`.
  final String? code;

  final int? statusCode;

  /// Lỗi theo từng field cho form: `{'phone': 'Số điện thoại không hợp lệ'}`.
  final Map<String, String> fieldErrors;

  final Object? cause;
  final StackTrace? stackTrace;

  bool get isUnauthorized => kind == FailureKind.unauthorized;
  bool get isNetwork => kind == FailureKind.network;
  bool get isCancelled => kind == FailureKind.cancelled;

  /// Lỗi đáng gửi lên crash reporting (lỗi mạng/nghiệp vụ thì không).
  bool get shouldReport =>
      kind == FailureKind.server || kind == FailureKind.unknown;

  Failure copyWith({String? message, String? code}) => Failure(
        kind: kind,
        message: message ?? this.message,
        code: code ?? this.code,
        statusCode: statusCode,
        fieldErrors: fieldErrors,
        cause: cause,
        stackTrace: stackTrace,
      );

  @override
  String toString() =>
      'Failure(${kind.name}, status: $statusCode, code: $code, message: $message)';
}
