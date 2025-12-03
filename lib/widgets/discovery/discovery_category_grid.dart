import 'package:flutter/material.dart';
import '../../core/utils/ui_helper.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';

/// 发现页分类网格组件
class DiscoveryCategoryGrid extends StatelessWidget {
  const DiscoveryCategoryGrid({super.key});

  // 博物馆分类数据
  final List<CategoryItem> _categories = const [
    CategoryItem(
      id: 1,
      name: '历史类',
      icon: Icons.account_balance,
      color: Color(0xFF5C6BC0),
    ),
    CategoryItem(
      id: 2,
      name: '艺术类',
      icon: Icons.palette,
      color: AppColors.errorLight,
    ),
    CategoryItem(
      id: 3,
      name: '科技类',
      icon: Icons.science,
      color: AppColors.infoLight,
    ),
    CategoryItem(
      id: 4,
      name: '自然类',
      icon: Icons.nature,
      color: AppColors.successLight,
    ),
    CategoryItem(
      id: 5,
      name: '民俗类',
      icon: Icons.festival,
      color: AppColors.errorLight,
    ),
    CategoryItem(
      id: 6,
      name: '军事类',
      icon: Icons.shield,
      color: Color(0xFF8D6E63),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.2,
          mainAxisSpacing: AppDimensions.paddingM,
          crossAxisSpacing: AppDimensions.paddingM,
        ),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          return _buildCategoryItem(context, category);
        },
      ),
    );
  }

  /// 构建分类项
  Widget _buildCategoryItem(BuildContext context, CategoryItem category) {
    return GestureDetector(
      onTap: () => _onCategoryTapped(context, category),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: category.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusL),
              ),
              child: Icon(
                category.icon,
                color: category.color,
                size: 24,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingS),
            Text(
              category.name,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 处理分类点击事件
  void _onCategoryTapped(BuildContext context, CategoryItem category) {
    UIHelper.showInfo(context, '点击了分类: ${category.name}');
    // TODO: 跳转到对应分类的博物馆列表
  }
}

/// 分类项数据模型
class CategoryItem {
  final int id;
  final String name;
  final IconData icon;
  final Color color;

  const CategoryItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}
