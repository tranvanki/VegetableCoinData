import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hhmmobile/core/storage/image_cache_manager.dart';
// import 'package:hhmmobile/core/storage/image_cache_manager.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_dimens.dart';
import '../../../core/utils/extensions/context_x.dart';
import '../state/state_views.dart';

/// Nút chính có trạng thái loading — khoá luôn thao tác khi đang gửi request
/// để không tạo đơn/thêm giỏ hai lần.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.expanded = true,
    this.height = AppSizes.buttonHeight,
    this.backgroundColor,
    this.foregroundColor,
    this.fontSize,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;
  final bool expanded;
  final double height;
  final Color? backgroundColor;
  final double? fontSize;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || isLoading;

    // Vòng quay phải cùng màu chữ, nếu không nền sáng sẽ nuốt mất nó.
    final spinnerColor = foregroundColor ??
        (isOutlined ? AppColors.primary : AppColors.textOnPrimary);
    final child = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: spinnerColor,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16),
                const SizedBox(width: AppSpacing.sm),
              ],
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            ],
          );
    // Định nghĩa TextStyle nếu fontSize được truyền vào
    final customTextStyle =
        fontSize != null ? TextStyle(fontSize: fontSize) : null;

    final button = isOutlined
        ? OutlinedButton(
            onPressed: isDisabled ? null : onPressed,
            style: OutlinedButton.styleFrom(
              minimumSize: Size.fromHeight(height),
              foregroundColor: foregroundColor,
            ),
            child: child,
          )
        : ElevatedButton(
            onPressed: isDisabled ? null : onPressed,
            style: ElevatedButton.styleFrom(
              minimumSize: Size.fromHeight(height),
              backgroundColor: backgroundColor,
              foregroundColor: foregroundColor,
              textStyle: customTextStyle, // Áp dụng kích thước chữ ở đây
            ),
            child: child,
          );
    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Ảnh từ CDN có cache, placeholder và ảnh thay thế khi lỗi.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.radius = 0,
  });
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double radius;
  @override
  Widget build(BuildContext context) {
    final placeholder = ShimmerBox(
      width: width,
      height: height ?? 100,
      radius: radius,
    );
    final image = url.trim().isEmpty
        ? _fallback(context)
        : CachedNetworkImage(
            cacheManager: AppImageCacheManager.instance,
            imageUrl: url,
            width: width,
            height: height,
            fit: fit,
            memCacheHeight: height != null ? (height! * 2).toInt() : null,
            memCacheWidth: width != null ? (width! * 2).toInt() : null,
            fadeInDuration: const Duration(milliseconds: 180),
            placeholder: (_, __) => placeholder,
            errorWidget: (_, __, ___) => _fallback(context),
          );
    return radius > 0
        ? ClipRRect(borderRadius: BorderRadius.circular(radius), child: image)
        : image;
  }

  Widget _fallback(BuildContext context) => Container(
        width: width,
        height: height,
        color: context.isDarkMode
            ? AppColors.surfaceVariantDark
            : const Color.fromARGB(255, 8, 72, 199),
        alignment: Alignment.center,
        child: const Icon(
          Icons.image_not_supported_outlined,
          color: AppColors.textDisabled,
        ),
      );
}

class AppWidget extends StatelessWidget {
  const AppWidget({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.margin = EdgeInsets.zero,
    this.onTap,
    this.color,
    this.border,
    this.radius = AppRadius.md,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final Color? color;
  final BoxBorder? border;
  final double radius;
  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    Widget content = Padding(padding: padding, child: child);
    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: content,
      );
    }
    Widget card = Material(
      color: color ?? context.colors.surface,
      borderRadius: borderRadius,
      clipBehavior: Clip.antiAlias,
      child: content,
    );
    // Viền vẽ ngoài Material để không chắn ink của các tile bên trong.
    if (border != null) {
      card = DecoratedBox(
        decoration: BoxDecoration(border: border, borderRadius: borderRadius),
        child: card,
      );
    }
    return Padding(
      padding: margin,
      child: card,
    );
  }
}

/// Chấm đếm trên icon (giỏ hàng, thông báo). Trên 99 hiển thị `99+`.
class CountBadge extends StatelessWidget {
  const CountBadge({super.key, required this.count, required this.child});

  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return child;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -6,
          top: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            constraints: const BoxConstraints(minWidth: 16),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: context.colors.surface, width: 1.5),
            ),
            child: Text(
              count > 99 ? '99+' : '$count',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onMore,
    this.moreLabel = 'Xem tất cả',
  });
  final String title;
  final String? subtitle;
  final VoidCallback? onMore;
  final String moreLabel;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.textStyles.titleMedium),
                if (subtitle != null)
                  Text(subtitle!, style: context.textStyles.bodySmall),
              ],
            ),
          ),
          if (onMore != null)
            TextButton(
              onPressed: onMore,
              child: Row(
                children: [
                  Text(moreLabel),
                  const Icon(Icons.chevron_right_rounded, size: 18),
                ],
              ),
            )
        ],
      ),
    );
  }
}
