// MockFixtures — dữ liệu mẫu tĩnh cho MockApiClient (Auth & Trading Demo).
//
// Nội dung dự kiến:
// - Tài khoản mock theo 3 vai trò: guest, demoTrader, verifiedTrader.
// - Token JWT mock hợp lệ về cấu trúc để test Jwt.decodePayload và AuthInterceptor.
// - Số dư ví Demo mặc định (ví dụ: 10,000 USDT) và phản hồi lỗi chuẩn {ok, msg, code}.
