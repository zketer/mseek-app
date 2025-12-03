import '../../models/banner.dart';
import '../../models/api_response.dart';
import 'http_client.dart';

/// 轮播图API服务
class BannerService {
  static final BannerService _instance = BannerService._internal();
  factory BannerService() => _instance;
  BannerService._internal();

  final _httpClient = HttpClient();

  /// 获取活跃的轮播图列表
  Future<List<Banner>> getActiveBanners({int limit = 5}) async {
    final response = await _httpClient.get('/api/v1/museums/miniapp/banners', queryParameters: {
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
        .map((json) => Banner.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// 记录轮播图点击
  Future<void> recordClick(int bannerId) async {
    final response = await _httpClient.post('/api/v1/museums/miniapp/banners/$bannerId/click');

    final apiResponse = ApiResponse<dynamic>.fromJson(
      response.data,
      (json) => json,
    );

    if (!apiResponse.isSuccess) {
      throw Exception(apiResponse.message);
    }
  }

  /// 获取轮播图详情
  Future<Banner> getBannerDetail(int id) async {
    final response = await _httpClient.get('/v1/banners/$id');

    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      response.data,
      (json) => json as Map<String, dynamic>,
    );

    if (!apiResponse.isSuccess) {
      throw Exception(apiResponse.message);
    }

    return Banner.fromJson(apiResponse.data!);
  }
}
