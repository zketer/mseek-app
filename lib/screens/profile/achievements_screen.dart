import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/bottom_sheet_helper.dart';
import '../../../services/api/achievements_service.dart';
import '../../../services/auth/auth_service.dart';
import '../../../widgets/common/common_app_bar.dart';

// 本地分类数据模型（用于UI展示）
// ignore_for_file: unused_element_parameter
class _LocalAchievementCategory {
  final String id;
  final String name;
  int count;
  int unlockedCount;

  _LocalAchievementCategory({
    required this.id,
    required this.name,
    this.count = 0,
    this.unlockedCount = 0,
  });
}

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({Key? key}) ;

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final _achievementsService = AchievementsService();
  final _authService = AuthService();
  
  String _selectedCategory = 'all';
  
  // 数据状态
  List<_LocalAchievementCategory> _categories = [];
  List<Achievement> _achievements = [];
  
  // UI状态
  bool _isLoading = false;
  String? _errorMessage;
  
  // 统计信息
  int _totalAchievements = 0;
  int _unlockedAchievements = 0;
  int _completionRate = 0;

  @override
  void initState() {
    super.initState();
    _initializeCategories();
    _loadAchievements();
  }

  /// 初始化分类
  void _initializeCategories() {
    _categories = [
      _LocalAchievementCategory(id: 'all', name: '全部'),
      _LocalAchievementCategory(id: 'checkin', name: '打卡成就'),
      _LocalAchievementCategory(id: 'explore', name: '探索成就'),
      _LocalAchievementCategory(id: 'social', name: '社交成就'),
      _LocalAchievementCategory(id: 'special', name: '特殊成就'),
    ];
  }

  /// 加载成就数据
  Future<void> _loadAchievements() async {
    // 检查登录状态
    if (!(await _authService.isLoggedIn())) {
      _showLoginDialog();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 从API获取成就数据
      final achievements = await _achievementsService.getUserAchievements();
      
      setState(() {
        _achievements = achievements;
        _isLoading = false;
      });
      
      // 计算统计信息
      _calculateStats();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '加载成就数据失败: ${e.toString()}';
      });
      
      // 不显示错误提示
    }
  }

  /// 显示登录对话框
  Future<void> _showLoginDialog() async {
    final confirmed = await BottomSheetHelper.showConfirm(
      context,
      title: '需要登录',
      content: '成就徽章功能需要登录后使用，是否前往登录？',
      confirmText: '去登录',
      cancelText: '取消',
      icon: Icons.lock_outline,
    );
    
    if (confirmed == true) {
      if (!mounted) return;
      context.go('/login');
    } else {
      if (!mounted) return;
      context.go('/profile');
    }
  }

  void _calculateStats() {
    if (_achievements.isEmpty) {
      setState(() {
        _totalAchievements = 0;
        _unlockedAchievements = 0;
        _completionRate = 0;
      });
      return;
    }

    final totalCount = _achievements.length;
    final unlockedCount = _achievements.where((a) => a.unlocked).length;
    final completionRate = ((unlockedCount / totalCount) * 100).round();

    // 更新分类统计
    for (var cat in _categories) {
      if (cat.id == 'all') {
        cat.count = totalCount;
        cat.unlockedCount = unlockedCount;
      } else {
        final categoryAchievements = _achievements.where((a) => a.category == cat.id).toList();
        cat.count = categoryAchievements.length;
        cat.unlockedCount = categoryAchievements.where((a) => a.unlocked).length;
      }
    }

    setState(() {
      _totalAchievements = totalCount;
      _unlockedAchievements = unlockedCount;
      _completionRate = completionRate;
    });
  }

  List<Achievement> _getFilteredAchievements() {
    if (_selectedCategory == 'all') {
      return _achievements;
    }
    return _achievements.where((a) => a.category == _selectedCategory).toList();
  }

  Color _getRarityColor(String rarity) {
    switch (rarity) {
      case 'rare':
        return AppColors.successDark; // 绿色
      case 'epic':
        return AppColors.linkVisited; // 紫色
      case 'legendary':
        return AppColors.warningDark; // 橙色
      default:
        return Colors.grey;
    }
  }

  Future<void> _onAchievementTap(Achievement achievement) async {
    final progressText = achievement.unlocked
        ? '🎉 已解锁\n解锁时间：${achievement.unlockedDate}'
        : '进度：${achievement.progress}/${achievement.target}\n${achievement.requirement}';

    await BottomSheetHelper.showInfo(
      context,
      title: '${achievement.icon} ${achievement.name}',
      content: '${achievement.description}\n\n$progressText',
      buttonText: '知道了',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CommonAppBar.simple(title: '成就徽章'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryLight))
          : _achievements.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    // 成就概览
                    _buildAchievementHeader(),
                    
                    // 分类标签
                    _buildCategoryTabs(),
                    
                    // 成就列表
                    Expanded(
                      child: _buildAchievementsGrid(),
                    ),
                  ],
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.military_tech,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? '暂无成就数据',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadAchievements,
            child: const Text('重新加载'),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppDimensions.paddingM,
        0, // 完全去掉顶部边距，紧贴导航栏
        AppDimensions.paddingM,
        0,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingM,
        vertical: AppDimensions.paddingL,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark], // 更新为鲜艳粉色
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // 统计数据
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatItem(_unlockedAchievements.toString(), '已解锁'),
              _buildDivider(),
              _buildStatItem(_totalAchievements.toString(), '总成就'),
              _buildDivider(),
              _buildStatItem('$_completionRate%', '完成度'),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 进度条
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: _completionRate / 100,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String number, String label) {
    return Column(
      children: [
        Text(
          number,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      color: Colors.white.withValues(alpha: 0.3),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.paddingM,
        AppDimensions.paddingM,
        AppDimensions.paddingM,
        AppDimensions.paddingS,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _categories.map((cat) {
            final isSelected = _selectedCategory == cat.id;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = cat.id;
                });
              },
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      cat.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? AppColors.primary : Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${cat.unlockedCount}/${cat.count})',
                      style: TextStyle(
                        fontSize: 11,
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.8)
                            : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAchievementsGrid() {
    final filteredAchievements = _getFilteredAchievements();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: GridView.builder(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.28,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: filteredAchievements.length,
        itemBuilder: (context, index) {
          final achievement = filteredAchievements[index];
          return _buildAchievementCard(achievement);
        },
      ),
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    final isLocked = !achievement.unlocked;
    final hasRarity = achievement.rarity != 'common';
    final rarityColor = _getRarityColor(achievement.rarity);

    return GestureDetector(
      onTap: () => _onAchievementTap(achievement),
      child: Container(
        decoration: BoxDecoration(
          color: isLocked ? AppColors.backgroundLight : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: hasRarity && !isLocked
              ? Border.all(color: rarityColor, width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: hasRarity && !isLocked && achievement.rarity == 'legendary'
                  ? rarityColor.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // 稀有度渐变背景
            if (hasRarity && !isLocked)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.transparent,
                        rarityColor.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            
            // 主内容
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 图标
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      isLocked ? '🔒' : achievement.icon,
                      style: TextStyle(
                        fontSize: 28,
                        color: isLocked ? Colors.grey : null,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  const SizedBox(height: 5),
                  
                  // 成就名称
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      achievement.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isLocked ? Colors.grey : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  const SizedBox(height: 3),
                  
                  // 描述
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      achievement.description,
                      style: TextStyle(
                        fontSize: 11,
                        color: isLocked ? Colors.grey[400] : Colors.black54,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  const SizedBox(height: 5),
                  
                  // 进度信息或解锁时间
                  if (isLocked) ...[
                    // 进度文字
                    SizedBox(
                      width: double.infinity,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              achievement.requirement,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${achievement.progress}/${achievement.target}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 3),
                    // 进度条
                    SizedBox(
                      width: double.infinity,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(1),
                        child: LinearProgressIndicator(
                          value: achievement.progress / achievement.target,
                          backgroundColor: AppColors.backgroundDark,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                          minHeight: 2,
                        ),
                      ),
                    ),
                  ] else ...[
                    SizedBox(
                      width: double.infinity,
                      child: Text(
                        '${achievement.unlockedDate} 解锁',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.successDark,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // 稀有度标签
            if (hasRarity)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: rarityColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    achievement.rarityText,
                    style: const TextStyle(
                      fontSize: 9,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            
            // 解锁效果
            if (!isLocked)
              Positioned(
                top: 4,
                left: 4,
                child: _buildSparkleEffect(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSparkleEffect() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.7, end: 1.0),
      duration: const Duration(seconds: 2),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: 1 + (value - 0.7) * 0.5,
            child: const Text(
              '✨',
              style: TextStyle(fontSize: 10),
            ),
          ),
        );
      },
      onEnd: () {
        if (mounted) {
          setState(() {}); // 重启动画
        }
      },
    );
  }
}

