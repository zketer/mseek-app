import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';

/// 简单空状态组件（无卡片样式）
/// 用于列表页等不需要边框和背景装饰的场景
/// 
/// 使用示例：
/// ```dart
/// SimpleEmptyState(
///   icon: Icons.museum_outlined,
///   message: '暂无博物馆数据',
///   subtitle: '试试调整筛选条件',
/// )
/// ```
class SimpleEmptyState extends StatelessWidget {
  /// 空状态图标
  final IconData icon;
  
  /// 主要提示文字
  final String message;
  
  /// 副标题（可选）
  final String? subtitle;
  
  /// 图标大小，默认64
  final double iconSize;
  
  const SimpleEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.subtitle,
    this.iconSize = 64.0,
  });
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 图标（使用更淡的颜色）
            Icon(
              icon,
              size: iconSize,
              color: AppColors.textHint.withValues(alpha: 0.4),
            ),
            
            const SizedBox(height: AppDimensions.paddingL),
            
            // 主要文字
            Text(
              message,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            
            // 副标题（可选）
            if (subtitle != null) ...[
              const SizedBox(height: AppDimensions.paddingS),
              Text(
                subtitle!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textHint,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

