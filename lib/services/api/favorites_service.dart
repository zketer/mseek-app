import 'package:dio/dio.dart';
import '../../models/api_response.dart';
import '../auth/auth_service.dart';
import 'http_client.dart';

/// 收藏的博物馆模型
class FavoriteMuseum {
  final int id;
  final String name;
  final String cityName;
  final String provinceName;
  final String address;
  final String level;
  final String category;
  final double? rating;
  final String? distance;
  final String? ticketPrice;
  final List<String>? images;
  final bool isVisited;
  final String favoriteTime;

  FavoriteMuseum({
    required this.id,
    required this.name,
    required this.cityName,
    required this.provinceName,
    required this.address,
    required this.level,
    required this.category,
    this.rating,
    this.distance,
    this.ticketPrice,
    this.images,
    required this.isVisited,
    required this.favoriteTime,
  });

  factory FavoriteMuseum.fromJson(Map<String, dynamic> json) {
    // 处理isVisited：后端可能返回 int (0/1) 或 bool
    bool isVisited = false;
    final isVisitedValue = json['isVisited'];
    if (isVisitedValue != null) {
      if (isVisitedValue is int) {
        isVisited = isVisitedValue == 1;
      } else if (isVisitedValue is bool) {
        isVisited = isVisitedValue;
      }
    }
    
    return FavoriteMuseum(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? '',
      cityName: json['cityName']?.toString() ?? '未知城市',
      provinceName: json['provinceName']?.toString() ?? '未知省份',
      address: json['address']?.toString() ?? '',
      level: json['level']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      rating: json['rating']?.toDouble(),
      distance: json['distance']?.toString(),
      ticketPrice: json['ticketPrice']?.toString(),
      images: json['images'] != null ? List<String>.from(json['images']) : null,
      isVisited: isVisited,
      favoriteTime: json['favoriteTime']?.toString() ?? json['createAt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'cityName': cityName,
      'provinceName': provinceName,
      'address': address,
      'level': level,
      'category': category,
      'rating': rating,
      'distance': distance,
      'ticketPrice': ticketPrice,
      'images': images,
      'isVisited': isVisited,
      'favoriteTime': favoriteTime,
    };
  }
}

/// 收藏的展览模型
class FavoriteExhibition {
  final int id;
  final String title;
  final String museumName;
  final String cityName;
  final String startDate;
  final String endDate;
  final String category;
  final String status; // ongoing | upcoming | ended
  final bool isPermanent;
  final String? ticketPrice;
  final List<String>? images;
  final String favoriteTime;

  FavoriteExhibition({
    required this.id,
    required this.title,
    required this.museumName,
    required this.cityName,
    required this.startDate,
    required this.endDate,
    required this.category,
    required this.status,
    required this.isPermanent,
    this.ticketPrice,
    this.images,
    required this.favoriteTime,
  });

  factory FavoriteExhibition.fromJson(Map<String, dynamic> json) {
    // 处理状态转换：后端可能返回 int (0/1/2) 或 String ('ended'/'ongoing'/'upcoming')
    String status = 'ongoing';
    final statusValue = json['status'];
    if (statusValue != null) {
      if (statusValue is int) {
        // 0=已结束, 1=进行中, 2=即将开始
        switch (statusValue) {
          case 0:
            status = 'ended';
            break;
          case 1:
            status = 'ongoing';
            break;
          case 2:
            status = 'upcoming';
            break;
          default:
            status = 'ongoing';
        }
      } else {
        status = statusValue.toString();
      }
    }
    
    // 处理isPermanent：后端可能返回 int (0/1) 或 bool
    bool isPermanent = false;
    final isPermanentValue = json['isPermanent'];
    if (isPermanentValue != null) {
      if (isPermanentValue is int) {
        isPermanent = isPermanentValue == 1;
      } else if (isPermanentValue is bool) {
        isPermanent = isPermanentValue;
      }
    }
    
    return FavoriteExhibition(
      id: json['id'] ?? 0,
      title: json['title']?.toString() ?? '',
      museumName: json['museumName']?.toString() ?? '',
      cityName: json['cityName']?.toString() ?? '未知城市',
      startDate: json['startDate']?.toString() ?? '',
      endDate: json['endDate']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      status: status,
      isPermanent: isPermanent,
      ticketPrice: json['ticketPrice']?.toString(),
      images: json['images'] != null ? List<String>.from(json['images']) : null,
      favoriteTime: json['favoriteTime']?.toString() ?? json['createAt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'museumName': museumName,
      'cityName': cityName,
      'startDate': startDate,
      'endDate': endDate,
      'category': category,
      'status': status,
      'isPermanent': isPermanent,
      'ticketPrice': ticketPrice,
      'images': images,
      'favoriteTime': favoriteTime,
    };
  }

  /// 获取状态文本
  String get statusText {
    switch (status) {
      case 'ongoing':
        return '进行中';
      case 'upcoming':
        return '即将开始';
      case 'ended':
        return '已结束';
      default:
        return '未知';
    }
  }

  /// 获取展览时间描述
  String get timeDescription {
    if (isPermanent) {
      return '长期展览';
    }
    return '$startDate - $endDate';
  }
}

/// 收藏统计数据模型
class FavoriteStats {
  final int museumCount;
  final int exhibitionCount;
  final int totalCount;

