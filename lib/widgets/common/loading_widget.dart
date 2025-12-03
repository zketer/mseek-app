import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';

/// 统一的加载Widget
/// 
/// 提供多种加载样式：
/// - 默认：中心圆形进度条
/// - 带文字：进度条+加载文字
/// - 全屏：覆盖整个屏幕的加载
/// 
/// 使用示例：
/// ```dart
/// // 默认加载
/// LoadingWidget()
/// 
/// // 带文字
/// LoadingWidget(message: '加载中...')
/// 
/// // 全屏加载
/// LoadingWidget.fullScreen()
/// ```
class LoadingWidget extends StatelessWidget {
  /// 加载提示文字
  final String? message;
  
  /// 进度条颜色
  final Color? color;
  
  /// 是否全屏
  final bool isFullScreen;
  
  /// 背景色（全屏模式下使用）
  final Color? backgroundColor;

  const LoadingWidget({
    super.key,
    this.message,
    this.color,
    this.isFullScreen = false,
    this.backgroundColor,
  });

  /// 全屏加载
  factory LoadingWidget.fullScreen({
    String? message,
    Color? color,
    Color? backgroundColor,
  }) {
    return LoadingWidget(
      message: message,
      color: color,
      isFullScreen: true,
      backgroundColor: backgroundColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 圆形进度条
          CircularProgressIndicator(
            color: color ?? AppColors.primaryLight,
            strokeWidth: 3,
          ),
          
          // 加载文字（可选）
          if (message != null) ...[
            const SizedBox(height: AppDimensions.paddingM),
            Text(
              message!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );

    if (isFullScreen) {
      return Container(
        color: backgroundColor ?? AppColors.background,
        child: content,
      );
    }

    return content;
  }
}

/// 列表加载中状态Widget
class ListLoadingWidget extends StatelessWidget {
  final String? message;

  const ListLoadingWidget({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppColors.primaryLight,
              strokeWidth: 3,
            ),
            if (message != null) ...[
              const SizedBox(height: AppDimensions.paddingM),
              Text(
                message!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textHint,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 底部加载更多Widget
class LoadMoreWidget extends StatelessWidget {
  final bool isLoading;
  final bool hasMore;
  final String loadingText;
  final String noMoreText;

  const LoadMoreWidget({
    super.key,
    required this.isLoading,
    required this.hasMore,
    this.loadingText = '加载中...',
    this.noMoreText = '没有更多了',
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingM),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryLight,
              ),
            ),
            const SizedBox(width: AppDimensions.paddingS),
            Text(
              loadingText,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      );
    }

    if (!hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingM),
        child: Text(
          noMoreText,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textHint,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

