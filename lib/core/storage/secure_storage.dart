// SecureStorage — bọc FlutterSecureStorage cho dữ liệu nhạy cảm (token, session).
//
// Khác với LocalStorage (SharedPreferences):
// - Chỉ dùng cho accessToken, refreshToken, thông tin phiên bảo mật.
// - Không lưu dữ liệu nhạy cảm dạng plain-text trong SharedPreferences.
// - Cung cấp read / write / delete / deleteAll an toàn, không làm vỡ bootstrap.
