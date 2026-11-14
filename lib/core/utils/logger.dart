import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warn, error }

/// Log tập trung. Ở release chỉ warn/error được giữ lại và đẩy sang
/// crash reporter qua [AppLogger.onError].
class AppLogger {
  const AppLogger._();

  static bool enabled = !kReleaseMode;

  /// Gắn ở bootstrap để forward lỗi sang CrashService.
  static void Function(Object error, StackTrace? stack, {String? context})?
      onError;

  static void d(Object? message, {String? tag}) =>
      _log(LogLevel.debug, message, tag: tag);

  static void i(Object? message, {String? tag}) =>
      _log(LogLevel.info, message, tag: tag);

  static void w(Object? message, {String? tag}) =>
      _log(LogLevel.warn, message, tag: tag);

  static void e(
    Object? message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(LogLevel.error, message, tag: tag, error: error, stack: stackTrace);
    if (error != null) {
      onError?.call(error, stackTrace, context: '$tag: $message');
    }
  }

  static void _log(
    LogLevel level,
    Object? message, {
    String? tag,
    Object? error,
    StackTrace? stack,
  }) {
    if (!enabled && level.index < LogLevel.warn.index) return;

    final name = tag ?? 'Crypto';
    developer.log(
      '$message',
      name: name,
      level: switch (level) {
        LogLevel.debug => 500,
        LogLevel.info => 800,
        LogLevel.warn => 900,
        LogLevel.error => 1000,
      },
      error: error,
      stackTrace: stack,
    );

    // `developer.log` chỉ tới DevTools/VM service — KHÔNG xuống logcat, nên khi
    // chạy app đã cài trên máy thật (không qua `flutter run`) sẽ không thấy gì.
    // debugPrint đi theo stdout nên hiện ở `adb logcat -s flutter`.
    if (enabled) {
      debugPrint('[${level.name.toUpperCase()}][$name] $message');
      if (error != null) debugPrint('  error: $error');
      if (stack != null) debugPrint('  stack: $stack');
    }
  }
}
