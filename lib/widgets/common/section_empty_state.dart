import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';

/// 通用区域空状态组件
/// 
/// 极简设计：只需传入图标、文字即可
/// 
/// 使用示例：
/// ```dart
/// SectionEmptyState(
///   icon: Icons.museum_outlined,
///   message: '暂无热门博物馆',
///   subtitle: '等待更多博物馆入驻',
/// )
/// ```
class SectionEmptyState extends StatelessWidget {
  /// 区域标题（可选，如"热门博物馆"）
  final String? sectionTitle;
  
  /// 空状态图标
  final IconData icon;
  
  /// 空状态主要文字
  final String message;
  
  /// 空状态副标题（可选）
  final String? subtitle;
  
  /// 容器高度
  final double height;
  
  /// 是否显示边框
  final bool showBorder;
  
  /// 是否添加水平padding
  final bool addHorizontalPadding;
  
  const SectionEmptyState({
    super.key,
    this.sectionTitle,
    required this.icon,
    required this.message,
    this.subtitle,
    this.height = 200.0,
    this.showBorder = true,
    this.addHorizontalPadding = true,
  });
  
  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: showBorder ? Border.all(color: AppColors.divider) : null,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 图标（使用淡色）
            Icon(
              icon,
              size: 64,
              color: AppColors.textHint.withValues(alpha: 0.4),
            ),
            
            const SizedBox(height: AppDimensions.paddingM),
            
            // 主要文字
            Text(
              message,
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            
            // 副标题（可选）
            if (subtitle != null) ...[
              const SizedBox(height: AppDimensions.paddingS),
              Text(
                subtitle!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textHint,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
    
    // 如果有标题，包裹在Column中
    if (sectionTitle != null) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(sectionTitle!, style: AppTextStyles.titleLarge),
          const SizedBox(height: AppDimensions.paddingM),
          content,
        ],
      );
    }
    
    // 添加水平padding（可选）
    if (addHorizontalPadding) {
      content = Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingM),
        child: content,
      );
    }
    
    return content;
  }
}
