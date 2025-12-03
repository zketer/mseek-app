import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';

/// 发现页筛选栏组件
class DiscoveryFilterBar extends StatefulWidget {
  const DiscoveryFilterBar({super.key});

  @override
  State<DiscoveryFilterBar> createState() => _DiscoveryFilterBarState();
}

class _DiscoveryFilterBarState extends State<DiscoveryFilterBar> {
  String _selectedSort = '距离最近';
  
  final List<String> _sortOptions = ['距离最近', '评分最高', '最新发布', '热度最高'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingM,
        vertical: AppDimensions.paddingS,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // 筛选按钮
          _buildFilterChip(
            icon: Icons.filter_list,
            label: '筛选',
            onTap: () => _showFilterDialog(),
          ),
          
          const SizedBox(width: AppDimensions.paddingM),
          
          // 排序按钮
          _buildFilterChip(
            icon: Icons.sort,
            label: _selectedSort,
            onTap: () => _showSortDialog(),
          ),
          
          const Spacer(),
          
          // 视图切换按钮
          Row(
            children: [
              _buildViewButton(
                icon: Icons.view_list,
                isSelected: true,
                onTap: () {},
              ),
              const SizedBox(width: 4),
              _buildViewButton(
                icon: Icons.grid_view,
                isSelected: false,
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建筛选标签
  Widget _buildFilterChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingS,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建视图切换按钮
  Widget _buildViewButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent.withValues(alpha: 0.1) : null,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isSelected ? AppColors.accent : AppColors.textSecondary,
        ),
      ),
    );
  }

  /// 显示筛选对话框
  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('筛选条件', style: AppTextStyles.titleMedium),
            const SizedBox(height: AppDimensions.paddingM),
            const Text('筛选功能待开发...'),
            const SizedBox(height: AppDimensions.paddingM),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('确定'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示排序对话框
  void _showSortDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('排序方式', style: AppTextStyles.titleMedium),
            const SizedBox(height: AppDimensions.paddingM),
            ..._sortOptions.map((option) {
              return ListTile(
                title: Text(option),
                trailing: _selectedSort == option
                    ? const Icon(Icons.check, color: AppColors.accent)
                    : null,
                onTap: () {
                  setState(() {
                    _selectedSort = option;
                  });
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}
