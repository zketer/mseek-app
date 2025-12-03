import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/museum.dart';

/// 首页热门博物馆组件
/// 
/// 间距优化说明：
/// 1. 去除Card默认margin (4.0px) - 解决卡片间额外空隙
/// 2. ListView添加左右padding (16px) - 保持与标题边距一致  
/// 3. separatorBuilder间距调整为6px - 匹配小程序紧密布局
/// 4. 卡片宽度140px (280rpx) - 匹配小程序设计规范
/// 5. ListView高度优化为200px，减少底部留白
/// 6. 卡片内部padding减小，让布局更紧凑
/// 
/// 字体大小完全匹配小程序CSS规范，统一行高避免高度差异：
/// - "热门"标签: 10px (20rpx, .museum-badge, height: 1.0)
/// - 评分数字"4.5": 8px (16rpx, .rating-score, fontWeight: 600, height: 1.0)
/// - 五角星"★": 8px (统一大小避免高度差异, fontWeight: normal, height: 1.0)
/// - 后端返回标签: 8px (16rpx, .backend-tag, padding更小, height: 1.0)
/// - 分类标签: 9px (18rpx, .tag通用样式, height: 1.0)
/// - 等级标签: 9px (18rpx, .tag通用样式, height: 1.0)  
/// - 免费参观标签: 9px (18rpx, .tag通用样式, height: 1.0)
class HomeHotMuseumsSection extends StatelessWidget {
  final List<Museum> museums;

  const HomeHotMuseumsSection({
    super.key,
    required this.museums,
  });

