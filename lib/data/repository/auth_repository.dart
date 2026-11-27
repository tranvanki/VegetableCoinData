// AuthRepository — hợp đồng xác thực (Mock trước, BFF/OIDC sau).
//
// Trách nhiệm:
// - restoreSession(): đọc TokenStorage lúc AppBootstrap trước runApp().
// - login(email, password) / switchMockRole(role): MockAuthRepository dùng khi USE_MOCK_API=true.
// - refreshSession(): phát lại token cho AuthInterceptor khi gặp 401.
// - logout(): xoá TokenStorage + LocalStorage.clearUserScoped(keepKeys).
// - Mọi hàm trả Result<T>, không throw exception ra ngoài.
