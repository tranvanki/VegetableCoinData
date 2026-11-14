import '../core/network/api_client.dart';
import '../data/model/crypto/token_model.dart';
import '../data/repository/coin_repository.dart';
import 'base_view_model.dart';

/// ViewModel của màn Token List.
///
/// Chỉ nạp một lần rồi lọc cục bộ: `/coins/list` trả vài chục nghìn phần tử,
/// gọi lại API cho từng ký tự tìm kiếm sẽ đốt rate limit của CoinGecko.
class TokenListProvider extends BaseViewModel {
  TokenListProvider({required CoinRepository repository})
      : _repository = repository;

  final CoinRepository _repository;

  ApiCancelToken? _cancelToken;
  List<TokenModel> _tokens = const [];
  List<TokenModel> _filtered = const [];
  String _query = '';
  bool _initialized = false;

  /// Danh sách sau khi lọc theo [query].
  List<TokenModel> get tokens => _filtered;

  /// Toàn bộ token đã tải — dùng cho badge đếm.
  List<TokenModel> get allTokens => _tokens;

  int get totalCount => _tokens.length;
  String get query => _query;
  bool get hasQuery => _query.isNotEmpty;

  /// Gọi khi màn hình mở. Đã có dữ liệu thì không gọi lại API.
  Future<void> init() async {
    if (_initialized || isLoading) return;
    await load();
  }

  /// Nạp lần đầu: loading → ready / empty / error.
  /// Nạp lần đầu: loading → ready / empty / error.
  Future<void> load({bool isRefresh = false}) async {
    _cancelToken?.cancel('reload');
    final cancelToken = ApiCancelToken();
    _cancelToken = cancelToken;

    // Khai báo rõ ràng kiểu dữ liệu trả về cho hàm runInitial
    await runInitial<List<TokenModel>>(
      () => _repository.getTokens(
        cancelToken: cancelToken,
        forceRefresh: isRefresh,
      ),
      onData: (data) => _setTokens(data),
      isEmpty: (data) => data.isEmpty,
      keepDataOnError: _tokens.isNotEmpty,
    );
  }

  /// Kéo xuống để làm mới: giữ danh sách cũ, chỉ bật [isBusy].
  /// Lỗi hiển thị bằng snackbar, không thay cả màn hình.
  // Future<void> refresh() async {
  //   if (isBusy) return;
  //   final cancelToken = ApiCancelToken();
  //   _cancelToken = cancelToken;

  //   await runAction(
  //     () => _repository.getTokens(cancelToken: cancelToken),
  //     onData: _setTokens,
  //   );
  // }
  /// Kéo xuống để làm mới danh sách đơn giản bằng cách tái sử dụng hàm [load].
  Future<void> refresh() => load(isRefresh: true);

  /// Lọc theo tên, mã hoặc id. Chạy đồng bộ trên dữ liệu trong bộ nhớ.
  void setQuery(String value) {
    final next = value.trim().toLowerCase();
    if (next == _query) return;
    _query = next;
    _filtered = _applyQuery();
    safeNotify();
  }

  void _setTokens(List<TokenModel> data) {
    final sorted = [...data]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    _tokens = List.unmodifiable(sorted);
    _filtered = _applyQuery();
  }

  List<TokenModel> _applyQuery() {
    if (_query.isEmpty) return _tokens;
    return List.unmodifiable(
      _tokens.where((token) {
        return token.name.toLowerCase().contains(_query) ||
            token.symbol.toLowerCase().contains(_query) ||
            token.id.toLowerCase().contains(_query);
      }),
    );
  }

  @override
  void dispose() {
    _cancelToken?.cancel('dispose');
    super.dispose();
  }
}
