/// Khoảng cách, bo góc và kích thước dùng chung.
/// Mọi `EdgeInsets`/`BorderRadius` trong app lấy số từ đây.
class AppSpacing {
  const AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  /// Lề ngang chuẩn của mọi màn hình.
  static const double screenPadding = 16;
}

class AppRadius {
  const AppRadius._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double pill = 999;
}

class AppSizes {
  const AppSizes._();

  static const double buttonHeight = 48;
  static const double buttonHeightSmall = 36;
  static const double inputHeight = 48;
  static const double appBarHeight = 56;
  static const double bottomNavHeight = 60;
  static const double iconSm = 16;
  static const double iconMd = 24;
  static const double iconLg = 32;
  static const double avatarSm = 32;
  static const double avatarMd = 48;
  static const double avatarLg = 72;

  /// Tỉ lệ khung ảnh sản phẩm trong lưới.
  static const double productImageAspectRatio = 1;

  /// Tỉ lệ thẻ sản phẩm (ảnh + tên + giá) — dùng cho `childAspectRatio`.
  ///
  /// Ảnh là ô vuông bằng chiều rộng thẻ, phần chữ cần thêm ~120px (tên 2 dòng,
  /// giá, giá gạch + badge giảm, điểm đánh giá) và còn phải chịu được cỡ chữ
  /// hệ thống phóng tới 1.3 lần. Trên máy hẹp một cột rộng ~158px thì thẻ cao
  /// ~282px — đúng tỉ lệ này. Đặt lớn hơn là thẻ bị tràn.
  static const double productCardAspectRatio = 0.56;
}
