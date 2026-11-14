/// Kiểm tra dữ liệu nhập. Trả `null` khi hợp lệ, ngược lại là thông báo lỗi
/// tiếng Việt — khớp chữ ký `FormFieldValidator<String>`.
///
/// Đây chỉ là lớp chặn đầu tiên cho trải nghiệm; backend vẫn phải validate lại.
class Validators {
  const Validators._();

  /// Đầu số di động Việt Nam sau quy hoạch 2018: 03, 05, 07, 08, 09.
  static final RegExp _phone = RegExp(r'^(0|\+84)(3|5|7|8|9)\d{8}$');
  static final RegExp _email =
      RegExp(r'^[\w.!#$%&*+/=?^`{|}~-]+@[\w-]+(\.[\w-]+)+$');

  static String? required$(String? value, {String field = 'Trường này'}) {
    if (value == null || value.trim().isEmpty) {
      return '$field không được để trống';
    }
    return null;
  }

  static String? phone(String? value) {
    final text = value?.replaceAll(RegExp(r'[\s.]'), '') ?? '';
    if (text.isEmpty) return 'Vui lòng nhập số điện thoại';
    if (!_phone.hasMatch(text)) return 'Số điện thoại không hợp lệ';
    return null;
  }

  static String? email(String? value, {bool optional = false}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return optional ? null : 'Vui lòng nhập email';
    if (!_email.hasMatch(text)) return 'Email không hợp lệ';
    return null;
  }

  /// Tối thiểu 8 ký tự, có cả chữ và số.
  static String? password(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Vui lòng nhập mật khẩu';
    if (text.length < 8) return 'Mật khẩu tối thiểu 8 ký tự';
    if (!RegExp(r'[A-Za-z]').hasMatch(text) || !RegExp(r'\d').hasMatch(text)) {
      return 'Mật khẩu cần có cả chữ và số';
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value != original) return 'Mật khẩu nhập lại không khớp';
    return null;
  }

  static String? otp(String? value, {int length = 6}) {
    final text = value?.trim() ?? '';
    if (text.length != length) return 'Mã OTP gồm $length chữ số';
    if (!RegExp(r'^\d+$').hasMatch(text)) return 'Mã OTP chỉ gồm chữ số';
    return null;
  }

  static String? fullName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Vui lòng nhập họ tên';
    if (text.length < 2) return 'Họ tên quá ngắn';
    if (!text.contains(' ')) return 'Vui lòng nhập đầy đủ họ và tên';
    return null;
  }

  /// Mã số thuế Việt Nam: 10 số, hoặc 13 số dạng `xxxxxxxxxx-xxx`.
  static String? taxCode(String? value) {
    final text = value?.trim().replaceAll(' ', '') ?? '';
    if (text.isEmpty) return 'Vui lòng nhập mã số thuế';
    if (!RegExp(r'^\d{10}(-\d{3})?$').hasMatch(text)) {
      return 'Mã số thuế không hợp lệ';
    }
    return null;
  }

  /// Mã định danh thiết bị (serial).
  static String? deviceSerial(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Vui lòng nhập serial thiết bị';
    if (text.length < 6) return 'Serial thiết bị không hợp lệ';
    return null;
  }

  /// Chuẩn hoá số điện thoại về dạng `0xxxxxxxxx` trước khi gửi backend.
  static String normalizePhone(String value) {
    final digits = value.replaceAll(RegExp(r'[\s.\-()]'), '');
    if (digits.startsWith('+84')) return '0${digits.substring(3)}';
    if (digits.startsWith('84') && digits.length == 11) {
      return '0${digits.substring(2)}';
    }
    return digits;
  }
}
