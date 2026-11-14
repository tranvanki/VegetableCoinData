import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_dimens.dart';

/// Theme sáng/tối của app. Màn hình lấy style từ `Theme.of(context)`,
/// không tự dựng TextStyle rời rạc.
class AppTheme {
  const AppTheme._();

  static ThemeData light() => _base(Brightness.light);
  static ThemeData dark() => _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      error: AppColors.error,
      surface: isDark ? AppColors.surfaceDark : AppColors.surface,
    );

    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final subTextColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final dividerColor = isDark ? AppColors.dividerDark : AppColors.divider;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.background,
      dividerColor: dividerColor,
      // Dùng font hệ thống: tiếng Việt có dấu hiển thị chuẩn trên mọi máy và
      // không phải gánh thêm dung lượng font. Đổi ở đây nếu brand có font riêng.
      fontFamily: null,

      // Header đỏ thương hiệu ở cả hai chế độ — đây là mảng nhận diện mạnh
      // nhất của app bán lẻ, giữ nguyên để không lẫn với app khác.
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: Color.fromARGB(255, 5, 140, 110),
        foregroundColor: AppColors.textOnPrimary,
        iconTheme: IconThemeData(color: AppColors.textOnPrimary),
        actionsIconTheme: IconThemeData(color: AppColors.textOnPrimary),
        // Chữ trên thanh trạng thái phải sáng vì nền header đỏ đậm.
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          color: AppColors.textOnPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),

      textTheme: _textTheme(textColor, subTextColor),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          disabledBackgroundColor: AppColors.textDisabled,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.surfaceVariantDark : AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        hintStyle: TextStyle(color: subTextColor, fontSize: 14),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor:
            isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant,
        selectedColor: AppColors.primaryLight,
        labelStyle: TextStyle(color: textColor, fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        side: BorderSide.none,
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: subTextColor,
        selectedLabelStyle: const TextStyle(fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        elevation: 8,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
        ),
        showDragHandle: true,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),

      // Mọi TabBar trong app đều nằm trong AppBar đỏ, nên nhãn phải màu trắng.
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.textOnPrimary,
        unselectedLabelColor: Colors.white70,
        indicatorColor: AppColors.textOnPrimary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
      ),

      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: AppColors.primary),

      dividerTheme: DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static TextTheme _textTheme(Color primary, Color secondary) => TextTheme(
        displayLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: primary,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: primary,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: primary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: primary,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: primary,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: primary),
        bodyMedium: TextStyle(fontSize: 14, color: primary),
        bodySmall: TextStyle(fontSize: 12, color: secondary),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: primary,
        ),
        labelSmall: TextStyle(fontSize: 11, color: secondary),
      );
}
