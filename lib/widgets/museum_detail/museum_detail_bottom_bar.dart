import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/museum.dart';
import '../common/unified_favorite_button.dart';

/// 博物馆详情页底部操作栏
class MuseumDetailBottomBar extends StatelessWidget {
  final Museum museum;
  final bool isFavorited;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onCheckin;
  final VoidCallback onShare;

  const MuseumDetailBottomBar({
    super.key,
    required this.museum,
    required this.isFavorited,
    required this.onFavoriteToggle,
    required this.onCheckin,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: AppDimensions.paddingM,
        right: AppDimensions.paddingM,
        top: AppDimensions.paddingS,
        bottom: MediaQuery.of(context).padding.bottom + AppDimensions.paddingS,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // 收藏按钮（使用统一组件）
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              UnifiedFavoriteButton(
                isFavorited: isFavorited,
                onTap: onFavoriteToggle,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                '收藏',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          
          const SizedBox(width: AppDimensions.paddingM),
          
          // 分享按钮
          _buildActionButton(
            icon: Icons.share,
            label: '分享',
            color: AppColors.textSecondary,
            onTap: onShare,
          ),
          
          const SizedBox(width: AppDimensions.paddingM),
          
          // 打卡按钮
          Expanded(
            child: ElevatedButton(
              onPressed: onCheckin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.textWhite,
                padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingM),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '立即打卡',
                    style: AppTextStyles.buttonMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建操作按钮
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingM,
          vertical: AppDimensions.paddingS,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
