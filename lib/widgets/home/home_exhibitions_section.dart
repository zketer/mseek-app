import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/exhibition.dart';

/// 左上角横幅裁剪器 - 三角形
class CornerBannerClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width - 10, 0);
    path.lineTo(0, size.height - 10);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

/// 首页最新展览组件
class HomeExhibitionsSection extends StatelessWidget {
  final List<Exhibition> exhibitions;

  const HomeExhibitionsSection({
    super.key,
    required this.exhibitions,
  });

  @override
  Widget build(BuildContext context) {
    if (exhibitions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16), // 32rpx转换，匹配小程序
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end, // 匹配小程序align-items: flex-end
            children: [
              // 标题区域 - 完全匹配小程序：无图标，纯文字，无副标题
              const Text(
                '最新展览',
                style: TextStyle(
                  fontSize: 18, // 36rpx转换
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              // "查看更多"按钮 - 简洁文字版
              GestureDetector(
                onTap: () => _onViewMoreTapped(context),
                child: Text(
                  '查看更多',
                  style: TextStyle(
                    fontSize: 12, // 24rpx转换
                    color: AppColors.textHint,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 8), // 16rpx转换，减小标题与卡片间距
        
        // 展览列表
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16), // 与标题保持对齐 32rpx转换
          itemCount: exhibitions.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12), // 24rpx转换，缩小卡片间距
          itemBuilder: (context, index) {
            final exhibition = exhibitions[index];
            return _buildExhibitionCard(context, exhibition);
          },
        ),
      ],
    );
  }

  /// 构建单个展览卡片
  Widget _buildExhibitionCard(BuildContext context, Exhibition exhibition) {
    return GestureDetector(
      onTap: () {
        context.push('/exhibition-detail?id=${exhibition.id}');
      },
      child: Card(
        margin: EdgeInsets.zero, // 去除Card默认margin
        elevation: 1.0, // 匹配小程序较轻的阴影效果
        shadowColor: Colors.black.withValues(alpha: 0.08), // 匹配小程序box-shadow的透明度
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10), // 20rpx转换，匹配小程序border-radius
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // 匹配小程序展览卡片间距
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              // 展览图片 - 优化尺寸80x80px，减少卡片留白
              ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                child: SizedBox(
                  width: 80, // 160rpx转换
                  height: 80, // 增加高度到80px，减少卡片留白
                  child: _getExhibitionImageUrl(exhibition) != null
                      ? CachedNetworkImage(
                          imageUrl: _getExhibitionImageUrl(exhibition)!,
                          fit: BoxFit.cover,
                          memCacheWidth: 160, // 限制内存缓存尺寸（80px * 2 = 160）
                          memCacheHeight: 160, // 限制内存缓存尺寸（80px * 2 = 160）
                          placeholder: (context, url) => Container(
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                            ),
                            child: Center(
                              child: Icon(
                                Icons.museum,
                                color: AppColors.textWhite.withValues(alpha: 0.7),
                                size: AppDimensions.iconSizeLarge,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                            ),
                            child: Center(
                              child: Icon(
                                Icons.museum,
                                color: AppColors.textWhite.withValues(alpha: 0.7),
                                size: AppDimensions.iconSizeLarge,
                              ),
                            ),
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                          ),
                          child: Center(
                            child: Icon(
                              Icons.museum,
                              color: AppColors.textWhite.withValues(alpha: 0.7),
                              size: AppDimensions.iconSizeLarge,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12), // 24rpx转换，匹配小程序图片与信息间距
              // 展览信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exhibition.title,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontSize: 14, // 28rpx转换，匹配小程序exhibition-title
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4), // 8rpx转换，匹配小程序exhibition-title margin-bottom
                    Text(
                      exhibition.museumName ?? '未知博物馆',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 12, // 24rpx转换，匹配小程序exhibition-museum
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4), // 8rpx转换，匹配小程序exhibition-museum margin-bottom
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 12, // 匹配小程序图标大小
                          color: AppColors.textHint,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          exhibition.isPermanent == 1
                              ? '长期展览'
                              : '${exhibition.formattedStartDate} - ${exhibition.formattedEndDate}',
                          style: AppTextStyles.labelSmall.copyWith(
                            fontSize: 11, // 22rpx转换，匹配小程序exhibition-date
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
              ),
            ),
            // 左上角状态横幅 - 仅在"进行中"时显示
            if (exhibition.exhibitionStatus == '进行中')
              Positioned(
                top: 0,
                left: 0,
                child: _buildCornerBanner(exhibition.exhibitionStatus),
              ),
          ],
        ),
      ),
    );
  }

  /// 构建左上角斜角横幅
  Widget _buildCornerBanner(String status) {
    return ClipPath(
      clipper: CornerBannerClipper(),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.infoSky,
              AppColors.infoSky.withValues(alpha: 0.9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Transform.translate(
            offset: const Offset(-12, -12), // 向左上角偏移更多，使文字居中在三角形内
            child: Transform.rotate(
              angle: -0.785398, // -45度角，使文字沿着斜角方向
              child: Text(
                status,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getExhibitionStatusColor(String status) {
    switch (status) {
      case '进行中': // 匹配小程序渐变色 #4ecdc4到#44a08d的中间色
        return AppColors.infoSky;
      case '即将开始':
        return AppColors.backgroundLight; // 匹配小程序#f8f8f8
      case '已结束':
      case '时间待定':
        return AppColors.backgroundLight; // 统一使用灰色背景
      default:
        return AppColors.backgroundLight;
    }
  }

  /// 获取展览状态文字颜色
  Color _getExhibitionStatusTextColor(String status) {
    switch (status) {
      case '进行中':
        return Colors.white; // 匹配小程序进行中白色文字
      case '即将开始':
      case '已结束':
      case '时间待定':
      default:
        return AppColors.textSecondary; // 匹配小程序#666
    }
  }

  void _onViewMoreTapped(BuildContext context) {
    context.push('/latest_exhibitions');
  }

  /// 获取展览图片URL - 优先级：images.first → coverImage → null
  String? _getExhibitionImageUrl(Exhibition exhibition) {
    // 1. 优先使用 images 的第一张图片
    if (exhibition.images != null && exhibition.images!.isNotEmpty) {
      return exhibition.images!.first;
    }
    
    // 2. 备用：使用 coverImage 字段
    if (exhibition.coverImage != null && exhibition.coverImage!.isNotEmpty) {
      return exhibition.coverImage;
    }
    
    return null;
  }
}