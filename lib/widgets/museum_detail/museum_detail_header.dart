import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/museum.dart';

/// 博物馆详情页头部组件
class MuseumDetailHeader extends StatelessWidget {
  final Museum museum;
  
  const MuseumDetailHeader({
    super.key,
    required this.museum,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: AppColors.surface,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
            onPressed: () => _showMoreOptions(context),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: _buildHeaderContent(),
      ),
    );
  }

  /// 构建头部内容
  Widget _buildHeaderContent() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 背景图片
        museum.imageUrl != null
            ? Image.asset(
                museum.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildDefaultBackground(),
              )
            : _buildDefaultBackground(),
        
        // 渐变遮罩
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.transparent,
                Colors.black.withValues(alpha: 0.3),
                Colors.black.withValues(alpha: 0.7),
              ],
            ),
          ),
        ),
        
        // 底部信息
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 博物馆名称
                Text(
                  museum.name,
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: AppColors.textWhite,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: AppDimensions.paddingS),
                
                // 基本信息
                Row(
                  children: [
                    // 等级标签
                    if (museum.levelName.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          museum.levelName,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textWhite,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.paddingS),
                    ],
                    
                    // 评分
                    if (museum.rating != null) ...[
                      const Icon(
                        Icons.star,
                        size: 16,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        museum.rating!.toStringAsFixed(1),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textWhite,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.paddingM),
                    ],
                    
                    // 距离
                    if (museum.distance != null) ...[
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: AppColors.textWhite,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        museum.distance!,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textWhite,
                        ),
                      ),
                    ],
                  ],
                ),
                
                const SizedBox(height: AppDimensions.paddingS),
                
                // 地址
                if (museum.address != null)
                  Row(
                    children: [
                      const Icon(
                        Icons.place,
                        size: 16,
                        color: AppColors.textWhite,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          museum.address!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textWhite.withValues(alpha: 0.9),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 构建默认背景
  Widget _buildDefaultBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: const Center(
        child: Icon(
          Icons.museum,
          size: 80,
          color: AppColors.textWhite,
        ),
      ),
    );
  }

  /// 显示更多选项
  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('分享'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 分享功能
              },
            ),
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text('举报'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 举报功能
              },
            ),
          ],
        ),
      ),
    );
  }
}
