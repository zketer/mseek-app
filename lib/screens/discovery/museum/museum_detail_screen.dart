import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../models/museum.dart';
import '../../../services/api/museum_service.dart';
import '../../../services/api/favorites_service.dart';
import '../../../services/auth/auth_service.dart';
import '../../../core/router/auth_guard.dart';
import '../../../widgets/common/common_app_bar.dart';
import '../../../widgets/common/toast_widget.dart';
import '../../../core/utils/ui_helper.dart';

/// 博物馆详情页面 - 完全匹配小程序设计的简洁布局
class MuseumDetailScreen extends StatefulWidget {
  final int museumId;
  
  const MuseumDetailScreen({
    super.key,
    required this.museumId,
  });

  @override
  State<MuseumDetailScreen> createState() => _MuseumDetailScreenState();
}

class _MuseumDetailScreenState extends State<MuseumDetailScreen> {
  final MuseumService _museumService = MuseumService();
  final FavoritesService _favoritesService = FavoritesService();
  final AuthService _authService = AuthService();
  final PageController _pageController = PageController();
  Museum? _museum;
  bool _isLoading = true;
  bool _isFavorited = false;
  bool _showFullDescription = false;
  String? _error;
  int _currentImageIndex = 0;
  Timer? _autoPlayTimer;
  
  /// 获取博物馆图片列表（优先使用后端返回的 imageUrls）
  List<String> get _museumImages {
    List<String> images = [];
    
    // 优先使用后端返回的 imageUrls 列表
    if (_museum?.imageUrls != null && _museum!.imageUrls!.isNotEmpty) {
      images.addAll(_museum!.imageUrls!.where((url) => url.isNotEmpty));
    }
    
    // 降级逻辑：如果 imageUrls 为空，使用 imageUrl
    if (images.isEmpty && _museum?.imageUrl != null && _museum!.imageUrl!.isNotEmpty) {
      images.add(_museum!.imageUrl!);
    }
    
    // 降级逻辑：如果还是为空，使用 coverImage
    if (images.isEmpty && _museum?.coverImage != null && _museum!.coverImage!.isNotEmpty) {
      images.add(_museum!.coverImage!);
    }
    
    // 如果没有任何图片，使用默认占位符
    if (images.isEmpty) {
      images = [
        'https://via.placeholder.com/400x250?text=${_museum?.name ?? '博物馆'}',
      ];
    }
    
    return images;
  }

  /// 获取展览列表（暂时为空，等待后端展览API）
  List<Map<String, dynamic>> get _exhibitions {
    // TODO: 从API获取博物馆的展览列表
    // 目前返回空列表，展览部分不显示
    return [];
  }

  @override
  void initState() {
    super.initState();
    _loadMuseumDetail();
    _startAutoPlay();
  }

  @override
  void dispose() {
    _stopAutoPlay();
    _pageController.dispose();
    super.dispose();
  }

