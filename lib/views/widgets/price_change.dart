import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../core/utils/extensions/context_x.dart';

/// `▲ 4.5%` xanh / `▼ 1.6%` đỏ cho biến động 24h. null hiện `—`.
///
/// Có mũi tên ngoài màu để người mù màu vẫn phân biệt được tăng/giảm.
class PriceChange extends StatelessWidget {
  const PriceChange({super.key, required this.value, this.style});

  /// Phần trăm, ví dụ `4.5` nghĩa là +4.5%.
  final double? value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final change = value;
    final baseStyle = style ?? context.textStyles.bodyMedium;
    if (change == null) return Text('—', style: baseStyle);

    final color = change >= 0 ? AppColors.success : AppColors.error;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          change >= 0
              ? Icons.arrow_drop_up_rounded
              : Icons.arrow_drop_down_rounded,
          color: color,
          size: 20,
        ),
        Text(
          '${change.abs().toStringAsFixed(1)}%',
          style: baseStyle?.copyWith(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
