import 'dart:convert';
import '../../models/api_response.dart';
import '../auth/auth_service.dart';
import 'http_client.dart';

/// 打卡记录模型
class CheckinRecord {
  final int id;
  final int museumId;
  final String museumName;
  final String cityName;
  final String provinceName;
  final String checkInDate;
  final List<String>? photos;
  final String? notes;
  final double? rating;
  final String address;
  final String? mood;        // 心情
  final String? weather;     // 天气
  final List<String>? companions; // 同行人
  final List<String>? tags;  // 标签

  CheckinRecord({
    required this.id,
    required this.museumId,
    required this.museumName,
    required this.cityName,
    required this.provinceName,
    required this.checkInDate,
    this.photos,
    this.notes,
    this.rating,
    required this.address,
    this.mood,
    this.weather,
    this.companions,
    this.tags,
  });

  /// 安全解析字符串列表（可能是JSON字符串或数组）
  static List<String>? _parseStringList(dynamic value) {
    if (value == null) return null;
    
    try {
      // 如果已经是列表，直接转换
      if (value is List) {
        return List<String>.from(value);
      }
      
      // 如果是字符串，尝试解析JSON
      if (value is String) {
        if (value.isEmpty || value == 'null') return null;
        
        // 尝试解析JSON数组
        final decoded = jsonDecode(value);
        if (decoded is List) {
          return List<String>.from(decoded);
        }
      }
      
      return null;
    } catch (e) {
      // DEBUG: print('⚠️ 解析字符串列表失败: $e, value=$value');
      return null;
    }
  }

  factory CheckinRecord.fromJson(Map<String, dynamic> json) {
    // 从address解析省市信息（使用·分隔符）
    String provinceName = '未知省份';
    String cityName = '未知城市';
    String detailedAddress = '';
    
    final fullAddress = json['address']?.toString() ?? '';
    if (fullAddress.isNotEmpty) {
      // 如果地址包含·分隔符，按·分割
      if (fullAddress.contains('·')) {
        final parts = fullAddress.split('·');
        // DEBUG: print('📍 [地址解析] 完整地址: $fullAddress');
        // DEBUG: print('   分割后: ${parts.length}个部分: $parts');
        
        if (parts.length >= 3) {
          // 格式：省·市·详细地址
          provinceName = parts[0].trim();
          cityName = parts[1].trim();
          detailedAddress = parts.sublist(2).join('·').trim(); // 剩余部分作为详细地址
          // DEBUG: print('   省份: $provinceName, 城市: $cityName, 详细地址: $detailedAddress');
        } else if (parts.length == 2) {
          // 格式：省·市 或 省·详细地址
          provinceName = parts[0].trim();
          cityName = parts[1].trim();
        } else if (parts.length == 1) {
          detailedAddress = parts[0].trim();
        }
      } else {
        // 没有·分隔符，尝试传统解析方式
        final addressParts = fullAddress.split(RegExp(r'[省市区县]'));
        if (addressParts.length >= 2) {
          provinceName = addressParts[0] + 
              (fullAddress.contains('省') ? '省' : 
               fullAddress.contains('市') && !fullAddress.contains('省') ? '市' : '');
          if (addressParts.length >= 3) {
            cityName = '${addressParts[1]}市';
          } else if (addressParts[1].isNotEmpty) {
            cityName = addressParts[1];
          }
        }
        detailedAddress = fullAddress; // 保留完整地址
      }
    }
    
    // 如果API直接返回了省市信息，使用API的数据
    if (json['provinceName'] != null && json['provinceName'].toString().isNotEmpty) {
      provinceName = json['provinceName'].toString();
    }
    if (json['cityName'] != null && json['cityName'].toString().isNotEmpty) {
      cityName = json['cityName'].toString();
    }
    
    // 格式化日期为 YYYY-MM-DD 格式
    String checkInDate = '';
    final dateString = json['checkinTime'] ?? json['checkInDate'] ?? json['createAt'] ?? '';
    if (dateString.isNotEmpty) {
      try {
        final date = DateTime.parse(dateString);
        checkInDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      } catch (e) {
        // 如果解析失败，尝试直接使用，或者提取日期部分
        checkInDate = dateString.split(' ')[0];
      }
    }
    
    return CheckinRecord(
      id: json['id'] ?? 0,
      museumId: json['museumId'] ?? 0,
      museumName: json['museumName'] ?? '未知博物馆',
      cityName: cityName,
      provinceName: provinceName,
      checkInDate: checkInDate,
      photos: _parseStringList(json['photos']),
      notes: json['feeling'] ?? json['notes'],
      rating: json['rating']?.toDouble(),
      address: detailedAddress.isNotEmpty ? detailedAddress : fullAddress, // 使用解析后的详细地址
      mood: json['mood'],
      weather: json['weather'],
      companions: _parseStringList(json['companions']),
      tags: _parseStringList(json['tags']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'museumId': museumId,
      'museumName': museumName,
      'cityName': cityName,
      'provinceName': provinceName,
      'checkInDate': checkInDate,
      'photos': photos,
      'notes': notes,
      'feeling': notes, // 兼容小程序字段
      'rating': rating,
      'address': address,
      'mood': mood,
      'weather': weather,
      'companions': companions,
      'tags': tags,
    };
  }
}

/// 省份统计数据模型
class ProvinceStats {
  final String provinceCode;
  final String provinceName;
  final int totalMuseums;
  final int visitedMuseums;
  final bool isUnlocked;

