import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/ui_helper.dart';
import '../../../core/utils/bottom_sheet_helper.dart';
import '../../../models/exhibition.dart';
import '../../../services/api/exhibition_service.dart';
import '../../../services/api/favorites_service.dart';
import '../../../services/auth/auth_service.dart';
import '../../../widgets/common/toast_widget.dart';
import '../../../widgets/common/common_app_bar.dart';
import '../../../core/constants/app_dimensions.dart';

/// 展览详情页面 - 完全对齐小程序
class ExhibitionDetailScreen extends StatefulWidget {
  final int exhibitionId;
  
  const ExhibitionDetailScreen({
    super.key,
    required this.exhibitionId,
  });

  @override
  State<ExhibitionDetailScreen> createState() => _ExhibitionDetailScreenState();
}

class _ExhibitionDetailScreenState extends State<ExhibitionDetailScreen> {
  bool _isLoading = true;
  String? _error;
  Exhibition? _exhibitionDetail;
  bool _showFullDesc = false;
  bool _isFavorited = false;
  int _currentImageIndex = 0; // 当前图片索引
  
  final _exhibitionService = ExhibitionService();
  final _favoritesService = FavoritesService();
  final _authService = AuthService();
  
  // 轮播图相关
  PageController? _pageController;
  Timer? _autoPlayTimer;

