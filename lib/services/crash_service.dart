import 'package:flutter/foundation.dart';

import '../core/utils/logger.dart';

/// Thu thập lỗi không bắt được. Cài đặt thật (Crashlytics/Sentry) thay vào
/// trong DI; chỗ gọi không đổi.
abstract interface class CrashService {
  Future<void> initialize();
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    String? context,
    bool fatal = false,
  });
  Future<void> setUserIdentifier(String? userId);
  Future<void> log(String message);
}

/// Mặc định: in ra console. Giữ nguyên hành vi "không bao giờ làm sập app vì
/// lỗi của chính lớp báo lỗi".
class ConsoleCrashService implements CrashService {
  const ConsoleCrashService();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    String? context,
    bool fatal = false,
  }) async {
    // In thẳng, KHÔNG qua AppLogger: bootstrap gắn AppLogger.onError trỏ ngược
    // về đây, nên gọi AppLogger ở đây tạo vòng lặp logger → crash → logger
    // (biểu hiện là chuỗi "Crash: Crash: Crash: ..." dài vô tận rồi tràn stack).
    debugPrint(
      '[CRASH]${fatal ? '[FATAL]' : ''} ${context ?? 'Lỗi không bắt được'}',
    );
    debugPrint('  $error');
    if (kDebugMode && stackTrace != null) {
      debugPrintStack(stackTrace: stackTrace, maxFrames: 20);
    }
  }

  @override
  Future<void> setUserIdentifier(String? userId) async {}

  @override
  Future<void> log(String message) async {
    AppLogger.i(message, tag: 'Crash');
  }
}