  ProvinceStats({
    required this.provinceCode,
    required this.provinceName,
    required this.totalMuseums,
    required this.visitedMuseums,
    required this.isUnlocked,
  });

  factory ProvinceStats.fromJson(Map<String, dynamic> json) {
    return ProvinceStats(
      provinceCode: json['provinceCode'] ?? '',
      provinceName: json['provinceName'] ?? '',
      totalMuseums: json['totalMuseums'] ?? 0,
      visitedMuseums: json['visitedMuseums'] ?? 0,
      // 优先使用后端返回的isUnlocked字段
      isUnlocked: json['isUnlocked'] ?? ((json['visitedMuseums'] ?? 0) > 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'provinceCode': provinceCode,
      'provinceName': provinceName,
      'totalMuseums': totalMuseums,
      'visitedMuseums': visitedMuseums,
      'isUnlocked': isUnlocked,
    };
  }

  /// 计算完成度百分比
  double get completionRate {
    if (totalMuseums == 0) return 0.0;
    return (visitedMuseums / totalMuseums) * 100;
  }
}

/// 打卡统计数据模型
class CheckinHistoryStats {
  final int totalCheckins;
  final int thisMonthCheckins;
  final int unlockedProvinces;
  final int totalProvinces;
  final int visitedNationalMuseums;
  final int totalNationalMuseums;
  final double coverageRate;

  CheckinHistoryStats({
    required this.totalCheckins,
    required this.thisMonthCheckins,
    required this.unlockedProvinces,
    required this.totalProvinces,
    required this.visitedNationalMuseums,
    required this.totalNationalMuseums,
    required this.coverageRate,
  });

  factory CheckinHistoryStats.fromJson(Map<String, dynamic> json) {
    return CheckinHistoryStats(
      totalCheckins: json['totalCheckins'] ?? 0,
      thisMonthCheckins: json['thisMonthCheckins'] ?? 0,
      unlockedProvinces: json['unlockedProvinces'] ?? 0,
      totalProvinces: json['totalProvinces'] ?? 34,
      visitedNationalMuseums: json['visitedNationalMuseums'] ?? 0,
      totalNationalMuseums: json['totalNationalMuseums'] ?? 130,
      coverageRate: (json['coverageRate'] ?? 0.0).toDouble(),
    );
  }

  static CheckinHistoryStats empty() {
    return CheckinHistoryStats(
      totalCheckins: 0,
      thisMonthCheckins: 0,
      unlockedProvinces: 0,
      totalProvinces: 34,
      visitedNationalMuseums: 0,
      totalNationalMuseums: 130,
      coverageRate: 0.0,
    );
  }
}

/// 打卡服务类
class CheckinService {
  static final CheckinService _instance = CheckinService._internal();
  factory CheckinService() => _instance;
  CheckinService._internal();

  final _httpClient = HttpClient();
  final _authService = AuthService();
  
  // 暴露httpClient供外部使用
  HttpClient get httpClient => _httpClient;

