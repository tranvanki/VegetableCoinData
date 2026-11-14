import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/utils/extensions/context_x.dart';

/// Logo tròn của coin; thiếu hoặc lỗi ảnh thì hiện chữ cái đầu của [symbol].
class CoinLogo extends StatelessWidget {
  const CoinLogo({
    super.key,
    required this.imageUrl,
    required this.symbol,
    this.size = 28,
  });

  final String? imageUrl;
  final String symbol;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url == null || url.isEmpty) return _fallback(context);
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, __) => _fallback(context),
        errorWidget: (_, __, ___) => _fallback(context),
      ),
    );
  }

  Widget _fallback(BuildContext context) => CircleAvatar(
        radius: size / 2,
        child: Text(
          symbol.isEmpty ? '?' : symbol.substring(0, 1).toUpperCase(),
          style: context.textStyles.labelSmall,
        ),
      );
}
