// PaperTradingLocalDataSource — lưu trữ SQLite cục bộ (paper_trading.db) cho Demo Trading.
//
// Tách riêng khỏi binance_market.db để nâng cấp schema độc lập:
// - Bảng demo_accounts (user_id PK, quote_asset, available_balance, initial_balance, updated_at).
// - Bảng demo_positions (user_id + symbol PK, base_asset, quantity, avg_entry_price, updated_at).
// - Bảng demo_orders (client_order_id PK, user_id, symbol, side, order_type, execution_mode,
//   quantity, executed_price, total_quote, fee_quote, status, created_at).
// - Mọi thao tác đặt lệnh chạy trong một SQLite transaction nguyên tử và kiểm tra trùng client_order_id.
