import 'package:dio/dio.dart';
import '../../models/api_response.dart';
import '../auth/auth_service.dart';
import 'http_client.dart';

/// 用户统计数据模型 - 打卡统计
class CheckinStats {
  final int totalCheckins;      // 总打卡次数
  final int thisMonthCheckins;  // 本月打卡次数
  final int visitedMuseums;     // 已访问博物馆数量
  final int totalPhotos;        // 总照片数量

  CheckinStats({
    required this.totalCheckins,
    required this.thisMonthCheckins,
    required this.visitedMuseums,
    required this.totalPhotos,
  });

  factory CheckinStats.fromJson(Map<String, dynamic> json) {
    return CheckinStats(
      totalCheckins: json['totalCheckins'] ?? 0,
      thisMonthCheckins: json['thisMonthCheckins'] ?? 0,
      visitedMuseums: json['visitedMuseums'] ?? 0,
      totalPhotos: json['totalPhotos'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalCheckins': totalCheckins,
      'thisMonthCheckins': thisMonthCheckins,
      'visitedMuseums': visitedMuseums,
      'totalPhotos': totalPhotos,
    };
  }

  /// 创建空的统计数据（未登录时使用）
  static CheckinStats empty() {
    return CheckinStats(
      totalCheckins: 0,
      thisMonthCheckins: 0,
      visitedMuseums: 0,
      totalPhotos: 0,
    );
  }
}

/// 用户统计数据模型 - 收藏统计
class FavoriteStats {
  final int museumCount;      // 收藏博物馆数量
  final int exhibitionCount;  // 收藏展览数量
  final int totalCount;       // 总收藏数量

  FavoriteStats({
    required this.museumCount,
    required this.exhibitionCount,
    required this.totalCount,
  });

  factory FavoriteStats.fromJson(Map<String, dynamic> json) {
    return FavoriteStats(
      museumCount: json['museumCount'] ?? 0,
      exhibitionCount: json['exhibitionCount'] ?? 0,
      totalCount: json['totalCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'museumCount': museumCount,
      'exhibitionCount': exhibitionCount,
      'totalCount': totalCount,
    };
  }

  /// 创建空的统计数据（未登录时使用）
  static FavoriteStats empty() {
    return FavoriteStats(
      museumCount: 0,
      exhibitionCount: 0,
      totalCount: 0,
    );
  }
}

/// 用户综合统计数据
class UserStats {
  final CheckinStats checkinStats;
  final FavoriteStats favoriteStats;
  final int points;     // 积分（暂未实现）
  final int rank;       // 排名（暂未实现）

  UserStats({
    required this.checkinStats,
    required this.favoriteStats,
    this.points = 0,
    this.rank = 0,
  });

  /// 创建空的统计数据（未登录时使用）
  static UserStats empty() {
    return UserStats(
      checkinStats: CheckinStats.empty(),
      favoriteStats: FavoriteStats.empty(),
      points: 0,
      rank: 0,
    );
  }

  /// 获取打卡次数（用于界面显示）
  int get totalCheckins => checkinStats.totalCheckins;

  /// 获取收藏总数（用于界面显示）
  int get totalFavorites => favoriteStats.totalCount;
}

/// 用户统计API服务
class UserStatsService {
  static final UserStatsService _instance = UserStatsService._internal();
  factory UserStatsService() => _instance;
  UserStatsService._internal();

  final _httpClient = HttpClient();
  final _authService = AuthService();

  /// 获取用户打卡统计数据
  /// API: GET /api/v1/museums/miniapp/checkin/stats
  Future<CheckinStats> getCheckinStats() async {
    return await _authService.withAuth(() async {
      // 获取当前用户ID
      final userId = await _authService.getCurrentUserId();
      if (userId == null) {
        throw Exception('用户未登录');
      }

      final response = await _httpClient.get(
        '/api/v1/museums/miniapp/checkin/stats',
        options: Options(
          headers: {
            'userId': userId.toString(),
          },
        ),
      );

      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );

      if (!apiResponse.isSuccess) {
        throw Exception(apiResponse.message);
      }

      return CheckinStats.fromJson(apiResponse.data ?? {});
    });
  }

  /// 获取用户收藏统计数据
  /// API: GET /api/v1/museums/miniapp/favorites/stats
  Future<FavoriteStats> getFavoriteStats() async {
    return await _authService.withAuth(() async {
      // 获取当前用户ID
      final userId = await _authService.getCurrentUserId();
      if (userId == null) {
        throw Exception('用户未登录');
      }

      final response = await _httpClient.get(
        '/api/v1/museums/miniapp/favorites/stats',
        options: Options(
          headers: {
            'userId': userId.toString(),
          },
        ),
      );

      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );

      if (!apiResponse.isSuccess) {
        throw Exception(apiResponse.message);
      }

      return FavoriteStats.fromJson(apiResponse.data ?? {});
    });
  }

  /// 获取用户综合统计数据
  /// 并行调用打卡和收藏统计API，与小程序保持一致
  Future<UserStats> getUserStats() async {
    if (!(await _authService.isLoggedIn())) {
      return UserStats.empty();
    }

    try {
      // DEBUG: print('🔄 开始加载用户统计数据...');

      // 并行获取打卡统计和收藏统计，与小程序保持一致
      final checkinStats = await getCheckinStats();
      final favoriteStats = await getFavoriteStats();

      // DEBUG: print('📊 打卡统计数据: ${checkinStats.toJson()}');
      // DEBUG: print('❤️ 收藏统计数据: ${favoriteStats.toJson()}');

      final userStats = UserStats(
        checkinStats: checkinStats,
        favoriteStats: favoriteStats,
        points: 0,    // 积分功能暂未实现，显示0
        rank: 0,      // 排名功能暂未实现，显示0
      );

      // DEBUG: print('✅ 用户统计数据加载成功');
      return userStats;
    } catch (e) {
      // DEBUG: print('❌ 加载用户统计数据失败: $e');
      return UserStats.empty();
    }
  }
}
