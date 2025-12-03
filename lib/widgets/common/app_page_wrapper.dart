import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';

/// 统一的页面容器组件
/// 
/// 功能：
/// 1. 统一处理状态栏安全区域（SafeArea）
/// 2. 支持自定义状态栏样式（深色/浅色文字）
/// 3. 支持渐变背景过渡到状态栏
/// 4. 支持自定义背景颜色
/// 
/// 使用场景：
/// - 主 Tab 页面（首页、发现、打卡、我的）
/// - 需要统一状态栏间距的页面
class AppPageWrapper extends StatelessWidget {
  /// 子组件
  final Widget child;
  
  /// 背景颜色（默认使用应用背景色）
  final Color? backgroundColor;
  
  /// 状态栏背景颜色（用于沉浸式状态栏）
  /// 如果不设置，状态栏为透明，显示 backgroundColor
  final Color? statusBarColor;
  
  /// 状态栏文字亮度（深色背景用 Brightness.light，浅色背景用 Brightness.dark）
  final Brightness statusBarBrightness;
  
  /// 是否使用渐变背景延伸到状态栏（适用于有渐变背景的页面）
  final bool extendToStatusBar;
  
  /// 渐变背景（如果设置，会覆盖 backgroundColor）
  final Gradient? gradient;
  
  /// 是否在底部留出安全区域（默认 true）
  final bool safeAreaBottom;
  
  /// 是否在顶部留出安全区域（默认 true）
  final bool safeAreaTop;

  const AppPageWrapper({
    super.key,
    required this.child,
    this.backgroundColor,
    this.statusBarColor,
    this.statusBarBrightness = Brightness.dark, // 默认深色文字（适配浅色背景）
    this.extendToStatusBar = false,
    this.gradient,
    this.safeAreaBottom = true,
    this.safeAreaTop = true,
  });

  @override
  Widget build(BuildContext context) {
    // 设置状态栏样式
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: statusBarColor ?? Colors.transparent, // 状态栏颜色
        statusBarIconBrightness: statusBarBrightness, // 状态栏图标亮度
        statusBarBrightness: statusBarBrightness == Brightness.dark 
            ? Brightness.light 
            : Brightness.dark, // iOS 状态栏文字亮度
      ),
    );

    // 构建背景容器
    Widget container;
    if (gradient != null) {
      // 渐变背景
      container = Container(
        decoration: BoxDecoration(gradient: gradient),
      );
    } else if (backgroundColor != null) {
      // 纯色背景
      container = Container(
        color: backgroundColor,
      );
    } else {
      // 默认背景
      container = Container(
        color: AppColors.background,
      );
    }

    // 应用 SafeArea 在最外层（统一处理）
    if (safeAreaTop || safeAreaBottom) {
      return Stack(
        children: [
          // 背景层（覆盖全屏包括状态栏）
          Positioned.fill(child: container),
          // 内容层（有安全距离）
          SafeArea(
            top: safeAreaTop,
            bottom: safeAreaBottom,
            child: child,
          ),
        ],
      );
    }

    // 不需要安全距离时，直接叠加
    return Stack(
      children: [
        Positioned.fill(child: container),
        child,
      ],
    );
  }
}

/// 带渐变背景的页面容器（快捷方式）
/// 适用于：个人中心页面
class AppPageWrapperWithGradient extends StatelessWidget {
  final Widget child;
  final Gradient? gradient;
  final bool safeAreaBottom;

  const AppPageWrapperWithGradient({
    super.key,
    required this.child,
    this.gradient,
    this.safeAreaBottom = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppPageWrapper(
      gradient: gradient ?? AppColors.primaryGradient,
      statusBarBrightness: Brightness.light, // 渐变背景通常是深色，使用浅色文字
      extendToStatusBar: true,
      safeAreaTop: false, // 渐变背景延伸到状态栏，不需要 SafeArea
      safeAreaBottom: safeAreaBottom,
      child: child,
    );
  }
}
