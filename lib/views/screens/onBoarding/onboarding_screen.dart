import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_dimens.dart';
import '../../../core/config/app_constants.dart';
import '../../../core/storage/local_storage.dart';

/// Giới thiệu một lần trong lần mở app đầu tiên.
///
/// Router chuyển hướng tới đây khi [AppConstants.kOnboardingSeen] còn `false`;
/// bấm nút sẽ ghi cờ và vào thẳng tab Home.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  Future<void> _start(BuildContext context) async {
    await context
        .read<LocalStorage>()
        .setBool(AppConstants.kOnboardingSeen, value: true);
    if (context.mounted) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.currency_bitcoin,
                  size: 56,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'CoinGecko',
                style: textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Theo dõi giá, khối lượng và biến động của hàng nghìn '
                'token theo thời gian thực.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              const _FeatureRow(
                icon: Icons.trending_up_rounded,
                text: 'Bảng giá và xu hướng thị trường',
              ),
              const SizedBox(height: AppSpacing.md),
              const _FeatureRow(
                icon: Icons.search_rounded,
                text: 'Tìm kiếm token tức thì',
              ),
              const SizedBox(height: AppSpacing.md),
              const _FeatureRow(
                icon: Icons.insights_rounded,
                text: 'Biểu đồ lịch sử giá',
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: AppSizes.buttonHeight,
                child: FilledButton(
                  onPressed: () => _start(context),
                  child: const Text('Khám phá thị trường'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
        ),
      ],
    );
  }
}
