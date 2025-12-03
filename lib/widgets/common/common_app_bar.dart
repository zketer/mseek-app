import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

/// 通用顶部导航栏
class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// 页面标题
  final String title;
  
  /// 右侧操作按钮列表
  final List<Widget>? actions;
  
  /// 是否显示返回按钮
  final bool showBackButton;
  
  /// 自定义返回按钮回调
  final VoidCallback? onBackPressed;
  
  /// 背景颜色
  final Color? backgroundColor;
  
  /// 标题颜色
  final Color? titleColor;
  
  /// 图标颜色
  final Color? iconColor;

  const CommonAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = true,
    this.onBackPressed,
    this.backgroundColor,
    this.titleColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor ?? Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: showBackButton
          ? IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                color: iconColor ?? AppColors.textPrimary,
                size: 20,
              ),
              onPressed: onBackPressed ?? () => _handleBackPressed(context),
            )
          : null,
      title: Text(
        title,
        style: AppTextStyles.titleMedium.copyWith(
          fontSize: 18, // 36rpx
          fontWeight: FontWeight.w600,
          color: titleColor ?? AppColors.textPrimary,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      centerTitle: true,
      actions: actions != null 
          ? [...actions!, const SizedBox(width: 8)] // 添加右边距
          : null,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  /// 处理返回按钮点击
  static void _handleBackPressed(BuildContext context) {
    // 使用go_router统一的导航API
    if (context.canPop()) {
      // 使用go_router返回
      context.pop();
    } else {
      // 如果无法返回，导航到首页
      context.go('/');
    }
  }

  /// 创建一个带收藏和分享按钮的AppBar
  static CommonAppBar withFavoriteAndShare({
    required String title,
    required bool isFavorited,
    required VoidCallback onFavoritePressed,
    required VoidCallback onSharePressed,
    VoidCallback? onBackPressed,
  }) {
    return CommonAppBar(
      title: title,
      onBackPressed: onBackPressed,
      actions: [
        // 收藏按钮（和分享按钮保持一致）
        IconButton(
          icon: Icon(
            isFavorited ? Icons.favorite : Icons.favorite_border,
            color: isFavorited ? AppColors.primary : AppColors.textSecondary,
            size: 24,
          ),
          onPressed: onFavoritePressed,
        ),
        // 分享按钮
        IconButton(
          icon: const Icon(
            Icons.share,
            color: AppColors.textSecondary,
            size: 24,
          ),
          onPressed: onSharePressed,
        ),
      ],
    );
  }

  /// 创建一个只有标题的简单AppBar
  static CommonAppBar simple({
    required String title,
    VoidCallback? onBackPressed,
  }) {
    return CommonAppBar(
      title: title,
      onBackPressed: onBackPressed,
    );
  }

  /// 创建一个带搜索按钮的AppBar
  static CommonAppBar withSearch({
    required String title,
    required VoidCallback onSearchPressed,
    VoidCallback? onBackPressed,
    List<Widget>? additionalActions,
  }) {
    List<Widget> actions = [
      IconButton(
        icon: const Icon(
          Icons.search,
          color: AppColors.textSecondary,
          size: 24,
        ),
        onPressed: onSearchPressed,
      ),
    ];
    
    if (additionalActions != null) {
      actions.addAll(additionalActions);
    }
    
    return CommonAppBar(
      title: title,
      onBackPressed: onBackPressed,
      actions: actions,
    );
  }
}
