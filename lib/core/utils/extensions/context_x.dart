import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../error/failure.dart';

/// Tiện ích trên BuildContext — rút gọn những thứ gõ đi gõ lại trong View.
extension ContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textStyles => Theme.of(this).textTheme;
  ColorScheme get colors => Theme.of(this).colorScheme;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  MediaQueryData get mq => MediaQuery.of(this);
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;
  EdgeInsets get safeArea => MediaQuery.paddingOf(this);
  double get keyboardHeight => MediaQuery.viewInsetsOf(this).bottom;
  bool get isKeyboardOpen => MediaQuery.viewInsetsOf(this).bottom > 0;

  /// Máy tablet/màn hình lớn — dùng để tăng số cột lưới coin.
  bool get isWideScreen => MediaQuery.sizeOf(this).width >= 600;

  int get coinGridColumns => isWideScreen ? 3 : 2;

  // ---------------------------- Thông báo -------------------------------

  void showSnack(String message,
      {bool isError = false, SnackBarAction? action}) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? AppColors.error : null,
          duration: const Duration(seconds: 3),
          action: action,
        ),
      );
  }

  /// Hiển thị lỗi đã chuẩn hoá. Lỗi do người dùng huỷ thì im lặng.
  void showFailure(Failure? failure) {
    if (failure == null || failure.isCancelled) return;
    showSnack(failure.message, isError: true);
  }

  void showSuccess(String message) => showSnack(message);

  // ---------------------------- Hộp thoại -------------------------------

  Future<bool> confirm({
    required String title,
    required String message,
    String confirmLabel = 'Đồng ý',
    String cancelLabel = 'Huỷ',
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: this,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: isDestructive
                ? TextButton.styleFrom(foregroundColor: AppColors.error)
                : null,
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void unfocus() => FocusScope.of(this).unfocus();
}
