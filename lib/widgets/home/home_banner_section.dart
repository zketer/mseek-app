import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/ui_helper.dart';
import '../../models/banner.dart' as app_banner;

/// 首页轮播图组件 - 完全匹配小程序设计：真实图片+副标题+中间指示器
class HomeBannerSection extends StatefulWidget {
  final List<app_banner.Banner> banners;
  
  const HomeBannerSection({
    super.key,
    required this.banners,
  });

  @override
  State<HomeBannerSection> createState() => _HomeBannerSectionState();
}

class _HomeBannerSectionState extends State<HomeBannerSection> {
  int _currentIndex = 0;
  late PageController _pageController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    // 如果有多个轮播图，启动自动播放
    if (widget.banners.length > 1) {
      _startAutoPlay();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  /// 启动自动播放
  void _startAutoPlay() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_currentIndex < widget.banners.length - 1) {
        _currentIndex++;
      } else {
        _currentIndex = 0;
      }
      
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentIndex,
          duration: const Duration(milliseconds: 500), // 匹配小程序500ms
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingM), // 只保留左右边距
      child: SizedBox(
        height: AppDimensions.bannerHeight,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.bannerRadius),
          child: Stack(
            children: [
              // 轮播图
              PageView.builder(
                controller: _pageController,
                itemCount: widget.banners.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final banner = widget.banners[index];
                  return _buildBannerItem(banner);
                },
              ),
              
              // 指示器 - 位于轮播图内部底部中间
              if (widget.banners.length > 1)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: AppDimensions.paddingM,
                  child: Center(child: _buildIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建轮播图项
  Widget _buildBannerItem(app_banner.Banner banner) {
    return GestureDetector(
      onTap: () => _onBannerTapped(banner),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.bannerRadius),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.bannerRadius),
          child: Stack(
            children: [
              // 背景图片
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: banner.imageUrl,
                  fit: BoxFit.cover,
                  memCacheWidth: 800, // 限制内存缓存尺寸（Banner横幅优化）
                  memCacheHeight: 320, // 限制内存缓存尺寸（160px * 2 = 320）
                  placeholder: (context, url) => Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.textWhite),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.error_outline,
                        color: AppColors.textWhite,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),
              
              // 半透明遮罩层（确保文字可读性）
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.3),
                        Colors.black.withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                ),
              ),
              
              // 文字内容
              Positioned(
                left: AppDimensions.paddingL,
                bottom: AppDimensions.paddingL,
                right: AppDimensions.paddingL,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      banner.title,
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            offset: const Offset(1, 1),
                            blurRadius: 2,
                            color: Colors.black.withValues(alpha: 0.5),
                          ),
                        ],
                      ),
                    ),
                    // 固定显示副标题（和小程序保持一致）
                    const SizedBox(height: AppDimensions.paddingXS),
                    Text(
                      '发现文化之美',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textWhite.withValues(alpha: 0.9),
                        shadows: [
                          Shadow(
                            offset: const Offset(1, 1),
                            blurRadius: 2,
                            color: Colors.black.withValues(alpha: 0.5),
                          ),
                        ],
                      ),
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

  /// 构建指示器
  Widget _buildIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: widget.banners.asMap().entries.map((entry) {
          final index = entry.key;
          final isActive = index == _currentIndex;
          
          return GestureDetector(
            onTap: () => _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 500), // 匹配小程序500ms
              curve: Curves.easeInOut,
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: isActive ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 轮播图点击事件
  void _onBannerTapped(app_banner.Banner banner) {
    // TODO: 处理轮播图点击，跳转到对应页面
    UIHelper.showInfo(context, '点击了轮播图: ${banner.title}');
  }
}