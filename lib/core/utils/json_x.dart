/// Trích giá trị từ JSON một cách an toàn.
///
/// CoinGecko dùng snake_case; một số API khác dùng camelCase/PascalCase, nên
/// mọi hàm đều thử lần lượt các tên khoá truyền vào. Không bao giờ ném —
/// dữ liệu thiếu luôn về giá trị mặc định, vì một field lạ không đáng làm
/// sập cả màn hình.
extension JsonX on Map<String, dynamic> {
  Object? pick(List<String> keys) {
    for (final key in keys) {
      if (containsKey(key) && this[key] != null) return this[key];
      // Thử biến thể PascalCase/camelCase của chính khoá đó.
      final alt =
          key.isEmpty ? key : '${key[0].toUpperCase()}${key.substring(1)}';
      if (containsKey(alt) && this[alt] != null) return this[alt];
    }
    return null;
  }

  String str(List<String> keys, {String fallback = ''}) {
    final value = pick(keys);
    if (value == null) return fallback;
    return value.toString();
  }

  String? strOrNull(List<String> keys) {
    final value = pick(keys);
    final text = value?.toString().trim();
    return (text == null || text.isEmpty) ? null : text;
  }

  int intVal(List<String> keys, {int fallback = 0}) {
    final value = pick(keys);
    return switch (value) {
      final int v => v,
      final num v => v.toInt(),
      final String v => int.tryParse(v) ?? num.tryParse(v)?.toInt() ?? fallback,
      final bool v => v ? 1 : 0,
      _ => fallback,
    };
  }

  double dbl(List<String> keys, {double fallback = 0}) {
    final value = pick(keys);
    return switch (value) {
      final double v => v,
      final num v => v.toDouble(),
      final String v => double.tryParse(v.replaceAll(',', '')) ?? fallback,
      _ => fallback,
    };
  }

  bool flag(List<String> keys, {bool fallback = false}) {
    final value = pick(keys);
    return switch (value) {
      final bool v => v,
      final num v => v != 0,
      final String v =>
        const ['true', '1', 'y', 'yes'].contains(v.toLowerCase()),
      _ => fallback,
    };
  }

  DateTime? date(List<String> keys) {
    final value = pick(keys);
    if (value is DateTime) return value;
    if (value is int) {
      // Epoch giây hoặc mili giây.
      return DateTime.fromMillisecondsSinceEpoch(
        value < 100000000000 ? value * 1000 : value,
      );
    }
    final text = value?.toString();
    if (text == null || text.isEmpty) return null;
    return DateTime.tryParse(text);
  }

  Map<String, dynamic> obj(List<String> keys) {
    final value = pick(keys);
    return value is Map<String, dynamic> ? value : const <String, dynamic>{};
  }

  List<Map<String, dynamic>> objList(List<String> keys) {
    final value = pick(keys);
    if (value is! List) return const [];
    return value.whereType<Map<String, dynamic>>().toList();
  }

  List<String> strList(List<String> keys) {
    final value = pick(keys);
    if (value is! List) return const [];
    return value.map((e) => e.toString()).toList();
  }

  /// Parse danh sách model con.
  List<T> modelList<T>(
    List<String> keys,
    T Function(Map<String, dynamic> json) fromJson,
  ) =>
      objList(keys).map(fromJson).toList();
}
