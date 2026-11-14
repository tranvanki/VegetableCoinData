import 'package:flutter/material.dart';

/// Bảng màu HHM. Đổi ở đây là đổi toàn app — màn hình không tự định nghĩa màu.
///
/// Giá trị hiện tại lấy theo nhận diện hoanghamobile.com; chốt lại với team
/// thiết kế trước khi phát hành (xem docs/01-development/ui-design-system.md).
class AppColors {
  const AppColors._();

  // --- Thương hiệu -------------------------------------------------------
  static const Color primary = Color(0xFFD70018);
  static const Color primaryDark = Color(0xFFA60012);
  static const Color primaryLight = Color(0xFFFFE8EA);
  static const Color secondary = Color(0xFF1C3FAA);
  static const Color accent = Color(0xFFFF8A00);

  // --- Trạng thái --------------------------------------------------------
  static const Color success = Color(0xFF0F9D58);
  static const Color warning = Color(0xFFF2A51A);
  static const Color error = Color(0xFFD93025);
  static const Color info = Color(0xFF1A73E8);

  // --- Nền sáng ----------------------------------------------------------
  static const Color background = Color(0xFFF5F5F7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F1F3);
  static const Color divider = Color(0xFFE4E6EB);

  // --- Chữ sáng ----------------------------------------------------------
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textDisabled = Color(0xFFA1A5AD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // --- Nền tối -----------------------------------------------------------
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color surfaceVariantDark = Color(0xFF2A2A2A);
  static const Color dividerDark = Color(0xFF333333);

  // --- Chữ tối -----------------------------------------------------------
  static const Color textPrimaryDark = Color(0xFFF5F5F5);
  static const Color textSecondaryDark = Color(0xFFB0B4BB);

  // --- Nghiệp vụ ---------------------------------------------------------
  static const Color priceColor = primary;
  static const Color discountBadge = primary;
  static const Color flashSale = Color(0xFFFF4D00);
  static const Color memberGold = Color(0xFFD4A017);
  static const Color outOfStock = Color(0xFF9AA0A6);
  static const Color ratingStar = Color(0xFFFFB300);

  /// Màu nền nhãn trạng thái đơn hàng.
  static Color orderStatusColor(String statusCode) => switch (statusCode) {
        'pending' || 'confirmed' => info,
        'awaiting_payment' => warning,
        'paid' || 'packing' || 'shipping' => secondary,
        'completed' => success,
        'cancelled' || 'returned' => error,
        _ => textSecondary,
      };
}
