// TradingModels — các DTO/model thuần cho giao dịch (Safe Demo đầu tiên, sẵn sàng Live BFF).
//
// Dự kiến định nghĩa:
// - enum TradingMode { demo, live }  (mặc định cứng là demo)
// - enum OrderSide { buy, sell }
// - enum OrderType { market }
// - enum OrderStatus { pending, filled, rejected, cancelled }
// - OrderRequest (clientOrderId, userId, symbol, side, quantity, referencePrice, mode)
// - OrderPreview (totalQuote, estimatedFee, remainingBalance, warnings)
// - OrderRecord, DemoAccount, Position (bất biến, có toMap/fromMap cho paper_trading.db).
