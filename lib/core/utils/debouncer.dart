import 'dart:async';

/// Hoãn chạy một hành động cho tới khi ngừng gọi trong [delay].
/// Dùng cho ô tìm kiếm coin, lọc thị trường, đổi khung thời gian biểu đồ.
class Debouncer {
  Debouncer(this.delay);

  final Duration delay;
  Timer? _timer;

  bool get isActive => _timer?.isActive ?? false;

  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  /// Chạy ngay và huỷ lần hẹn đang chờ (ví dụ khi người dùng bấm Enter).
  void flush(void Function() action) {
    _timer?.cancel();
    action();
  }

  void cancel() => _timer?.cancel();

  void dispose() => _timer?.cancel();
}

/// Chặn gọi lại quá nhanh — chỉ cho chạy tối đa một lần trong [interval].
/// Dùng cho nút làm mới/gửi form để tránh double-tap.
class Throttler {
  Throttler(this.interval);

  final Duration interval;
  DateTime? _lastRun;

  bool run(void Function() action) {
    final now = DateTime.now();
    if (_lastRun != null && now.difference(_lastRun!) < interval) return false;
    _lastRun = now;
    action();
    return true;
  }
}
