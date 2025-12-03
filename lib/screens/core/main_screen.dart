import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/preload_manager.dart';
import '../../widgets/common/toast_widget.dart';

/// 主界面 - 包含底部导航栏
class MainScreen extends StatefulWidget {
  final Widget child;

  const MainScreen({
    super.key,
    required this.child,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  
  // Tab访问历史栈
  final List<int> _tabHistory = [0];
  
  // 双击退出相关
  DateTime? _lastPressedAt;

  // 底部导航项配置
  final List<BottomNavigationBarItem> _navItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home),
      label: '首页',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.explore_outlined),
      activeIcon: Icon(Icons.explore),
      label: '发现',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.location_on_outlined),
      activeIcon: Icon(Icons.location_on),
      label: '打卡',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.person_outline),
      activeIcon: Icon(Icons.person),
      label: '我的',
    ),
  ];

  // 路由路径
  final List<String> _routes = [
    '/',
    '/discovery',
    '/checkin',
    '/profile',
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // 拦截返回键，自定义处理
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBackPress();
      },
      child: Scaffold(
        body: widget.child,
        bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(
              color: AppColors.divider,
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            height: AppDimensions.tabBarHeight,
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: AppColors.accent,
              unselectedItemColor: AppColors.secondary,
              selectedLabelStyle: AppTextStyles.tabSelected,
              unselectedLabelStyle: AppTextStyles.tabUnselected,
              iconSize: AppDimensions.tabIconSize,
              items: _navItems,
              onTap: _onTabTapped,
            ),
          ),
        ),
      ),
      ),
    );
  }

  /// 处理返回键
  Future<void> _handleBackPress() async {
    // 如果当前在首页，直接触发双击退出逻辑
    if (_currentIndex == 0) {
      // 已在首页，显示"再按一次退出"提示
      final now = DateTime.now();
      if (_lastPressedAt == null || 
          now.difference(_lastPressedAt!) > const Duration(seconds: 2)) {
        // 首次按下或距离上次按下超过2秒
        _lastPressedAt = now;
        
        if (mounted) {
          ToastWidget.showInfo(context, '再按一次退出');
        }
      } else {
        // 2秒内再次按下，退出应用
        SystemNavigator.pop();
      }
    } else if (_tabHistory.length > 1) {
      // 不在首页且历史栈有记录，返回到上一个Tab
      _tabHistory.removeLast();
      final previousIndex = _tabHistory.last;
      
      setState(() {
        _currentIndex = previousIndex;
      });
      
      // 导航到上一个Tab
      context.go(_routes[previousIndex]);
    } else {
      // 不在首页但历史栈为空（异常情况），回到首页
      setState(() {
        _currentIndex = 0;
      });
      context.go(_routes[0]);
    }
  }

  /// 处理底部导航栏点击
  void _onTabTapped(int index) {
    if (index != _currentIndex) {
      setState(() {
        _currentIndex = index;
      });
      
      // 将新的Tab索引添加到历史栈
      // 如果已经存在，先移除再添加（避免重复）
      _tabHistory.remove(index);
      _tabHistory.add(index);
      
      // 在后台预加载即将访问的页面数据（不阻塞导航）
      _preloadPageData(index);
      
      // 导航到对应页面
      context.go(_routes[index]);
    }
  }

  /// 预加载页面数据（异步，不阻塞UI）
  void _preloadPageData(int index) {
    // 在后台异步预加载，不等待完成
    Future.microtask(() async {
      try {
        await PreloadManager().preloadTabData(index);
      } catch (e) {
        debugPrint('预加载Tab $index 数据失败: $e');
      }
    });
  }

  /// 根据当前路由更新选中状态
  void _updateCurrentIndex(String path) {
    final index = _routes.indexOf(path);
    if (index != -1 && index != _currentIndex) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // 监听路由变化，更新底部导航栏选中状态
    final currentPath = GoRouterState.of(context).uri.path;
    _updateCurrentIndex(currentPath);
  }
}
