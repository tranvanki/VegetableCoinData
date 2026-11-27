import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_dimens.dart';
import '../../../core/utils/extensions/context_x.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/model/system/global_stats.dart';
import '../../widgets/common/app_widget.dart';
import '../../widgets/price_change.dart';


class GlobalStatsRow extends StatelessWidget {
  const GlobalStatsRow({super.key, required this.global});
  final GlobalStats? global;

  @override
  Widget build(BuildContext context) {
    final stats = global;
    // ép chiều cao của widget con
    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(
              child: _StatCard(
                  title: 'Giá trị vốn hóa thị trường toàn cầu',
                  value: Formatters.usdCompact(stats?.totalMarketCap['usd']))),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
              child: _StatCard(
                  title: 'Khối lượng trong 24h',
                  value: Formatters.usdCompact(stats?.totalVolume['usd'])))
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(
      {super.key, required this.title, required this.value, this.change});
  final String title;
  final String value;
  final double? change;

  @override
  Widget build(BuildContext context) {
    return AppWidget(
      color: context.isDarkMode
          ? AppColors.surfaceVariantDark
          : AppColors.surfaceVariant,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.textStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: context.textStyles.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          if (change != null) PriceChange(value: change),
        ],
      ),
    );
  }
}