  /// 获取用户打卡记录
  /// API: GET /api/v1/museums/miniapp/checkin/records
  Future<PageResponse<CheckinRecord>> getUserCheckinRecords({
    int page = 1,
    int pageSize = 20,
    String? keyword,
    String? filterType, // all | thisMonth | thisYear
    bool isDraft = false, // 是否查询草稿，默认false只查正式记录
  }) async {
    return await _authService.withAuth(() async {
      final userId = await _authService.getCurrentUserId();
      if (userId == null) {
        throw Exception('用户未登录');
      }

      final queryParams = {
        'page': page.toString(),
        'pageSize': pageSize.toString(),
        'isDraft': isDraft.toString(),
      };

      if (keyword != null && keyword.isNotEmpty) {
        queryParams['keyword'] = keyword;
      }
      
      if (filterType != null && filterType != 'all') {
        queryParams['filterType'] = filterType;
      }

      // userId已由全局拦截器自动添加到请求头
      final response = await _httpClient.get(
        '/api/v1/museums/miniapp/checkin/records',
        queryParameters: queryParams,
      );

      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );

      if (!apiResponse.isSuccess) {
        throw Exception(apiResponse.message);
      }

      return PageResponse<CheckinRecord>.fromJson(
        apiResponse.data ?? {},
        (json) => CheckinRecord.fromJson(json as Map<String, dynamic>),
      );
    });
  }

  /// 获取打卡记录详情
  /// API: GET /api/v1/museums/miniapp/checkin/{id}
  Future<CheckinRecord> getCheckinDetail(int id) async {
    return await _authService.withAuth(() async {
      final userId = await _authService.getCurrentUserId();
      if (userId == null) {
        throw Exception('用户未登录');
      }

      // userId已由全局拦截器自动添加到请求头
      final response = await _httpClient.get(
        '/api/v1/museums/miniapp/checkin/$id',
      );

      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );

      if (!apiResponse.isSuccess) {
        throw Exception(apiResponse.message);
      }

      return CheckinRecord.fromJson(apiResponse.data ?? {});
    });
  }

  /// 删除打卡记录
  /// API: DELETE /api/v1/museums/miniapp/checkin/{id}
  Future<bool> deleteCheckinRecord(int id) async {
    return await _authService.withAuth(() async {
      final userId = await _authService.getCurrentUserId();
      if (userId == null) {
        throw Exception('用户未登录');
      }

      // DEBUG: print('🗑️ [删除打卡记录] ID=$id');

      try {
        // userId已由全局拦截器自动添加到请求头
        final response = await _httpClient.delete(
          '/api/v1/museums/miniapp/checkin/$id',
        );
        
        // DEBUG: print('✅ [删除打卡记录] 响应: ${response.data}');

        // 检查success字段和data字段
        final code = response.data['code'] as int?;
        final success = response.data['success'] as bool?;
        final data = response.data['data'];
        
        // 后端返回success=true且data=true才算删除成功
        // 或者如果data不是bool类型，则只检查success
        final isDeleted = (code == 200 && success == true && (data == true || data is! bool));
        
        // DEBUG: print(isDeleted ? '✅ [删除打卡记录] 删除成功' : '❌ [删除打卡记录] 删除失败');
        
        return isDeleted;
      } catch (e) {
        // DEBUG: print('❌ [删除打卡记录] 失败: $e');
        rethrow;
      }
    });
  }

