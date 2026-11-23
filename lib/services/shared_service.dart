import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/config/app_config.dart';
import '../core/utils/logger.dart';

/// Chia sẻ thông tin Coin, mở Block Explorer, Hotline hoặc trình duyệt ngoài.
class ShareService {
  const ShareService(this._config);

  final AppConfig _config;

  /// Chia sẻ thông tin một đồng Coin (Tên, mã, giá, % thay đổi và link chi tiết).
  Future<void> shareCoin({
    required String symbol,
    required String name,
    required double price,
    double? change24h,
    String? coinId, // Dùng cho web URL ví dụ: /coin/bitcoin hoặc dùng mã symbol
  }) async {
    final identifier = coinId ?? symbol.toLowerCase();
    final url = '${_config.webBaseUrl}/coins/$identifier';

    //format % changes(if has)
    final changeText = change24h != null
        ? (change24h >= 0
            ? '+${change24h.toStringAsFixed(2)}%'
            : '${change24h.toStringAsFixed(2)}%')
        : '';

    final priceStr = '\$${price.toStringAsFixed(price < 1 ? 4 : 2)}';

    final text = '''
🚀 $name ($symbol)
💰 Giá: $priceStr ${'($changeText)'}
📊 Theo dõi ngay tại:
$url
''';

    await SharePlus.instance.share(
      ShareParams(
        text: text.trim(),
        subject: 'Cập nhật giá $name ($symbol)',
      ),
    );
  }

  /// Chia sẻ văn bản chung (Dùng cho báo cáo portfolio, tin tức thị trường...)
  Future<void> shareText(String text, {String? subject}) =>
      SharePlus.instance.share(ShareParams(text: text, subject: subject));

  /// Gửi email hỗ trợ / liên hệ kỹ thuật
  Future<bool> sendEmail(String email, {String subject = ''}) => _launch(
        Uri(
          scheme: 'mailto',
          path: email,
          query: subject.isEmpty
              ? null
              : 'subject=${Uri.encodeComponent(subject)}',
        ),
      );

  /// Mở trình duyệt xem giao dịch trên Block Explorer (Etherscan, BscScan, Solscan...)
  Future<bool> openBlockExplorer(String txHashOrAddress,
      {String explorerUrl = 'https://etherscan.io'}) {
    final url = '$explorerUrl/tx/$txHashOrAddress';
    return openExternal(url);
  }

  /// Mở URL bằng trình duyệt ngoài (Dùng cho Whitepaper, Website chính thức của dự án, v.v.)
  Future<bool> openExternal(String url) {
    final uri = Uri.tryParse(url);
    return uri == null ? Future.value(false) : _launch(uri);
  }

  Future<bool> _launch(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      AppLogger.w('Không mở được $uri: $e', tag: 'ShareService');
      return false;
    }
  }
}
