import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/router/auth_guard.dart';
import '../../core/utils/ui_helper.dart';

/// 首页快速入口组件 - 完全匹配小程序：5个入口+渐变图标+flex布局
class HomeQuickEntrySection extends StatelessWidget {
  const HomeQuickEntrySection({super.key});

  // 快速入口数据 - 完全匹配小程序的5个入口
  static const List<QuickEntryItem> _entries = [
    QuickEntryItem(
      id: 1,
      name: '同城博物馆',
      icon: Icons.location_city,
      route: '/nearby-museums',
    ),
    QuickEntryItem(
      id: 2,
      name: '成就徽章',
      icon: Icons.military_tech,
      route: '/achievements',
    ),
    QuickEntryItem(
      id: 3,
      name: '我的打卡',
      icon: Icons.check_circle_outline,
      route: '/history',
    ),
    QuickEntryItem(
      id: 4,
      name: '我的收藏',
      icon: Icons.favorite_border,
      route: '/favorites',
    ),
    QuickEntryItem(
      id: 5,
      name: '更多功能',
      icon: Icons.more_horiz,
      route: '/more-features',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingM),
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround, // 小程序使用space-around
        children: _entries.map((entry) => Expanded(
          child: _buildQuickEntryItem(context, entry),
        )).toList(),
      ),
    );
  }

  /// 构建快速入口项
  Widget _buildQuickEntryItem(BuildContext context, QuickEntryItem entry) {
    return GestureDetector(
      onTap: () => _onQuickEntryTapped(context, entry),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 图标容器 - 小程序样式渐变背景，增加尺寸让图标更饱满
            Container(
              width: 55, // 增加到55让图标有更多空间
              height: 55,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFF9A9E), // #ff9a9e
                    Color(0xFFFECFEF), // #fecfef
                  ],
                ),
                borderRadius: BorderRadius.circular(12), // 24rpx转换
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF9A9E).withValues(alpha: 0.3),
                    blurRadius: 8, // 16rpx转换
                    offset: const Offset(0, 2), // 4rpx转换
                  ),
                ],
              ),
              child: Icon(
                entry.icon,
                size: 30, // 增加到30，让图标更饱满
                color: AppColors.textWhite,
              ),
            ),
            
            const SizedBox(height: 10), // 20rpx转换
            
            // 名称
            Text(
              entry.name,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textPrimary,
                fontSize: 12, // 24rpx转换
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// 快速入口点击事件
  Future<void> _onQuickEntryTapped(BuildContext context, QuickEntryItem entry) async {
    // 根据route跳转到对应页面
    if (entry.route == '/more-features') {
      // 更多功能暂未实现，显示提示
      UIHelper.showInfo(context, '更多功能即将上线');
      return;
    }
    
    // 需要登录的页面，使用登录守卫
    // 注意：AuthGuards 内部已经处理了跳转逻辑，不需要再次跳转
    switch (entry.route) {
      case '/achievements':
        // 成就徽章需要登录
        await AuthGuards.achievements(context);
        break;
      case '/history':
        // 我的打卡需要登录
        await AuthGuards.history(context);
        break;
      case '/favorites':
        // 我的收藏需要登录
        await AuthGuards.favorites(context);
        break;
      default:
        // 其他页面直接跳转（不需要登录）
        if (context.mounted) {
          context.push(entry.route);
        }
    }
  }
}

/// 快速入口项数据模型 - 匹配小程序样式，统一渐变背景
class QuickEntryItem {
  final int id;
  final String name;
  final IconData icon;
  final String route;

  const QuickEntryItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.route,
  });
}
