import 'package:hhmmobile/app/app_boostrap.dart';

/// Điểm vào duy nhất. Mọi khởi tạo nằm trong [AppBootstrap] để `main` không
/// phình ra như app cũ — và để test có thể gọi lại từng bước riêng lẻ.
///
/// Chạy theo môi trường:
///   flutter run --dart-define-from-file=env/dev.json
///   flutter build apk --release --dart-define-from-file=env/prod.json
void main() => AppBootstrap.run();
