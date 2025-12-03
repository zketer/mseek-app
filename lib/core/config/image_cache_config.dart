import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// 图片缓存配置
/// 
/// 优化图片加载性能，减少内存占用和网络请求
class ImageCacheConfig {
  /// 初始化图片缓存配置
  /// 
  /// 建议在app启动时调用（main.dart）
  static void init() {
    // 配置图片缓存大小
    PaintingBinding.instance.imageCache.maximumSize = 200; // 最多缓存200张图片
    PaintingBinding.instance.imageCache.maximumSizeBytes = 100 * 1024 * 1024; // 最大100MB

    debugPrint('✅ [图片缓存] 配置完成: 最多200张图片, 最大100MB');
  }

  /// 清理图片缓存
  static void clear() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    debugPrint('🗑️  [图片缓存] 已清理');
  }

  /// 获取缓存统计信息
  static Map<String, dynamic> getCacheStats() {
    final imageCache = PaintingBinding.instance.imageCache;
    return {
      'currentSize': imageCache.currentSize,
      'maximumSize': imageCache.maximumSize,
      'currentSizeBytes': imageCache.currentSizeBytes,
      'maximumSizeBytes': imageCache.maximumSizeBytes,
      'liveImageCount': imageCache.liveImageCount,
      'pendingImageCount': imageCache.pendingImageCount,
    };
  }

  /// 打印缓存统计信息
  static void printCacheStats() {
    final stats = getCacheStats();
    debugPrint('''
========================================
📊 图片缓存统计
========================================
当前缓存图片数: ${stats['currentSize']} / ${stats['maximumSize']}
当前缓存大小: ${(stats['currentSizeBytes'] / 1024 / 1024).toStringAsFixed(2)}MB / ${(stats['maximumSizeBytes'] / 1024 / 1024).toStringAsFixed(2)}MB
活跃图片数: ${stats['liveImageCount']}
待处理图片数: ${stats['pendingImageCount']}
========================================
    ''');
  }
}

/// 优化的图片加载Widget
/// 
/// 自动应用性能优化配置
class OptimizedCachedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget Function(BuildContext, String)? placeholder;
  final Widget Function(BuildContext, String, dynamic)? errorWidget;
  final bool enableMemCache;

  const OptimizedCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.enableMemCache = true,
  });

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: width != null ? (width! * MediaQuery.of(context).devicePixelRatio).toInt().clamp(0, 1024) : null,
      memCacheHeight: height != null ? (height! * MediaQuery.of(context).devicePixelRatio).toInt().clamp(0, 1024) : null,
      placeholder: placeholder ?? _defaultPlaceholder,
      errorWidget: errorWidget ?? _defaultErrorWidget,
    );
  }

  /// 默认占位符
  static Widget _defaultPlaceholder(BuildContext context, String url) {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
        ),
      ),
    );
  }

  /// 默认错误Widget
  static Widget _defaultErrorWidget(BuildContext context, String url, dynamic error) {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: Colors.grey,
          size: 48,
        ),
      ),
    );
  }
}

