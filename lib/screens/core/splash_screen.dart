import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/preload_manager.dart';

/// 启动页 - 应用启动时的开屏界面
/// 
/// 功能：
/// 1. 显示品牌Logo和欢迎信息
/// 2. 预加载缓存数据（可选）
/// 3. 检查登录状态
/// 4. 完成后自动跳转到首页
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // 初始化动画
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );
    
    // 启动动画
    _animationController.forward();
    
    // 开始初始化流程
    _initialize();
  }

  /// 初始化流程
  Future<void> _initialize() async {
    try {
      // 最小显示时间2秒（确保用户能看到Logo）
      final minimumDisplayTime = Future.delayed(const Duration(seconds: 2));
      
      // 执行初始化任务
      final initTasks = Future.wait([
        _preloadData(),
        _checkLoginStatus(),
      ]);
      
      // 等待所有任务完成，但至少显示2秒
      await Future.wait([minimumDisplayTime, initTasks]);
      
      // 初始化完成，跳转到首页
      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      // 即使出错也跳转到首页
      debugPrint('启动页初始化错误: $e');
      if (mounted) {
        context.go('/');
      }
    }
  }

  /// 预加载数据 - 使用预加载管理器
  Future<void> _preloadData() async {
    try {
      // 使用预加载管理器加载核心数据
      // 包括：轮播图、热门博物馆、最新展览、公告
      await PreloadManager().preloadCoreData();
      
      // 可选：预加载发现页数据（如果用户经常使用）
      // await PreloadManager().preloadDiscoveryData();
    } catch (e) {
      debugPrint('预加载数据失败: $e');
    }
  }

  /// 检查登录状态
  Future<void> _checkLoginStatus() async {
    try {
      // 检查是否有登录token
      // 这里可以添加自动登录逻辑
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      debugPrint('检查登录状态失败: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryLight,
              AppColors.primaryDark,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              
              // Logo和标题动画
              FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    children: [
                      // Logo图标
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.museum,
                          size: 64,
                          color: AppColors.primary,
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // 应用名称
                      Text(
                        AppConstants.appName,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // 副标题
                      Text(
                        '探索文化 · 记录足迹',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.9),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const Spacer(flex: 3),
              
              // 加载指示器
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 3,
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '正在加载...',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}

