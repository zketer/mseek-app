import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../utils/bottom_sheet_helper.dart';
import '../../services/auth/auth_service.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common/toast_widget.dart';
import '../utils/ui_helper.dart';

/// 登录验证守卫工具
/// 
/// 统一处理登录验证、跳转和返回逻辑
/// 参考小程序 auth-guard.ts 实现
/// 
/// @author lynn
/// @since 2024-10-17

/// 登录守卫选项
class AuthGuardOptions {
  /// 提示标题
  final String title;
  
  /// 提示内容
  final String content;
  
  /// 确认按钮文字
  final String confirmText;
  
  /// 是否显示取消按钮
  final bool showCancel;
  
  /// 取消回调
  final VoidCallback? onCancel;
  
  /// 是否静默检查（不显示弹窗，直接跳转）
  final bool silent;
  
  /// 登录成功后要跳转的目标页面路径
  final String? targetPath;
  
  /// 登录成功后的回调函数（用于执行操作而不是跳转页面）
  final VoidCallback? onSuccess;
  
  /// 操作类型：navigate | action
  final String type;
  
  const AuthGuardOptions({
    this.title = '提示',
    this.content = '请先登录后再使用此功能',
    this.confirmText = '去登录',
    this.showCancel = true,
    this.onCancel,
    this.silent = false,
    this.targetPath,
    this.onSuccess,
    this.type = 'navigate',
  });
}

/// 登录验证守卫
/// 
/// 使用示例：
/// ```dart
/// final isLoggedIn = await requireAuth(context);
/// if (isLoggedIn) {
///   // 执行需要登录的操作
/// }
/// ```
Future<bool> requireAuth(
  BuildContext context, {
  AuthGuardOptions options = const AuthGuardOptions(),
}) async {
  final authService = AuthService();
  
  // 检查登录状态并自动刷新 Token
  final hasValidToken = await authService.ensureValidToken();
  if (hasValidToken) {
    // 如果已登录且有目标路径，直接跳转
    if (options.targetPath != null) {
      debugPrint('用户已登录，直接跳转到: ${options.targetPath}');
      if (context.mounted) {
        context.push(options.targetPath!);
      }
    }
    return true;
  }
  
  // 统一处理目标路径
  String? redirectPath = options.targetPath;
  
  if (redirectPath == null && options.type != 'action' && context.mounted) {
    // 如果没有指定目标路径且不是操作类型，则使用当前页面路径
    final currentLocation = GoRouterState.of(context).uri.toString();
    redirectPath = currentLocation;
  }
  
  // 构建登录页面URL（包含redirect参数）
  String loginUrl = AppConstants.routeLogin;
  if (redirectPath != null && options.type != 'action') {
    loginUrl += '?redirect=${Uri.encodeQueryComponent(redirectPath)}';
    debugPrint('构建登录URL: $loginUrl');
  }
  
  // 静默模式直接跳转
  if (options.silent) {
    if (context.mounted) {
      context.push(loginUrl);
    }
    return false;
  }
  
  // 显示登录提示底部卡片
  if (!context.mounted) return false;
  
  final result = await BottomSheetHelper.showConfirm(
    context,
    title: options.title,
    content: options.content,
    confirmText: options.confirmText,
    cancelText: options.showCancel ? '取消' : '',
    icon: Icons.lock_outline,
  );
  
  if (result == true) {
    // 用户确认，跳转到登录页
    if (context.mounted) {
      context.push(loginUrl);
    }
  } else {
    // 用户取消
    options.onCancel?.call();
  }
  
  return result ?? false;
}

/// 快速登录验证（静默模式）
/// 不显示弹窗，直接跳转到登录页
Future<bool> requireAuthSilent(BuildContext context) {
  return requireAuth(
    context,
    options: const AuthGuardOptions(silent: true),
  );
}

/// 页面级登录验证
/// 适用于整个页面需要登录才能访问的场景
/// 
/// @param pageName 页面名称，用于提示
Future<bool> requireAuthForPage(BuildContext context, String pageName) {
  return requireAuth(
    context,
    options: AuthGuardOptions(
      title: '访问受限',
      content: '$pageName需要登录后才能访问',
      confirmText: '立即登录',
      showCancel: false,
    ),
  );
}

/// 功能级登录验证 - 页面跳转类型
/// 适用于页面内某个功能需要登录的场景
/// 
/// @param featureName 功能名称，用于提示
/// @param targetPath 登录成功后跳转的目标页面路径
Future<bool> requireAuthForFeature(
  BuildContext context,
  String featureName, {
  String? targetPath,
}) {
  return requireAuth(
    context,
    options: AuthGuardOptions(
      title: '功能受限',
      content: '使用$featureName功能需要先登录',
      confirmText: '去登录',
      showCancel: true,
      targetPath: targetPath,
      type: 'navigate',
    ),
  );
}

