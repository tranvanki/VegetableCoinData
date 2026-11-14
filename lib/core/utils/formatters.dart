import 'package:intl/intl.dart';

/// Định dạng hiển thị theo chuẩn Việt Nam. Dùng chung để con số và ngày
/// tháng trông giống nhau ở mọi màn hình.
class Formatters {
  const Formatters._();

  static final NumberFormat _currency = NumberFormat.decimalPattern('vi_VN');
  static final NumberFormat _compact = NumberFormat.compact(locale: 'vi_VN');
  static final DateFormat _date = DateFormat('dd/MM/yyyy', 'vi_VN');
  static final DateFormat _dateTime = DateFormat('HH:mm dd/MM/yyyy', 'vi_VN');
  static final DateFormat _time = DateFormat('HH:mm', 'vi_VN');
  static final NumberFormat _usdCompact = NumberFormat.compactCurrency(
    locale: 'en_US',
    symbol: r'$',
    decimalDigits: 2,
  );
  static final NumberFormat _usdLarge = NumberFormat.currency(
    locale: 'en_US',
    symbol: r'$',
    decimalDigits: 2,
  );
  static final NumberFormat _usdSmall = NumberFormat.currency(
    locale: 'en_US',
    symbol: r'$',
    decimalDigits: 4,
  );
  static final NumberFormat _usdTiny = NumberFormat.currency(
    locale: 'en_US',
    symbol: r'$',
    decimalDigits: 8,
  );

  /// Giá coin theo USD: `$65,420.50`; coin giá nhỏ hiện thêm chữ số thập
  /// phân (`$0.00001234`). null hiện `—`.
  static String usd(num? value) {
    if (value == null) return '—';
    final abs = value.abs();
    if (abs >= 1) return _usdLarge.format(value);
    if (abs >= 0.01) return _usdSmall.format(value);
    return _usdTiny.format(value);
  }

  /// Giá trị lớn gọn: `$2.62T`, `$95.1B` (3 chữ số có nghĩa). null hiện `—`.
  static String usdCompact(num? value) =>
      value == null ? '—' : _usdCompact.format(value);

  /// `29.990.000₫`. Giá 0 hiển thị "Liên hệ" theo thông lệ ngành hàng.
  static String price(num? value, {String zeroText = 'Liên hệ'}) {
    if (value == null || value <= 0) return zeroText;
    return '${_currency.format(value)}₫';
  }

  /// `29.990.000` — không kèm ký hiệu tiền.
  static String number(num? value) => _currency.format(value ?? 0);

  /// `1,2 N` cho lượt xem/đánh giá.
  static String compact(num? value) => _compact.format(value ?? 0);

  static String date(DateTime? value) =>
      value == null ? '' : _date.format(value);

  static String dateTime(DateTime? value) =>
      value == null ? '' : _dateTime.format(value);

  static String time(DateTime? value) =>
      value == null ? '' : _time.format(value);

  /// `2 giờ trước`, `hôm qua`, `12/03/2026`.
  static String relative(DateTime? value) {
    if (value == null) return '';
    final diff = DateTime.now().difference(value);

    if (diff.inSeconds < 60) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays == 1) return 'Hôm qua';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return date(value);
  }

  /// Đếm ngược flash sale: `02:15:30`.
  static String countdown(Duration duration) {
    if (duration.isNegative) return '00:00:00';
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  /// Che số điện thoại khi hiển thị công khai: `090****567`.
  static String maskPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 7) return phone;
    return '${digits.substring(0, 3)}****${digits.substring(digits.length - 3)}';
  }

  static String maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2 || parts.first.length < 2) return email;
    final name = parts.first;
    return '${name[0]}${'*' * (name.length - 1)}@${parts[1]}';
  }

  /// `+3.45%` / `-2.10%` cho biến động giá 24h.
  static String percentChange(num value) {
    final sign = value > 0 ? '+' : '';
    return '$sign${value.toStringAsFixed(2)}%';
  }
}
