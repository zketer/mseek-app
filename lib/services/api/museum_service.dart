import '../../models/museum.dart';
import '../../models/api_response.dart';
import 'http_client.dart';

/// 博物馆API服务
class MuseumService {
  static final MuseumService _instance = MuseumService._internal();
  factory MuseumService() => _instance;
  MuseumService._internal();

  final _httpClient = HttpClient();

  /// 获取热门博物馆列表（支持搜索）
  Future<PageResponse<Museum>> getHotMuseums({
    int page = 1,
    int pageSize = 20,
    String? cityCode,
    String? name, // 搜索关键词
  }) async {
    final response = await _httpClient.get('/api/v1/museums/miniapp/museums/hot', queryParameters: {
      'page': page,
      'pageSize': pageSize,
      if (cityCode != null) 'cityCode': cityCode,
      if (name != null && name.isNotEmpty) 'name': name,
    });

    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      response.data,
      (json) => json as Map<String, dynamic>,
    );

    if (!apiResponse.isSuccess) {
      throw Exception(apiResponse.message);
    }

    return PageResponse<Museum>.fromJson(
      apiResponse.data!,
      (json) => Museum.fromJson(json as Map<String, dynamic>),
    );
  }

  /// 获取博物馆分类列表
  Future<List<Map<String, dynamic>>> getCategories() async {
    final response = await _httpClient.get('/api/v1/museums/miniapp/museums/categories');
    
    final apiResponse = ApiResponse<List<dynamic>>.fromJson(
      response.data,
      (json) => json as List<dynamic>,
    );

    if (!apiResponse.isSuccess) {
      throw Exception(apiResponse.message);
    }

    return (apiResponse.data ?? []).map((item) => item as Map<String, dynamic>).toList();
  }

  /// 获取博物馆分页列表（匹配小程序API）
  Future<Map<String, dynamic>> getMuseumPage({
    int page = 1,
    int pageSize = 10,
    String? keyword,
    int? categoryId,
    String? cityCode,
    String sortBy = 'hot',
  }) async {
    final queryParams = {
      'page': page,
      'pageSize': pageSize,
      'sortBy': sortBy,
    };
    
    // 只有非空值才添加到请求参数中
    if (keyword != null && keyword.isNotEmpty) {
      queryParams['keyword'] = keyword;
    }
    if (categoryId != null && categoryId != 0) {
      queryParams['categoryId'] = categoryId;
    }
    if (cityCode != null && cityCode.isNotEmpty) {
      queryParams['cityCode'] = cityCode;
    }

    final response = await _httpClient.get(
      '/api/v1/museums/miniapp/museums',
      queryParameters: queryParams,
    );

    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      response.data,
      (json) => json as Map<String, dynamic>,
    );

    if (!apiResponse.isSuccess) {
      throw Exception(apiResponse.message);
    }

    return apiResponse.data ?? {'records': [], 'total': 0, 'current': 1, 'size': 10};
  }

  /// 获取博物馆列表
  Future<PageResponse<Museum>> getMuseums({
    int page = 1,
    int pageSize = 20,
    String? keyword,
    String? cityCode,
    String? category,
    bool? freeAdmission,
    int? level,
    double? latitude,
    double? longitude,
    String? sortBy = 'distance', // distance, rating, visitCount
  }) async {
    final response = await _httpClient.get('/v1/museums', queryParameters: {
      'current': page,
      'pageSize': pageSize,
      if (keyword != null) 'keyword': keyword,
      if (cityCode != null) 'cityCode': cityCode,
      if (category != null) 'category': category,
      if (freeAdmission != null) 'freeAdmission': freeAdmission ? 1 : 0,
      if (level != null) 'level': level,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (sortBy != null) 'sortBy': sortBy,
    });

    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      response.data,
      (json) => json as Map<String, dynamic>,
    );

    if (!apiResponse.isSuccess) {
      throw Exception(apiResponse.message);
    }

    return PageResponse<Museum>.fromJson(
      apiResponse.data!,
      (json) => Museum.fromJson(json as Map<String, dynamic>),
    );
  }

  /// 获取博物馆详情
  Future<Museum> getMuseumDetail(int id) async {
    final response = await _httpClient.get('/api/v1/museums/miniapp/museums/$id');

    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      response.data,
      (json) => json as Map<String, dynamic>,
    );

    if (!apiResponse.isSuccess) {
      throw Exception(apiResponse.message);
    }

    return Museum.fromJson(apiResponse.data!);
  }

  /// 获取附近博物馆
  Future<List<Museum>> getNearbyMuseums({
    required double latitude,
    required double longitude,
    int radius = 20,
    int limit = 20,
    int page = 1,
    int pageSize = 20,
    String? name,
    String? cityCode,
    String? cityName,
  }) async {
    final queryParams = <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
      'page': page,
      'pageSize': pageSize,
      'radius': radius,
    };
    
    // 只添加非空参数（radius 必传，所以不需要条件判断）
    if (name != null && name.isNotEmpty) {
      queryParams['name'] = name;
    }
    if (cityCode != null && cityCode.isNotEmpty) {
      queryParams['cityCode'] = cityCode;
    }
    if (cityName != null && cityName.isNotEmpty) {
      queryParams['cityName'] = cityName;
    }
    
    // DEBUG: print('🌐 调用附近博物馆API: /api/v1/museums/miniapp/museums/nearby');
    // DEBUG: print('📍 参数: $queryParams');
    
    final response = await _httpClient.get(
      '/api/v1/museums/miniapp/museums/nearby',
      queryParameters: queryParams,
    );

    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      response.data,
      (json) => json as Map<String, dynamic>,
    );

    if (!apiResponse.isSuccess) {
      throw Exception(apiResponse.message);
    }

    // 解析响应数据：{ location: {...}, museums: { records: [...], total, current, size } }
    final responseData = apiResponse.data!;
    // DEBUG: print('✅ API响应: location=${responseData['location']}, museums keys=${(responseData['museums'] as Map?)?.keys}');
    
    final museumsData = responseData['museums'] as Map<String, dynamic>?;
    
    if (museumsData == null) {
      // DEBUG: print('⚠️ museums 数据为空');
      return [];
    }
    
    final records = museumsData['records'] as List<dynamic>? ?? [];
    // DEBUG: print('✅ 解析到 ${records.length} 家博物馆');
    
    // 打印第一个博物馆的distance字段
    if (records.isNotEmpty) {
      // DEBUG: print('📊 示例博物馆: name=${firstMuseum['name']}, distance=${firstMuseum['distance']}');
    }
    
    return records
        .map((json) => Museum.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// 收藏/取消收藏博物馆
  Future<bool> toggleFavorite(int museumId) async {
    final response = await _httpClient.post('/v1/museums/$museumId/favorite');

    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      response.data,
      (json) => json as Map<String, dynamic>,
    );

    if (!apiResponse.isSuccess) {
      throw Exception(apiResponse.message);
    }

    return apiResponse.data!['isFavorite'] as bool;
  }

  /// 获取用户收藏的博物馆
  Future<PageResponse<Museum>> getFavoriteMuseums({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _httpClient.get('/api/v1/users/favorites/museums', queryParameters: {
      'current': page,
      'pageSize': pageSize,
    });

    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      response.data,
      (json) => json as Map<String, dynamic>,
    );

    if (!apiResponse.isSuccess) {
      throw Exception(apiResponse.message);
    }

    return PageResponse<Museum>.fromJson(
      apiResponse.data!,
      (json) => Museum.fromJson(json as Map<String, dynamic>),
    );
  }

  /// 搜索博物馆
  Future<List<Museum>> searchMuseums(String keyword, {int limit = 10}) async {
    final response = await _httpClient.get('/api/v1/museums/search', queryParameters: {
      'keyword': keyword,
      'limit': limit,
    });

    final apiResponse = ApiResponse<List<dynamic>>.fromJson(
      response.data,
      (json) => json as List<dynamic>,
    );

    if (!apiResponse.isSuccess) {
      throw Exception(apiResponse.message);
    }

    return apiResponse.data!
        .map((json) => Museum.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
