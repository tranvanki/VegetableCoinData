import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_dimens.dart';

/// Màn hình chờ trong lúc bootstrap nạp phiên đăng nhập và cấu hình.
///
/// Không gọi API ở đây — việc đó do [AppBootstrap] làm trước khi dựng app;
/// màn này chỉ tồn tại cho khoảnh khắc router quyết định đi đâu.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.storefront_rounded,
              size: 72,
              color: AppColors.textOnPrimary,
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              'Hoàng Hà Mobile',
              style: TextStyle(
                color: AppColors.textOnPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: AppSpacing.xxl),
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.textOnPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
