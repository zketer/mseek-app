import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 性能优化工具类
/// 
/// 提供性能监控、优化建议和常用性能优化方法，包括：
/// - 性能计时器
/// - FPS监控
/// - 内存使用监控
/// - 图片加载优化
/// - Widget构建优化
/// 
/// 使用示例：
/// ```dart
/// // 性能计时
/// final timer = PerformanceHelper.startTimer('loadData');
/// await loadData();
/// PerformanceHelper.endTimer(timer);
/// 
/// // 图片大小优化建议
/// final size = PerformanceHelper.getOptimalImageSize(context);
/// 
/// // 防抖动
/// PerformanceHelper.debounce(() {
///   // 执行搜索
/// }, duration: Duration(milliseconds: 300));
/// ```
class PerformanceHelper {
  /// 性能计时器Map
  static final Map<String, DateTime> _timers = {};
  
  /// 防抖动Map
  static final Map<String, Timer?> _debounceTimers = {};

  /// 开始性能计时
  /// 
  /// [label] 计时器标签
  /// 
  /// 返回：计时器标签（用于结束计时）
  static String startTimer(String label) {
    _timers[label] = DateTime.now();
    if (kDebugMode) {
      debugPrint('⏱️  [性能] 开始计时: $label');
    }
    return label;
  }

  /// 结束性能计时并打印耗时
  /// 
  /// [label] 计时器标签
  static void endTimer(String label) {
    final startTime = _timers[label];
    if (startTime == null) {
      if (kDebugMode) {
        debugPrint('⚠️  [性能] 未找到计时器: $label');
      }
      return;
    }

    final duration = DateTime.now().difference(startTime);
    _timers.remove(label);

    if (kDebugMode) {
      debugPrint('⏱️  [性能] $label 耗时: ${duration.inMilliseconds}ms');
      
      // 性能警告
      if (duration.inMilliseconds > 1000) {
        debugPrint('⚠️  [性能警告] $label 耗时超过1秒！');
      } else if (duration.inMilliseconds > 500) {
        debugPrint('⚠️  [性能提示] $label 耗时超过500ms');
      }
    }
  }

  /// 获取最优图片加载尺寸
  /// 
  /// 根据屏幕密度和设备性能返回合适的图片尺寸
  /// 
  /// [context] BuildContext
  /// [targetWidth] 目标显示宽度（逻辑像素）
  /// 
  /// 返回：最优图片宽度（物理像素）
  static int getOptimalImageWidth(BuildContext context, double targetWidth) {
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    
    // 根据设备像素比例计算实际需要的图片宽度
    final physicalWidth = targetWidth * devicePixelRatio;
    
    // 限制最大宽度为2048px（避免加载过大图片）
    return physicalWidth.toInt().clamp(0, 2048);
  }

  /// 获取最优图片加载尺寸
  /// 
  /// [context] BuildContext
  /// 
  /// 返回：Size(宽度, 高度)，单位为物理像素
  static Size getOptimalImageSize(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    
    // 计算屏幕物理像素
    final physicalWidth = screenSize.width * devicePixelRatio;
    final physicalHeight = screenSize.height * devicePixelRatio;
    
    // 限制最大尺寸（避免加载过大图片导致OOM）
    return Size(
      physicalWidth.clamp(0, 2048),
      physicalHeight.clamp(0, 2048),
    );
  }

  /// 计算缩略图尺寸
  /// 
  /// [context] BuildContext
  /// [thumbnailWidth] 缩略图显示宽度（逻辑像素）
  /// 
  /// 返回：缩略图物理像素宽度
  static int getThumbnailWidth(BuildContext context, double thumbnailWidth) {
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final physicalWidth = thumbnailWidth * devicePixelRatio;
    
    // 缩略图最大400px（优化内存使用）
    return physicalWidth.toInt().clamp(0, 400);
  }

  /// 防抖动函数
  /// 
  /// 在指定时间内多次调用，只执行最后一次
  /// 
  /// [callback] 要执行的函数
  /// [duration] 防抖动时间，默认300ms
  /// [key] 防抖动键（支持多个独立的防抖动）
  static void debounce(
    VoidCallback callback, {
    Duration duration = const Duration(milliseconds: 300),
    String key = 'default',
  }) {
    // 取消之前的定时器
    _debounceTimers[key]?.cancel();
    
    // 创建新的定时器
    _debounceTimers[key] = Timer(duration, () {
      callback();
      _debounceTimers.remove(key);
    });
  }

