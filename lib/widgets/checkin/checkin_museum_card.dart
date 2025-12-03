import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';

/// 打卡页博物馆卡片组件
class CheckinMuseumCard extends StatelessWidget {
  final String name;
  final String distance;
  final bool canCheckin;
  final VoidCallback onCheckin;
  final VoidCallback onViewDetail;

  const CheckinMuseumCard({
    super.key,
    required this.name,
    required this.distance,
    required this.canCheckin,
    required this.onCheckin,
    required this.onViewDetail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 博物馆图标
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            child: const Icon(
              Icons.museum,
              color: AppColors.textWhite,
              size: 28,
            ),
          ),
          
          const SizedBox(width: AppDimensions.paddingM),
          
          // 博物馆信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 名称和状态标签
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: AppTextStyles.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (canCheckin)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '可打卡',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textWhite,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 4),
                
                // 距离信息
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: canCheckin ? AppColors.success : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      distance,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: canCheckin ? AppColors.textPrimary : AppColors.textSecondary,
                        fontWeight: canCheckin ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppDimensions.paddingS),
                
                // 操作按钮
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onViewDetail,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          minimumSize: const Size(0, 32),
                        ),
                        child: const Text('查看详情'),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.paddingS),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: canCheckin ? onCheckin : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canCheckin ? AppColors.accent : AppColors.textHint,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          minimumSize: const Size(0, 32),
                        ),
                        child: Text(
                          canCheckin ? '立即打卡' : '距离太远',
                          style: const TextStyle(color: AppColors.textWhite),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
