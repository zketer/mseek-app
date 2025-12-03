import 'package:dio/dio.dart';
import '../../models/api_response.dart';
import '../auth/auth_service.dart';
import 'http_client.dart';

/// 成就模型
class Achievement {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String category;
  final String requirement;
  final int progress;
  final int target;
  final bool unlocked;
  final String? unlockedDate;
  final String rarity; // common | rare | epic | legendary

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    required this.requirement,
    required this.progress,
    required this.target,
    required this.unlocked,
    this.unlockedDate,
    required this.rarity,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? '🏆',
      category: json['category'] ?? 'checkin',
      requirement: json['requirement'] ?? '',
      progress: json['progress'] ?? 0,
      target: json['target'] ?? 1,
      unlocked: json['unlocked'] ?? false,
      unlockedDate: json['unlockedDate'],
      rarity: json['rarity'] ?? 'common',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'category': category,
      'requirement': requirement,
      'progress': progress,
      'target': target,
      'unlocked': unlocked,
      'unlockedDate': unlockedDate,
      'rarity': rarity,
    };
  }

  /// 获取稀有度文本
  String get rarityText {
    switch (rarity) {
      case 'rare':
        return '稀有';
      case 'epic':
        return '史诗';
      case 'legendary':
        return '传说';
      default:
        return '';
    }
  }

  /// 获取进度百分比
  double get progressPercentage {
    if (target == 0) return 0.0;
    return (progress / target * 100).clamp(0.0, 100.0);
  }
}

/// 成就分类模型
class AchievementCategory {
  final String id;
  final String name;
  final int count;
  final int unlockedCount;

  AchievementCategory({
    required this.id,
    required this.name,
    required this.count,
    required this.unlockedCount,
  });

  factory AchievementCategory.fromJson(Map<String, dynamic> json) {
    return AchievementCategory(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      count: json['count'] ?? 0,
      unlockedCount: json['unlockedCount'] ?? 0,
    );
  }
}

/// 成就统计模型
class AchievementStats {
  final int totalAchievements;
  final int unlockedAchievements;
  final double completionRate;

  AchievementStats({
    required this.totalAchievements,
    required this.unlockedAchievements,
  }) : completionRate = totalAchievements > 0 
           ? (unlockedAchievements / totalAchievements * 100) 
           : 0.0;

  factory AchievementStats.fromJson(Map<String, dynamic> json) {
    return AchievementStats(
      totalAchievements: json['totalAchievements'] ?? 0,
      unlockedAchievements: json['unlockedAchievements'] ?? 0,
    );
  }

  static AchievementStats empty() {
    return AchievementStats(
      totalAchievements: 0,
      unlockedAchievements: 0,
    );
  }
}

/// 成就服务类
class AchievementsService {
  static final AchievementsService _instance = AchievementsService._internal();
  factory AchievementsService() => _instance;
  AchievementsService._internal();

  final _httpClient = HttpClient();
  final _authService = AuthService();

  /// 获取用户成就列表
  /// API: GET /api/v1/museums/miniapp/achievements
  Future<List<Achievement>> getUserAchievements() async {
    return await _authService.withAuth(() async {
      final userId = await _authService.getCurrentUserId();
      if (userId == null) {
        throw Exception('用户未登录');
      }

      try {
        final response = await _httpClient.get(
          '/api/v1/museums/miniapp/achievements',
          options: Options(
            headers: {
              'userId': userId.toString(),
            },
          ),
        );

        final apiResponse = ApiResponse<List<dynamic>>.fromJson(
          response.data,
          (json) => json as List<dynamic>,
        );

        if (!apiResponse.isSuccess) {
          throw Exception(apiResponse.message);
        }

        final achievements = (apiResponse.data ?? [])
            .map((json) => Achievement.fromJson(json as Map<String, dynamic>))
            .toList();

        return achievements;
      } catch (e) {
        // 如果后端API未实现，返回默认成就数据
        // DEBUG: print('获取成就数据失败，使用默认数据: $e');
        return _getDefaultAchievements();
      }
    });
  }

  /// 检查并解锁新成就
  /// API: POST /api/v1/museums/miniapp/achievements/check
  Future<List<Achievement>> checkAndUnlockAchievements() async {
    return await _authService.withAuth(() async {
      final userId = await _authService.getCurrentUserId();
      if (userId == null) {
        throw Exception('用户未登录');
      }

      try {
        final response = await _httpClient.post(
          '/api/v1/museums/miniapp/achievements/check',
          options: Options(
            headers: {
              'userId': userId.toString(),
            },
          ),
        );

        final apiResponse = ApiResponse<List<dynamic>>.fromJson(
          response.data,
          (json) => json as List<dynamic>,
        );

        if (!apiResponse.isSuccess) {
          return [];
        }

        return (apiResponse.data ?? [])
            .map((json) => Achievement.fromJson(json as Map<String, dynamic>))
            .toList();
      } catch (e) {
        // DEBUG: print('检查新成就失败: $e');
        return [];
      }
    });
  }

  /// 获取成就统计
  Future<AchievementStats> getAchievementStats() async {
    return await _authService.withAuth(() async {
      final achievements = await getUserAchievements();
      final unlockedCount = achievements.where((a) => a.unlocked).length;
      
      return AchievementStats(
        totalAchievements: achievements.length,
        unlockedAchievements: unlockedCount,
      );
    });
  }

