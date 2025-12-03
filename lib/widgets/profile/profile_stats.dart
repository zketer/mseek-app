import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';
import '../../services/api/user_stats_service.dart';

/// 我的页面统计数据组件
class ProfileStats extends StatefulWidget {
  final bool isLoggedIn;
  
  const ProfileStats({
    super.key,
    required this.isLoggedIn,
  });

  @override
  State<ProfileStats> createState() => _ProfileStatsState();
}

class _ProfileStatsState extends State<ProfileStats> {
  final _userStatsService = UserStatsService();
  UserStats? _userStats;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserStats();
  }

  @override
  void didUpdateWidget(ProfileStats oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当登录状态改变时重新加载统计数据
    if (oldWidget.isLoggedIn != widget.isLoggedIn) {
      _loadUserStats();
    }
  }

  /// 加载用户统计数据
  Future<void> _loadUserStats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final stats = await _userStatsService.getUserStats();
      if (mounted) {
        setState(() {
          _userStats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      // DEBUG: print('加载用户统计数据失败: $e');
      if (mounted) {
        setState(() {
          _userStats = UserStats.empty();
          _isLoading = false;
        });
      }
    }
  }

  // 获取统计数据 - 根据登录状态和API数据显示
  List<StatItem> get _stats {
    final stats = _userStats ?? UserStats.empty();
    
    if (widget.isLoggedIn && _userStats != null) {
      // 已登录且有数据 - 显示真实统计数据
      return [
        StatItem(title: '打卡', value: '${stats.totalCheckins}', action: 'checkins'),
        StatItem(title: '积分', value: '${stats.points}', action: 'points'), 
        StatItem(title: '收藏', value: '${stats.totalFavorites}', action: 'favorites'),
        StatItem(title: '排名', value: '${stats.rank}', action: 'rank'),
      ];
    } else {
      // 未登录或数据加载中 - 显示0，与小程序保持一致
      return const [
        StatItem(title: '打卡', value: '0', action: 'checkins'),
        StatItem(title: '积分', value: '0', action: 'points'), 
        StatItem(title: '收藏', value: '0', action: 'favorites'),
        StatItem(title: '排名', value: '0', action: 'rank'),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppDimensions.paddingM,
        0,
        AppDimensions.paddingM, 
        AppDimensions.paddingL, // 底部间距，避免与下方内容重合
      ),
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.textWhite.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(
          color: AppColors.textWhite.withValues(alpha: 0.2),
        ),
      ),
      child: _isLoading
          ? const Center(
              child: SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _stats.map((stat) => _buildStatItem(context, stat)).toList(),
            ),
    );
  }

  /// 构建统计项 - 与小程序保持一致的纯数字显示
  Widget _buildStatItem(BuildContext context, StatItem stat) {
    return GestureDetector(
      onTap: () => _onStatTapped(context, stat),
      child: Column(
        children: [
          Text(
            stat.value,
            style: AppTextStyles.headlineLarge.copyWith(
              color: AppColors.textWhite,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            stat.title,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textWhite.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  /// 处理统计项点击 - 与小程序保持一致
  void _onStatTapped(BuildContext context, StatItem stat) {
    switch (stat.action) {
      case 'checkins':
        // 跳转到打卡历史页面
        context.go('/checkin-history');
        break;
      case 'points':
        // 积分页面暂未实现，显示提示
        _showComingSoon(context, '积分功能');
        break;
      case 'favorites':
        // 跳转到收藏页面
        context.go('/favorites');
        break;
      case 'rank':
        // 排行榜页面暂未实现，显示提示
        _showComingSoon(context, '排行榜功能');
        break;
    }
  }

  /// 显示功能开发中提示
  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('提示'),
        content: Text('$feature 正在开发中，敬请期待！'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

/// 统计项数据模型
class StatItem {
  final String title;
  final String value;
  final String action;

  const StatItem({
    required this.title,
    required this.value,
    required this.action,
  });
}