  /// 获取省份统计数据
  /// API: GET /api/v1/museums/miniapp/checkin/stats/provinces
  Future<List<ProvinceStats>> getProvinceStats() async {
    return await _authService.withAuth(() async {
      final userId = await _authService.getCurrentUserId();
      if (userId == null) {
        // DEBUG: print('❌ [ProvinceStats API] 用户未登录');
        throw Exception('用户未登录');
      }

      // DEBUG: print('📤 [ProvinceStats API] 请求: /api/v1/museums/miniapp/checkin/stats/provinces, userId=$userId');

      // userId已由全局拦截器自动添加到请求头
      final response = await _httpClient.get(
        '/api/v1/museums/miniapp/checkin/stats/provinces',
      );

      // DEBUG: print('📥 [ProvinceStats API] 响应状态码: ${response.statusCode}');
      // DEBUG: print('📥 [ProvinceStats API] 响应数据: ${response.data}');

      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );

      // DEBUG: print('📊 [ProvinceStats API] API响应解析: success=${apiResponse.isSuccess}, message=${apiResponse.message}');

      if (!apiResponse.isSuccess) {
        // DEBUG: print('❌ [ProvinceStats API] API返回失败: ${apiResponse.message}');
        throw Exception(apiResponse.message);
      }

      // DEBUG: print('📋 [ProvinceStats API] apiResponse.data类型: ${apiResponse.data.runtimeType}');
      // DEBUG: print('📋 [ProvinceStats API] apiResponse.data内容: ${apiResponse.data}');

      final provinces = apiResponse.data?['provinces'] as List<dynamic>? ?? [];
      // DEBUG: print('✅ [ProvinceStats API] 解析到${provinces.length}个省份');
      
      if (provinces.isNotEmpty) {
        // DEBUG: print('📋 [ProvinceStats API] 第一个省份: ${provinces[0]}');
      }

      final result = provinces
          .map((json) => ProvinceStats.fromJson(json as Map<String, dynamic>))
          .toList();
      
      // DEBUG: print('✅ [ProvinceStats API] 返回${result.length}个省份对象');
      return result;
    });
  }

  /// 获取打卡历史统计信息
  /// API: GET /api/v1/museums/miniapp/checkin/history-stats
  Future<CheckinHistoryStats> getCheckinHistoryStats() async {
    return await _authService.withAuth(() async {
      final userId = await _authService.getCurrentUserId();
      if (userId == null) {
        throw Exception('用户未登录');
      }

      // userId已由全局拦截器自动添加到请求头
      final response = await _httpClient.get(
        '/api/v1/museums/miniapp/checkin/history-stats',
      );

      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );

      if (!apiResponse.isSuccess) {
        throw Exception(apiResponse.message);
      }

      return CheckinHistoryStats.fromJson(apiResponse.data ?? {});
    });
  }

  /// 获取省份博物馆详情
  Future<ProvinceMuseumDetail> getProvinceMuseumDetail(String provinceCode) async {
    return _authService.withAuth(() async {
      final userId = await _authService.getCurrentUserId();
      if (userId == null) {
        throw Exception('用户未登录');
      }

      // DEBUG: print('🔍 正在请求省份详情: /api/v1/museums/miniapp/checkin/provinces/$provinceCode/museums');
      // DEBUG: print('📋 请求头: userId=$userId');

      // userId已由全局拦截器自动添加到请求头
      final response = await _httpClient.dio.get(
        '/api/v1/museums/miniapp/checkin/provinces/$provinceCode/museums',
      );

      // DEBUG: print('📥 省份详情API响应: ${response.statusCode}');
      // DEBUG: print('📦 响应数据: ${response.data}');

      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );

      if (!apiResponse.isSuccess) {
        throw Exception(apiResponse.message);
      }

      return ProvinceMuseumDetail.fromJson(apiResponse.data ?? {});
    });
  }

  /// 删除暂存草稿
  Future<bool> deleteDraft(int draftId) async {
    return await _authService.withAuth(() async {
      try {
        // DEBUG: print('🗑️ [删除草稿API] 请求路径: /api/v1/museums/miniapp/checkin/draft/$draftId');
        
        final response = await _httpClient.dio.delete(
          '/api/v1/museums/miniapp/checkin/draft/$draftId',
        );
        
        // DEBUG: print('✅ [删除草稿API] 响应: ${response.data}');
        
        // 检查success字段和data字段
        final code = response.data['code'] as int?;
        final success = response.data['success'] as bool?;
        final data = response.data['data'];
        
        // DEBUG: print('📊 [删除草稿API] code=$code, success=$success, data=$data');
        
        // 后端返回success=true且data=true才算删除成功
        // 或者如果data不是bool类型，则只检查success
        final isDeleted = (code == 200 && success == true && (data == true || data is! bool));
        
        // DEBUG: print('📊 [删除草稿API] 最终删除结果: $isDeleted');
        
        return isDeleted;
      } catch (e) {
        // DEBUG: print('❌ [删除草稿API] 删除草稿失败: $e');
        rethrow;
      }
    });
  }

  /// 提交打卡（匹配小程序逻辑）
  Future<Map<String, dynamic>> submitCheckin({
    required int museumId,
    required String museumName,
    required List<String> photos,
    required String feeling,
    required double rating,
    String? mood,
    String? weather,
    List<String>? companions,
    List<String>? tags,
    double? longitude,
    double? latitude,
    String? address, // 新增地址参数
  }) async {
    return await _authService.withAuth(() async {
      final userId = await _authService.getCurrentUserId();
      
      final requestData = {
        'museumId': museumId,
        'museumName': museumName,
        'photos': photos,
        'feeling': feeling,
        'notes': feeling, // 兼容性
        'rating': rating,
        'mood': mood,
        'weather': weather,
        'companions': companions,
        'tags': tags,
        'isDraft': false, // 标识为正式打卡
        'userId': userId,
        'location': {
          'longitude': longitude,
          'latitude': latitude,
          'address': address, // 添加地址字段
        },
      };
      
      print('');
      print('📤 ==================== 发送打卡请求到后端 ====================');
      print('🌐 API: POST /api/v1/museums/miniapp/checkin/submit');
      print('📦 请求数据:');
      print('   museumId: $museumId');
      print('   museumName: $museumName');
      print('   photos: $photos');
      print('   feeling: $feeling');
      print('   rating: $rating');
      print('   mood: $mood');
      print('   weather: $weather');
      print('   companions: $companions');
      print('   tags: $tags');
      print('   isDraft: false');
      print('   userId: $userId');
      print('   location: {longitude: $longitude, latitude: $latitude, address: $address}');
      print('📋 完整请求体: $requestData');
      
      // userId已由全局拦截器自动添加到请求头
      final response = await _httpClient.dio.post(
        '/api/v1/museums/miniapp/checkin/submit',
        data: requestData,
      );
      
      print('📥 后端响应: ${response.data}');
      print('==================== 请求完成 ====================');
      print('');
      
      if (response.data['code'] == 200) {
        return {
          'success': true,
          'id': response.data['data']?['id'] ?? 0,
          'checkinTime': response.data['data']?['checkinTime'] ?? '',
        };
      } else {
        throw Exception(response.data['message'] ?? '打卡失败');
      }
    });
  }

  /// 保存暂存草稿（匹配小程序逻辑）
  Future<Map<String, dynamic>> saveDraft({
    required int museumId,
    required String museumName,
    required List<String> photos,
    required String feeling,
    required double rating,
    String? mood,
    String? weather,
    List<String>? companions,
    List<String>? tags,
    double? longitude,
    double? latitude,
    String? address, // 新增地址参数
    int? draftId, // 如果是编辑已有草稿，传递草稿ID
  }) async {
    return await _authService.withAuth(() async {
      final userId = await _authService.getCurrentUserId();
      
      final requestData = {
        'museumId': museumId,
        'museumName': museumName,
        'photos': photos,
        'feeling': feeling,
        'notes': feeling, // 兼容性
        'rating': rating,
        'mood': mood,
        'weather': weather,
        'companions': companions,
        'tags': tags,
        'isDraft': true, // 标识为草稿
        'userId': userId,
        'location': {
          'longitude': longitude,
          'latitude': latitude,
          'address': address, // 添加地址字段
        },
      };
      
      // 如果有draftId，则是更新现有草稿（字段名必须是draftId）
      if (draftId != null) {
        requestData['draftId'] = draftId.toString();
      }
      
      print('');
      print('📤 ==================== 发送草稿请求到后端 ====================');
      print('🌐 API: POST /api/v1/museums/miniapp/checkin/submit');
      print('📦 请求数据:');
      print('   museumId: $museumId');
      print('   museumName: $museumName');
      print('   photos: $photos');
      print('   feeling: $feeling');
      print('   rating: $rating');
      print('   mood: $mood');
      print('   weather: $weather');
      print('   companions: $companions');
      print('   tags: $tags');
      print('   isDraft: true');
      print('   draftId: $draftId');
      print('   userId: $userId');
      print('   location: {longitude: $longitude, latitude: $latitude, address: $address}');
      print('📋 完整请求体: $requestData');
      
      // userId已由全局拦截器自动添加到请求头
      final response = await _httpClient.dio.post(
        '/api/v1/museums/miniapp/checkin/submit',
        data: requestData,
      );
      
      print('📥 后端响应: ${response.data}');
      print('==================== 请求完成 ====================');
      print('');
      
      if (response.data['code'] == 200) {
        return {
          'success': true,
          'id': response.data['data']?['id'] ?? draftId ?? 0,
        };
      } else {
        throw Exception(response.data['message'] ?? '暂存失败');
      }
    });
  }
}

