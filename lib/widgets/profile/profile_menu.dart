import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/router/auth_guard.dart';

/// 我的页面菜单组件 - 与小程序保持一致
class ProfileMenu extends StatelessWidget {
  const ProfileMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.paddingM,
        AppDimensions.paddingL, // 顶部间距，与渐变区域分离
        AppDimensions.paddingM,
        0,
      ),
      child: Column(
        children: [
          // 功能菜单 - 与小程序保持一致
          _buildMenuGroup([
            MenuItem(
              icon: Icons.history,
              title: '打卡历史',
              iconColor: AppColors.errorLight, // 橙色
              onTap: () => _onMenuTap(context, 'history'),
            ),
            MenuItem(
              icon: Icons.favorite,
              title: '我的收藏',
              iconColor: AppColors.infoLight, // 蓝色
              onTap: () => _onMenuTap(context, 'favorites'),
            ),
            MenuItem(
              icon: Icons.military_tech,
              title: '成就徽章',
              iconColor: AppColors.successLight, // 绿色
              onTap: () => _onMenuTap(context, 'achievements'),
            ),
            MenuItem(
              icon: Icons.settings,
              title: '设置',
              iconColor: AppColors.warningLight, // 黄色
              onTap: () => _onMenuTap(context, 'settings'),
            ),
            MenuItem(
              icon: Icons.feedback,
              title: '反馈建议',
              iconColor: const Color(0xFF7986CB), // 紫色
              onTap: () => _onMenuTap(context, 'feedback'),
            ),
            MenuItem(
              icon: Icons.info,
              title: '关于我们',
              iconColor: const Color(0xFF26C6DA), // 青色
              onTap: () => _onMenuTap(context, 'about'),
            ),
          ]),
          
          const SizedBox(height: AppDimensions.paddingXL * 2),
        ],
      ),
    );
  }

  /// 构建菜单组 - 与小程序样式保持一致
  Widget _buildMenuGroup(List<MenuItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: List.generate(
          items.length,
          (index) => Column(
            children: [
              _buildMenuItem(items[index]),
              if (index < items.length - 1) 
                Divider(
                  height: 1,
                  color: AppColors.divider.withValues(alpha: 0.5),
                  indent: 60,
                  endIndent: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建菜单项 - 与小程序样式保持一致（彩色方形图标）
  Widget _buildMenuItem(MenuItem item) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingM,
          vertical: AppDimensions.paddingL,
        ),
        child: Row(
          children: [
            // 菜单图标 - 彩色方形背景
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: item.iconColor,
                borderRadius: BorderRadius.circular(8), // 方形圆角
              ),
              child: Icon(
                item.icon,
                size: 20,
                color: Colors.white, // 白色图标
              ),
            ),
            
            const SizedBox(width: AppDimensions.paddingM),
            
            // 菜单标题
            Expanded(
              child: Text(
                item.title,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            
            // 右箭头
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  /// 处理菜单项点击 - 与小程序业务逻辑保持一致
  Future<void> _onMenuTap(BuildContext context, String type) async {
    // 需要登录的页面使用登录守卫
    // 注意：AuthGuards 内部已经处理了跳转逻辑
    switch (type) {
      case 'history':
        // 打卡历史需要登录
        await AuthGuards.history(context);
        break;
      case 'favorites':
        // 我的收藏需要登录
        await AuthGuards.favorites(context);
        break;
      case 'achievements':
        // 成就徽章需要登录
        await AuthGuards.achievements(context);
        break;
      case 'settings':
        // 设置需要登录
        await AuthGuards.settings(context);
        break;
      case 'feedback':
        // 反馈建议不需要登录，直接跳转
        if (context.mounted) {
          context.push('/feedback');
        }
        break;
      case 'about':
        // 关于我们不需要登录，直接跳转
        if (context.mounted) {
          context.push('/about');
        }
        break;
    }
  }

  /// 显示功能开发中提示
  // TODO: Show coming soon message
  // ignore: unused_element
  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('提示'),
        content: Text('$feature 功能正在开发中，敬请期待！'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('确定'),
          ),
        ],
      ),
    );
  }
}

/// 菜单项数据模型 - 支持彩色图标
class MenuItem {
  final IconData icon;
  final String title;
  final Color iconColor;
  final VoidCallback onTap;

  const MenuItem({
    required this.icon,
    required this.title,
    required this.iconColor,
    required this.onTap,
  });
}