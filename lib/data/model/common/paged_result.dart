/// Trang dữ liệu chuẩn cho mọi danh sách có phân trang.
///
/// Chấp nhận cả hai kiểu phân trang backend hay dùng: theo trang
/// (`page`/`pageSize`/`total`) và theo con trỏ (`nextCursor`).
class PagedResult<T> {
  const PagedResult({
    required this.items,
    this.page = 1,
    this.pageSize = 20,
    this.total = 0,
    this.nextCursor,
  });

  const PagedResult.empty()
      : items = const [],
        page = 1,
        pageSize = 20,
        total = 0,
        nextCursor = null;

  factory PagedResult.fromJson(
    Object? json,
    T Function(Map<String, dynamic> item) itemFromJson,
  ) {
    // Backend có thể trả thẳng một mảng khi không phân trang.
    if (json is List) {
      final items =
          json.whereType<Map<String, dynamic>>().map(itemFromJson).toList();
      return PagedResult<T>(items: items, total: items.length);
    }

    final map = json is Map<String, dynamic> ? json : const <String, dynamic>{};
    final rawItems = map['items'] ?? map['data'] ?? map['results'] ?? const [];

    return PagedResult<T>(
      items: rawItems is List
          ? rawItems
              .whereType<Map<String, dynamic>>()
              .map(itemFromJson)
              .toList()
          : const [],
      page: _asInt(map['page'] ?? map['pageIndex'], 1),
      pageSize: _asInt(map['pageSize'] ?? map['limit'], 20),
      total: _asInt(map['total'] ?? map['totalCount'] ?? map['totalItems'], 0),
      nextCursor: map['nextCursor']?.toString(),
    );
  }

  final List<T> items;
  final int page;
  final int pageSize;
  final int total;
  final String? nextCursor;

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  /// Còn trang sau hay không — ưu tiên con trỏ, sau đó mới suy ra từ tổng số.
  bool get hasMore {
    if (nextCursor != null && nextCursor!.isNotEmpty) return true;
    if (total > 0) return page * pageSize < total;
    return items.length >= pageSize;
  }

  int get nextPage => page + 1;

  /// Nối trang mới vào trang hiện có (dùng cho infinite scroll).
  PagedResult<T> append(PagedResult<T> next) => PagedResult<T>(
        items: [...items, ...next.items],
        page: next.page,
        pageSize: next.pageSize,
        total: next.total,
        nextCursor: next.nextCursor,
      );

  PagedResult<R> map<R>(R Function(T item) transform) => PagedResult<R>(
        items: items.map(transform).toList(),
        page: page,
        pageSize: pageSize,
        total: total,
        nextCursor: nextCursor,
      );

  static int _asInt(Object? value, int fallback) => switch (value) {
        final int v => v,
        final num v => v.toInt(),
        final String v => int.tryParse(v) ?? fallback,
        _ => fallback,
      };
}
