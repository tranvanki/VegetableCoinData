/// Môi trường build. Chọn bằng `--dart-define=FLAVOR=dev|staging|prod`
/// hoặc `--dart-define-from-file=env/dev.json` (xem thư mục `env/`).
enum AppFlavor {
  dev('dev'),
  staging('staging'),
  prod('prod');

  const AppFlavor(this.key);

  final String key;

  bool get isProd => this == AppFlavor.prod;
  bool get isDev => this == AppFlavor.dev;

  static AppFlavor fromKey(String value) {
    return AppFlavor.values.firstWhere(
      (f) => f.key == value.trim().toLowerCase(),
      orElse: () => AppFlavor.dev,
    );
  }
}
