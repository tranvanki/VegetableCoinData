// MockApiClient — cài đặt giả lập của ApiClient dùng khi USE_MOCK_API=true.
//
// Trách nhiệm:
// - Trả Result<T> từ MockFixtures cho các endpoint Auth / Profile / Trading BFF
//   để app chạy và test đầy đủ mà không cần backend thật.
// - Chỉ gắn cho authApiClient (publicApiClient vẫn gọi CoinGecko/Binance thật
//   hoặc mock riêng khi cần test offline).
// - Hỗ trợ giả lập độ trễ mạng và lỗi 401/429/business để test UI & retry.