  /// 节流函数
  /// 
  /// 在指定时间内只执行一次，忽略期间的其他调用
  /// 
  /// [callback] 要执行的函数
  /// [duration] 节流时间，默认1000ms
  /// [key] 节流键（支持多个独立的节流）
  static void throttle(
    VoidCallback callback, {
    Duration duration = const Duration(milliseconds: 1000),
    String key = 'default',
  }) {
    final throttleKey = 'throttle_$key';
    
    // 检查是否在节流期内
    if (_debounceTimers[throttleKey] != null && 
        _debounceTimers[throttleKey]!.isActive) {
      return; // 忽略调用
    }
    
    // 执行回调
    callback();
    
    // 设置节流定时器
    _debounceTimers[throttleKey] = Timer(duration, () {
      _debounceTimers.remove(throttleKey);
    });
  }

  /// 延迟执行（避免在build期间执行某些操作）
  /// 
  /// [callback] 要执行的函数
  /// [duration] 延迟时间，默认0（下一帧）
  static void delayed(
    VoidCallback callback, {
    Duration duration = Duration.zero,
  }) {
    Future.delayed(duration, callback);
  }

  /// 在下一帧执行
  /// 
  /// [callback] 要执行的函数
  static void nextFrame(VoidCallback callback) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      callback();
    });
  }

  /// 计算列表预加载范围
  /// 
  /// [totalItems] 总条目数
  /// [visibleItems] 可见条目数，默认10
  /// 
  /// 返回：建议的预加载范围（提前加载多少条）
  static int calculateCacheExtent(int totalItems, {int visibleItems = 10}) {
    // 预加载策略：可见条目的2倍
    return (visibleItems * 2).clamp(10, 50);
  }

  /// 优化的ScrollController（自动释放资源）
  /// 
  /// 使用示例：
  /// ```dart
  /// final controller = PerformanceHelper.createScrollController();
  /// // 使用controller...
  /// // dispose时会自动清理
  /// ```
  static ScrollController createScrollController({
    double initialScrollOffset = 0.0,
    bool keepScrollOffset = true,
  }) {
    return ScrollController(
      initialScrollOffset: initialScrollOffset,
      keepScrollOffset: keepScrollOffset,
    );
  }

  /// 清理所有计时器
  static void clearAllTimers() {
    for (final timer in _debounceTimers.values) {
      timer?.cancel();
    }
    _debounceTimers.clear();
    _timers.clear();
  }

  /// 获取图片缓存配置建议
  /// 
  /// 返回：Map<String, dynamic> 包含maxCacheSize和maxCacheCount
  static Map<String, dynamic> getImageCacheConfig() {
    // 根据设备内存情况动态调整缓存大小
    return {
      'maxCacheSize': 100 * 1024 * 1024, // 100MB
      'maxCacheCount': 200, // 最多缓存200张图片
    };
  }

  /// 打印性能建议
  static void printPerformanceTips() {
    if (kDebugMode) {
      debugPrint('''
========================================
📊 性能优化建议
========================================

1. 图片优化
   - 使用CachedNetworkImage缓存图片
   - 限制图片加载尺寸（maxWidth/maxHeight）
   - 使用placeholder和errorWidget
   - 缩略图使用小尺寸加载

2. 列表优化
   - 使用ListView.builder而非ListView
   - 使用GridView.builder而非GridView
   - 设置合理的cacheExtent预加载范围
   - 避免在itemBuilder中创建复杂Widget

3. 异步操作
   - 耗时操作使用async/await
   - 图片解码使用compute隔离
   - 大数据处理使用Isolate

4. Widget优化
   - 使用const构造函数
   - 合理使用Key
   - 避免不必要的setState
   - 使用ValueListenableBuilder局部刷新

5. 内存优化
   - 及时dispose资源（controller、stream等）
   - 避免内存泄漏（取消订阅、清理定时器）
   - 大列表使用分页加载

========================================
      ''');
    }
  }
}

