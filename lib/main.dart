import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/constants/app_constants.dart';
import 'core/constants/app_colors.dart';
import 'core/config/image_cache_config.dart';
import 'services/api/http_client.dart';
import 'services/cache/cache_manager.dart';
import 'providers/app_provider.dart';

void main() async {
  // ========== 全局错误边界配置 ==========
  
  // 1. 捕获Flutter框架错误
  FlutterError.onError = (FlutterErrorDetails details) {
    // 开发环境打印详细错误
    FlutterError.presentError(details);
    
    // 生产环境可以上报到错误监控平台
    // 例如: Sentry.captureException(details.exception, stackTrace: details.stack);
  };
  
  // 2. 自定义错误Widget（更友好的错误界面）
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return _buildErrorWidget(details);
  };
  
  // 3. 捕获异步错误 - 将所有初始化代码都放在同一个 zone 中
  runZonedGuarded(
    () async {
      // Flutter 绑定初始化（必须在同一个 zone 中）
      WidgetsFlutterBinding.ensureInitialized();
      
      // 初始化HTTP客户端
      HttpClient().init();
      
      // 初始化缓存管理器
      await CacheManager().init();
      
      // 初始化图片缓存配置（优化性能）
      ImageCacheConfig.init();
      
      // 设置系统UI样式
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      );
      
      // 启动应用
      runApp(const MuseumSeekApp());
    },
    (error, stackTrace) {
      // 处理未捕获的异步错误
      // 开发环境打印错误
      debugPrint('Uncaught async error: $error');
      debugPrint('Stack trace: $stackTrace');
      
      // 生产环境可以上报到错误监控平台
      // 例如: Sentry.captureException(error, stackTrace: stackTrace);
    },
  );
}

/// 自定义错误Widget - 提供友好的错误提示
Widget _buildErrorWidget(FlutterErrorDetails details) {
  return Material(
    child: Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 错误图标
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            
            const SizedBox(height: 16),
            
            // 友好的错误提示
            Text(
              '页面加载出错',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              '请稍后重试或联系客服',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 开发环境显示详细错误（生产环境应该隐藏）
            if (const bool.fromEnvironment('dart.vm.product') == false) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    '${details.exception}\n\n${details.stack}',
                    style: TextStyle(
                      fontSize: 10,
                      fontFamily: 'monospace',
                      color: AppColors.error,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class MuseumSeekApp extends StatelessWidget {
  const MuseumSeekApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final provider = AppProvider();
            // 初始化时加载用户状态
            provider.init();
            return provider;
          },
        ),
      ],
      child: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          return MaterialApp.router(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            routerConfig: AppRouter.router,
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.noScaling, // 禁用系统字体缩放
                ),
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}