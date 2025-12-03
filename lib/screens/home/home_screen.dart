import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';
import '../../widgets/home/home_banner_section.dart';
import '../../widgets/home/home_announcement_section.dart';
import '../../widgets/home/home_quick_entry_section.dart';
import '../../widgets/home/home_hot_museums_section.dart';
import '../../widgets/home/home_exhibitions_section.dart';
import '../../widgets/common/skeleton/banner_skeleton.dart';
import '../../widgets/common/skeleton/museum_card_skeleton.dart';
import '../../widgets/common/skeleton/exhibition_card_skeleton.dart';
import '../../widgets/common/section_empty_state.dart';
import '../../widgets/common/app_page_wrapper.dart';
import '../../services/api/banner_service.dart';
import '../../services/api/announcement_service.dart';
import '../../services/api/museum_service.dart';
import '../../services/api/exhibition_service.dart';
import '../../services/cache/cache_manager.dart';
import '../../services/cache/cache_keys.dart';
import '../../models/banner.dart' as app_banner;
import '../../models/announcement.dart';
import '../../models/museum.dart';
import '../../models/exhibition.dart';

/// 首页界面 - 已优化图片加载和移除顶部AppBar
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  
  // API服务实例
  final _bannerService = BannerService();
  final _announcementService = AnnouncementService();
  final _museumService = MuseumService();
  final _exhibitionService = ExhibitionService();
  
  // 数据状态
  List<app_banner.Banner> _banners = [];
  List<Announcement> _announcements = [];
  List<Museum> _hotMuseums = [];
  List<Exhibition> _exhibitions = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 加载页面数据
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // 并行加载各种数据，和小程序保持一致
          await Future.wait([
        _loadBanners(),
        _loadAnnouncements(),
        _loadHotMuseums(),
        _loadLatestExhibitions(),
      ]);
      
      // DEBUG: print('首页数据加载完成');
    } catch (e) {
      // DEBUG: print('首页数据加载失败: $e');
      // 不显示错误提示，空状态组件已经足够
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  /// 加载轮播图数据（使用缓存30分钟）
  Future<void> _loadBanners() async {
    try {
      final banners = await CacheManager().getOrSet<List<app_banner.Banner>>(
        key: CacheKeys.banners,
        fetcher: () => _bannerService.getActiveBanners(limit: 5),
        duration: CacheDuration.minute30,
        toJson: (data) => data.map((e) => e.toJson()).toList(),
        fromJson: (json) => (json as List)
            .map((e) => app_banner.Banner.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
      
      if (mounted) {
        setState(() {
          _banners = banners;
        });
      }
    } catch (e) {
      // DEBUG: print('轮播图加载失败: $e');
      // 保持默认空数组，不影响其他功能
    }
  }
  
  /// 加载公告数据（使用缓存30分钟）
  Future<void> _loadAnnouncements() async {
    try {
      final announcements = await CacheManager().getOrSet<List<Announcement>>(
        key: CacheKeys.announcements,
        fetcher: () => _announcementService.getActiveAnnouncements(limit: 3),
        duration: CacheDuration.minute30,
        toJson: (data) => data.map((e) => e.toJson()).toList(),
        fromJson: (json) => (json as List)
            .map((e) => Announcement.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
      
      if (mounted) {
        setState(() {
          _announcements = announcements;
        });
      }
    } catch (e) {
      // DEBUG: print('公告加载失败: $e');
      // 保持默认空数组，不影响其他功能
    }
  }
  
  /// 加载热门博物馆数据（使用缓存10分钟）
  Future<void> _loadHotMuseums() async {
    try {
      final museums = await CacheManager().getOrSet<List<Museum>>(
        key: CacheKeys.hotMuseums,
        fetcher: () async {
          final response = await _museumService.getHotMuseums(
            page: 1,
            pageSize: 5,
          );
          return response.records;
        },
        duration: CacheDuration.minute10,
        toJson: (data) => data.map((e) => e.toJson()).toList(),
        fromJson: (json) => (json as List)
            .map((e) => Museum.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
      
      if (mounted) {
        setState(() {
          _hotMuseums = museums;
        });
      }
    } catch (e) {
      // DEBUG: print('热门博物馆加载失败: $e');
      // 保持默认空数组，不影响其他功能
    }
  }
  
  /// 加载最新展览数据（使用缓存10分钟）
  Future<void> _loadLatestExhibitions() async {
    try {
      final exhibitions = await CacheManager().getOrSet<List<Exhibition>>(
        key: CacheKeys.latestExhibitions,
        fetcher: () async {
          final response = await _exhibitionService.getLatestExhibitions(
            page: 1,
            pageSize: 5,
          );
          return response.records;
        },
        duration: CacheDuration.minute10,
        toJson: (data) => data.map((e) => e.toJson()).toList(),
        fromJson: (json) => (json as List)
            .map((e) => Exhibition.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
      
      if (mounted) {
        setState(() {
          _exhibitions = exhibitions;
        });
      }
    } catch (e) {
      // DEBUG: print('最新展览加载失败: $e');
      // 保持默认空数组，不影响其他功能
    }
  }

  /// 下拉刷新（清除缓存）
  Future<void> _onRefresh() async {
    // 清除首页相关缓存
    await CacheManager().clearHomeCache();
    // 重新加载数据
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须调用，用于AutomaticKeepAliveClientMixin

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppPageWrapper(
        safeAreaTop: false, // 首页不使用顶部安全区域，让轮播图延伸到状态栏
        child: _isLoading
            ? _buildLoadingWidget()
            : RefreshIndicator(
                onRefresh: _onRefresh,
                color: AppColors.primaryLight, // 浅粉色刷新指示器
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    // 添加状态栏高度的占位
                    SliverToBoxAdapter(
                      child: SizedBox(height: MediaQuery.of(context).padding.top),
                    ),
                    // 页面内容（移除AppBar，直接从轮播图开始）
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          // 轮播图区域（显示空状态占位）
                          _buildBannerSection(),
                          
                          const SizedBox(height: AppDimensions.paddingM),
                          
                          // 公告栏区域
                          HomeAnnouncementSection(announcements: _announcements),
                          
                          const SizedBox(height: AppDimensions.paddingS), // 减少间距以匹配小程序
                          
                          // 快速入口区域
                          const HomeQuickEntrySection(),
                          
                          const SizedBox(height: 16), // 32rpx转换，缩小快捷按钮和热门博物馆间距
                          
                          // 热门博物馆区域（显示空状态占位）
                          _buildHotMuseumsSection(),
                          
                          const SizedBox(height: 16), // 32rpx转换，缩小热门博物馆和最新展览间距
                          
                          // 最新展览区域（显示空状态占位）
                          _buildExhibitionsSection(),
                          
                          // 底部空白区域
                          const SizedBox(height: AppDimensions.paddingXXL),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  /// 构建加载widget（使用骨架屏）
  Widget _buildLoadingWidget() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          // 轮播图骨架屏
          const BannerSkeleton(),
          
          const SizedBox(height: AppDimensions.paddingM),
          
          // 快速入口（保持显示）
          const HomeQuickEntrySection(),
          
          const SizedBox(height: 16),
          
          // 热门博物馆骨架屏
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('热门博物馆', style: AppTextStyles.titleLarge),
                const SizedBox(height: AppDimensions.paddingS),
                ...List.generate(2, (index) => const MuseumCardSkeleton()),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 最新展览骨架屏
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('最新展览', style: AppTextStyles.titleLarge),
                const SizedBox(height: AppDimensions.paddingS),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  child: Row(
                    children: List.generate(
                      2,
                      (index) => const ExhibitionCardSkeleton(),
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
  
  /// 构建轮播图区域（带空状态）
  Widget _buildBannerSection() {
    if (_banners.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 20), // 添加20pt顶部边距，与轮播图保持一致
        child: SectionEmptyState(
          icon: Icons.image_outlined,
          message: '暂无轮播内容',
          subtitle: '敬请期待更多精彩内容',
          height: AppDimensions.bannerHeight,
        ),
      );
    }
    return HomeBannerSection(banners: _banners);
  }
  
  /// 构建热门博物馆区域（带空状态）
  Widget _buildHotMuseumsSection() {
    if (_hotMuseums.isEmpty) {
      return SectionEmptyState(
        sectionTitle: '热门博物馆',
        icon: Icons.museum_outlined,
        message: '暂无热门博物馆',
        subtitle: '等待更多博物馆入驻',
      );
    }
    return HomeHotMuseumsSection(museums: _hotMuseums);
  }
  
  /// 构建最新展览区域（带空状态）
  Widget _buildExhibitionsSection() {
    if (_exhibitions.isEmpty) {
      return SectionEmptyState(
        sectionTitle: '最新展览',
        icon: Icons.art_track_outlined,
        message: '暂无最新展览',
        subtitle: '敬请期待精彩展览',
      );
    }
    return HomeExhibitionsSection(exhibitions: _exhibitions);
  }
}
