// AuthSession, AuthUser, UserRole, AppPermission — model xác thực & phân quyền.
//
// Dự kiến định nghĩa:
// - enum UserRole { guest, demoTrader, verifiedTrader }
// - enum AppPermission { viewMarket, manageWatchlist, tradeDemo, viewDemoOrders, resetDemoWallet, tradeLive }
// - AuthUser (id, email, displayName, role, isMock)
// - AuthSession (user, accessToken, refreshToken, expiresAt)
// - AuthorizationPolicy: bảng ánh xạ UserRole -> Set<AppPermission>, dùng chung cho GoRouter và TradingProvider.
