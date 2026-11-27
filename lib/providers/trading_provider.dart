// TradingProvider — ViewModel điều phối đặt lệnh, ví Demo, vị thế và lịch sử lệnh.
//
// Kế thừa BaseViewModel; nguyên tắc an toàn:
// - Mặc định chạy TradingMode.demo qua DemoTradingRepository (paper_trading.db).
// - Kiểm tra AuthN/AuthZ qua AuthProvider + AuthorizationPolicy trước mọi thao tác.
// - Kiểm tra an toàn tiền giao dịch: giá live chưa stale, số lượng > 0, đủ số dư, clientOrderId chống double-submit.
// - Live mode bị khóa trừ khi đủ 4 điều kiện: ENABLE_LIVE_TRADING + RemoteConfig + tradeLive + xác nhận 2 bước.
