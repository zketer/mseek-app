import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../screens/core/main_screen.dart';
import '../../screens/core/splash_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/discovery/discovery_screen.dart';
import '../../screens/checkin/checkin_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/discovery/museum/museum_detail_screen.dart';
import '../../screens/discovery/museum/nearby_museums_screen.dart';
import '../../screens/discovery/exhibition/exhibition_detail_screen.dart';
import '../../screens/discovery/exhibition/exhibition_list_screen.dart';
import '../../screens/discovery/museum/hot_museums_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/auth/reset_password_screen.dart';
import '../../screens/checkin/checkin_history_screen.dart';
import '../../screens/checkin/checkin_detail_screen.dart';
import '../../screens/profile/favorites_screen.dart';
import '../../screens/profile/about_screen.dart';
import '../../screens/legal/agreement_screen.dart';
import '../../screens/legal/privacy_screen.dart';
import '../../screens/legal/qualification_screen.dart';
import '../../screens/profile/feedback_screen.dart';
import '../../screens/profile/settings_screen.dart';
import '../../screens/profile/achievements_screen.dart';
import '../../screens/discovery/region/province_detail_screen.dart';
import '../../screens/discovery/region/city_detail_screen.dart';
import '../../screens/checkin/draft_list_screen.dart';
import '../../screens/checkin/checkin_action_screen.dart';
import '../constants/app_constants.dart';