/// 博物馆详情模型（用于省份/城市详情页）
class MuseumDetail {
  final int id;
  final String name;
  final String address;
  final String level;
  final String category;
  final bool isVisited;
  final String? visitDate;
  final String? openTime;
  final String ticketPrice;
  final double? rating;
  final String? description;
  final String cityName;

  MuseumDetail({
    required this.id,
    required this.name,
    required this.address,
    required this.level,
    required this.category,
    required this.isVisited,
    this.visitDate,
    this.openTime,
    required this.ticketPrice,
    this.rating,
    this.description,
    required this.cityName,
  });

  factory MuseumDetail.fromJson(Map<String, dynamic> json) {
    // 格式化门票价格
    String formatTicketPrice() {
      final freeAdmission = json['freeAdmission'];
      final ticketPrice = json['ticketPrice'];
      
      if (freeAdmission == 1 || ticketPrice == 0) {
        return '免费';
      } else if (ticketPrice != null && ticketPrice > 0) {
        return '$ticketPrice元';
      } else {
        return '价格待查';
      }
    }

    // 格式化访问日期
    String? formatVisitDate() {
      final visitDateStr = json['firstVisitDate']?.toString();
      if (visitDateStr == null || visitDateStr.isEmpty) return null;
      
      try {
        final date = DateTime.parse(visitDateStr);
        return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      } catch (e) {
        return visitDateStr.split(' ')[0];
      }
    }

    return MuseumDetail(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? '未知博物馆',
      address: json['address']?.toString() ?? '地址未知',
      level: json['level']?.toString() ?? '未定级',
      category: json['category']?.toString() ?? '综合类',
      isVisited: json['isVisited'] == true,
      visitDate: formatVisitDate(),
      openTime: json['openTime']?.toString() ?? '09:00-17:00',
      ticketPrice: formatTicketPrice(),
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      description: json['description']?.toString() ?? '暂无描述',
      cityName: json['cityName']?.toString() ?? '未知城市',
    );
  }
}