  FavoriteStats({
    required this.museumCount,
    required this.exhibitionCount,
  }) : totalCount = museumCount + exhibitionCount;

  factory FavoriteStats.fromJson(Map<String, dynamic> json) {
    return FavoriteStats(
      museumCount: json['museumCount'] ?? 0,
      exhibitionCount: json['exhibitionCount'] ?? 0,
    );
  }

  static FavoriteStats empty() {
    return FavoriteStats(
      museumCount: 0,
      exhibitionCount: 0,
    );
  }
}

/// 收藏服务类
class FavoritesService {
  static final FavoritesService _instance = FavoritesService._internal();
  factory FavoritesService() => _instance;
  FavoritesService._internal();

  final _httpClient = HttpClient();
  final _authService = AuthService();

  /// 获取用户收藏统计
  /// API: GET /api/v1/museums/miniapp/favorites/stats
  Future<FavoriteStats> getUserFavoriteStats() async {
    return await _authService.withAuth(() async {
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

  /// 获取用户收藏的博物馆列表
  /// API: GET /api/v1/museums/miniapp/favorites/museums
  Future<PageResponse<FavoriteMuseum>> getUserFavoriteMuseums({
    int page = 1,
    int pageSize = 10,
    bool? visitStatus, // null=全部, true=已访问, false=未访问
    String sortBy = 'time', // time | name | distance
  }) async {
    return await _authService.withAuth(() async {
      final userId = await _authService.getCurrentUserId();
      if (userId == null) {
        throw Exception('用户未登录');
      }

      final queryParams = {
        'page': page.toString(),
        'pageSize': pageSize.toString(),
        'sortBy': sortBy,
      };

      if (visitStatus != null) {
        queryParams['visitStatus'] = visitStatus.toString();
      }

      final response = await _httpClient.get(
        '/api/v1/museums/miniapp/favorites/museums',
        queryParameters: queryParams,
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

      return PageResponse<FavoriteMuseum>.fromJson(
        apiResponse.data ?? {},
        (json) => FavoriteMuseum.fromJson(json as Map<String, dynamic>),
      );
    });
  }

  /// 获取用户收藏的展览列表
  /// API: GET /api/v1/museums/miniapp/favorites/exhibitions
  Future<PageResponse<FavoriteExhibition>> getUserFavoriteExhibitions({
    int page = 1,
    int pageSize = 10,
    int? status, // null=全部, 1=进行中, 2=即将开始, 0=已结束
    String sortBy = 'time', // time | name
  }) async {
    return await _authService.withAuth(() async {
      final userId = await _authService.getCurrentUserId();
      if (userId == null) {
        // DEBUG: print('❌ [FavoritesService] 用户未登录');
        throw Exception('用户未登录');
      }

      final queryParams = {
        'page': page.toString(),
        'pageSize': pageSize.toString(),
        'sortBy': sortBy,
      };

      if (status != null) {
        queryParams['status'] = status.toString();
      }

      final response = await _httpClient.get(
        '/api/v1/museums/miniapp/favorites/exhibitions',
        queryParameters: queryParams,
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

      return PageResponse<FavoriteExhibition>.fromJson(
        apiResponse.data ?? {},
        (json) => FavoriteExhibition.fromJson(json as Map<String, dynamic>),
      );
    });
  }

  /// 取消收藏博物馆
  /// API: DELETE /api/v1/museums/miniapp/favorites/museum/{id}
  Future<bool> unfavoriteMuseum(int museumId) async {
    return await _authService.withAuth(() async {
      final userId = await _authService.getCurrentUserId();
      if (userId == null) {
        throw Exception('用户未登录');
      }

      // DEBUG: print('🗑️ [FavoritesService] 取消收藏博物馆: $museumId, userId: $userId');

      final response = await _httpClient.delete(
        '/api/v1/museums/miniapp/favorites/museum/$museumId',
        options: Options(
          headers: {
            'userId': userId.toString(),
          },
        ),
      );

      // DEBUG: print('📡 [FavoritesService] 取消收藏博物馆响应: ${response.data}');

      final apiResponse = ApiResponse<bool>.fromJson(
        response.data,
        (json) => json as bool,
      );

      // DEBUG: print('✅ [FavoritesService] 取消收藏博物馆${apiResponse.isSuccess ? "成功" : "失败"}');

      return apiResponse.data ?? false;
    });
  }

  /// 取消收藏展览
  /// API: DELETE /api/v1/museums/miniapp/favorites/exhibition/{id}
  Future<bool> unfavoriteExhibition(int exhibitionId) async {
    return await _authService.withAuth(() async {
      final userId = await _authService.getCurrentUserId();
      if (userId == null) {
        throw Exception('用户未登录');
      }

      // DEBUG: print('🗑️ [FavoritesService] 取消收藏展览: $exhibitionId, userId: $userId');

      final response = await _httpClient.delete(
        '/api/v1/museums/miniapp/favorites/exhibition/$exhibitionId',
        options: Options(
          headers: {
            'userId': userId.toString(),
          },
        ),
      );

      // DEBUG: print('📡 [FavoritesService] 取消收藏展览响应: ${response.data}');

      final apiResponse = ApiResponse<bool>.fromJson(
        response.data,
        (json) => json as bool,
      );

      // DEBUG: print('✅ [FavoritesService] 取消收藏展览${apiResponse.isSuccess ? "成功" : "失败"}');

      return apiResponse.data ?? false;
    });
  }

  /// 添加收藏展览
  /// API: POST /api/v1/museums/miniapp/favorites/exhibition/{id}
  Future<bool> favoriteExhibition(int exhibitionId) async {
    return await _authService.withAuth(() async {
      final userId = await _authService.getCurrentUserId();
      if (userId == null) {
        // DEBUG: print('❌ [FavoritesService] 用户未登录');
        throw Exception('用户未登录');
      }

      // DEBUG: print('⭐ [FavoritesService] 收藏展览: $exhibitionId, userId: $userId');

      final response = await _httpClient.post(
        '/api/v1/museums/miniapp/favorites/exhibition/$exhibitionId',
        data: {},
        options: Options(
          headers: {
            'userId': userId.toString(),
          },
        ),
      );

      // DEBUG: print('📡 [FavoritesService] 收藏展览响应: ${response.data}');

      final apiResponse = ApiResponse<bool>.fromJson(
        response.data,
        (json) => json as bool,
      );

      // DEBUG: print('✅ [FavoritesService] 收藏展览${apiResponse.isSuccess ? "成功" : "失败"}');

      return apiResponse.data ?? false;
    });
  }

  /// 检查展览收藏状态
  /// API: GET /api/v1/museums/miniapp/favorites/check/exhibition/{id}
  Future<bool> checkExhibitionFavorite(int exhibitionId) async {
    return await _authService.withAuth(() async {
      final userId = await _authService.getCurrentUserId();
      if (userId == null) {
        // DEBUG: print('❌ [FavoritesService] 检查收藏状态失败：用户未登录');
        return false;
      }

      try {
        final response = await _httpClient.get(
          '/api/v1/museums/miniapp/favorites/check/exhibition/$exhibitionId',
          options: Options(
            headers: {
              'userId': userId.toString(),
            },
          ),
        );

        final apiResponse = ApiResponse<bool>.fromJson(
          response.data,
          (json) => json as bool,
        );

        final isFavorited = apiResponse.data ?? false;
        // DEBUG: print('✅ [FavoritesService] 展览收藏状态: $isFavorited');

        return isFavorited;
      } catch (e) {
        // DEBUG: print('❌ [FavoritesService] 检查收藏状态失败: $e');
        return false;
      }
    });
  }

  /// 添加收藏博物馆
  /// API: POST /api/v1/museums/miniapp/favorites/museum/{id}
  Future<bool> favoriteMuseum(int museumId) async {
    return await _authService.withAuth(() async {
      final userId = await _authService.getCurrentUserId();
      if (userId == null) {
        // DEBUG: print('❌ [FavoritesService] 用户未登录');
        throw Exception('用户未登录');
      }

      // DEBUG: print('⭐ [FavoritesService] 收藏博物馆: $museumId, userId: $userId');

      final response = await _httpClient.post(
        '/api/v1/museums/miniapp/favorites/museum/$museumId',
        data: {},
        options: Options(
          headers: {
            'userId': userId.toString(),
          },
        ),
      );

      // DEBUG: print('📡 [FavoritesService] 收藏博物馆响应: ${response.data}');

      final apiResponse = ApiResponse<bool>.fromJson(
        response.data,
        (json) => json as bool,
      );

      // DEBUG: print('✅ [FavoritesService] 收藏博物馆${apiResponse.isSuccess ? "成功" : "失败"}');

      return apiResponse.data ?? false;
    });
  }

  /// 检查博物馆收藏状态
  /// API: GET /api/v1/museums/miniapp/favorites/check/museum/{id}
  Future<bool> checkMuseumFavorite(int museumId) async {
    return await _authService.withAuth(() async {
      final userId = await _authService.getCurrentUserId();
      if (userId == null) {
        // DEBUG: print('❌ [FavoritesService] 检查收藏状态失败：用户未登录');
        return false;
      }

      try {
        final response = await _httpClient.get(
          '/api/v1/museums/miniapp/favorites/check/museum/$museumId',
          options: Options(
            headers: {
              'userId': userId.toString(),
            },
          ),
        );

        final apiResponse = ApiResponse<bool>.fromJson(
          response.data,
          (json) => json as bool,
        );

        final isFavorited = apiResponse.data ?? false;
        // DEBUG: print('✅ [FavoritesService] 博物馆收藏状态: $isFavorited');

        return isFavorited;
      } catch (e) {
        // DEBUG: print('❌ [FavoritesService] 检查收藏状态失败: $e');
        return false;
      }
    });
  }
}