/// 操作级登录验证 - 回调执行类型
/// 适用于需要登录后执行特定操作的场景（如收藏、点赞等）
/// 
/// @param actionName 操作名称，用于提示
/// @param onSuccess 登录成功后执行的操作
Future<bool> requireAuthForAction(
  BuildContext context,
  String actionName, {
  VoidCallback? onSuccess,
}) {
  return requireAuth(
    context,
    options: AuthGuardOptions(
      title: '需要登录',
      content: '$actionName需要先登录',
      confirmText: '去登录',
      showCancel: true,
      type: 'action',
      onSuccess: onSuccess,
    ),
  );
}

/// 检查页面是否需要登录访问
/// 可以在页面的 initState 或 didChangeDependencies 中调用
/// 
/// @param pageName 页面名称
/// @returns 是否已登录
Future<bool> checkPageAuth(BuildContext context, String pageName) async {
  final isLoggedIn = await requireAuthForPage(context, pageName);
  if (!isLoggedIn) {
    // 未登录，阻止页面继续加载
    return false;
  }
  return true;
}

/// 统一的退出登录处理
class LogoutOptions {
  /// 是否显示确认弹窗
  final bool showConfirm;
  
  /// 确认弹窗标题
  final String confirmTitle;
  
  /// 确认弹窗内容
  final String confirmContent;
  
  /// 退出成功后是否跳转到首页
  final bool redirectToHome;
  
  /// 是否显示加载提示
  final bool showLoading;
  
  /// 成功回调
  final VoidCallback? onSuccess;
  
  /// 失败回调
  final Function(dynamic error)? onError;
  
  const LogoutOptions({
    this.showConfirm = true,
    this.confirmTitle = '确认退出',
    this.confirmContent = '确定要退出登录吗？退出后需要重新登录才能使用相关功能。',
    this.redirectToHome = true,
    this.showLoading = false,
    this.onSuccess,
    this.onError,
  });
}

/// 执行退出登录
Future<bool> performLogout(
  BuildContext context, {
  LogoutOptions options = const LogoutOptions(),
}) async {
  try {
    // 如果需要显示确认弹窗
    if (options.showConfirm) {
      if (!context.mounted) return false;
      
      final confirmed = await BottomSheetHelper.showConfirm(
        context,
        title: options.confirmTitle,
        content: options.confirmContent,
        confirmText: '确定退出',
        cancelText: '再想想',
        icon: Icons.logout,
      );
      
      if (confirmed != true) {
        return false;
      }
    }
    
    // 显示加载提示（可选）
    bool hasLoadingDialog = false;
    if (options.showLoading && context.mounted) {
      hasLoadingDialog = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // 调用退出登录API
    final authService = AuthService();
    try {
      await authService.logout();
      debugPrint('✅ [performLogout] 退出登录API调用完成');
    } catch (logoutError) {
      debugPrint('⚠️ [performLogout] 退出登录API调用失败，但继续执行本地清理: $logoutError');
      // 不抛出错误，继续执行后续逻辑
    }
    
    debugPrint('✅ [performLogout] 退出登录流程完成');
    
    // 隐藏加载提示
    if (hasLoadingDialog && context.mounted) {
      Navigator.of(context).pop();
    }
    
    // 显示成功提示（使用 Toast）
    if (context.mounted) {
      ToastWidget.showSuccess(context, '已退出登录');
    }
    
    // 调用成功回调
    options.onSuccess?.call();
    
    // 刷新 AppProvider 状态
    if (context.mounted) {
      try {
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        await appProvider.logout();
        // DEBUG: print('✅ [AuthGuard] AppProvider 状态已更新');
      } catch (e) {
        // DEBUG: print('⚠️ [AuthGuard] 更新AppProvider失败: $e');
      }
    }
    
    // 如果需要跳转到首页
    if (options.redirectToHome) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (context.mounted) {
        context.go(AppConstants.routeHome);
      }
    }
    
    return true;
    
  } catch (error) {
    debugPrint('退出登录失败: $error');
    
    // 显示失败提示
    if (context.mounted) {
      UIHelper.showError(context, '退出失败，请重试');
    }
    
    // 调用失败回调
    options.onError?.call(error);
    
    return false;
  }
}

/// 预配置的登录守卫
class AuthGuards {
  /// 成就徽章
  static Future<bool> achievements(BuildContext context) {
    return requireAuthForFeature(
      context,
      '成就徽章',
      targetPath: AppConstants.routeAchievements,
    );
  }
  
  /// 我的打卡（跳转到打卡历史）
  static Future<bool> checkin(BuildContext context) {
    return requireAuthForFeature(
      context,
      '我的打卡',
      targetPath: AppConstants.routeHistory,
    );
  }
  
  /// 打卡历史
  static Future<bool> history(BuildContext context) {
    return requireAuthForFeature(
      context,
      '打卡历史',
      targetPath: AppConstants.routeHistory,
    );
  }
  
  /// 我的收藏
  static Future<bool> favorites(BuildContext context) {
    return requireAuthForFeature(
      context,
      '我的收藏',
      targetPath: AppConstants.routeFavorites,
    );
  }
  
  /// 个人中心
  static Future<bool> profile(BuildContext context) {
    return requireAuthForPage(context, '个人中心');
  }
  
  /// 设置页面
  static Future<bool> settings(BuildContext context) {
    return requireAuthForFeature(
      context,
      '设置',
      targetPath: AppConstants.routeSettings,
    );
  }
}