/// 应用路由配置
class AppRouter {
  static final GoRouter _router = GoRouter(
    initialLocation: '/splash', // 启动时显示开屏界面
    routes: [
      // 开屏页 - 应用启动时的首个页面
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      
      // 主界面 - 包含底部导航的Shell Route
      ShellRoute(
        builder: (context, state, child) => MainScreen(child: child),
        routes: [
          // 首页
          GoRoute(
            path: AppConstants.routeHome,
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          
          // 发现页
          GoRoute(
            path: '/discovery',
            name: 'discovery',
            builder: (context, state) => const DiscoveryScreen(),
          ),
          
          // 打卡页
          GoRoute(
            path: '/checkin',
            name: 'checkin',
            builder: (context, state) => const CheckinScreen(),
          ),
          
          // 我的页面
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      
      // 博物馆详情页 - 全屏页面，使用路径参数
      GoRoute(
        path: '/museum/:id',
        name: 'museum-detail',
        builder: (context, state) {
          final museumId = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
          return MuseumDetailScreen(museumId: museumId);
        },
      ),
      
      // 展览详情页
      GoRoute(
        path: AppConstants.routeExhibitionDetail,
        name: 'exhibition-detail',
        builder: (context, state) {
          final exhibitionId = int.tryParse(state.uri.queryParameters['id'] ?? '') ?? 0;
          return ExhibitionDetailScreen(exhibitionId: exhibitionId);
        },
      ),
      
      // 展览列表页（最新展览）
      GoRoute(
        path: '/latest_exhibitions',
        name: 'latest-exhibitions',
        builder: (context, state) {
          return const ExhibitionListScreen(title: '最新展览');
        },
      ),
      
      // 热门博物馆列表页
      GoRoute(
        path: '/hot_museums',
        name: 'hot-museums',
        builder: (context, state) {
          return const HotMuseumsScreen();
        },
      ),
      
      // 登录页面
      GoRoute(
        path: AppConstants.routeLogin,
        name: 'login',
        builder: (context, state) {
          // 获取重定向URL参数
          final redirectUrl = state.uri.queryParameters['redirect'];
          return LoginScreen(redirectUrl: redirectUrl);
        },
      ),
      
      // 注册页面
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      
      // 重置密码页面
      GoRoute(
        path: '/reset-password',
        name: 'reset-password',
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      
      // 搜索页面
      GoRoute(
        path: AppConstants.routeSearch,
        name: 'search',
        builder: (context, state) {
          // TODO: 创建搜索页面
          return Scaffold(
            appBar: AppBar(title: const Text('搜索')),
            body: const Center(
              child: Text('搜索页面'),
            ),
          );
        },
      ),

      // 同城博物馆页面
      GoRoute(
        path: '/nearby-museums',
        name: 'nearby-museums',
        builder: (context, state) => const NearbyMuseumsScreen(),
      ),
      
      // 收藏夹
      GoRoute(
        path: AppConstants.routeFavorites,
        name: 'favorites',
        builder: (context, state) => const FavoritesScreen(),
      ),
      
      // 打卡历史
      GoRoute(
        path: AppConstants.routeHistory,
        name: 'history',
        builder: (context, state) => const CheckinHistoryScreen(),
      ),
      
      // 打卡详情
      GoRoute(
        path: '/checkin/detail/:id',
        name: 'checkin-detail',
        builder: (context, state) {
          final checkinId = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
          return CheckinDetailScreen(checkinId: checkinId);
        },
      ),
      
      // 暂存草稿列表
      GoRoute(
        path: '/drafts',
        name: 'drafts',
        builder: (context, state) => const DraftListScreen(),
      ),
      
      // 打卡操作页面
      GoRoute(
        path: '/checkin/action/:museumId',
        name: 'checkin-action',
        builder: (context, state) {
          final museumId = int.tryParse(state.pathParameters['museumId'] ?? '0') ?? 0;
          final draftId = state.uri.queryParameters['draftId'] != null 
              ? int.tryParse(state.uri.queryParameters['draftId']!) 
              : null;
          return CheckinActionScreen(
            museumId: museumId,
            draftId: draftId,
          );
        },
      ),
      
      // 省份详情
      GoRoute(
        path: '/province/:provinceCode',
        name: 'province-detail',
        builder: (context, state) {
          final provinceCode = state.pathParameters['provinceCode'] ?? '';
          return ProvinceDetailScreen(provinceCode: provinceCode);
        },
      ),
      
      // 城市详情
      GoRoute(
        path: '/city/:cityName',
        name: 'city-detail',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          
          // 优先从 extra 参数获取城市名称（避免 URL 编码问题）
          String cityName = extra?['cityName'] as String? ?? '';
          
          // 如果 extra 中没有，则从路径参数获取
          if (cityName.isEmpty) {
            final pathCityName = state.pathParameters['cityName'] ?? '';
            cityName = pathCityName.replaceAll('-', '/'); // 还原斜杠
          }
          
          return CityDetailScreen(
            provinceCode: extra?['provinceCode'] ?? '',
            provinceName: extra?['provinceName'] ?? '',
            cityName: cityName,
          );
        },
      ),
      
      // 成就页面
      GoRoute(
        path: AppConstants.routeAchievements,
        name: 'achievements',
        builder: (context, state) => const AchievementsScreen(),
      ),
      
      // 设置页面
      GoRoute(
        path: AppConstants.routeSettings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      
      // 关于我们页面
      GoRoute(
        path: '/about',
        name: 'about',
        builder: (context, state) => const AboutScreen(),
      ),

      // 法务与合规模块
      GoRoute(
        path: AppConstants.routeQualification,
        name: 'qualification',
        builder: (context, state) => const QualificationScreen(),
      ),
      GoRoute(
        path: AppConstants.routeAgreement,
        name: 'agreement',
        builder: (context, state) => const AgreementScreen(),
      ),
      GoRoute(
        path: AppConstants.routePrivacy,
        name: 'privacy',
        builder: (context, state) => const PrivacyScreen(),
      ),

      // 反馈建议
      GoRoute(
        path: AppConstants.routeFeedback,
        name: 'feedback',
        builder: (context, state) => const FeedbackScreen(),
      ),
    ],
    
    // 错误处理
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('页面未找到')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('页面未找到'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(AppConstants.routeHome),
              child: const Text('返回首页'),
            ),
          ],
        ),
      ),
    ),
  );

  static GoRouter get router => _router;
}
