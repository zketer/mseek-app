import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';

/// 展览卡片骨架屏组件
class ExhibitionCardSkeleton extends StatelessWidget {
  const ExhibitionCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: AppColors.errorBg, // 浅粉色高光
      period: const Duration(milliseconds: 1500),
      child: Container(
        width: 280, // 修复：添加固定宽度，防止在横向滚动中出现unbounded width错误
        margin: const EdgeInsets.only(bottom: 12, right: 12),
        padding: const EdgeInsets.all(12),
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 图片占位
            Container(
              width: 100,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题占位
                  Container(
                    width: double.infinity,
                    height: 16,
                    color: Colors.grey[200],
                    margin: const EdgeInsets.only(bottom: 8),
                  ),
                  // 博物馆名称占位
                  Container(
                    width: 120,
                    height: 12,
                    color: Colors.grey[200],
                    margin: const EdgeInsets.only(bottom: 6),
                  ),
                  // 日期占位
                  Container(
                    width: 80,
                    height: 10,
                    color: Colors.grey[200],
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
