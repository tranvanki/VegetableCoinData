// TokenStorage — quản lý vòng đời token phiên đăng nhập trên SecureStorage.
//
// Trách nhiệm:
// - Lưu/đọc/xoá: accessToken, refreshToken, expiresAt, mockRole (khi USE_MOCK_API=true).
// - Cung cấp callback tokenProvider cho AuthInterceptor (chỉ gắn trên authApiClient).
// - Hỗ trợ rotation refresh token (luôn ghi đè refreshToken mới sau mỗi lần refresh).
