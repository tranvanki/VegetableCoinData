import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Đường biểu đồ nhỏ (sparkline) — chỉ vẽ, không có trục hay tương tác.
///
/// Màu xanh khi điểm cuối ≥ điểm đầu, đỏ khi thấp hơn. Dưới 2 điểm thì không
/// vẽ gì (khung trống giữ nguyên kích thước để hàng không nhảy layout).
class Sparkline extends StatelessWidget {
  const Sparkline({
    super.key,
    required this.prices,
    this.width = 96,
    this.height = 36,
  });

  final List<double> prices;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final isUp = prices.length < 2 || prices.last >= prices.first;
    return RepaintBoundary(
      child: CustomPaint(
        size: Size(width, height),
        painter: _SparklinePainter(
          prices: prices,
          color: isUp ? AppColors.success : AppColors.error,
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({required this.prices, required this.color});

  final List<double> prices;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (prices.length < 2) return;

    var min = prices.first;
    var max = prices.first;
    for (final price in prices) {
      if (price < min) min = price;
      if (price > max) max = price;
    }
    // Đường phẳng (min == max) vẽ ở giữa thay vì chia cho 0.
    final range = max - min;
    final stepX = size.width / (prices.length - 1);

    final path = Path();
    for (var i = 0; i < prices.length; i++) {
      final x = i * stepX;
      final y = range == 0
          ? size.height / 2
          : size.height - ((prices[i] - min) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.color != color || old.prices != prices;
}
