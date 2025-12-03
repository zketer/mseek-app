import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';

/// 博物馆卡片骨架屏组件
class MuseumCardSkeleton extends StatelessWidget {
  const MuseumCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: AppColors.errorBg, // 浅粉色高光
      period: const Duration(milliseconds: 1500),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: AppDimensions.paddingM),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 图片占位
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppDimensions.radiusM),
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题占位
                  Container(
                    width: double.infinity,
                    height: 14,
                    color: Colors.grey[200],
                    margin: const EdgeInsets.only(bottom: 6),
                  ),
                  // 位置占位
                  Container(
                    width: 80,
                    height: 10,
                    color: Colors.grey[200],
                    margin: const EdgeInsets.only(bottom: 6),
                  ),
                  // 标签占位
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 10,
                        color: Colors.grey[200],
                        margin: const EdgeInsets.only(right: 4),
                      ),
                      Container(
                        width: 50,
                        height: 10,
                        color: Colors.grey[200],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
