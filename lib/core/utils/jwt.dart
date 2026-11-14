import 'dart:convert';

/// Đọc phần payload của một JWT.
///
/// KHÔNG kiểm chữ ký — và đó là chủ ý: ID token được lấy trực tiếp từ token
/// endpoint của nhà cung cấp danh tính (IdP) qua TLS trong luồng Authorization
/// Code (AppAuth đã xác thực sẵn), nên theo OIDC Core §3.1.3.7 client không bắt buộc phải tự
/// kiểm lại chữ ký. Hàm này chỉ dùng cho token do CHÍNH app vừa nhận về, tuyệt
/// đối không dùng để xác thực token đến từ nguồn ngoài.
class Jwt {
  const Jwt._();

  /// Trả payload đã giải mã, hoặc map rỗng nếu token không hợp lệ.
  static Map<String, dynamic> decodePayload(String token) {
    if (token.isEmpty) return const {};

    final parts = token.split('.');
    if (parts.length != 3) return const {};

    try {
      final decoded =
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final json = jsonDecode(decoded);
      return json is Map<String, dynamic> ? json : const {};
    } catch (_) {
      // Token méo mó thì coi như không có claim — caller tự rơi về userinfo.
      return const {};
    }
  }
}