  @override
  void initState() {
    super.initState();
    _loadExhibitionDetail();
    _loadFavoriteStatus();
  }
  
  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController?.dispose();
    super.dispose();
  }

  /// 加载展览详情
  Future<void> _loadExhibitionDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // DEBUG: print('🎨 [展览详情] 开始加载展览详情: ${widget.exhibitionId}');
      
      final exhibition = await _exhibitionService.getExhibitionDetail(widget.exhibitionId);
      
      // DEBUG: print('✅ [展览详情] 展览详情加载成功: ${exhibition.title}');
      // DEBUG: print('📷 [展览详情] images字段: ${exhibition.images}');
      // DEBUG: print('📷 [展览详情] coverImage字段: ${exhibition.coverImage}');
      
      setState(() {
        _exhibitionDetail = exhibition;
        _isLoading = false;
      });
      
      // 初始化轮播图（对齐首页轮播图）
      _initImageSwiper();
    } catch (e) {
      // DEBUG: print('❌ [展览详情] 加载失败: $e');
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      });
    }
  }
  
  /// 初始化图片轮播（对齐首页轮播图 - 3秒自动播放）
  void _initImageSwiper() {
    // 获取图片列表
    List<String> images = [];
    if (_exhibitionDetail?.images != null && _exhibitionDetail!.images!.isNotEmpty) {
      images = _exhibitionDetail!.images!.where((img) => img.isNotEmpty).toList();
    } else if (_exhibitionDetail?.coverImage != null && _exhibitionDetail!.coverImage!.isNotEmpty) {
      images = [_exhibitionDetail!.coverImage!];
    }
    
    // 如果有多张图片，初始化PageController并启动自动播放
    if (images.length > 1) {
      _pageController = PageController();
      _startAutoPlay(images.length);
      // DEBUG: print('✅ [图片轮播] 已启动自动播放：${images.length}张图片，每3秒切换');
    }
  }
  
  /// 启动自动播放（对齐首页轮播图 - 3秒间隔）
  void _startAutoPlay(int imageCount) {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController == null || !_pageController!.hasClients) {
        timer.cancel();
        return;
      }
      
      if (_currentImageIndex < imageCount - 1) {
        _currentImageIndex++;
      } else {
        _currentImageIndex = 0;
      }
      
      _pageController!.animateToPage(
        _currentImageIndex,
        duration: const Duration(milliseconds: 500), // 对齐首页500ms
        curve: Curves.easeInOut,
      );
    });
  }
  
  /// 加载收藏状态（对齐小程序）
  Future<void> _loadFavoriteStatus() async {
    final isLoggedIn = await _authService.isLoggedIn();
    
    if (!isLoggedIn) {
      // DEBUG: print('ℹ️ [展览详情] 未登录，跳过加载收藏状态');
      return;
    }
    
    try {
      // DEBUG: print('📡 [展览详情] 开始检查收藏状态: ${widget.exhibitionId}');
      
      final isFavorited = await _favoritesService.checkExhibitionFavorite(widget.exhibitionId);
      
      if (mounted) {
        setState(() {
          _isFavorited = isFavorited;
        });
        
        // DEBUG: print('✅ [展览详情] 收藏状态加载成功: $isFavorited');
      }
    } catch (e) {
      // DEBUG: print('❌ [展览详情] 加载收藏状态失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          // 如果没有成功pop，跳转到首页
          context.go('/');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
      appBar: CommonAppBar.withFavoriteAndShare(
          title: _exhibitionDetail?.title ?? '展览详情',
        isFavorited: _isFavorited,
          onFavoritePressed: _onFavorite,
          onSharePressed: _onShare,
          onBackPressed: () => _handleBack(context),
        ),
      body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadExhibitionDetail,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('重新加载', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (_exhibitionDetail == null) {
      return const Center(
        child: Text('展览信息不存在', style: TextStyle(color: Colors.grey)),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // 图片轮播
          _buildImageSwiper(),
          
          // 展览信息
          _buildInfoSection(),
          
          const SizedBox(height: 10),
          
          // 展览介绍
          _buildDescriptionSection(),
          
          const SizedBox(height: 10),
          
          // 参观须知
          _buildNoticeSection(),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// 图片轮播 - 对齐小程序500rpx高度
  Widget _buildImageSwiper() {
    // 小程序500rpx = 250px
    const double swiperHeight = 250.0;
    
    // 获取图片列表：优先使用 images，其次使用 coverImage，最后使用默认图片
    List<String> images = [];
    if (_exhibitionDetail?.images != null && _exhibitionDetail!.images!.isNotEmpty) {
      images = _exhibitionDetail!.images!;
      // DEBUG: print('📷 [图片轮播] 使用images列表: ${images.length}张图片');
      // DEBUG: print('📷 [图片轮播] 第一张图片URL: ${images.first}');
    } else if (_exhibitionDetail?.coverImage != null && _exhibitionDetail!.coverImage!.isNotEmpty) {
      images = [_exhibitionDetail!.coverImage!];
      // DEBUG: print('📷 [图片轮播] 使用coverImage: ${_exhibitionDetail!.coverImage}');
    } else {
      // 使用默认图片
      images = [''];
      // DEBUG: print('📷 [图片轮播] 没有图片，使用默认占位图');
      // DEBUG: print('📷 [图片轮播] images字段: ${_exhibitionDetail?.images}');
      // DEBUG: print('📷 [图片轮播] coverImage字段: ${_exhibitionDetail?.coverImage}');
    }
    
    return SizedBox(
      height: swiperHeight,
      child: Stack(
      children: [
          // 图片轮播（添加自动播放 - 对齐首页轮播图）
          PageView.builder(
            controller: _pageController, // 添加controller支持自动播放
            itemCount: images.length,
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemBuilder: (context, index) {
          final imageUrl = images[index];
          
          // 如果图片URL为空，显示默认占位图
          if (imageUrl.isEmpty) {
            return Container(
              decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
              child: const Center(
                child: Icon(
                  Icons.museum,
                  size: 64,
                  color: Colors.white,
                ),
              ),
            );
          }
          
          return GestureDetector(
            onTap: () {
              // 图片预览
              // TODO: 实现图片预览功能
            },
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              memCacheWidth: 800, // 限制内存缓存尺寸（轮播图优化，适配不同屏幕）
              memCacheHeight: 500, // 限制内存缓存尺寸（250px * 2 = 500）
              placeholder: (context, url) => Container(
                color: AppColors.borderLight,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                ),
              ),
              errorWidget: (context, url, error) {
                // DEBUG: print('❌ [图片轮播] 图片加载失败: $url');
                // DEBUG: print('❌ [图片轮播] 错误信息: $error');
                return Container(
          decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.museum,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
          
          // 轮播指示器（只有多张图片时显示）
          if (images.length > 1 && images.first.isNotEmpty)
        Positioned(
              bottom: 12,
          left: 0,
          right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  images.length,
                  (index) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentImageIndex == index
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                      ),
                    ),
                  ],
                ),
    );
  }

  /// 展览信息区块 - 对齐小程序
  Widget _buildInfoSection() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题和收藏按钮
          // 标题（收藏按钮已移到AppBar）
          Text(
            _exhibitionDetail!.title,
            style: const TextStyle(
              fontSize: 20, // 40rpx
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
          
          const SizedBox(height: 6),
          
          // 博物馆名称（可点击）
          GestureDetector(
            onTap: _onNavigateToMuseum,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
              Text(
                _exhibitionDetail!.museumName ?? '',
                style: const TextStyle(
                  fontSize: 14, // 28rpx
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
                const SizedBox(width: 4),
                const Text(
                  '›',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 6),
          
          // 评分 - 对齐小程序（暂时不显示，因为后端没有这个字段）
          // TODO: 等后端添加 rating 和 reviewCount 字段后再显示
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
                children: [
              const Text(
                '4.5',
                style: TextStyle(
                  fontSize: 16, // 32rpx
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 4),
                        Text(
                '/5.0 (${_exhibitionDetail!.viewCount ?? 0}条评价)',
                style: TextStyle(
                  fontSize: 12, // 24rpx
                  color: Colors.grey[600],
                ),
                        ),
                      ],
                    ),
          
          const SizedBox(height: 12),
          
          // 元信息列表
          Column(
            children: [
              // 展览日期
              _buildMetaItem(Icons.access_time, '${_exhibitionDetail!.startDate} - ${_exhibitionDetail!.endDate}'),
              
              // 展览位置（如果有）
              if (_exhibitionDetail!.location != null && _exhibitionDetail!.location!.isNotEmpty) ...[
                const SizedBox(height: 6),
                _buildMetaItem(Icons.location_on, _exhibitionDetail!.location!),
              ],
              
              // 门票信息
              if (_exhibitionDetail!.freeAdmission == 1) ...[
                const SizedBox(height: 6),
                _buildMetaItem(Icons.confirmation_number, '免费参观', isHighlight: true),
              ] else if (_exhibitionDetail!.ticketPrice != null && _exhibitionDetail!.ticketPrice! > 0) ...[
                const SizedBox(height: 6),
                _buildMetaItem(Icons.confirmation_number, '¥${_exhibitionDetail!.ticketPrice}/人'),
              ],
              
              // 是否常设展览
              if (_exhibitionDetail!.isPermanent == 1) ...[
                const SizedBox(height: 6),
                _buildMetaItem(Icons.star, '常设展览', isHighlight: true),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// 元信息项
  Widget _buildMetaItem(IconData icon, String text, {bool isHighlight = false}) {
    return Row(
      children: [
        Icon(
          icon, 
          size: 14, 
          color: isHighlight ? AppColors.successDark : AppColors.textHint,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 13, // 26rpx
            color: isHighlight ? AppColors.successDark : AppColors.textSecondary,
            fontWeight: isHighlight ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  /// 展览介绍区块 - 对齐小程序
  Widget _buildDescriptionSection() {
    final description = _exhibitionDetail?.description ?? '暂无介绍';
    
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '展览介绍',
            style: TextStyle(
              fontSize: 16, // 32rpx
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(
              fontSize: 14, // 28rpx
              color: AppColors.textSecondary,
              height: 1.6,
            ),
            maxLines: _showFullDesc ? null : 3,
            overflow: _showFullDesc ? null : TextOverflow.ellipsis,
          ),
          if (description.length > 50) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () {
                setState(() {
                  _showFullDesc = !_showFullDesc;
                });
              },
              child: Text(
                _showFullDesc ? '收起' : '展开',
                style: const TextStyle(
                  fontSize: 13, // 26rpx
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 参观须知区块 - 对齐小程序
  Widget _buildNoticeSection() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '参观须知',
            style: TextStyle(
              fontSize: 16, // 32rpx
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Column(
            children: [
              _buildNoticeItem('🔔', '请按展览时间安排参观，部分展品可能调整'),
              const SizedBox(height: 10),
              _buildNoticeItem('📷', '部分展品禁止拍照，请遵守相关规定'),
              const SizedBox(height: 10),
              _buildNoticeItem('🤫', '参观时请保持安静，勿大声喧哗'),
              const SizedBox(height: 10),
              _buildNoticeItem('👶', '儿童需在成人陪同下参观'),
            ],
          ),
        ],
      ),
    );
  }

  /// 参观须知项
  Widget _buildNoticeItem(String emoji, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 14), // 28rpx
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14, // 28rpx
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  /// 收藏操作 - 需要登录
  Future<void> _onFavorite() async {
    // 检查登录状态
    final isLoggedIn = await _authService.isLoggedIn();
    
    if (!isLoggedIn) {
      // 未登录，使用登录守卫
      if (mounted) {
        final confirmed = await BottomSheetHelper.showConfirm(
          context,
          title: '需要登录',
          content: '收藏展览需要登录后使用，是否前往登录？',
          confirmText: '去登录',
          cancelText: '取消',
          icon: Icons.lock_outline,
        );
        
        if (confirmed == true && mounted) {
          // 跳转到登录页，登录成功后返回当前页面
          final currentPath = '/exhibition-detail?id=${widget.exhibitionId}';
          context.push('/login?redirect=${Uri.encodeComponent(currentPath)}');
        }
      }
      return;
    }
    
    // 已登录，执行收藏操作（对齐小程序）
    final currentFavoriteStatus = _isFavorited;
    // DEBUG: print('⭐ [收藏] 当前状态: ${currentFavoriteStatus ? "已收藏" : "未收藏"}');
    
    try {
      bool success = false;
      
      if (currentFavoriteStatus) {
        // 取消收藏
        success = await _favoritesService.unfavoriteExhibition(widget.exhibitionId);
      } else {
        // 添加收藏
        success = await _favoritesService.favoriteExhibition(widget.exhibitionId);
      }
      
      if (success) {
        // 更新本地状态
        if (mounted) {
          setState(() {
            _isFavorited = !currentFavoriteStatus;
          });
          
          // 使用Toast显示提示（对齐小程序）
          ToastWidget.showSuccess(
            context,
            _isFavorited ? '已添加收藏' : '已取消收藏',
          );
        }
      } else {
        throw Exception('服务器返回操作失败');
      }
    } catch (e) {
      // DEBUG: print('❌ [收藏] 操作失败: $e');
      
      if (mounted) {
        ToastWidget.showError(
          context,
          '操作失败，请重试',
        );
      }
    }
  }

  /// 跳转到博物馆
  void _onNavigateToMuseum() {
    if (_exhibitionDetail?.museumId == null) {
      return;
    }
    
    // DEBUG: print('🏛️ [跳转博物馆] museumId: ${_exhibitionDetail!.museumId}');
    
    // 跳转到博物馆详情页
    context.push('/museum/${_exhibitionDetail!.museumId}');
  }
  
  /// 分享展览
  void _onShare() {
    // TODO: 实现分享功能
    UIHelper.showWarning(context, '分享功能开发中');
  }

  /// 处理返回 - 对齐小程序逻辑
  void _handleBack(BuildContext context) {
    // 检查是否可以返回
    if (context.canPop()) {
      // 有上一页，正常返回
      context.pop();
    } else {
      // 没有上一页，跳转到首页
      context.go('/');
    }
  }
}
