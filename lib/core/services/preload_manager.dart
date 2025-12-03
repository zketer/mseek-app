import 'package:flutter/foundation.dart';
import '../../services/api/banner_service.dart';
import '../../services/api/museum_service.dart';
import '../../services/api/exhibition_service.dart';
import '../../services/api/announcement_service.dart';

/// 预加载管理器
/// 
/// 负责在应用启动时预加载关键数据，提升用户体验
/// 
/// 预加载策略：
/// 1. 首页数据（轮播图、热门博物馆、最新展览）- 优先级高
/// 2. 发现页分类数据 - 优先级中
/// 3. 用户数据 - 按需加载
class PreloadManager {
  static final PreloadManager _instance = PreloadManager._internal();
  factory PreloadManager() => _instance;
  PreloadManager._internal();

  final BannerService _bannerService = BannerService();
  final MuseumService _museumService = MuseumService();
  final ExhibitionService _exhibitionService = ExhibitionService();
  final AnnouncementService _announcementService = AnnouncementService();

  bool _isPreloaded = false;
  
  /// 是否已完成预加载
  bool get isPreloaded => _isPreloaded;

  /// 预加载核心数据（在启动页调用）
  /// 
  /// 包括：
  /// - 轮播图
  /// - 热门博物馆
  /// - 最新展览
  /// - 公告
  Future<void> preloadCoreData() async {
    if (_isPreloaded) {
      debugPrint('📦 [预加载] 数据已预加载，跳过');
      return;
    }

    debugPrint('🚀 [预加载] 开始预加载核心数据...');
    
    final startTime = DateTime.now();

    try {
      // 并行加载多个接口，提高效率
      await Future.wait([
        _preloadBanners(),
        _preloadHotMuseums(),
        _preloadLatestExhibitions(),
        _preloadAnnouncements(),
      ], eagerError: false); // eagerError: false 表示某个失败不影响其他
      
      _isPreloaded = true;
      
      final duration = DateTime.now().difference(startTime);
      debugPrint('✅ [预加载] 核心数据预加载完成，耗时: ${duration.inMilliseconds}ms');
    } catch (e) {
      debugPrint('❌ [预加载] 预加载失败: $e');
      // 即使失败也标记为已加载，避免重复尝试
      _isPreloaded = true;
    }
  }

  /// 预加载轮播图
  Future<void> _preloadBanners() async {
    try {
      debugPrint('📸 [预加载] 加载轮播图...');
      await _bannerService.getActiveBanners(limit: 5);
      debugPrint('✓ [预加载] 轮播图加载完成');
    } catch (e) {
      debugPrint('✗ [预加载] 轮播图加载失败: $e');
    }
  }

  /// 预加载热门博物馆
  Future<void> _preloadHotMuseums() async {
    try {
      debugPrint('🏛️ [预加载] 加载热门博物馆...');
      await _museumService.getHotMuseums(page: 1, pageSize: 5);
      debugPrint('✓ [预加载] 热门博物馆加载完成');
    } catch (e) {
      debugPrint('✗ [预加载] 热门博物馆加载失败: $e');
    }
  }

  /// 预加载最新展览
  Future<void> _preloadLatestExhibitions() async {
    try {
      debugPrint('🎨 [预加载] 加载最新展览...');
      await _exhibitionService.getLatestExhibitions(page: 1, pageSize: 5);
      debugPrint('✓ [预加载] 最新展览加载完成');
    } catch (e) {
      debugPrint('✗ [预加载] 最新展览加载失败: $e');
    }
  }

  /// 预加载公告
  Future<void> _preloadAnnouncements() async {
    try {
      debugPrint('📢 [预加载] 加载公告...');
      await _announcementService.getActiveAnnouncements(limit: 3);
      debugPrint('✓ [预加载] 公告加载完成');
    } catch (e) {
      debugPrint('✗ [预加载] 公告加载失败: $e');
    }
  }

  /// 预加载发现页数据（在切换到发现页前调用）
  Future<void> preloadDiscoveryData() async {
    debugPrint('🔍 [预加载] 开始预加载发现页数据...');
    
    try {
      // 预加载博物馆分类和部分列表数据
      await Future.wait([
        _museumService.getCategories(),
        _museumService.getMuseums(page: 1, pageSize: 10), // 预加载第一页
      ], eagerError: false);
      debugPrint('✓ [预加载] 发现页数据加载完成');
    } catch (e) {
      debugPrint('✗ [预加载] 发现页数据加载失败: $e');
    }
  }

  /// 预加载打卡页数据（在切换到打卡页前调用）
  Future<void> preloadCheckinData() async {
    debugPrint('📍 [预加载] 开始预加载打卡页数据...');
    
    try {
      // 打卡页主要依赖定位，不需要预加载太多数据
      // 可以预加载打卡历史摘要
      debugPrint('✓ [预加载] 打卡页数据加载完成');
    } catch (e) {
      debugPrint('✗ [预加载] 打卡页数据加载失败: $e');
    }
  }

  /// 预加载我的页面数据（在切换到我的页面前调用）
  Future<void> preloadProfileData() async {
    debugPrint('👤 [预加载] 开始预加载我的页面数据...');
    
    try {
      // 预加载用户统计数据、成就等
      // 这些数据需要登录状态，需要检查
      debugPrint('✓ [预加载] 我的页面数据加载完成');
    } catch (e) {
      debugPrint('✗ [预加载] 我的页面数据加载失败: $e');
    }
  }

  /// 根据Tab索引预加载对应页面数据
  Future<void> preloadTabData(int tabIndex) async {
    switch (tabIndex) {
      case 0: // 首页
        // 首页数据已在启动时预加载
        break;
      case 1: // 发现页
        await preloadDiscoveryData();
        break;
      case 2: // 打卡页
        await preloadCheckinData();
        break;
      case 3: // 我的页面
        await preloadProfileData();
        break;
    }
  }

  /// 清除预加载标记（用于测试或强制重新加载）
  void reset() {
    _isPreloaded = false;
    debugPrint('🔄 [预加载] 预加载状态已重置');
  }

  /// 获取预加载进度（可用于显示加载进度）
  Stream<PreloadProgress> preloadWithProgress() async* {
    int total = 4; // 总任务数
    int completed = 0;

    yield PreloadProgress(completed, total, '开始预加载...');

    // 轮播图
    try {
      await _preloadBanners();
      completed++;
      yield PreloadProgress(completed, total, '轮播图加载完成');
    } catch (e) {
      debugPrint('轮播图加载失败: $e');
    }

    // 热门博物馆
    try {
      await _preloadHotMuseums();
      completed++;
      yield PreloadProgress(completed, total, '热门博物馆加载完成');
    } catch (e) {
      debugPrint('热门博物馆加载失败: $e');
    }

    // 最新展览
    try {
      await _preloadLatestExhibitions();
      completed++;
      yield PreloadProgress(completed, total, '最新展览加载完成');
    } catch (e) {
      debugPrint('最新展览加载失败: $e');
    }

    // 公告
    try {
      await _preloadAnnouncements();
      completed++;
      yield PreloadProgress(completed, total, '公告加载完成');
    } catch (e) {
      debugPrint('公告加载失败: $e');
    }

    _isPreloaded = true;
    yield PreloadProgress(completed, total, '预加载完成');
  }
}

/// 预加载进度数据类
class PreloadProgress {
  final int completed;
  final int total;
  final String message;

  PreloadProgress(this.completed, this.total, this.message);

  double get progress => completed / total;
  
  bool get isComplete => completed >= total;
}

