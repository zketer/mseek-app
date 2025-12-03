import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';
import '../common/simple_empty_state.dart';

/// 发现页博物馆列表 - 完全匹配小程序设计
class DiscoveryMuseumList extends StatefulWidget {
  final List<Map<String, dynamic>> museums;
  final int total;
  final bool isLoading;
  final bool hasMore;
  final VoidCallback onRefresh;
  final VoidCallback? onLoadMore;

  const DiscoveryMuseumList({
    super.key,
    required this.museums,
    required this.total,
    required this.isLoading,
    required this.hasMore,
    required this.onRefresh,
    this.onLoadMore,
  });

  @override
  State<DiscoveryMuseumList> createState() => _DiscoveryMuseumListState();
}

class _DiscoveryMuseumListState extends State<DiscoveryMuseumList> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      // 距离底部200像素时触发加载更多
      widget.onLoadMore?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16), // 32rpx转换
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 列表标题 - 显示博物馆数量，精确匹配小程序间距
          if (widget.museums.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 10, 0, 0), // 下间距设为0，完全贴近卡片
              child: Text(
                '共找到 ${widget.total} 家博物馆',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 14, // 精确匹配小程序 28rpx = 14px
                  color: AppColors.textSecondary, // 精确匹配小程序 #666
                ),
              ),
            ),
          
          // 博物馆列表
          if (widget.isLoading)
            _buildLoadingWidget()
          else if (widget.museums.isEmpty)
            _buildEmptyWidget()
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => widget.onRefresh(),
                child: ListView.separated(
                  controller: _scrollController,
                  padding: EdgeInsets.zero, // 移除ListView默认的padding
                  itemCount: widget.museums.length + (widget.hasMore ? 1 : 0), // 如果有更多，添加一个加载项
                  separatorBuilder: (context, index) => const SizedBox(height: 8), // 进一步减少卡片间距
                  itemBuilder: (context, index) {
                    if (index < widget.museums.length) {
                      final museum = widget.museums[index];
                      return Container(
                        margin: index == 0 ? const EdgeInsets.only(top: 2) : null, // 第一个卡片添加极小间距，匹配小程序
                        child: _buildMuseumCard(context, museum),
                      );
                    } else {
                      // 加载更多指示器
                      return _buildLoadMoreWidget();
                    }
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 构建博物馆卡片 - 完全匹配小程序设计
  Widget _buildMuseumCard(BuildContext context, Map<String, dynamic> museum) {
    return GestureDetector(
      onTap: () {
        context.push('/museum/${museum['id']}');
      },
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 1.0, // 匹配小程序较轻的阴影效果
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10), // 20rpx转换
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight( // 让Row高度自适应内容
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // 进一步减少垂直内边距
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch, // 拉伸填充，消除留白
              children: [
                // 博物馆图片 - 调整宽度让比例更协调
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 95, // 增加宽度到95px，让图片更协调
                    height: 65, // 稍微增加高度到65px
                    child: _getImageUrl(museum) != null
                        ? CachedNetworkImage(
                            imageUrl: _getImageUrl(museum)!,
                            fit: BoxFit.cover,
                            memCacheWidth: 190, // 限制内存缓存尺寸（95px * 2 = 190）
                            memCacheHeight: 130, // 限制内存缓存尺寸（65px * 2 = 130）
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
              
              const SizedBox(width: 12), // 图片和文字间距 24rpx = 12px
              
              // 博物馆信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 博物馆名称
                      Text(
                        museum['name'] ?? '未知博物馆',
                        style: AppTextStyles.titleMedium.copyWith(
                          fontSize: 16, // 32rpx转换
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6), // 12rpx转换
                      
                      // 地址信息
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 12, // 24rpx转换
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4), // 8rpx转换
                          Expanded(
                            child: Text(
                              museum['address'] ?? '地址未知',
                              style: AppTextStyles.bodySmall.copyWith(
                                fontSize: 12, // 24rpx转换
                                color: Colors.grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8), // 16rpx转换
                      
                      // 藏品数量（如果有）
                      if (museum['collectionCount'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), // 8rpx 4rpx转换
                          decoration: BoxDecoration(
                            color: AppColors.backgroundLight,
                            borderRadius: BorderRadius.circular(4), // 8rpx转换
                          ),
                          child: Text(
                            '藏品: ${museum['collectionCount']}件',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 11, // 22rpx转换
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      
                      // 标签
                      if (museum['tags'] != null && museum['tags'].isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8), // 16rpx转换
                          child: Wrap(
                            spacing: 4, // 8rpx转换
                            runSpacing: 4,
                            children: (museum['tags'] as List)
                                .map((tag) => Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), // 8rpx 4rpx转换
                                      decoration: BoxDecoration(
                                        color: _parseColor(tag['color'] ?? '#f0f8ff'),
                                        borderRadius: BorderRadius.circular(6), // 12rpx转换
                                        border: Border.all(
                                          color: Colors.black.withValues(alpha: 0.1),
                                          width: 0.5, // 1rpx转换
                                        ),
                                      ),
                                      child: Text(
                                        tag['name'] ?? '',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          fontSize: 9, // 18rpx转换
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                      
                      // 描述信息（如果有）
                      if (museum['description'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6), // 12rpx转换
                          child: Text(
                            museum['description']!,
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 12, // 24rpx转换
                              color: Colors.grey,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建加载状态
  Widget _buildLoadingWidget() {
    return const Expanded(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(20), // 40rpx转换
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
              SizedBox(height: 16),
              Text(
                '加载中...',
                style: TextStyle(
                  fontSize: 14, // 28rpx转换
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyWidget() {
    return Expanded(
      child: SimpleEmptyState(
        icon: Icons.museum_outlined,
        message: '暂无博物馆数据',
        subtitle: '试试调整筛选条件',
      ),
    );
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

  /// 构建加载更多指示器
  Widget _buildLoadMoreWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: const Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            SizedBox(width: 8),
            Text(
              '加载更多...',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 获取博物馆图片URL - 优先级：imageUrls.first → imageUrl → coverImage → null
  String? _getImageUrl(Map<String, dynamic> museum) {
    // 1. 优先使用 imageUrls 的第一张图片
    if (museum['imageUrls'] != null && museum['imageUrls'] is List && (museum['imageUrls'] as List).isNotEmpty) {
      return museum['imageUrls'][0] as String?;
    }
    
    // 2. 备用：使用 imageUrl 字段
    if (museum['imageUrl'] != null && museum['imageUrl'].toString().isNotEmpty) {
      return museum['imageUrl'] as String?;
    }
    
    // 3. 备用：使用 coverImage 字段
    if (museum['coverImage'] != null && museum['coverImage'].toString().isNotEmpty) {
      return museum['coverImage'] as String?;
    }
    
    // 4. 兼容旧的 image 字段
    if (museum['image'] != null && museum['image'].toString().isNotEmpty) {
      return museum['image'] as String?;
    }
    
    return null;
  }
}