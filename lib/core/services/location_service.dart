import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// 定位服务结果
class LocationResult {
  final Position? position;
  final bool success;
  final String? errorMessage;
  final LocationErrorType? errorType;

  LocationResult({
    this.position,
    required this.success,
    this.errorMessage,
    this.errorType,
  });

  factory LocationResult.success(Position position) {
    return LocationResult(
      position: position,
      success: true,
    );
  }

  factory LocationResult.failure(String message, LocationErrorType type) {
    return LocationResult(
      success: false,
      errorMessage: message,
      errorType: type,
    );
  }
}

/// 定位错误类型
enum LocationErrorType {
  serviceDisabled,      // 定位服务未启用
  permissionDenied,     // 权限被拒绝
  permissionDeniedForever, // 权限被永久拒绝
  timeout,              // 超时
  other,                // 其他错误
}

/// 统一定位服务
/// 
/// 功能：
/// 1. 统一的定位逻辑
/// 2. 自动处理权限检查
/// 3. 支持缓存位置备用
/// 4. 统一的错误处理
/// 
/// 使用示例：
/// ```dart
/// final result = await LocationService.getCurrentLocation();
/// if (result.success && result.position != null) {
///   // 定位成功
///   print('位置: ${result.position!.latitude}, ${result.position!.longitude}');
/// } else {
///   // 定位失败
///   print('错误: ${result.errorMessage}');
/// }
/// ```
class LocationService {
  // 单例模式
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // 缓存的最后位置
  Position? _lastKnownPosition;
  DateTime? _lastKnownPositionTime;
  
  // 缓存有效期（5分钟）
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  // 城市信息缓存（优化：避免重复调用高德API）
  static String? _cachedCityCode;
  static String? _cachedCityName;
  static String? _cachedProvince;
  static String? _cachedDistrict;

  /// 获取当前位置（主方法）
  /// 
  /// [desiredAccuracy] 期望精度，默认为高精度
  /// [timeoutSeconds] 超时时间（秒），默认10秒
  /// [useCachedPosition] 是否使用缓存位置作为备用，默认true
  /// 
  /// 返回 [LocationResult] 包含位置信息或错误信息
  static Future<LocationResult> getCurrentLocation({
    LocationAccuracy desiredAccuracy = LocationAccuracy.high,
    int timeoutSeconds = 10,
    bool useCachedPosition = true,
  }) async {
    // DEBUG: print('📍 [LocationService] 开始获取位置...');

    try {
      // 1. 检查定位服务是否启用
      // DEBUG: print('🔍 [LocationService] 检查定位服务状态...');
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // DEBUG: print('❌ [LocationService] 定位服务未启用');
        return LocationResult.failure(
          '定位服务未启用',
          LocationErrorType.serviceDisabled,
        );
      }

      // 2. 检查定位权限
      // DEBUG: print('🔐 [LocationService] 检查定位权限...');
      LocationPermission permission = await Geolocator.checkPermission();
      
      // 如果权限被拒绝，尝试请求权限
      if (permission == LocationPermission.denied) {
        // DEBUG: print('⚠️ [LocationService] 权限被拒绝，请求权限...');
        permission = await Geolocator.requestPermission();
        
        if (permission == LocationPermission.denied) {
          // DEBUG: print('❌ [LocationService] 用户拒绝授予权限');
          return LocationResult.failure(
            '定位权限被拒绝',
            LocationErrorType.permissionDenied,
          );
        }
      }

      // 如果权限被永久拒绝
      if (permission == LocationPermission.deniedForever) {
        // DEBUG: print('❌ [LocationService] 权限被永久拒绝');
        return LocationResult.failure(
          '定位权限被永久拒绝',
          LocationErrorType.permissionDeniedForever,
        );
      }

      // 3. 获取位置
      Position? position;
      
      // 3.1 检查是否有新鲜缓存（5分钟内）
      if (useCachedPosition) {
        position = await _getCachedPosition();
        if (position != null) {
          debugPrint('💾 [LocationService] 使用新鲜缓存，直接返回（不调用GPS）');
          // ✅ 关键优化：缓存足够新鲜，直接返回，不再调用GPS！
          return LocationResult.success(position);
        } else {
          debugPrint('⚠️ [LocationService] 缓存过期或不存在，需要重新定位');
        }
      }

      // 3.2 缓存不可用，获取当前实时位置
      try {
        debugPrint('📡 [LocationService] 开始GPS定位... 精度: $desiredAccuracy, 超时: $timeoutSeconds秒');
        
        final currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: desiredAccuracy,
          timeLimit: Duration(seconds: timeoutSeconds),
        ).timeout(
          Duration(seconds: timeoutSeconds),
          onTimeout: () {
            // DEBUG: print('⏱️ [LocationService] 获取位置超时');
            if (position != null) {
              // DEBUG: print('   使用缓存位置作为备用');
              return position;
            }
            throw TimeoutException('获取位置超时');
          },
        );

        // 更新缓存
        _instance._updateCache(currentPosition);
        position = currentPosition;
        
        // DEBUG: print('✅ [LocationService] 定位成功！');
        // DEBUG: print('   位置: (${position.latitude}, ${position.longitude})');
        // DEBUG: print('   精度: ${position.accuracy}米');
        
      } catch (e) {
        // DEBUG: print('⚠️ [LocationService] 获取实时位置失败: $e');
        
        // 如果有缓存位置，使用缓存
        if (position != null) {
          // DEBUG: print('   使用缓存位置');
          return LocationResult.success(position);
        }
        
        // 否则返回错误
        if (e is TimeoutException) {
          return LocationResult.failure(
            '获取位置超时',
            LocationErrorType.timeout,
          );
        }
        
        return LocationResult.failure(
          '定位失败: $e',
          LocationErrorType.other,
        );
      }

