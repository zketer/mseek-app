import '../../models/exhibition.dart';
import '../../models/api_response.dart';
import 'http_client.dart';

/// 展览API服务
class ExhibitionService {
  static final ExhibitionService _instance = ExhibitionService._internal();
  factory ExhibitionService() => _instance;
  ExhibitionService._internal();

  final _httpClient = HttpClient();

  /// 获取最新展览列表（首页使用，不支持筛选）
  Future<PageResponse<Exhibition>> getLatestExhibitions({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _httpClient.get(
      '/api/v1/museums/miniapp/exhibitions/latest',
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
      },
    );

    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      response.data,
      (json) => json as Map<String, dynamic>,
    );

    if (!apiResponse.isSuccess) {
      throw Exception(apiResponse.message);
    }

    return PageResponse<Exhibition>.fromJson(
      apiResponse.data!,
      (json) => Exhibition.fromJson(json as Map<String, dynamic>),
    );
  }

  /// 获取所有展览列表（支持搜索和筛选，展览列表页使用）
  Future<PageResponse<Exhibition>> getAllExhibitions({
    int page = 1,
    int pageSize = 20,
    String? title,          // 搜索关键词
    int? status,            // 状态筛选：0-已结束，1-进行中，2-未开始
    int? museumId,          // 博物馆ID
    int? isPermanent,       // 是否常设展览
  }) async {
    final Map<String, dynamic> queryParams = {
      'page': page,
      'pageSize': pageSize,
    };
    
    // 添加可选参数
    if (title != null && title.isNotEmpty) {
      queryParams['title'] = title;
    }
    if (status != null) {
      queryParams['status'] = status;
    }
    if (museumId != null) {
      queryParams['museumId'] = museumId;
    }
    if (isPermanent != null) {
      queryParams['isPermanent'] = isPermanent;
    }

    // DEBUG: print('📡 [ExhibitionService] 调用API: /api/v1/museums/miniapp/exhibitions/all');
    // DEBUG: print('📋 [ExhibitionService] 参数: $queryParams');

    final response = await _httpClient.get(
      '/api/v1/museums/miniapp/exhibitions/all',
      queryParameters: queryParams,
    );

    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      response.data,
      (json) => json as Map<String, dynamic>,
    );

    if (!apiResponse.isSuccess) {
      throw Exception(apiResponse.message);
    }

    return PageResponse<Exhibition>.fromJson(
      apiResponse.data!,
      (json) => Exhibition.fromJson(json as Map<String, dynamic>),
    );
  }

  /// 获取展览列表
  Future<PageResponse<Exhibition>> getExhibitions({
    int page = 1,
    int pageSize = 20,
    String? keyword,
    int? museumId,
    String? status, // 'ongoing', 'upcoming', 'ended'
  }) async {
    final response = await _httpClient.get('/v1/exhibitions', queryParameters: {
      'current': page,
      'pageSize': pageSize,
      if (keyword != null) 'keyword': keyword,
      if (museumId != null) 'museumId': museumId,
      if (status != null) 'exhibitionStatus': status,
    });

    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      response.data,
      (json) => json as Map<String, dynamic>,
    );

    if (!apiResponse.isSuccess) {
      throw Exception(apiResponse.message);
    }

    return PageResponse<Exhibition>.fromJson(
      apiResponse.data!,
      (json) => Exhibition.fromJson(json as Map<String, dynamic>),
    );
  }

  /// 获取展览详情
  Future<Exhibition> getExhibitionDetail(int id) async {
    final response = await _httpClient.get('/api/v1/museums/miniapp/exhibitions/$id');

    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      response.data,
      (json) => json as Map<String, dynamic>,
    );

    if (!apiResponse.isSuccess) {
      throw Exception(apiResponse.message);
    }

    return Exhibition.fromJson(apiResponse.data!);
  }

  /// 根据博物馆ID获取展览
  Future<List<Exhibition>> getExhibitionsByMuseum(int museumId, {int limit = 10}) async {
    final response = await _httpClient.get('/v1/museums/$museumId/exhibitions', queryParameters: {
      'limit': limit,
      'status': 1,
    });

    final apiResponse = ApiResponse<List<dynamic>>.fromJson(
      response.data,
      (json) => json as List<dynamic>,
    );

    if (!apiResponse.isSuccess) {
      throw Exception(apiResponse.message);
    }

    return apiResponse.data!
        .map((json) => Exhibition.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
