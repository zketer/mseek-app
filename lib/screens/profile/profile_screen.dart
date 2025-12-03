import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../providers/app_provider.dart';
import '../../../widgets/profile/profile_header.dart';
import '../../../widgets/profile/profile_stats.dart';
import '../../../widgets/profile/profile_menu.dart';
import '../../../widgets/common/app_page_wrapper.dart';

/// 我的页面 - 用户信息、统计数据、功能菜单
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // 页面加载时刷新登录状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshUserState();
    });
  }
  
  /// 刷新用户状态
  Future<void> _refreshUserState() async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    await appProvider.refreshUserState();
    // DEBUG: print('🔄 [ProfileScreen] 用户状态已刷新');
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final isLoggedIn = appProvider.isLoggedIn;
        
        return Scaffold(
          backgroundColor: AppColors.background,
          body: AppPageWrapper(
            safeAreaTop: false, // 渐变背景延伸到状态栏，不需要顶部 SafeArea
            safeAreaBottom: false, // CustomScrollView 自己处理底部
            statusBarBrightness: Brightness.light, // 渐变背景是深色，使用浅色文字
            child: CustomScrollView(
              slivers: [
                // 用户信息头部（只有这部分有渐变背景）
                SliverToBoxAdapter(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Column(
                        children: [
                          // 用户头像和基本信息
                          const ProfileHeader(),
                          
                          // 统计数据 - 传递登录状态，已包含底部间距
                          ProfileStats(isLoggedIn: isLoggedIn),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // 功能菜单
                const SliverToBoxAdapter(
                  child: ProfileMenu(),
                ),
                
                // 底部空白
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppDimensions.paddingXL),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}