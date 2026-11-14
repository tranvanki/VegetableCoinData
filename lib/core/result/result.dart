import '../error/failure.dart';


/// Kiểu trả về chuẩn của mọi repository: thành công có dữ liệu, hoặc thất bại
/// có [Failure]. Không dùng `throw` xuyên qua ranh giới repository → ViewModel.
sealed class Result<T> {
  const Result();

  const factory Result.ok(T data) = Ok<T>;
  const factory Result.err(Failure failure) = Err<T>;

  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;

  T? get dataOrNull => switch (this) {
        Ok<T>(:final data) => data,
        Err<T>() => null,
      };

  Failure? get failureOrNull => switch (this) {
        Ok<T>() => null,
        Err<T>(:final failure) => failure,
      };

  T getOrElse(T fallback) => dataOrNull ?? fallback;

  /// Biến đổi dữ liệu, giữ nguyên lỗi.
  Result<R> map<R>(R Function(T data) transform) => switch (this) {
        Ok<T>(:final data) => Ok<R>(transform(data)),
        Err<T>(:final failure) => Err<R>(failure),
      };

  R fold<R>({
    required R Function(T data) onOk,
    required R Function(Failure failure) onErr,
  }) =>
      switch (this) {
        Ok<T>(:final data) => onOk(data),
        Err<T>(:final failure) => onErr(failure),
      };
}

final class Ok<T> extends Result<T> {
  const Ok(this.data);
  final T data;

  @override
  String toString() => 'Ok($data)';
}

final class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;

  @override
  String toString() => 'Err($failure)';
}
