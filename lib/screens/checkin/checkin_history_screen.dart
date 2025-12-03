import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/ui_helper.dart';
import '../../../core/utils/bottom_sheet_helper.dart';
import '../../../widgets/common/common_app_bar.dart';
import '../../../services/api/checkin_service.dart';
import '../../../services/auth/auth_service.dart';
import '../../../models/api_response.dart';

/// 打卡历史页面
class CheckinHistoryScreen extends StatefulWidget {
  const CheckinHistoryScreen({super.key});

  @override
  State<CheckinHistoryScreen> createState() => _CheckinHistoryScreenState();
}

class _CheckinHistoryScreenState extends State<CheckinHistoryScreen>
    with SingleTickerProviderStateMixin {
  final _checkinService = CheckinService();
  final _authService = AuthService();
  
  late TabController _tabController;
  
  // 数据状态
  List<CheckinRecord> _checkinRecords = [];
  List<ProvinceStats> _provinceStats = [];
  CheckinHistoryStats _historyStats = CheckinHistoryStats.empty();
  
  // UI状态
  bool _isLoading = false;
  String _searchKeyword = '';
  String _filterType = 'all'; // all | thisMonth | thisYear
  int _currentPage = 1;
  bool _hasMore = true;
  
  // 控制器
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController.addListener(_onScroll);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
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
      // 1. 先加载统计数据和省份数据
      await Future.wait([
        _loadHistoryStats(),
        _loadProvinceStats(),
      ]);
      
      // 2. 然后加载打卡记录（会调用 _calculateStatsFromRecords 更新统计）
      await _loadCheckinHistory(refresh: true);
    } catch (e) {
      _showErrorSnackBar('加载数据失败: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 加载打卡历史
  Future<void> _loadCheckinHistory({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _checkinRecords.clear();
    }

    if (!_hasMore) return;

    try {
      // DEBUG: print('🔍 [打卡历史] 请求参数: page=$_currentPage, pageSize=100, keyword=$_searchKeyword, filterType=$_filterType, isDraft=false');
      
      final result = await _checkinService.getUserCheckinRecords(
        page: _currentPage,
        pageSize: 100, // 加载更多数据用于统计计算
        keyword: _searchKeyword.isEmpty ? null : _searchKeyword,
        filterType: _filterType,
        isDraft: false, // 只查询正式打卡记录，不包括草稿
      );

      // DEBUG: print('📥 [打卡历史] API返回: total=${result.total}, records=${result.records.length}');
      if (result.records.isNotEmpty) {
        // DEBUG: print('📋 [打卡历史] 记录列表: ${result.records.map((r) => '${r.id}:${r.museumName}').join(', ')}');
      }

      if (mounted) {
        setState(() {
          if (refresh) {
            _checkinRecords = result.records;
          } else {
            _checkinRecords.addAll(result.records);
          }
          
          _currentPage++;
          _hasMore = result.records.length >= 100;
          
          // 从打卡记录中计算统计数据（像小程序一样）
          _calculateStatsFromRecords();
        });
        
        // DEBUG: print('✅ [打卡历史] 本地数据: ${_checkinRecords.length}条记录');
      }
    } catch (e) {
      // DEBUG: print('❌ [打卡历史] 加载失败: $e');
      if (mounted) {
        _showErrorSnackBar('加载打卡记录失败: ${e.toString()}');
      }
    }
  }
  
  /// 从打卡记录中计算统计数据
  void _calculateStatsFromRecords() {
    final totalCheckins = _checkinRecords.length;
    
    // 计算本月打卡次数
    final now = DateTime.now();
    final thisMonthCheckins = _checkinRecords.where((record) {
      try {
        final recordDate = DateTime.parse(record.checkInDate);
        return recordDate.year == now.year && recordDate.month == now.month;
      } catch (e) {
        return false;
      }
    }).length;
    
    // 计算已解锁的省份数量
    final uniqueProvinces = _checkinRecords
        .map((record) => record.provinceName)
        .where((name) => name != '未知省份')
        .toSet()
        .length;
    
    // DEBUG: print('📊 [统计计算] 总打卡: $totalCheckins, 本月: $thisMonthCheckins, 省份: $uniqueProvinces');
    
    // 更新统计数据（保留从API获取的总体数据）
    _historyStats = CheckinHistoryStats(
      totalCheckins: totalCheckins,
      thisMonthCheckins: thisMonthCheckins,
      unlockedProvinces: uniqueProvinces,
      totalProvinces: _historyStats.totalProvinces,
      visitedNationalMuseums: _historyStats.visitedNationalMuseums,
      totalNationalMuseums: _historyStats.totalNationalMuseums,
      coverageRate: _historyStats.coverageRate,
    );
  }

  /// 加载省份统计
  Future<void> _loadProvinceStats() async {
    try {
      // DEBUG: print('🗺️  [足迹地图] 开始加载省份统计');
      final response = await _checkinService.getProvinceStats();
      // DEBUG: print('📥 [足迹地图] API返回: ${response.length}个省份');
      
      // 统计已解锁和未解锁的省份
        // ignore: unused_local_variable
      final unlocked = response.where((p) => p.isUnlocked).length;
      // DEBUG: print('📊 [足迹地图] 已解锁: $unlocked, 未解锁: $locked');
      
      if (response.isNotEmpty) {
        // DEBUG: print('📋 [足迹地图] 前5个省份: ${response.take(5).map((p) => '${p.provinceName}(${p.isUnlocked ? "已解锁" : "未解锁"})').join(', ')}');
      }
      
      // 排序：已解锁的省份排在前面，然后按省份名称排序
      final sortedProvinces = [...response];
      sortedProvinces.sort((a, b) {
        // 优先排序：已解锁的省份排在前面
        if (a.isUnlocked && !b.isUnlocked) return -1;
        if (!a.isUnlocked && b.isUnlocked) return 1;
        
        // 同一状态内按省份名称排序
        return a.provinceName.compareTo(b.provinceName);
      });
      
      if (mounted) {
        setState(() {
          _provinceStats = sortedProvinces;
        });
      }
      // DEBUG: print('✅ [足迹地图] 省份数据加载完成，已排序');
    } catch (e) {
      // DEBUG: print('❌ [足迹地图] 加载省份统计失败: $e');
    }
  }

  /// 加载历史统计（从API或省份统计中获取总体数据）
  Future<void> _loadHistoryStats() async {
    try {
      // DEBUG: print('📈 [总体统计] 开始加载历史统计');
      
      // 尝试从province-stats API获取总体统计
      final userId = await _authService.getCurrentUserId();
      if (userId == null) {
        // DEBUG: print('❌ [总体统计] 用户未登录');
        return;
      }
      
      // DEBUG: print('📤 [总体统计] 请求 stats/provinces API, userId=$userId');
      
      final response = await _checkinService.httpClient.get(
        '/api/v1/museums/miniapp/checkin/stats/provinces',
        options: Options(
          headers: {
            'userId': userId.toString(),
          },
        ),
      );
      
      // DEBUG: print('📥 [总体统计] API响应: ${response.data}');
      
      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );
      
      if (apiResponse.isSuccess && apiResponse.data != null) {
        final overall = apiResponse.data!['overall'] as Map<String, dynamic>?;
        // DEBUG: print('📊 [总体统计] overall数据: $overall');
        
        if (overall != null) {
          final unlockedProvinces = overall['unlockedProvinces'] ?? 0;
          final totalProvinces = overall['totalProvinces'] ?? 34;
          final visitedMuseums = overall['visitedNationalMuseums'] ?? 0;
          final totalMuseums = overall['totalNationalMuseums'] ?? 6582;
          final coverageRate = (overall['coverageRate'] ?? 0.0).toDouble();
          
          // DEBUG: print('✅ [总体统计] 解析成功: 省份=$unlockedProvinces/$totalProvinces, 博物馆=$visitedMuseums/$totalMuseums, 覆盖率=$coverageRate%');
          
          if (mounted) {
            setState(() {
              _historyStats = CheckinHistoryStats(
                totalCheckins: _historyStats.totalCheckins, // 从打卡记录计算
                thisMonthCheckins: _historyStats.thisMonthCheckins, // 从打卡记录计算
                unlockedProvinces: unlockedProvinces,
                totalProvinces: totalProvinces,
                visitedNationalMuseums: visitedMuseums,
                totalNationalMuseums: totalMuseums,
                coverageRate: coverageRate,
              );
            });
          }
        } else {
          // DEBUG: print('⚠️  [总体统计] overall字段为null');
        }
      } else {
        // DEBUG: print('❌ [总体统计] API返回失败: ${apiResponse.message}');
      }
    } catch (e) {
      // DEBUG: print('❌ [总体统计] 加载失败: $e');
      // DEBUG: print('📍 [总体统计] 堆栈: $stackTrace');
    }
  }

  /// 滚动监听
  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _loadCheckinHistory();
      }
    }
  }

  /// 搜索
  void _onSearch() {
    setState(() {
      _searchKeyword = _searchController.text.trim();
    });
    _loadCheckinHistory(refresh: true);
  }

  /// 筛选类型切换
  void _onFilterChange(String filterType) {
    setState(() {
      _filterType = filterType;
    });
    _loadCheckinHistory(refresh: true);
  }

  /// 删除打卡记录
  Future<void> _onDeleteRecord(CheckinRecord record) async {
    final confirmed = await BottomSheetHelper.showConfirm(
      context,
      title: '确认删除',
      content: '确定要删除「${record.museumName}」的打卡记录吗？',
      confirmText: '确定删除',
      cancelText: '取消',
      isDangerous: true,
      icon: Icons.delete_outline,
    );
    
    if (confirmed == true) {
      await _deleteRecord(record.id);
    }
  }

  /// 执行删除
  Future<void> _deleteRecord(int id) async {
    try {
      final success = await _checkinService.deleteCheckinRecord(id);
      if (success) {
        setState(() {
          _checkinRecords.removeWhere((record) => record.id == id);
        });
        _showSuccessSnackBar('删除成功');
        // 重新加载统计数据
        _loadHistoryStats();
      } else {
        _showErrorSnackBar('删除失败');
      }
    } catch (e) {
      _showErrorSnackBar('删除失败: ${e.toString()}');
    }
  }

  /// 显示登录对话框
  Future<void> _showLoginDialog() async {
    final confirmed = await BottomSheetHelper.showConfirm(
      context,
      title: '需要登录',
      content: '请先登录后再查看打卡历史',
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
        title: '打卡历史',
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
                // 打卡记录
                _buildRecordsView(),
                // 足迹地图
                _buildMapView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建统计头部
  Widget _buildStatsHeader() {
    // 根据当前Tab显示不同的统计数据
    final isMapView = _tabController.index == 1;
    
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
          // 统计数据（根据Tab显示不同内容）
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: isMapView
                ? [
                    // 足迹地图模式的统计
                    _buildStatItem('省份', '${_historyStats.unlockedProvinces}/${_historyStats.totalProvinces}'),
                    _buildStatDivider(),
                    _buildStatItem('博物馆', '${_historyStats.visitedNationalMuseums}/${_historyStats.totalNationalMuseums}'),
                    _buildStatDivider(),
                    _buildStatItem('覆盖率', '${_historyStats.coverageRate.toStringAsFixed(0)}%'),
                  ]
                : [
                    // 打卡记录模式的统计
                    _buildStatItem('总打卡', '${_historyStats.totalCheckins}'),
                    _buildStatDivider(),
                    _buildStatItem('省份', '${_historyStats.unlockedProvinces}'),
                    _buildStatDivider(),
                    _buildStatItem('本月', '${_historyStats.thisMonthCheckins}'),
                  ],
          ),
          
          const SizedBox(height: AppDimensions.paddingM),
          
          // 进度条
          Container(
            width: double.infinity, // 确保进度条占满整个宽度
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: _historyStats.coverageRate / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Tab切换（嵌入在Header内）- 使用和收藏页相同的样式
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _tabController,
              onTap: (_) {
                // 当Tab切换时，触发UI更新以改变统计显示
                setState(() {});
              },
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
                Tab(text: '打卡记录'),
                Tab(text: '足迹地图'),
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

  /// 构建记录视图
  Widget _buildRecordsView() {
    return Column(
      children: [
        // 搜索栏
        _buildSearchBar(),
        
        // 筛选栏
        _buildFilterBar(),
        
        // 记录列表
        Expanded(
          child: _isLoading && _checkinRecords.isEmpty
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryLight))
              : _checkinRecords.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(AppDimensions.paddingM),
                      itemCount: _checkinRecords.length + (_hasMore ? 1 : 0),
                      separatorBuilder: (context, index) => 
                          const SizedBox(height: AppDimensions.paddingS),
                      itemBuilder: (context, index) {
                        if (index == _checkinRecords.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(AppDimensions.paddingM),
                              child: CircularProgressIndicator(color: AppColors.primaryLight),
                            ),
                          );
                        }
                        return _buildRecordCard(_checkinRecords[index]);
                      },
                    ),
        ),
      ],
    );
  }

  /// 构建搜索栏
  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: '搜索博物馆、省市...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingM,
                  vertical: AppDimensions.paddingS,
                ),
              ),
              onSubmitted: (_) => _onSearch(),
            ),
          ),
          IconButton(
            onPressed: _onSearch,
            icon: const Icon(Icons.search),
          ),
        ],
      ),
    );
  }

  /// 构建筛选栏
  Widget _buildFilterBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingM),
      child: Row(
        children: [
          _buildFilterChip('全部', 'all'),
          const SizedBox(width: AppDimensions.paddingS),
          _buildFilterChip('本月', 'thisMonth'),
          const SizedBox(width: AppDimensions.paddingS),
          _buildFilterChip('今年', 'thisYear'),
        ],
      ),
    );
  }

  /// 构建筛选标签
  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterType == value;
    return GestureDetector(
      onTap: () => _onFilterChange(value),
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

  /// 构建记录卡片
  Widget _buildRecordCard(CheckinRecord record) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () {
          // 跳转到打卡详情页
          context.push('/checkin/detail/${record.id}');
        },
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // 博物馆信息
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.museumName,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${record.provinceName} · ${record.cityName}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primary, // 红色 - 匹配小程序
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _onDeleteRecord(record),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppDimensions.paddingXS),
            
            // 地址和日期
            Row(
              children: [
                Expanded(
                  child: Text(
                    record.address,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  record.checkInDate,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary, // 深灰色 - 匹配小程序
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            
            // 笔记
            if (record.notes != null && record.notes!.isNotEmpty) ...[
              const SizedBox(height: AppDimensions.paddingXS),
              Text(
                record.notes!,
                style: AppTextStyles.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            ],
          ),
        ),
      ),
    );
  }

  /// 构建地图视图
  Widget _buildMapView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryLight));
    }
    
    if (_provinceStats.isEmpty) {
      return _buildEmptyState();
    }
    
    return Column(
      children: [
        // 地图标题
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingM,
            vertical: AppDimensions.paddingL,
          ),
          child: Column(
            children: [
              Text(
                '我的足迹地图',
                style: AppTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '点击查看省份详情',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        
        // 省份网格
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, // 小程序是3列
              crossAxisSpacing: AppDimensions.paddingS, // 8px
              mainAxisSpacing: AppDimensions.paddingS, // 8px  
              childAspectRatio: 1.0, // 调整为正方形，使卡片更紧凑
            ),
            itemCount: _provinceStats.length,
            itemBuilder: (context, index) {
              final province = _provinceStats[index];
              return _buildProvinceCard(province);
            },
          ),
        ),
        
        // 地图说明（图例）
        _buildMapLegend(),
        
        const SizedBox(height: AppDimensions.paddingM),
      ],
    );
  }
  
  /// 构建地图图例
  Widget _buildMapLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingL),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLegendItem(AppColors.successDark, '已探索省份'),
          const SizedBox(width: AppDimensions.paddingL),
          _buildLegendItem(AppColors.border, '未探索省份'),
        ],
      ),
    );
  }
  
  /// 构建图例项
  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// 构建省份卡片
  Widget _buildProvinceCard(ProvinceStats province) {
    return GestureDetector(
      onTap: () => _onProvinceTap(province),
      child: Opacity(
        opacity: province.isUnlocked ? 1.0 : 0.6, // 未解锁卡片半透明
        child: Container(
        decoration: BoxDecoration(
          color: province.isUnlocked ? Colors.white : AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: province.isUnlocked
              ? Border.all(color: AppColors.successDark, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 12), // 上边距增大，使图标距顶部更远

            child: Column(
              mainAxisAlignment: MainAxisAlignment.start, // 从上到下对齐，确保所有卡片元素在同一水平线
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ========== 省份图标 (province-icon) ==========
                SizedBox(
                  width: double.infinity,
                  child: Opacity(
                    opacity: province.isUnlocked ? 1.0 : 0.5, // 未解锁图标半透明
                    child: ColorFiltered(
                      colorFilter: province.isUnlocked 
                          ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
                          : const ColorFilter.matrix(<double>[ // grayscale filter
                              0.2126, 0.7152, 0.0722, 0, 0,
                              0.2126, 0.7152, 0.0722, 0, 0,
                              0.2126, 0.7152, 0.0722, 0, 0,
                              0, 0, 0, 1, 0,
                            ]),
                      child: Text(
                        province.isUnlocked ? '🏛️' : '🔒',
                        style: const TextStyle(
                          fontSize: 16, // 32rpx = 16px
                          height: 1.0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6), // province-icon margin-bottom: 12rpx = 6px
                
                // ========== 省份信息容器 (province-info) 开始 ==========
                // 省份名称 (province-name)
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    province.provinceName,
                    style: TextStyle(
                      fontSize: 12, // 24rpx = 12px
                      fontWeight: FontWeight.w600,
                      color: province.isUnlocked 
                          ? AppColors.textPrimary
                          : AppColors.textHint,
                      height: 1.0,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 24), // 增加省份名称与统计信息间距，使布局看起来更居中
                
                // 统计信息 (province-stats 或 province-locked)
                if (province.isUnlocked) ...[
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      '${province.visitedMuseums}/${province.totalMuseums}',
                      style: const TextStyle(
                        fontSize: 10, // 20rpx = 10px
                        color: AppColors.successDark,
                        fontWeight: FontWeight.w500,
                        height: 1.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // 统计信息与进度条间距
                  const SizedBox(height: 8),
                  
                  // 进度条 (completion-bar)
                  Container(
                    width: double.infinity, // 确保进度条占满整个宽度
                    height: 3, // 增加到3px使其更明显
                    decoration: BoxDecoration(
                      color: AppColors.backgroundDark,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: province.totalMuseums > 0 
                          ? province.visitedMuseums / province.totalMuseums 
                          : 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.successDark,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  // 未解锁状态 (province-locked)
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      '未解锁',
                      style: const TextStyle(
                        fontSize: 10, // 20rpx = 10px
                        color: AppColors.textHint,
                        height: 1.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // 右上角的✨徽章（仅已解锁且有访问记录的省份）
          if (province.isUnlocked && province.visitedMuseums > 0)
            Positioned(
              top: 4,
              right: 4,
              child: Text(
                '✨',
                style: const TextStyle(fontSize: 12),
              ),
            ),
        ],
      ),
      ),
      ),
    );
  }

  /// 处理省份卡片点击事件
  void _onProvinceTap(ProvinceStats province) {
    if (!province.isUnlocked) {
      // 未解锁省份，显示提示
      UIHelper.showInfo(context, '该省份暂未解锁');
      return;
    }

    // 导航到省份详情页面，传递省份代码
    context.go('/province/${province.provinceCode}');
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: AppDimensions.paddingM),
          Text(
            '暂无打卡记录',
            style: AppTextStyles.bodyLarge,
          ),
          SizedBox(height: AppDimensions.paddingXS),
          Text(
            '快去探索博物馆吧！',
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }
}