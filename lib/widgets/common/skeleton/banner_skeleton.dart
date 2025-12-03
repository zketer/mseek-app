import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';

/// 轮播图骨架屏组件
class BannerSkeleton extends StatelessWidget {
  const BannerSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: AppColors.errorBg, // 浅粉色高光
      period: const Duration(milliseconds: 1500),
      child: Container(
        width: double.infinity,
        height: 200,
        margin: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingM,
          vertical: AppDimensions.paddingS,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        ),
        child: Stack(
          children: [
            // 背景占位
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                ),
              ),
            ),
            
            // 底部文字占位
            Positioned(
              bottom: AppDimensions.paddingL,
              left: AppDimensions.paddingL,
              right: AppDimensions.paddingL,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 120,
                    height: 20,
                    color: Colors.white.withValues(alpha: 0.5),
                    margin: const EdgeInsets.only(bottom: 8),
                  ),
                  Container(
                    width: 80,
                    height: 16,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
            
            // 指示器占位
            Positioned(
              bottom: AppDimensions.paddingM,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 60,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
