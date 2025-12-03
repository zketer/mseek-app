import 'package:flutter/material.dart';
import '../../widgets/common/toast_widget.dart';

/// UI交互工具类
/// 
/// 提供统一的UI交互方法，包括：
/// - 成功/错误/警告/信息提示（使用Toast代替SnackBar）
/// - 加载提示
/// 
/// 使用示例：
/// ```dart
/// UIHelper.showSuccess(context, '保存成功');
/// UIHelper.showError(context, '网络错误');
/// UIHelper.showWarning(context, '功能开发中');
/// UIHelper.showInfo(context, '提示信息');
/// UIHelper.showLoading(context, message: '加载中...');
/// UIHelper.hideLoading(context);
/// ```
class UIHelper {
  /// 显示成功提示（使用Toast）
  /// 
  /// [context] 上下文
  /// [message] 提示消息
  /// [duration] 显示时长，默认2秒
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    ToastWidget.showSuccess(context, message, duration: duration);
  }

  /// 显示错误提示（使用Toast）
  /// 
  /// [context] 上下文
  /// [message] 错误消息
  /// [duration] 显示时长，默认3秒
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ToastWidget.showError(context, message, duration: duration);
  }

  /// 显示警告提示（使用Toast）
  /// 
  /// [context] 上下文
  /// [message] 警告消息
  /// [duration] 显示时长，默认2秒
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    ToastWidget.showWarning(context, message, duration: duration);
  }

  /// 显示信息提示（使用Toast）
  /// 
  /// [context] 上下文
  /// [message] 信息消息
  /// [duration] 显示时长，默认2秒
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    ToastWidget.showInfo(context, message, duration: duration);
  }

  // 保存当前的 loading overlay entry
  static OverlayEntry? _currentLoadingEntry;

  /// 显示加载提示（使用Toast）
  /// 
  /// [context] 上下文
  /// [message] 加载消息，默认"加载中..."
  static void showLoading(
    BuildContext context, {
    String message = '加载中...',
  }) {
    // 先移除之前的loading
    hideLoading(context);
    // 显示新的loading
    _currentLoadingEntry = ToastWidget.showLoading(context, message);
  }

  /// 隐藏加载提示
  /// 
  /// [context] 上下文
  static void hideLoading(BuildContext context) {
    if (_currentLoadingEntry != null) {
      ToastWidget.hideLoading(_currentLoadingEntry);
      _currentLoadingEntry = null;
    }
  }

  /// 显示简单提示（使用Toast）
  /// 
  /// [context] 上下文
  /// [message] 提示消息
  /// [duration] 显示时长，默认2秒
  static void showSimple(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    ToastWidget.showInfo(context, message, duration: duration);
  }

  // ========== 废弃的SnackBar相关方法（保留用于兼容，但内部使用Toast） ==========
  
  /// @deprecated 请使用 hideLoading(context) 代替
  static void hideSnackBar(BuildContext context) {
    hideLoading(context);
  }

  /// @deprecated 请使用 hideLoading(context) 代替
  static void clearAllSnackBars(BuildContext context) {
    hideLoading(context);
  }

  /// @deprecated 使用Toast无需操作按钮，建议使用 showInfo 或自定义Dialog
  static void showWithAction(
    BuildContext context,
    String message, {
    required String actionLabel,
    required VoidCallback onActionPressed,
    Duration duration = const Duration(seconds: 4),
  }) {
    // 降级为简单提示
    showInfo(context, message, duration: duration);
  }
}
