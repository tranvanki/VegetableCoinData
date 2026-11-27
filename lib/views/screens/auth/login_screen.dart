// LoginScreen — màn hình đăng nhập (/auth/login).
//
// Giai đoạn Mock (USE_MOCK_API=true):
// - Cho phép đăng nhập mock (validate bằng Validators) hoặc chọn nhanh vai trò
//   Demo Trader / Verified Trader để test luồng AuthN/AuthZ và Demo Trading.
// - Luôn hiển thị rõ nhãn "MOCK AUTH / DEMO".
// Giai đoạn BFF/OIDC (USE_MOCK_API=false):
// - Chuyển sang Authorization Code + PKCE bằng trình duyệt hệ thống (flutter_appauth), không dùng WebView nhúng.
