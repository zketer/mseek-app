import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../widgets/common/common_app_bar.dart';
import '../../../widgets/common/modern_dialog.dart';
import '../../../services/api/favorites_service.dart';
import '../../../services/auth/auth_service.dart';
import '../../../core/utils/ui_helper.dart';
import '../../../core/utils/bottom_sheet_helper.dart';

/// 收藏页面
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  final _favoritesService = FavoritesService();
  final _authService = AuthService();
  
  late TabController _tabController;
  
  // 数据状态
  List<FavoriteMuseum> _favoriteMuseums = [];
  List<FavoriteExhibition> _favoriteExhibitions = [];
  FavoriteStats _favoriteStats = FavoriteStats.empty();
  
  // UI状态
  bool _isLoading = false;
  String _museumFilter = 'all'; // all | visited | unvisited
  String _exhibitionFilter = 'all'; // all | ongoing | upcoming | ended
  
  // 分页
  int _museumPage = 1;
  int _exhibitionPage = 1;
  bool _hasMoreMuseums = true;
  bool _hasMoreExhibitions = true;
  
  // 控制器
  final _museumScrollController = ScrollController();
  final _exhibitionScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _museumScrollController.addListener(_onMuseumScroll);
    _exhibitionScrollController.addListener(_onExhibitionScroll);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _museumScrollController.dispose();
    _exhibitionScrollController.dispose();
    super.dispose();
  }

  /// 加载初始数据
  Future<void> _loadInitialData() async {
    if (!(await _authService.isLoggedIn())) {
      _showLoginDialog();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await Future.wait([
        _loadFavoriteStats(),
        _loadFavoriteMuseums(refresh: true),
        _loadFavoriteExhibitions(refresh: true),
      ]);
    } catch (e) {
      _showErrorSnackBar('加载数据失败: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 加载收藏统计
  Future<void> _loadFavoriteStats() async {
    try {
      final stats = await _favoritesService.getUserFavoriteStats();
      if (mounted) {
        setState(() {
          _favoriteStats = stats;
        });
      }
    } catch (e) {
      // DEBUG: print('加载收藏统计失败: $e');
    }
  }

  /// 加载收藏博物馆
  Future<void> _loadFavoriteMuseums({bool refresh = false}) async {
    if (refresh) {
      _museumPage = 1;
      _hasMoreMuseums = true;
      _favoriteMuseums.clear();
    }

    if (!_hasMoreMuseums) return;

    try {
      bool? visitStatus;
      if (_museumFilter == 'visited') visitStatus = true;
      if (_museumFilter == 'unvisited') visitStatus = false;

      final result = await _favoritesService.getUserFavoriteMuseums(
        page: _museumPage,
        pageSize: 10,
        visitStatus: visitStatus,
      );

      if (mounted) {
        setState(() {
          if (refresh) {
            _favoriteMuseums = result.records;
          } else {
            _favoriteMuseums.addAll(result.records);
          }
          
          _museumPage++;
          _hasMoreMuseums = result.records.length >= 10;
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('加载博物馆收藏失败: ${e.toString()}');
      }
    }
  }

  /// 加载收藏展览
  Future<void> _loadFavoriteExhibitions({bool refresh = false}) async {
    if (refresh) {
      _exhibitionPage = 1;
      _hasMoreExhibitions = true;
      _favoriteExhibitions.clear();
    }

    if (!_hasMoreExhibitions) return;

    try {
      int? status;
      if (_exhibitionFilter == 'ongoing') status = 1;
      if (_exhibitionFilter == 'upcoming') status = 2;
      if (_exhibitionFilter == 'ended') status = 0;
      
      final result = await _favoritesService.getUserFavoriteExhibitions(
        page: _exhibitionPage,
        pageSize: 10,
        status: status,
      );

      if (mounted) {
        setState(() {
          if (refresh) {
            _favoriteExhibitions = result.records;
          } else {
            _favoriteExhibitions.addAll(result.records);
          }
          
          _exhibitionPage++;
          _hasMoreExhibitions = result.records.length >= 10;
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('加载展览收藏失败: ${e.toString()}');
      }
    }
  }

  /// 博物馆滚动监听
  void _onMuseumScroll() {
    if (_museumScrollController.position.pixels >= 
        _museumScrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMoreMuseums) {
        _loadFavoriteMuseums();
      }
    }
  }

  /// 展览滚动监听
  void _onExhibitionScroll() {
    if (_exhibitionScrollController.position.pixels >= 
        _exhibitionScrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMoreExhibitions) {
        _loadFavoriteExhibitions();
      }
    }
  }

  /// 展览筛选切换
  void _onExhibitionFilterChange(String filter) {
    setState(() {
      _exhibitionFilter = filter;
    });
    _loadFavoriteExhibitions(refresh: true);
  }

  /// 取消收藏博物馆
  void _onUnfavoriteMuseum(FavoriteMuseum museum) async {
    final confirmed = await ModernDialog.showConfirm(
      context,
      title: '取消收藏',
      content: '确定要取消收藏「${museum.name}」吗？',
      cancelText: '取消',
      confirmText: '确定',
      icon: Icons.star_border,
      iconColor: AppColors.warningLight,
    );
    
    if (confirmed == true) {
      await _unfavoriteMuseum(museum.id);
    }
  }

  /// 执行取消收藏博物馆
  Future<void> _unfavoriteMuseum(int museumId) async {
    try {
      final success = await _favoritesService.unfavoriteMuseum(museumId);
      if (success) {
        setState(() {
          _favoriteMuseums.removeWhere((museum) => museum.id == museumId);
          _favoriteStats = FavoriteStats(
            museumCount: _favoriteStats.museumCount - 1,
            exhibitionCount: _favoriteStats.exhibitionCount,
          );
        });
        _showSuccessSnackBar('取消收藏成功');
      } else {
        _showErrorSnackBar('取消收藏失败');
      }
    } catch (e) {
      _showErrorSnackBar('取消收藏失败: ${e.toString()}');
    }
  }

  /// 取消收藏展览
  Future<void> _onUnfavoriteExhibition(FavoriteExhibition exhibition) async {
    final confirmed = await BottomSheetHelper.showConfirm(
      context,
      title: '取消收藏',
      content: '确定要取消收藏「${exhibition.title}」吗？',
      confirmText: '取消收藏',
      cancelText: '再想想',
      icon: Icons.heart_broken,
    );
    
    if (confirmed == true) {
      await _unfavoriteExhibition(exhibition.id);
    }
  }

  /// 执行取消收藏展览
  Future<void> _unfavoriteExhibition(int exhibitionId) async {
    try {
      final success = await _favoritesService.unfavoriteExhibition(exhibitionId);
      if (success) {
        setState(() {
          _favoriteExhibitions.removeWhere((exhibition) => exhibition.id == exhibitionId);
          _favoriteStats = FavoriteStats(
            museumCount: _favoriteStats.museumCount,
            exhibitionCount: _favoriteStats.exhibitionCount - 1,
          );
        });
        _showSuccessSnackBar('取消收藏成功');
      } else {
        _showErrorSnackBar('取消收藏失败');
      }
    } catch (e) {
      _showErrorSnackBar('取消收藏失败: ${e.toString()}');
    }
  }

  /// 显示登录对话框
  Future<void> _showLoginDialog() async {
    final confirmed = await BottomSheetHelper.showConfirm(
      context,
      title: '需要登录',
      content: '请先登录后再查看收藏',
      confirmText: '去登录',
      cancelText: '取消',
      icon: Icons.lock_outline,
    );
    
    if (confirmed == true) {
      if (!mounted) return;
      context.go('/login');
    }
  }

  /// 显示错误提示
  void _showErrorSnackBar(String message) {
    UIHelper.showError(context, message);
  }

  /// 显示成功提示
  void _showSuccessSnackBar(String message) {
    UIHelper.showSuccess(context, message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CommonAppBar.simple(
        title: '我的收藏',
      ),
      body: Column(
        children: [
          // 统计概览（包含Tab切换）
          _buildStatsHeader(),
          
          // Tab内容
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 博物馆收藏
                _buildMuseumsView(),
                // 展览收藏
                _buildExhibitionsView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建统计头部
  Widget _buildStatsHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppDimensions.paddingM,
        0, // 完全去掉顶部边距
        AppDimensions.paddingM,
        AppDimensions.paddingM,
      ),
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
      ),
      child: Column(
        children: [
          // 统计数据
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('博物馆', '${_favoriteStats.museumCount}'),
              _buildStatDivider(),
              _buildStatItem('展览', '${_favoriteStats.exhibitionCount}'),
              _buildStatDivider(),
              _buildStatItem('总收藏', '${_favoriteStats.totalCount}'),
            ],
          ),
          
          const SizedBox(height: AppDimensions.paddingM),
          
          // 进度条 (按总收藏数显示进度，最多100%)
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (_favoriteStats.totalCount * 10).clamp(0, 100) / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Tab切换（在概览卡片内）
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(11),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.white,
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(text: '博物馆'),
                Tab(text: '展览'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建统计项
  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.headlineMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }

  /// 构建统计分割线
  Widget _buildStatDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.white.withValues(alpha: 0.3),
    );
  }

  /// 构建博物馆视图
  Widget _buildMuseumsView() {
    return Column(
      children: [
        // 博物馆列表
        Expanded(
          child: _isLoading && _favoriteMuseums.isEmpty
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryLight))
              : _favoriteMuseums.isEmpty
                  ? _buildEmptyState('暂无收藏的博物馆')
                  : ListView.separated(
                      controller: _museumScrollController,
                      padding: const EdgeInsets.all(AppDimensions.paddingM),
                      itemCount: _favoriteMuseums.length + (_hasMoreMuseums ? 1 : 0),
                      separatorBuilder: (context, index) => 
                          const SizedBox(height: AppDimensions.paddingS),
                      itemBuilder: (context, index) {
                        if (index == _favoriteMuseums.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(AppDimensions.paddingM),
                              child: CircularProgressIndicator(color: AppColors.primaryLight),
                            ),
                          );
                        }
                        return _buildMuseumCard(_favoriteMuseums[index]);
                      },
                    ),
        ),
      ],
    );
  }

  /// 构建展览视图
  Widget _buildExhibitionsView() {
    return Column(
      children: [
        // 筛选栏
        _buildExhibitionFilterBar(),
        
        // 展览列表
        Expanded(
          child: _isLoading && _favoriteExhibitions.isEmpty
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryLight))
              : _favoriteExhibitions.isEmpty
                  ? _buildEmptyState('暂无收藏的展览')
                  : ListView.separated(
                      controller: _exhibitionScrollController,
                      padding: const EdgeInsets.all(AppDimensions.paddingM),
                      itemCount: _favoriteExhibitions.length + (_hasMoreExhibitions ? 1 : 0),
                      separatorBuilder: (context, index) => 
                          const SizedBox(height: AppDimensions.paddingS),
                      itemBuilder: (context, index) {
                        if (index == _favoriteExhibitions.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(AppDimensions.paddingM),
                              child: CircularProgressIndicator(color: AppColors.primaryLight),
                            ),
                          );
                        }
                        return _buildExhibitionCard(_favoriteExhibitions[index]);
                      },
                    ),
        ),
      ],
    );
  }

  /// 构建展览筛选栏
  Widget _buildExhibitionFilterBar() {
    return Container(
      margin: const EdgeInsets.all(AppDimensions.paddingM),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('全部', 'all', _exhibitionFilter, _onExhibitionFilterChange),
            const SizedBox(width: AppDimensions.paddingS),
            _buildFilterChip('进行中', 'ongoing', _exhibitionFilter, _onExhibitionFilterChange),
            const SizedBox(width: AppDimensions.paddingS),
            _buildFilterChip('即将开始', 'upcoming', _exhibitionFilter, _onExhibitionFilterChange),
            const SizedBox(width: AppDimensions.paddingS),
            _buildFilterChip('已结束', 'ended', _exhibitionFilter, _onExhibitionFilterChange),
          ],
        ),
      ),
    );
  }

  /// 构建筛选标签
  Widget _buildFilterChip(String label, String value, String currentValue, Function(String) onChanged) {
    final isSelected = currentValue == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingM,
          vertical: AppDimensions.paddingXS,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  /// 构建博物馆卡片
  Widget _buildMuseumCard(FavoriteMuseum museum) {
    return GestureDetector(
      onTap: () => context.push('/museum/${museum.id}'),
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 博物馆图片
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                  child: SizedBox(
                    width: double.infinity,
                    height: 180,
                    child: CachedNetworkImage(
                      imageUrl: museum.images?.first ?? '',
                      fit: BoxFit.cover,
                      memCacheWidth: 800, // 限制内存缓存尺寸（卡片优化）
                      memCacheHeight: 360, // 限制内存缓存尺寸（180px * 2 = 360）
                      placeholder: (context, url) => Container(
                        color: AppColors.backgroundDark,
                        child: const Center(
                          child: Icon(Icons.museum, size: 50, color: AppColors.textDisabled),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.backgroundDark,
                        child: const Center(
                          child: Icon(Icons.museum, size: 50, color: AppColors.textDisabled),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // 收藏按钮（右上角星星）
                Positioned(
                  top: 6,
                  right: 10,
                  child: GestureDetector(
                    onTap: () => _onUnfavoriteMuseum(museum),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.star,
                        color: AppColors.warningLight,
                        size: 16,
                      ),
                    ),
                  ),
                ),
                
                // 已打卡标签（右上角）
                if (museum.isVisited)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.successDark,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '已打卡',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            
            // 博物馆信息
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 博物馆名称
                  Text(
                    museum.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // 位置信息（红色）
                  Text(
                    '${museum.cityName} · ${museum.provinceName}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // 详细地址（灰色）
                  Text(
                    museum.address,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textHint,
                      height: 1.4,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // 标签（橙色、蓝色、绿色）
                  Row(
                    children: [
                      // 等级标签（橙色）
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.warningDark,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          museum.level,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 4),
                      
                      // 分类标签（蓝色）
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.infoDark,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          museum.category,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 4),
                      
                      // 价格标签（绿色）
                      if (museum.ticketPrice != null && museum.ticketPrice!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.successDark,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            museum.ticketPrice!,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建展览卡片
  Widget _buildExhibitionCard(FavoriteExhibition exhibition) {
    Color statusColor;
    switch (exhibition.status) {
      case 'ongoing':
        statusColor = AppColors.successDark; // 绿色
        break;
      case 'upcoming':
        statusColor = AppColors.infoDark; // 蓝色
        break;
      case 'ended':
        statusColor = AppColors.textHint; // 灰色
        break;
      default:
        statusColor = AppColors.textHint;
    }

    return GestureDetector(
      onTap: () => context.push('/exhibition/${exhibition.id}'),
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 展览图片
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                  child: SizedBox(
                    width: double.infinity,
                    height: 160,
                    child: CachedNetworkImage(
                      imageUrl: exhibition.images?.first ?? '',
                      fit: BoxFit.cover,
                      memCacheWidth: 800, // 限制内存缓存尺寸（卡片优化）
                      memCacheHeight: 320, // 限制内存缓存尺寸（160px * 2 = 320）
                      placeholder: (context, url) => Container(
                        color: AppColors.backgroundDark,
                        child: const Center(
                          child: Icon(Icons.museum, size: 50, color: AppColors.textDisabled),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.backgroundDark,
                        child: const Center(
                          child: Icon(Icons.museum, size: 50, color: AppColors.textDisabled),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // 状态标签（左上角）
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      exhibition.statusText,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                
                // 收藏按钮（右上角星星）
                Positioned(
                  top: 6,
                  right: 10,
                  child: GestureDetector(
                    onTap: () => _onUnfavoriteExhibition(exhibition),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.star,
                        color: AppColors.warningLight,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // 展览信息
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 展览标题
                  Text(
                    exhibition.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // 博物馆和位置（红色）
                  Text(
                    '${exhibition.museumName} · ${exhibition.cityName}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // 时间信息（灰色）
                  Text(
                    exhibition.isPermanent ? '长期展览' : '${exhibition.startDate} - ${exhibition.endDate}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // 标签
                  Row(
                    children: [
                      // 分类标签
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.infoDark,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          exhibition.category,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 4),
                      
                      // 价格标签
                      if (exhibition.ticketPrice != null && exhibition.ticketPrice!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.successDark,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            exhibition.ticketPrice!,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.favorite_border,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppDimensions.paddingM),
          Text(
            message,
            style: AppTextStyles.bodyLarge,
          ),
          const SizedBox(height: AppDimensions.paddingXS),
          const Text(
            '去发现页面探索更多内容吧！',
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }
}