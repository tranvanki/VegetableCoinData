// AuthProvider — ViewModel phiên đăng nhập toàn app (app-scoped ChangeNotifier).
//
// Trách nhiệm:
// - Quản lý session hiện tại, UserRole, isAuthenticated, và helper can(AppPermission).
// - Khởi chạy restoreSession() trong AppBootstrap trước khi dựng router.
// - Gắn vào AppRouter.refreshListenable cùng AppStateProvider để tự kích hoạt redirect guard.
// - Cung cấp onSessionExpired() cho AuthInterceptor khi refresh token thất bại.