  /// 加载博物馆详情
  Future<void> _loadMuseumDetail() async {
    try {
      // DEBUG: print('🏛️ [博物馆详情] 开始加载博物馆详情: ID=${widget.museumId}');
      
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
      // DEBUG: print('📡 [博物馆详情] 调用API: /api/v1/museums/miniapp/museums/${widget.museumId}');
      final museum = await _museumService.getMuseumDetail(widget.museumId);
      
      // DEBUG: print('✅ [博物馆详情] 加载成功: ${museum.name}');
      // DEBUG: print('📊 [博物馆详情] 数据详情:');
      // DEBUG: print('   - ticketDescription: ${museum.ticketDescription}');
      // DEBUG: print('   - collectionCount: ${museum.collectionCount}');
      // DEBUG: print('   - annualVisitors: ${museum.annualVisitors}');
      // DEBUG: print('   - exhibitions: ${museum.exhibitions}');
      // DEBUG: print('   - educationActivities: ${museum.educationActivities}');
      // DEBUG: print('   - imageUrls: ${museum.imageUrls?.length ?? 0}张图片');
      
      setState(() {
        _museum = museum;
        _isLoading = false;
      });
      
      // 异步加载收藏状态
      _loadFavoriteStatus();
      
      // 重新启动自动播放（因为图片可能发生变化）
      _resetAutoPlay();
    } catch (e) {
      // DEBUG: print('❌ [博物馆详情] 加载失败: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// 加载收藏状态（从API获取）
  Future<void> _loadFavoriteStatus() async {
    if (!await _authService.isLoggedIn()) {
      return; // 未登录时不获取收藏状态
    }

    try {
      final isFavorited = await _favoritesService.checkMuseumFavorite(widget.museumId);
      if (mounted) {
        setState(() {
          _isFavorited = isFavorited;
        });
      }
    } catch (e) {
      // DEBUG: print('❌ [博物馆详情] 获取收藏状态失败: $e');
      // 获取失败时保持默认状态
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // 匹配小程序背景色
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  /// 构建顶部导航栏
  PreferredSizeWidget _buildAppBar() {
    return CommonAppBar.withFavoriteAndShare(
      title: _museum?.name ?? '博物馆详情',
      isFavorited: _isFavorited,
      onFavoritePressed: _toggleFavorite,
      onSharePressed: _shareMuseum,
    );
  }

  /// 构建主体内容
  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }
    
    if (_error != null) {
      return _buildErrorState();
    }
    
    if (_museum == null) {
      return _buildEmptyState();
    }
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 图片轮播
          _buildImageSwiper(),
          
          // 博物馆基本信息（包含标签）
          _buildMuseumInfo(),
          
          // 统计信息
          _buildStatsSection(),
          
          // 博物馆介绍
          _buildDescriptionSection(),
          
          // 当前展览
          if (_exhibitions.isNotEmpty) _buildExhibitionSection(),
          
          // 门票信息
          _buildTicketSection(),
          
          // 参观须知
          _buildNoticeSection(),
          
          // 联系方式
          _buildContactSection(),
          
          // 底部间距
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  /// 构建加载状态
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primaryLight),
          SizedBox(height: AppDimensions.paddingM),
          Text('加载中...', style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }

  /// 构建错误状态
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: AppDimensions.paddingM),
          Text(
            '加载失败',
            style: AppTextStyles.titleMedium.copyWith(color: AppColors.error),
          ),
          const SizedBox(height: AppDimensions.paddingS),
          Text(
            _error ?? '未知错误',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.paddingM),
          ElevatedButton(
            onPressed: _loadMuseumDetail,
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.museum_outlined,
            size: 64,
            color: AppColors.textHint,
          ),
          SizedBox(height: AppDimensions.paddingM),
          Text('博物馆不存在', style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }

  /// 构建图片轮播 - 完全匹配小程序轮播图功能
  Widget _buildImageSwiper() {
    return SizedBox(
      height: 250, // 500rpx转换
      child: Stack(
        children: [
          // 图片轮播主体
          PageView.builder(
            controller: _pageController,
            itemCount: _museumImages.length,
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
              // 重置自动播放定时器
              _resetAutoPlay();
            },
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _previewImage(index),
                child: CachedNetworkImage(
                  imageUrl: _museumImages[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  memCacheWidth: 800, // 限制内存缓存尺寸（轮播图优化）
                  memCacheHeight: 500, // 限制内存缓存尺寸（250px * 2 = 500）
                  errorWidget: (context, url, error) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.museum,
                        size: 60,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              );
            },
          ),
          
          // 指示器点 - 匹配小程序样式
          if (_museumImages.length > 1)
            Positioned(
              bottom: 16, // 32rpx
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_museumImages.length, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4), // 8rpx
                    width: 8, // 16rpx
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentImageIndex == index
                          ? Colors.white // 选中状态：白色
                          : Colors.white.withValues(alpha: 0.5), // 未选中：半透明白色
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  /// 启动自动播放
  void _startAutoPlay() {
    if (_museumImages.length <= 1) return;
    
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        final nextIndex = (_currentImageIndex + 1) % _museumImages.length;
        _pageController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 500), // 匹配小程序动画时长
          curve: Curves.easeInOut,
        );
      }
    });
  }

  /// 停止自动播放
  void _stopAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = null;
  }

  /// 重置自动播放（用户手动滑动后重新开始计时）
  void _resetAutoPlay() {
    _stopAutoPlay();
    _startAutoPlay();
  }

  /// 构建博物馆基本信息（包含标签）
  Widget _buildMuseumInfo() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(AppDimensions.paddingM), // 32rpx
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Text(
            _museum?.name ?? '故宫博物院',
            style: AppTextStyles.headlineSmall.copyWith(
              fontSize: 20, // 40rpx
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          
          const SizedBox(height: 8), // 16rpx
          
          // 评分
          Row(
            children: [
              Text(
                _museum?.rating?.toString() ?? '0',
                style: AppTextStyles.titleMedium.copyWith(
                  fontSize: 16, // 32rpx
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '/5.0 (${_museum?.visitCount ?? 0}条评价)',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 14, // 28rpx
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16), // 32rpx
          
          // 基本信息
          _buildInfoRow(Icons.location_on, _museum?.address ?? '博物馆地址'),
          const SizedBox(height: 8), // 16rpx
          _buildInfoRow(Icons.access_time, _museum?.openTime ?? '开放时间'),
          const SizedBox(height: 8), // 16rpx
          _buildInfoRow(
            Icons.attach_money, 
            _museum?.isFree == true ? '免费开放' : '¥${_museum?.ticketPrice ?? 0}/人',
            color: _museum?.isFree == true ? AppColors.successDark : null,
          ),
          if (_museum?.level != null) ...[
            const SizedBox(height: 8), // 16rpx
            _buildInfoRow(
              Icons.star, 
              '国家${_getLevelText(_museum!.level!)}级博物馆',
              color: AppColors.rating,
            ),
          ],
          
          // 标签部分 - 直接放在基本信息后面
          const SizedBox(height: 16), // 32rpx
          _buildTagsSection(),
        ],
      ),
    );
  }

  /// 构建标签部分
  Widget _buildTagsSection() {
    return Wrap(
      spacing: 8, // 16rpx
      runSpacing: 8,
      children: [
        // 评分标签
        _buildTag(
          '${_museum?.rating ?? 4.5}★',
          backgroundColor: AppColors.primary,
          textColor: Colors.white,
        ),
        
        // 门票标签
        if (_museum?.isFree == true)
          _buildTag('免费', backgroundColor: AppColors.successDark, textColor: Colors.white)
        else if (_museum?.ticketPrice != null && _museum!.ticketPrice! > 0)
          _buildTag('¥${_museum!.ticketPrice!.toStringAsFixed(0)}', backgroundColor: Colors.grey[200]!, textColor: Colors.grey[700]!),
        
        // 营业状态标签
        _buildTag(
          '营业中',
          backgroundColor: AppColors.infoSky,
          textColor: Colors.white,
        ),
        
        // 特色标签 - 根据博物馆类型和分类生成
        ..._generateFeatureTags(),
      ],
    );
  }

  /// 生成特色标签
  List<Widget> _generateFeatureTags() {
    List<Widget> tags = [];
    
    // 基于博物馆分类生成标签
    if (_museum?.categories != null && _museum!.categories!.isNotEmpty) {
      for (var category in _museum!.categories!) {
        tags.add(_buildTag(
          category.name,
          backgroundColor: Colors.grey[200]!,
          textColor: Colors.grey[700]!,
        ));
      }
    } else {
      // 默认标签
      tags.addAll([
        _buildTag('历史文物', backgroundColor: Colors.grey[200]!, textColor: Colors.grey[700]!),
        _buildTag('文化教育', backgroundColor: Colors.grey[200]!, textColor: Colors.grey[700]!),
        _buildTag('艺术展览', backgroundColor: Colors.grey[200]!, textColor: Colors.grey[700]!),
      ]);
    }
    
    return tags;
  }

  /// 构建信息行
  Widget _buildInfoRow(IconData icon, String text, {Color? color}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14, // 28rpx
          color: color ?? Colors.grey[600],
        ),
        const SizedBox(width: 6), // 12rpx
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 13, // 26rpx
              color: color ?? Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }

  /// 获取级别文本
  String _getLevelText(int level) {
    switch (level) {
      case 1: return '一';
      case 2: return '二';
      case 3: return '三';
      default: return '一';
    }
  }

  /// 格式化数字（如访客量）
  String _formatNumber(int number) {
    if (number == 0) return '--';
    if (number >= 10000) {
      double value = number / 10000.0;
      if (value >= 10) {
        return '${value.toInt()}万+';
      } else {
        return '${value.toStringAsFixed(1)}万+';
      }
    } else if (number >= 1000) {
      return '${(number / 1000.0).toStringAsFixed(1)}千+';
    } else {
      return '$number';
    }
  }

  /// 获取门票描述（优先使用后端返回的 ticketDescription）
  String _getTicketDescription() {
    // 优先使用后端返回的 ticketDescription
    if (_museum?.ticketDescription != null && _museum!.ticketDescription!.isNotEmpty) {
      return _museum!.ticketDescription!;
    }
    
    // 降级逻辑：根据价格和免费标志生成描述
    if (_museum?.isFree == true) {
      return '本馆免费开放，请提前网上预约参观。';
    } else if (_museum?.ticketPrice != null && _museum!.ticketPrice! > 0) {
      return '成人票：¥${_museum!.ticketPrice!.toStringAsFixed(0)}/人，学生票半价，儿童免费。详情请咨询博物馆。';
    } else {
      return '门票信息请咨询博物馆，建议提前预约参观。';
    }
  }

  /// 切换收藏状态
  Future<void> _toggleFavorite() async {
    // 检查登录状态
    if (!await _authService.isLoggedIn()) {
      if (mounted) {
        await requireAuth(
          context,
          options: AuthGuardOptions(
            title: '需要登录',
            content: '收藏功能需要登录后使用，是否前往登录？',
            confirmText: '去登录',
            showCancel: true,
            targetPath: '/museum/${widget.museumId}',
          ),
        );
      }
      return;
    }

    // 已登录，执行收藏操作
    await _performFavoriteAction();
  }

  /// 执行收藏操作的具体逻辑
  Future<void> _performFavoriteAction() async {
    final museumId = widget.museumId;
    final isFavorited = _isFavorited;

    try {
      // DEBUG: print('${isFavorited ? "🗑️" : "⭐"} [博物馆收藏] ${isFavorited ? "取消收藏" : "收藏"}博物馆: $museumId');

      // 调用收藏/取消收藏API
      bool success = false;
      if (isFavorited) {
        success = await _favoritesService.unfavoriteMuseum(museumId);
      } else {
        success = await _favoritesService.favoriteMuseum(museumId);
      }

      if (success) {
        // 更新本地状态
        setState(() {
          _isFavorited = !isFavorited;
        });

        if (mounted) {
          ToastWidget.showSuccess(
            context,
            isFavorited ? '已取消收藏' : '已添加收藏',
          );
        }
      } else {
        throw Exception('服务器返回操作失败');
      }
    } catch (e) {
      // DEBUG: print('❌ [博物馆收藏] 操作失败: $e');
      if (mounted) {
        ToastWidget.showError(
          context,
          '操作失败: $e',
        );
      }
    }
  }


  /// 构建标签
  Widget _buildTag(String text, {required Color backgroundColor, required Color textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // 16rpx 8rpx
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12), // 24rpx
      ),
      child: Text(
        text,
        style: AppTextStyles.bodySmall.copyWith(
          fontSize: 11, // 22rpx
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// 构建统计信息
  Widget _buildStatsSection() {
    // 使用真实的后端数据
    final collectionCount = _museum?.collectionCount ?? 0;
    final annualVisitors = _museum?.annualVisitors ?? _museum?.visitCount ?? 0; // 优先使用 annualVisitors
    final exhibitions = _museum?.exhibitions ?? 0;
    final educationActivities = _museum?.educationActivities ?? 0;
    
    return Container(
      width: double.infinity,
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8), // 16rpx
      padding: const EdgeInsets.all(AppDimensions.paddingM), // 32rpx
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16), // 32rpx
          Row(
            children: [
              Expanded(child: _buildStatItem(
                collectionCount > 0 ? _formatNumber(collectionCount) : '--', 
                '馆藏文物'
              )),
              Expanded(child: _buildStatItem(
                annualVisitors > 0 ? _formatNumber(annualVisitors) : '--', 
                '年度访客'
              )),
              Expanded(child: _buildStatItem(
                exhibitions > 0 ? '$exhibitions' : '--', 
                '年度展览'
              )),
              Expanded(child: _buildStatItem(
                educationActivities > 0 ? '$educationActivities' : '--', 
                '教育活动'
              )),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建统计项
  Widget _buildStatItem(String number, String label) {
    return Column(
      children: [
        Text(
          number,
          style: AppTextStyles.titleMedium.copyWith(
            fontSize: 18, // 36rpx
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4), // 8rpx
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            fontSize: 12, // 24rpx
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  /// 构建描述部分
  Widget _buildDescriptionSection() {
    final description = _museum?.description ?? '暂无博物馆介绍信息。';
    
    return Container(
      width: double.infinity,
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8), // 16rpx
      padding: const EdgeInsets.all(AppDimensions.paddingM), // 32rpx
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '博物馆介绍',
            style: AppTextStyles.titleMedium.copyWith(
              fontSize: 16, // 32rpx
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12), // 24rpx
          Text(
            description,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 14, // 28rpx
              color: Colors.grey[700],
              height: 1.6,
            ),
            maxLines: _showFullDescription ? null : 3,
            overflow: _showFullDescription ? null : TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8), // 16rpx
          GestureDetector(
            onTap: _toggleDescription,
            child: Text(
              _showFullDescription ? '收起' : '展开',
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 14, // 28rpx
                color: AppColors.infoSky,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建展览部分
  Widget _buildExhibitionSection() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8), // 16rpx
      padding: const EdgeInsets.all(AppDimensions.paddingM), // 32rpx
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '当前展览',
            style: AppTextStyles.titleMedium.copyWith(
              fontSize: 16, // 32rpx
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12), // 24rpx
          ..._exhibitions.map((exhibition) => _buildExhibitionItem(exhibition)),
        ],
      ),
    );
  }

  /// 构建展览项
  Widget _buildExhibitionItem(Map<String, dynamic> exhibition) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12), // 24rpx
      child: Row(
        children: [
          // 展览图片
          ClipRRect(
            borderRadius: BorderRadius.circular(8), // 16rpx
            child: CachedNetworkImage(
              imageUrl: exhibition['image'],
              width: 60, // 120rpx
              height: 40, // 80rpx
              fit: BoxFit.cover,
              memCacheWidth: 120, // 限制内存缓存尺寸（60px * 2 = 120）
              memCacheHeight: 80, // 限制内存缓存尺寸（40px * 2 = 80）
              errorWidget: (context, url, error) {
                return Container(
                  width: 60,
                  height: 40,
                  color: Colors.grey[300],
                  child: const Icon(Icons.museum, color: Colors.grey),
                );
              },
            ),
          ),
          
          const SizedBox(width: 12), // 24rpx
          
          // 展览信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exhibition['title'],
                  style: AppTextStyles.titleSmall.copyWith(
                    fontSize: 14, // 28rpx
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4), // 8rpx
                Text(
                  '${exhibition['startDate']} - ${exhibition['endDate']}',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 12, // 24rpx
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4), // 8rpx
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), // 12rpx 4rpx
                  decoration: BoxDecoration(
                    color: exhibition['status'] == '进行中' 
                        ? AppColors.infoSky.withValues(alpha: 0.1)
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(4), // 8rpx
                  ),
                  child: Text(
                    exhibition['status'],
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 10, // 20rpx
                      color: exhibition['status'] == '进行中' 
                          ? AppColors.infoSky
                          : Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建门票信息
  Widget _buildTicketSection() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8), // 16rpx
      padding: const EdgeInsets.all(AppDimensions.paddingM), // 32rpx
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '门票信息',
            style: AppTextStyles.titleMedium.copyWith(
              fontSize: 16, // 32rpx
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12), // 24rpx
          Text(
            _getTicketDescription(),
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 14, // 28rpx
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建参观须知
  Widget _buildNoticeSection() {
    final notices = [
      {'icon': '🎫', 'text': '请提前预约，携带有效身份证件'},
      {'icon': '📷', 'text': '部分展厅禁止拍照，请遵守相关规定'},
      {'icon': '🔇', 'text': '参观时请保持安静，勿大声喧哗'},
      {'icon': '👶', 'text': '儿童需在成人陪同下参观'},
    ];

    return Container(
      width: double.infinity,
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8), // 16rpx
      padding: const EdgeInsets.all(AppDimensions.paddingM), // 32rpx
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '参观须知',
            style: AppTextStyles.titleMedium.copyWith(
              fontSize: 16, // 32rpx
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12), // 24rpx
          ...notices.map((notice) => _buildNoticeItem(notice['icon']!, notice['text']!)),
        ],
      ),
    );
  }

  /// 构建须知项
  Widget _buildNoticeItem(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12), // 24rpx
      child: Row(
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 12), // 24rpx
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 13, // 26rpx
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建联系方式
  Widget _buildContactSection() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8), // 16rpx
      padding: const EdgeInsets.all(AppDimensions.paddingM), // 32rpx
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '联系方式',
            style: AppTextStyles.titleMedium.copyWith(
              fontSize: 16, // 32rpx
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12), // 24rpx
          if (_museum?.phone != null) ...[
            _buildContactItem(Icons.phone, _museum!.phone!, _callPhone),
            const SizedBox(height: 8), // 16rpx
          ],
          if (_museum?.website != null) ...[
            _buildContactItem(Icons.language, '官方网站', _openWebsite),
            const SizedBox(height: 8), // 16rpx
          ],
          if (_museum?.phone == null && _museum?.website == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '暂无联系方式信息',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 构建联系项
  Widget _buildContactItem(IconData icon, String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            icon,
            size: 16, // 32rpx
            color: AppColors.primary,
          ),
          const SizedBox(width: 12), // 24rpx
          Text(
            text,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 14, // 28rpx
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  /// 切换描述显示
  void _toggleDescription() {
    setState(() {
      _showFullDescription = !_showFullDescription;
    });
  }

  /// 预览图片
  void _previewImage(int index) {
    // TODO: 实现图片预览功能
    UIHelper.showInfo(context, '预览图片 ${index + 1}');
  }

  /// 导航到博物馆
  // TODO: Implement navigation to museum
  // ignore: unused_element
  void _navigateToMuseum() {
    UIHelper.showInfo(context, '打开地图导航');
    // TODO: 打开地图导航
  }

  /// 拨打电话
  void _callPhone() {
    final phone = _museum?.phone;
    if (phone != null) {
      UIHelper.showInfo(context, '拨打电话：$phone');
      // TODO: 打开拨号界面
      // url_launcher.launch('tel:$phone');
    }
  }

  /// 打开网站
  void _openWebsite() {
    final website = _museum?.website;
    if (website != null) {
      UIHelper.showInfo(context, '打开网站：$website');
      // TODO: 打开浏览器
      // url_launcher.launch(website);
    }
  }

  /// 执行打卡
  // TODO: Implement check-in functionality
  // ignore: unused_element
  void _performCheckin() {
    // TODO: 检查位置权限和距离
    UIHelper.showInfo(context, '前往打卡: ${_museum?.name ?? '故宫博物院'}');
    // 可以跳转到打卡页面并定位到该博物馆
  }

  /// 分享博物馆
  void _shareMuseum() {
    // TODO: 调用系统分享功能
    UIHelper.showInfo(context, '分享博物馆: ${_museum?.name ?? '故宫博物院'}');
  }

}