  @override
  Widget build(BuildContext context) {
    if (museums.isEmpty) {
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
                '热门博物馆',
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
        
        // 博物馆列表 - 横向滚动，右边留出部分空间暗示可滑动
        Container(
          height: 210, // 优化高度：100px图片 + 80px内容区域 + 30px间距
          color: AppColors.background, // 设置背景色，避免右边空白
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 5, 0, 5), // 左边16px对齐标题，右边0让内容露出
            itemCount: museums.length,
            separatorBuilder: (context, index) => const SizedBox(width: 6), // 卡片间距6px
            itemBuilder: (context, index) {
              final museum = museums[index];
              // 最后一个卡片添加右边距，滚动到最后时和"查看更多"对齐
              return Padding(
                padding: EdgeInsets.only(right: index == museums.length - 1 ? 16.0 : 0.0),
                child: _buildMuseumCard(context, museum),
              );
            },
          ),
        ),
      ],
    );
  }

  /// 构建单个博物馆卡片 - 完全匹配小程序：热门标签+评分标签+地址+免费参观
  Widget _buildMuseumCard(BuildContext context, Museum museum) {
    return GestureDetector(
      onTap: () {
        context.push('/museum/${museum.id}');
      },
      child: Card(
        margin: EdgeInsets.zero, // 去除Card默认margin，避免额外间距
        elevation: 1.0, // 匹配小程序较轻的阴影效果
        shadowColor: Colors.black.withValues(alpha: 0.08), // 匹配小程序box-shadow的透明度
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10), // 20rpx转换，匹配小程序border-radius
        ),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: 140, // 280rpx转换，小程序样式
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 博物馆图片容器（带热门标签） - 小程序样式
              SizedBox(
                height: 90, // 180rpx转换
                width: double.infinity,
                child: Stack(
                  children: [
                    // 图片
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(10), // 20rpx转换，匹配小程序
                        ),
                        child: _getImageUrl(museum) != null
                            ? CachedNetworkImage(
                                imageUrl: _getImageUrl(museum)!,
                                fit: BoxFit.cover,
                                memCacheWidth: 280, // 限制内存缓存尺寸（140px * 2 = 280）
                                memCacheHeight: 180, // 限制内存缓存尺寸（90px * 2 = 180）
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
                    
                    // 热门标签 - 右上角红色渐变标签
                    Positioned(
                      top: 8, // 16rpx转换
                      right: 8, // 16rpx转换
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // 16rpx, 8rpx转换
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primary, // #ff6b6b
                              AppColors.primaryDark, // #ff8e8e
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10), // 20rpx转换
                        ),
                        child: Text(
                          '热门',
                          style: AppTextStyles.labelSmall.copyWith(
                            fontSize: 10, // 20rpx转换，匹配小程序museum-badge大小
                            color: AppColors.textWhite,
                            fontWeight: FontWeight.w500,
                            height: 1.0, // 统一行高
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
                  // 博物馆信息 - 完全匹配小程序布局
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 8), // 增加上方padding，让文字位置向下
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 博物馆名称
                    Text(
                      museum.name,
                      style: AppTextStyles.titleSmall.copyWith(
                        fontSize: 14, // 28rpx转换
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                        const SizedBox(height: 5), // 稍微减小间距，保持紧凑
                    
                    // 地址信息 - 带位置图标
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 12, // 与小程序一致
                          color: AppColors.textHint,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            museum.address ?? '位置信息暂无',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 11, // 22rpx转换
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    
                        const SizedBox(height: 3), // 减小间距，保持紧凑
                    
                    // 博物馆标签 - 完全匹配小程序：使用Wrap自动换行
                    Wrap(
                      spacing: 3, // 6rpx转换，匹配小程序gap
                      runSpacing: 3, // 垂直间距
                      children: _generateDisplayTags(museum),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 生成显示标签（完全匹配小程序逻辑）
  List<Widget> _generateDisplayTags(Museum museum) {
    final List<Widget> tagWidgets = [];

    // 1. 固定评分标签 - 小程序样式
    tagWidgets.add(Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary, // #ff6b6b
            AppColors.tagHistoryText, // #ee5a52
          ],
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              (museum.rating ?? 4.5).toStringAsFixed(1),
              style: AppTextStyles.labelSmall.copyWith(
                fontSize: 8, // 16rpx转换，匹配小程序评分数字大小
                fontWeight: FontWeight.w600, // 小程序中评分数字是w600
                color: AppColors.textWhite,
                height: 1.0, // 统一行高
              ),
            ),
            const SizedBox(width: 1),
            Text(
              '★',
              style: AppTextStyles.labelSmall.copyWith(
                fontSize: 8, // 统一为8px，避免高度差异
                fontWeight: FontWeight.normal, // 五角星不加粗
                color: AppColors.textWhite,
                height: 1.0, // 统一行高
              ),
            ),
          ],
        ),
      ),
    ));

    // 2. 后端返回的标签（如果有）
    if (museum.tags != null && museum.tags!.isNotEmpty) {
      for (final tag in museum.tags!) {
        tagWidgets.add(Container(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1), // 2rpx 6rpx转换，更小的padding
          decoration: BoxDecoration(
            color: _parseColor(tag.color ?? '#f0f8ff'),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.black.withValues(alpha: 0.1), width: 0.5),
          ),
          child: Text(
            tag.name,
            style: AppTextStyles.labelSmall.copyWith(
              fontSize: 8, // 16rpx转换，匹配小程序后端标签大小
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
              height: 1.0, // 统一行高
            ),
          ),
        ));
      }
    }

    // 3. 分类标签
    if (museum.categories != null && museum.categories!.isNotEmpty) {
      for (final category in museum.categories!) {
        tagWidgets.add(Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: _getCategoryColor(category.code),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.black.withValues(alpha: 0.1), width: 0.5),
          ),
        child: Text(
          category.name,
          style: AppTextStyles.labelSmall.copyWith(
            fontSize: 9, // 18rpx转换，匹配小程序通用标签大小
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
            height: 1.0, // 统一行高
          ),
        ),
        ));
      }
    }

    // 4. 等级标签
    if (museum.level != null && museum.level! > 0) {
      tagWidgets.add(Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.tagPrivate, // 匹配小程序#f6ffed
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.black.withValues(alpha: 0.1), width: 0.5),
        ),
        child: Text(
          museum.levelName,
          style: AppTextStyles.labelSmall.copyWith(
            fontSize: 9, // 18rpx转换，匹配小程序通用标签大小
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
            height: 1.0, // 统一行高
          ),
        ),
      ));
    }

    // 5. 免费参观标签
    if (museum.freeAdmission == 1) {
      tagWidgets.add(Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.tagFree, // 匹配小程序#fff2e8
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.black.withValues(alpha: 0.1), width: 0.5),
        ),
        child: Text(
          '免费参观',
          style: AppTextStyles.labelSmall.copyWith(
            fontSize: 9, // 18rpx转换，匹配小程序通用标签大小
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
            height: 1.0, // 统一行高
          ),
        ),
      ));
    }

    return tagWidgets;
  }

  /// 解析颜色字符串
  Color _parseColor(String colorStr) {
    try {
      if (colorStr.startsWith('#')) {
        return Color(int.parse(colorStr.substring(1), radix: 16) + 0xFF000000);
      }
      return AppColors.infoBg; // 默认颜色
    } catch (e) {
      return AppColors.infoBg; // 默认颜色
    }
  }

  /// 获取分类标签颜色（匹配小程序）
  Color _getCategoryColor(String categoryCode) {
    const colorMap = {
      'TYPE_CULTURAL': AppColors.infoBg, // 文化文物系统 - 蓝色
      'TYPE_PRIVATE': AppColors.tagPrivate,  // 非国有博物馆 - 绿色
      'FOLK': AppColors.tagFolk,          // 民俗类 - 橙色
      'SCIENCE': AppColors.tagScience,       // 科技类 - 紫色
      'HISTORY': AppColors.tagHistory,       // 历史类 - 红色
    };
    return colorMap[categoryCode] ?? AppColors.surfaceVariant; // 默认颜色
  }

  void _onViewMoreTapped(BuildContext context) {
    context.push('/hot_museums');
  }

  /// 获取博物馆图片URL - 优先级：imageUrls.first → imageUrl → coverImage → null
  String? _getImageUrl(Museum museum) {
    // 1. 优先使用 imageUrls 的第一张图片
    if (museum.imageUrls != null && museum.imageUrls!.isNotEmpty) {
      return museum.imageUrls!.first;
    }
    
    // 2. 备用：使用 imageUrl 字段
    if (museum.imageUrl != null && museum.imageUrl!.isNotEmpty) {
      return museum.imageUrl;
    }
    
    // 3. 备用：使用 coverImage 字段
    if (museum.coverImage != null && museum.coverImage!.isNotEmpty) {
      return museum.coverImage;
    }
    
    return null;
  }
}