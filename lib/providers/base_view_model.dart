import 'package:flutter/foundation.dart';

import '../core/error/failure.dart';
import '../core/result/result.dart';
import '../core/utils/logger.dart';

/// Trạng thái vòng đời của một màn hình.
enum ViewState {
  /// Chưa nạp lần nào.
  idle,

  /// Đang nạp lần đầu — hiện skeleton/shimmer.
  loading,

  /// Có dữ liệu.
  ready,

  /// Nạp xong nhưng không có dữ liệu — hiện empty state.
  empty,

  /// Lỗi khi chưa có dữ liệu nào — hiện trang lỗi kèm nút thử lại.
  error,
}

/// Lớp cha cho mọi ViewModel (ChangeNotifier) — giữ đúng tinh thần MVVM của
/// gs24_gps nhưng chuẩn hoá trạng thái và chặn `notifyListeners` sau dispose.
///
/// Quy ước: View chỉ đọc [state], [failure] và dữ liệu; mọi thay đổi đi qua
/// phương thức của ViewModel.
abstract class BaseViewModel extends ChangeNotifier {
  ViewState _state = ViewState.idle;
  Failure? _failure;
  bool _busy = false;
  bool _disposed = false;

  ViewState get state => _state;
  Failure? get failure => _failure;

  /// Đang chạy một thao tác phụ (thêm giỏ, lưu địa chỉ...) trong khi màn hình
  /// vẫn hiển thị dữ liệu cũ — dùng cho nút loading, không thay cả màn hình.
  bool get isBusy => _busy;

  bool get isLoading => _state == ViewState.loading;
  bool get isReady => _state == ViewState.ready;
  bool get hasError => _state == ViewState.error;
  bool get isEmpty => _state == ViewState.empty;
  bool get isDisposed => _disposed;

  @protected
  void setState(ViewState value) {
    if (_state == value) return;
    _state = value;
    if (value != ViewState.error) _failure = null;
    safeNotify();
  }

  @protected
  void setFailure(Failure value, {bool asScreenError = true}) {
    _failure = value;
    if (asScreenError) _state = ViewState.error;
    safeNotify();
  }

  @protected
  void setBusy({required bool value}) {
    if (_busy == value) return;
    _busy = value;
    safeNotify();
  }

  /// Xoá lỗi sau khi View đã hiển thị (snackbar/dialog), tránh hiện lại khi
  /// widget rebuild.
  void clearFailure() {
    if (_failure == null) return;
    _failure = null;
    safeNotify();
  }

  /// `notifyListeners` an toàn — ViewModel có thể bị dispose khi một request
  /// còn đang bay.
  @protected
  void safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  /// Chạy một tác vụ nạp dữ liệu và tự quản trạng thái màn hình.
  ///
  /// [isEmpty] quyết định hiển thị empty state; [keepDataOnError] để màn hình
  /// đang có dữ liệu không bị thay bằng trang lỗi khi refresh thất bại.
  @protected
  Future<void> runInitial<T>(
    Future<Result<T>> Function() task, {
    required void Function(T data) onData,
    bool Function(T data)? isEmpty,
    bool keepDataOnError = false,
  }) async {
    setState(ViewState.loading);
    final result = await task();

    if (_disposed) return;

    result.fold(
      onOk: (data) {
        onData(data);
        setState(
          (isEmpty?.call(data) ?? false) ? ViewState.empty : ViewState.ready,
        );
      },
      onErr: (error) {
        // Người dùng rời màn hình giữa chừng — không coi là lỗi.
        if (error.isCancelled) return;
        AppLogger.w(
          'Nạp dữ liệu lỗi: ${error.message}',
          tag: runtimeType.toString(),
        );
        setFailure(error, asScreenError: !keepDataOnError);
      },
    );
  }

  /// Chạy một hành động (ghi) và trả `true` nếu thành công.
  /// Lỗi được giữ ở [failure] để View hiện snackbar — không thay cả màn hình.
  @protected
  Future<bool> runAction<T>(
    Future<Result<T>> Function() task, {
    void Function(T data)? onData,
  }) async {
    setBusy(value: true);
    final result = await task();
    if (_disposed) return false;
    setBusy(value: false);

    return result.fold(
      onOk: (data) {
        onData?.call(data);
        safeNotify();
        return true;
      },
      onErr: (error) {
        if (!error.isCancelled) setFailure(error, asScreenError: false);
        return false;
      },
    );
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
