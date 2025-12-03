import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

/// 发现页面分类标签栏组件 - 完全匹配小程序设计
class DiscoveryCategoryTabs extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final int activeCategory;
  final ValueChanged<int> onCategoryChanged;
  final VoidCallback onFilterTap;

  const DiscoveryCategoryTabs({
    super.key,
    required this.categories,
    required this.activeCategory,
    required this.onCategoryChanged,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40, // 80rpx转换
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: AppColors.backgroundDark,
            width: 1, // 2rpx转换
          ),
        ),
      ),
      child: Row(
        children: [
          // 横向滚动的分类标签区域
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16), // 32rpx转换
              child: Row(
                children: [
                  // "全部" 选项
                  _buildTabItem(
                    text: '全部',
                    isActive: activeCategory == 0,
                    onTap: () => onCategoryChanged(0),
                  ),
                  
                  // 分类选项
                  ...categories.map((category) => _buildTabItem(
                    text: category['name'],
                    isActive: activeCategory == category['id'],
                    onTap: () => onCategoryChanged(category['id']),
                  )),
                ],
              ),
            ),
          ),
          
          // 筛选按钮区域
          Container(
            padding: const EdgeInsets.only(right: 16, left: 8), // 32rpx 16rpx转换
            child: GestureDetector(
              onTap: onFilterTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // 16rpx 8rpx转换
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(14), // 28rpx转换
                  border: Border.all(
                    color: AppColors.divider,
                    width: 0.5, // 1rpx转换
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '筛选',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 12, // 24rpx转换
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 2), // 4rpx转换
                    // 向下箭头
                    CustomPaint(
                      size: const Size(8, 6), // 16rpx 12rpx转换
                      painter: _ArrowPainter(color: Colors.grey[600]!),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建单个标签项
  Widget _buildTabItem({
    required String text,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8), // 16rpx转换
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // 16rpx 8rpx转换
        decoration: BoxDecoration(
          color: isActive ? AppColors.info : AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(14), // 28rpx转换
        ),
        child: Text(
          text,
          style: AppTextStyles.bodySmall.copyWith(
            fontSize: 12, // 24rpx转换
            color: isActive ? Colors.white : Colors.grey[600],
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            height: 1.2, // 确保文字垂直居中
          ),
        ),
      ),
    );
  }
}

/// 向下箭头绘制器
class _ArrowPainter extends CustomPainter {
  final Color color;

  _ArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width / 2, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
