/// Envelope tuỳ chọn dạng `{ok, msg, data}` cho API bọc dữ liệu.
/// CoinGecko trả JSON thô nên [looksLikeEnvelope] sẽ bỏ qua và dùng nguyên body.
class ApiEnvelope {
  const ApiEnvelope({
    required this.ok,
    this.message,
    this.data,
    this.code,
  });

  factory ApiEnvelope.fromJson(Map<String, dynamic> json) {
    final okValue = json['ok'] ?? json['success'] ?? json['Ok'];
    return ApiEnvelope(
      ok: switch (okValue) {
        final bool b => b,
        final num n => n != 0,
        final String s => s.toLowerCase() == 'true' || s == '1',
        _ => true,
      },
      message: (json['msg'] ?? json['message'] ?? json['Message']) as String?,
      data: json['data'] ?? json['Data'],
      code: (json['code'] ?? json['Code'])?.toString(),
    );
  }

  final bool ok;
  final String? message;
  final Object? data;
  final String? code;

  /// Body có phải envelope hay không — nếu không, coi cả body là `data`.
  static bool looksLikeEnvelope(Object? body) =>
      body is Map<String, dynamic> &&
      (body.containsKey('ok') ||
          body.containsKey('success') ||
          body.containsKey('Ok'));

  /// Bóc `data` ra khỏi envelope; body thường thì trả nguyên body.
  static Object? unwrap(Object? body) {
    if (!looksLikeEnvelope(body)) return body;
    return ApiEnvelope.fromJson(body! as Map<String, dynamic>).data;
  }
}
