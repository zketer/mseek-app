import '../../models/announcement.dart';
import '../../models/api_response.dart';
import 'http_client.dart';

/// 公告API服务
class AnnouncementService {
  static final AnnouncementService _instance = AnnouncementService._internal();
  factory AnnouncementService() => _instance;
  AnnouncementService._internal();

  final _httpClient = HttpClient();

  /// 获取活跃的公告列表
  Future<List<Announcement>> getActiveAnnouncements({int limit = 3}) async {
    final response = await _httpClient.get('/api/v1/museums/miniapp/announcements', queryParameters: {
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
        .map((json) => Announcement.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// 获取公告详情
  Future<Announcement> getAnnouncementDetail(int id) async {
    final response = await _httpClient.get('/v1/announcements/$id');

    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      response.data,
      (json) => json as Map<String, dynamic>,
    );

    if (!apiResponse.isSuccess) {
      throw Exception(apiResponse.message);
    }

    return Announcement.fromJson(apiResponse.data!);
  }
}