  /// 获取成就分类
  Future<List<AchievementCategory>> getAchievementCategories() async {
    final achievements = await getUserAchievements();
    
    final categories = <String, AchievementCategory>{};
    
    // 全部分类
    categories['all'] = AchievementCategory(
      id: 'all',
      name: '全部',
      count: achievements.length,
      unlockedCount: achievements.where((a) => a.unlocked).length,
    );
    
    // 按分类统计
    for (final achievement in achievements) {
      final categoryId = achievement.category;
      final categoryName = _getCategoryName(categoryId);
      
      if (categories.containsKey(categoryId)) {
        final existing = categories[categoryId]!;
        categories[categoryId] = AchievementCategory(
          id: categoryId,
          name: categoryName,
          count: existing.count + 1,
          unlockedCount: existing.unlockedCount + (achievement.unlocked ? 1 : 0),
        );
      } else {
        categories[categoryId] = AchievementCategory(
          id: categoryId,
          name: categoryName,
          count: 1,
          unlockedCount: achievement.unlocked ? 1 : 0,
        );
      }
    }
    
    return categories.values.toList();
  }

  /// 获取分类名称
  String _getCategoryName(String categoryId) {
    switch (categoryId) {
      case 'checkin':
        return '打卡成就';
      case 'explore':
        return '探索成就';
      case 'social':
        return '社交成就';
      case 'special':
        return '特殊成就';
      default:
        return '其他';
    }
  }

  /// 获取默认成就数据（用于API未实现时的备用）
  List<Achievement> _getDefaultAchievements() {
    return [
      // 打卡成就系列
      Achievement(
        id: 'register',
        name: '文博新人',
        description: '欢迎加入文博探索的世界！',
        icon: '🎉',
        category: 'checkin',
        requirement: '完成用户注册',
        progress: 1,
        target: 1,
        unlocked: true,
        unlockedDate: '2024-01-01',
        rarity: 'common',
      ),
      Achievement(
        id: 'first_checkin',
        name: '初来乍到',
        description: '完成第一次博物馆打卡',
        icon: '🏛️',
        category: 'checkin',
        requirement: '打卡1个博物馆',
        progress: 1,
        target: 1,
        unlocked: true,
        unlockedDate: '2024-01-02',
        rarity: 'common',
      ),
      Achievement(
        id: 'checkin_5',
        name: '文化探索者',
        description: '已探索5个不同的博物馆',
        icon: '🔍',
        category: 'checkin',
        requirement: '打卡5个博物馆',
        progress: 3,
        target: 5,
        unlocked: false,
        rarity: 'common',
      ),
      Achievement(
        id: 'checkin_10',
        name: '博物馆达人',
        description: '已成为真正的博物馆爱好者',
        icon: '⭐',
        category: 'checkin',
        requirement: '打卡10个博物馆',
        progress: 3,
        target: 10,
        unlocked: false,
        rarity: 'rare',
      ),
      Achievement(
        id: 'checkin_25',
        name: '文化收藏家',
        description: '对文化艺术有着深度的理解',
        icon: '💎',
        category: 'checkin',
        requirement: '打卡25个博物馆',
        progress: 3,
        target: 25,
        unlocked: false,
        rarity: 'epic',
      ),
      Achievement(
        id: 'checkin_50',
        name: '文博大师',
        description: '文化探索的终极成就',
        icon: '👑',
        category: 'checkin',
        requirement: '打卡50个博物馆',
        progress: 3,
        target: 50,
        unlocked: false,
        rarity: 'legendary',
      ),
      
      // 探索成就系列
      Achievement(
        id: 'first_province',
        name: '省域探索者',
        description: '探索了第一个省份的博物馆',
        icon: '🗺️',
        category: 'explore',
        requirement: '打卡1个省份',
        progress: 1,
        target: 1,
        unlocked: true,
        unlockedDate: '2024-01-02',
        rarity: 'common',
      ),
      Achievement(
        id: 'province_5',
        name: '跨省旅行者',
        description: '足迹已遍布多个省份',
        icon: '✈️',
        category: 'explore',
        requirement: '打卡5个省份',
        progress: 1,
        target: 5,
        unlocked: false,
        rarity: 'rare',
      ),
      Achievement(
        id: 'national_museum',
        name: '国家瑰宝',
        description: '参观了国家级博物馆',
        icon: '🏆',
        category: 'explore',
        requirement: '打卡国家一级博物馆',
        progress: 0,
        target: 1,
        unlocked: false,
        rarity: 'epic',
      ),
      
      // 社交成就系列
      Achievement(
        id: 'first_favorite',
        name: '收藏达人',
        description: '收藏了第一个心仪的博物馆',
        icon: '❤️',
        category: 'social',
        requirement: '收藏1个博物馆',
        progress: 0,
        target: 1,
        unlocked: false,
        rarity: 'common',
      ),
      Achievement(
        id: 'share_experience',
        name: '分享家',
        description: '与朋友分享了文博体验',
        icon: '📤',
        category: 'social',
        requirement: '分享1次',
        progress: 0,
        target: 1,
        unlocked: false,
        rarity: 'common',
      ),
      
      // 特殊成就系列
      Achievement(
        id: 'night_visit',
        name: '夜游者',
        description: '在夜间参观了博物馆',
        icon: '🌙',
        category: 'special',
        requirement: '夜间打卡',
        progress: 0,
        target: 1,
        unlocked: false,
        rarity: 'rare',
      ),
      Achievement(
        id: 'weekend_warrior',
        name: '周末勇士',
        description: '连续多个周末都在探索博物馆',
        icon: '⚔️',
        category: 'special',
        requirement: '连续4个周末打卡',
        progress: 0,
        target: 4,
        unlocked: false,
        rarity: 'epic',
      ),
    ];
  }
}
