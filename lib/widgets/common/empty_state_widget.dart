import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';

/// 统一空状态组件
class EmptyStateWidget extends StatelessWidget {
  final String message;
  final String? subtitle;
  final IconData? icon;
  final String? imagePath;
  final bool showButton;
  final String buttonText;
  final VoidCallback? onRetry;

  const EmptyStateWidget({
    super.key,
    this.message = '暂无数据',
    this.subtitle,
    this.icon = Icons.info_outline,
    this.imagePath,
    this.showButton = true,
    this.buttonText = '重新加载',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 图标或图片
            if (imagePath != null)
              Image.asset(
                imagePath!,
                width: 120,
                height: 120,
                fit: BoxFit.contain,
              )
            else if (icon != null)
              Icon(
                icon,
                size: 80,
                color: AppColors.textHint,
              ),
            
            const SizedBox(height: AppDimensions.paddingL),
            
            // 主要消息
            Text(
              message,
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            
            // 副标题（可选）
            if (subtitle != null) ...[
              const SizedBox(height: AppDimensions.paddingS),
              Text(
                subtitle!,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textHint,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            
            // 重试按钮（可选）
            if (showButton && onRetry != null) ...[
              const SizedBox(height: AppDimensions.paddingXL),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingXL,
                    vertical: AppDimensions.paddingS,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                  ),
                ),
                child: Text(
                  buttonText,
                  style: AppTextStyles.buttonMedium,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
