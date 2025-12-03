import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// 自定义 Toast 提示组件
/// 模仿小程序的 wx.showToast，在屏幕中间显示提示信息
class ToastWidget {
  /// 显示成功提示
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    _showToast(
      context,
      message: message,
      icon: Icons.check_circle,
      iconColor: Colors.white,
      backgroundColor: AppColors.textBlack.withValues(alpha: 0.7), // 统一黑色半透明
      duration: duration,
    );
  }

  /// 显示错误提示
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    _showToast(
      context,
      message: message,
      icon: Icons.cancel,
      iconColor: Colors.white,
      backgroundColor: AppColors.textBlack.withValues(alpha: 0.7), // 统一黑色半透明
      duration: duration,
    );
  }

  /// 显示警告提示
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    _showToast(
      context,
      message: message,
      icon: Icons.warning_amber,
      iconColor: Colors.white,
      backgroundColor: AppColors.textBlack.withValues(alpha: 0.7), // 统一黑色半透明
      duration: duration,
    );
  }

  /// 显示普通提示
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    _showToast(
      context,
      message: message,
      icon: Icons.info,
      iconColor: Colors.white,
      backgroundColor: AppColors.textBlack.withValues(alpha: 0.7), // 统一黑色半透明
      duration: duration,
    );
  }

  /// 显示加载中
  static OverlayEntry? showLoading(
    BuildContext context,
    String message,
  ) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => _LoadingToast(message: message),
    );
    overlay.insert(overlayEntry);
    return overlayEntry;
  }

  /// 隐藏加载中
  static void hideLoading(OverlayEntry? entry) {
    entry?.remove();
  }

  /// 通用 Toast 显示方法
  static void _showToast(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required Duration duration,
  }) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        icon: icon,
        iconColor: iconColor,
        backgroundColor: backgroundColor,
      ),
    );

    overlay.insert(overlayEntry);

    // 延迟后自动移除
    Future.delayed(duration, () {
      overlayEntry.remove();
    });
  }
}

/// Toast 内部组件
class _ToastWidget extends StatefulWidget {
  final String message;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;

  const _ToastWidget({
    required this.message,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              constraints: const BoxConstraints(
                minWidth: 120,
                maxWidth: 200,
                minHeight: 120,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 20,
              ),
              decoration: BoxDecoration(
                color: widget.backgroundColor.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.icon,
                    size: 48,
                    color: widget.iconColor,
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: Text(
                      widget.message,
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 加载中 Toast 组件
class _LoadingToast extends StatelessWidget {
  final String message;

  const _LoadingToast({required this.message});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(
            minWidth: 120,
            maxWidth: 200,
            minHeight: 120,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 20,
          ),
          decoration: BoxDecoration(
            color: AppColors.textBlack.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

