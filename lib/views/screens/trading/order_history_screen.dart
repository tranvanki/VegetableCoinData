// OrderHistoryScreen — danh sách vị thế & lịch sử lệnh (/orders, yêu cầu đăng nhập).
//
// Trách nhiệm hiển thị:
// - Gắn banner DEMO / PAPER TRADING rõ ràng khi TradingProvider.mode == TradingMode.demo.
// - Hiển thị danh sách vị thế đang nắm giữ và lịch sử lệnh từ TradingProvider (loading/empty/error qua state_views).
// - Bảo vệ bằng GoRouter requiresAuth() và AppPermission.viewDemoOrders.
