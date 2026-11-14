import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_dimens.dart';
import '../../../core/error/failure.dart';
import '../../../core/utils/extensions/context_x.dart';

/// Trạng thái đang tải lần đầu.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(strokeWidth: 2.5),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(message!, style: context.textStyles.bodySmall),
          ],
        ],
      ),
    );
  }
}

/// Trang lỗi khi chưa có dữ liệu nào để hiển thị.
///
/// Phân biệt lỗi mạng (gợi ý kiểm tra kết nối) với lỗi khác, vì cách người
/// dùng xử lý hai tình huống này khác nhau.
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.failure,
    this.onRetry,
    this.compact = false,
  });

  final Failure? failure;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isNetwork = failure?.isNetwork ?? false;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isNetwork ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
              size: compact ? 40 : 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              isNetwork ? 'Mất kết nối mạng' : 'Đã có lỗi xảy ra',
              style: context.textStyles.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              failure?.message ?? 'Vui lòng thử lại sau ít phút.',
              style: context.textStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: 180,
                child: OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Thử lại'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Trạng thái không có dữ liệu.
class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.message,
    this.title,
    this.icon = Icons.inbox_rounded,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? title;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppColors.textDisabled),
            const SizedBox(height: AppSpacing.lg),
            if (title != null) ...[
              Text(title!, style: context.textStyles.titleMedium),
              const SizedBox(height: AppSpacing.sm),
            ],
            Text(
              message,
              style: context.textStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: onAction,
                  child: Text(actionLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Dải báo mất mạng, ghim trên cùng nội dung.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.warning,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              const Icon(Icons.cloud_off_rounded,
                  size: 16, color: Colors.white),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Không có kết nối mạng. Một số nội dung có thể chưa cập nhật.',
                  style: context.textStyles.bodySmall?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Khối xám nhấp nháy thay cho nội dung đang tải.
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    this.width,
    this.height = 16,
    this.radius = AppRadius.xs,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return Shimmer.fromColors(
      baseColor:
          isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant,
      highlightColor: isDark ? AppColors.surfaceDark : Colors.white,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

/// Khung xương lưới sản phẩm — giữ đúng bố cục để không nhảy layout khi
/// dữ liệu thật về.
class ProductGridSkeleton extends StatelessWidget {
  const ProductGridSkeleton({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: context.coinGridColumns,
        childAspectRatio: AppSizes.productCardAspectRatio,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
      ),
      itemBuilder: (context, index) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
              child: ShimmerBox(height: double.infinity, radius: AppRadius.md)),
          const SizedBox(height: AppSpacing.sm),
          const ShimmerBox(height: 14),
          const SizedBox(height: AppSpacing.xs),
          ShimmerBox(height: 14, width: context.screenWidth * 0.25),
        ],
      ),
    );
  }
}