/// 城市详情模型
class CityDetail {
  final String cityName;
  final int totalMuseums;
  final int visitedMuseums;
  final int completionRate;
  final List<MuseumDetail> museums;

  CityDetail({
    required this.cityName,
    required this.totalMuseums,
    required this.visitedMuseums,
    required this.completionRate,
    required this.museums,
  });

  factory CityDetail.fromJson(Map<String, dynamic> json, List<MuseumDetail> allMuseums) {
    final cityName = json['cityName']?.toString() ?? '未知城市';
    
    // 从所有博物馆中筛选出该城市的博物馆
    final cityMuseums = allMuseums.where((m) => m.cityName == cityName).toList();
    
    return CityDetail(
      cityName: cityName,
      totalMuseums: json['totalMuseums'] ?? 0,
      visitedMuseums: json['visitedMuseums'] ?? 0,
      completionRate: json['completionRate'] ?? 0,
      museums: cityMuseums,
    );
  }
}

/// 省份博物馆详情模型
class ProvinceMuseumDetail {
  final String provinceCode;
  final String provinceName;
  final int totalMuseums;
  final int visitedMuseums;
  final int totalCities;
  final int unlockedCities;
  final int completionRate;
  final List<MuseumDetail> museums;
  final List<CityDetail> cities;

  ProvinceMuseumDetail({
    required this.provinceCode,
    required this.provinceName,
    required this.totalMuseums,
    required this.visitedMuseums,
    required this.totalCities,
    required this.unlockedCities,
    required this.completionRate,
    required this.museums,
    required this.cities,
  });

  factory ProvinceMuseumDetail.fromJson(Map<String, dynamic> json) {
    // 解析博物馆列表
    final museumsJson = json['museums'] as List<dynamic>? ?? [];
    final museums = museumsJson
        .map((m) => MuseumDetail.fromJson(m as Map<String, dynamic>))
        .toList();

    // 解析城市列表
    final citiesJson = json['cities'] as List<dynamic>? ?? [];
    final cities = citiesJson
        .map((c) => CityDetail.fromJson(c as Map<String, dynamic>, museums))
        .toList()
      ..sort((a, b) {
        // 已访问的城市排在前面
        final aVisited = a.visitedMuseums > 0;
        final bVisited = b.visitedMuseums > 0;
        
        if (aVisited && !bVisited) return -1;
        if (!aVisited && bVisited) return 1;
        
        // 同一状态内按城市名称排序
        return a.cityName.compareTo(b.cityName);
      });

    // 计算完成度
    final totalMuseums = json['totalMuseums'] ?? 0;
    final visitedMuseums = json['visitedMuseums'] ?? 0;
    final completionRate = totalMuseums > 0 
        ? ((visitedMuseums / totalMuseums) * 100).round()
        : 0;

    return ProvinceMuseumDetail(
      provinceCode: json['provinceCode']?.toString() ?? '',
      provinceName: json['provinceName']?.toString() ?? '未知省份',
      totalMuseums: totalMuseums,
      visitedMuseums: visitedMuseums,
      totalCities: cities.length,
      unlockedCities: cities.where((c) => c.visitedMuseums > 0).length,
      completionRate: completionRate,
      museums: museums,
      cities: cities,
    );
  }
}
