import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';

/// 统计项Widget
/// 
/// 用于显示数字+标签的统计信息。
/// 常见于个人中心、统计页面等。
/// 
/// 使用示例：
/// ```dart
/// StatItemWidget(
///   number: '168',
///   label: '打卡次数',
/// )
/// 
/// // 自定义颜色
/// StatItemWidget(
///   number: '42',
///   label: '收藏数',
///   numberColor: AppColors.accent,
/// )
/// ```
class StatItemWidget extends StatelessWidget {
  /// 数字
  final String number;
  
  /// 标签
  final String label;
  
  /// 数字颜色
  final Color? numberColor;
  
  /// 标签颜色
  final Color? labelColor;
  
  /// 数字字体大小
  final double? numberFontSize;
  
  /// 标签字体大小
  final double? labelFontSize;
  
  /// 是否可点击
  final VoidCallback? onTap;

  const StatItemWidget({
    super.key,
    required this.number,
    required this.label,
    this.numberColor,
    this.labelColor,
    this.numberFontSize,
    this.labelFontSize,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 数字
        Text(
          number,
          style: AppTextStyles.headlineLarge.copyWith(
            fontSize: numberFontSize,
            color: numberColor ?? AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: AppDimensions.paddingXXS),
        
        // 标签
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            fontSize: labelFontSize,
            color: labelColor ?? AppColors.textSecondary,
          ),
        ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingS),
          child: content,
        ),
      );
    }

    return content;
  }
}

/// 水平统计项Widget (数字和标签横向排列)
class HorizontalStatItemWidget extends StatelessWidget {
  /// 数字
  final String number;
  
  /// 标签
  final String label;
  
  /// 数字颜色
  final Color? numberColor;
  
  /// 标签颜色
  final Color? labelColor;
  
  /// 是否可点击
  final VoidCallback? onTap;

  const HorizontalStatItemWidget({
    super.key,
    required this.number,
    required this.label,
    this.numberColor,
    this.labelColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 数字
        Text(
          number,
          style: AppTextStyles.titleLarge.copyWith(
            color: numberColor ?? AppColors.accent,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(width: AppDimensions.paddingXS),
        
        // 标签
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: labelColor ?? AppColors.textSecondary,
          ),
        ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingS,
            vertical: AppDimensions.paddingXS,
          ),
          child: content,
        ),
      );
    }

    return content;
  }
}

/// 统计卡片Widget (带背景和阴影的统计项)
class StatCardWidget extends StatelessWidget {
  /// 数字
  final String number;
  
  /// 标签
  final String label;
  
  /// 图标
  final IconData? icon;
  
  /// 图标颜色
  final Color? iconColor;
  
  /// 是否可点击
  final VoidCallback? onTap;

  const StatCardWidget({
    super.key,
    required this.number,
    required this.label,
    this.icon,
    this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 图标（可选）
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 32,
                  color: iconColor ?? AppColors.primaryLight,
                ),
                const SizedBox(height: AppDimensions.paddingXS),
              ],
              
              // 数字
              Text(
                number,
                style: AppTextStyles.headlineLarge.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: AppDimensions.paddingXXS),
              
              // 标签
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

