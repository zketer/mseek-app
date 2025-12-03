import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 缓存数据模型
class CacheItem<T> {
  final T data;
  final int expireTime; // 过期时间戳（秒）

  CacheItem({
    required this.data,
    required this.expireTime,
  });

  Map<String, dynamic> toJson(Object? Function(T) toJsonT) {
    return {
      'data': toJsonT(data),
      'expireTime': expireTime,
    };
  }

  factory CacheItem.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) {
    return CacheItem(
      data: fromJsonT(json['data']),
      expireTime: json['expireTime'] as int,
    );
  }
}

/// 缓存管理器
/// 支持过期时间的本地缓存
class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  SharedPreferences? _prefs;

  /// 初始化
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// 设置缓存
  /// [key] 缓存键
  /// [data] 缓存数据
  /// [duration] 过期时间（秒），0表示不过期
  Future<void> set<T>(
    String key,
    T data,
    int duration, {
    Object? Function(T)? toJson,
  }) async {
    await init();
    final expireTime = duration > 0
        ? DateTime.now().millisecondsSinceEpoch ~/ 1000 + duration
        : 0;

    final cacheItem = CacheItem(data: data, expireTime: expireTime);

    String jsonStr;
    if (toJson != null) {
      jsonStr = jsonEncode(cacheItem.toJson(toJson));
    } else {
      // 默认使用toString
      jsonStr = jsonEncode({
        'data': data.toString(),
        'expireTime': expireTime,
      });
    }

    await _prefs!.setString(key, jsonStr);
  }

  /// 获取缓存
  /// [key] 缓存键
  /// 返回缓存数据，如果不存在或已过期返回null
  Future<T?> get<T>(
    String key, {
    T Function(Object?)? fromJson,
  }) async {
    await init();
    final jsonStr = _prefs!.getString(key);

    if (jsonStr == null || jsonStr.isEmpty) {
      return null;
    }

    try {
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      final expireTime = json['expireTime'] as int;

      // 检查是否过期
      if (expireTime > 0) {
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        if (expireTime < now) {
          await remove(key);
          return null;
        }
      }

      if (fromJson != null) {
        final cacheItem = CacheItem.fromJson(json, fromJson);
        return cacheItem.data;
      } else {
        return json['data'] as T;
      }
    } catch (e) {
      // DEBUG: print('[Cache] 获取缓存失败: $key, error: $e');
      return null;
    }
  }

  /// 删除缓存
  Future<void> remove(String key) async {
    await init();
    await _prefs!.remove(key);
  }

  /// 清空所有缓存
  Future<void> clear() async {
    await init();
    await _prefs!.clear();
  }

  /// 检查缓存是否存在且有效
  Future<bool> has(String key) async {
    final data = await get(key);
    return data != null;
  }

  /// 获取或设置缓存
  /// 如果缓存不存在或已过期，则执行fetcher函数获取数据并缓存
  Future<T> getOrSet<T>({
    required String key,
    required Future<T> Function() fetcher,
    required int duration,
    Object? Function(T)? toJson,
    T Function(Object?)? fromJson,
  }) async {
    // 先尝试从缓存获取
    final cached = await get<T>(key, fromJson: fromJson);
    if (cached != null) {
      // DEBUG: print('[Cache] 命中缓存: $key');
      return cached;
    }

    // 缓存不存在，执行获取函数
    // DEBUG: print('[Cache] 缓存未命中，重新获取: $key');
    final data = await fetcher();
    await set(key, data, duration, toJson: toJson);
    return data;
  }

  /// 清除首页相关缓存
  Future<void> clearHomeCache() async {
    await remove('cache_banners');
    await remove('cache_announcements');
    await remove('cache_hot_museums');
    await remove('cache_latest_exhibitions');
  }
}