      // 4. 返回成功结果（执行到这里position一定不为空）
      return LocationResult.success(position);

    } catch (e) {
      // DEBUG: print('❌ [LocationService] 定位过程异常: $e');
      return LocationResult.failure(
        '定位异常: $e',
        LocationErrorType.other,
      );
    }
  }

  /// 快速获取上次已知位置（不等待GPS，立即返回）
  /// 用于快速显示页面内容，提升用户体验
  /// 返回上次缓存的位置，如果没有则返回null
  static Future<LocationResult> getLastKnownPositionQuick() async {
    debugPrint('⚡ [LocationService] 快速获取上次已知位置...');
    
    try {
      // 1. 先检查内存缓存
      if (_instance._lastKnownPosition != null) {
        debugPrint('💾 [LocationService] 使用内存缓存位置');
        return LocationResult.success(_instance._lastKnownPosition!);
      }

      // 2. 获取系统缓存的最后位置
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        debugPrint('💾 [LocationService] 使用系统缓存位置');
        _instance._updateCache(lastKnown);
        return LocationResult.success(lastKnown);
      }
      
      debugPrint('⚠️ [LocationService] 没有可用的缓存位置');
      return LocationResult.failure(
        '没有可用的缓存位置',
        LocationErrorType.other,
      );
    } catch (e) {
      debugPrint('❌ [LocationService] 获取缓存位置失败: $e');
      return LocationResult.failure(
        '获取缓存位置失败: $e',
        LocationErrorType.other,
      );
    }
  }

  /// 获取缓存的位置（如果还有效）
  static Future<Position?> _getCachedPosition() async {
    try {
      // 先检查内存缓存
      if (_instance._lastKnownPosition != null && 
          _instance._lastKnownPositionTime != null) {
        final cacheAge = DateTime.now().difference(_instance._lastKnownPositionTime!);
        if (cacheAge < _cacheValidDuration) {
          // DEBUG: print('💾 [LocationService] 使用内存缓存位置（${cacheAge.inSeconds}秒前）');
          return _instance._lastKnownPosition;
        }
      }

      // 尝试获取系统缓存的最后位置
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        // DEBUG: print('💾 [LocationService] 使用系统缓存位置');
        _instance._updateCache(lastKnown);
        return lastKnown;
      }
    } catch (e) {
      // DEBUG: print('⚠️ [LocationService] 获取缓存位置失败: $e');
    }
    
    return null;
  }

  /// 更新缓存
  void _updateCache(Position position) {
    _lastKnownPosition = position;
    _lastKnownPositionTime = DateTime.now();
  }

  /// 清除缓存
  static void clearCache() {
    // DEBUG: print('🗑️ [LocationService] 清除位置缓存');
    _instance._lastKnownPosition = null;
    _instance._lastKnownPositionTime = null;
  }

  /// 检查定位服务是否可用
  static Future<bool> isLocationServiceAvailable() async {
    try {
      // 检查服务是否启用
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }

      // 检查权限
      final permission = await Geolocator.checkPermission();
      return permission == LocationPermission.whileInUse ||
             permission == LocationPermission.always;
    } catch (e) {
      return false;
    }
  }

  /// 打开位置设置页面
  static Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (e) {
      // DEBUG: print('❌ [LocationService] 打开设置失败: $e');
      return false;
    }
  }

  /// 打开应用设置页面
  static Future<bool> openAppSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (e) {
      // DEBUG: print('❌ [LocationService] 打开应用设置失败: $e');
      return false;
    }
  }

  /// 获取位置权限状态的描述文本
  static String getErrorMessage(LocationErrorType? errorType) {
    switch (errorType) {
      case LocationErrorType.serviceDisabled:
        return '定位服务未启用，请在系统设置中开启';
      case LocationErrorType.permissionDenied:
        return '定位权限被拒绝，请授予权限';
      case LocationErrorType.permissionDeniedForever:
        return '定位权限被永久拒绝，请在设置中手动开启';
      case LocationErrorType.timeout:
        return '获取位置超时，请检查网络和GPS信号';
      case LocationErrorType.other:
        return '定位失败，请稍后重试';
      default:
        return '未知错误';
    }
  }

  /// 获取两个位置之间的距离（米）
  static double getDistanceBetween(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// 格式化距离显示
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)}米';
    } else {
      final km = meters / 1000;
      return '${km.toStringAsFixed(1)}公里';
    }
  }

  /// 获取缓存的城市信息
  static Map<String, String?> getCachedCityInfo() {
    return {
      'cityCode': _cachedCityCode,
      'cityName': _cachedCityName,
      'province': _cachedProvince,
      'district': _cachedDistrict,
    };
  }

  /// 设置城市信息缓存（从API响应中保存）
  static void setCachedCityInfo({
    String? cityCode,
    String? cityName,
    String? province,
    String? district,
  }) {
    _cachedCityCode = cityCode;
    _cachedCityName = cityName;
    _cachedProvince = province;
    _cachedDistrict = district;
    debugPrint('📍 [LocationService] 缓存城市信息: $cityName($cityCode) - $province·$district');
  }

  /// 清除城市信息缓存
  static void clearCachedCityInfo() {
    _cachedCityCode = null;
    _cachedCityName = null;
    _cachedProvince = null;
    _cachedDistrict = null;
    debugPrint('📍 [LocationService] 清除城市信息缓存');
  }
}

