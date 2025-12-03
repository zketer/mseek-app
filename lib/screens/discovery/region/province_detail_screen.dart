import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../services/api/checkin_service.dart';
import '../../../widgets/common/common_app_bar.dart';

/// 省份详情页面
class ProvinceDetailScreen extends StatefulWidget {
  final String provinceCode;

  const ProvinceDetailScreen({
    super.key,
    required this.provinceCode,
  });

  @override
  State<ProvinceDetailScreen> createState() => _ProvinceDetailScreenState();
}

class _ProvinceDetailScreenState extends State<ProvinceDetailScreen> with SingleTickerProviderStateMixin {
  final CheckinService _checkinService = CheckinService();
  
  ProvinceMuseumDetail? _provinceInfo;
  bool _loading = false;
  String _error = '';
  
  // 视图模式：cities（城市列表）或 museums（博物馆列表）
  String _viewMode = 'cities';
  
  // 筛选状态（仅博物馆模式）
  String _filterStatus = 'all'; // all | visited | unvisited
  
  // 筛选后的博物馆列表
  List<MuseumDetail> _filteredMuseums = [];
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _viewMode = _tabController.index == 0 ? 'cities' : 'museums';
        });
      }
    });
    _loadProvinceDetail();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 加载省份详情
  Future<void> _loadProvinceDetail() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      // DEBUG: print('🔍 开始加载省份详情: ${widget.provinceCode}');
      
      final provinceDetail = await _checkinService.getProvinceMuseumDetail(widget.provinceCode);
      
      // DEBUG: print('✅ 省份详情加载成功: ${provinceDetail.provinceName}');
      // DEBUG: print('📊 统计: ${provinceDetail.visitedMuseums}/${provinceDetail.totalMuseums} 博物馆');
      
      setState(() {
        _provinceInfo = provinceDetail;
        _loading = false;
      });
      
      _updateFilteredMuseums();
      
    } catch (error) {
      // DEBUG: print('❌ 加载省份详情失败: $error');
      
      setState(() {
        _error = error.toString();
        _loading = false;
      });
      
      // 不显示错误提示
    }
  }

  /// 更新筛选后的博物馆列表
  void _updateFilteredMuseums() {
    if (_provinceInfo == null) {
      setState(() {
        _filteredMuseums = [];
      });
      return;
    }

    var museums = _provinceInfo!.museums;

    // 筛选
    if (_filterStatus == 'visited') {
      museums = museums.where((m) => m.isVisited).toList();
    } else if (_filterStatus == 'unvisited') {
      museums = museums.where((m) => !m.isVisited).toList();
    }

    // 排序：已访问优先，然后按名称排序
    museums.sort((a, b) {
      if (a.isVisited && !b.isVisited) return -1;
      if (!a.isVisited && b.isVisited) return 1;
      return a.name.compareTo(b.name);
    });

    setState(() {
      _filteredMuseums = museums;
    });
  }

  /// 处理城市卡片点击
  void _onCityTap(CityDetail city) {
    if (_provinceInfo == null) return;
    
    // 导航到城市详情页面
    // 使用 extra 参数传递完整信息，避免 URL 编码问题
    context.go(
      '/city/${city.cityName.replaceAll('/', '-')}', // 替换斜杠避免路由问题
      extra: {
        'provinceCode': _provinceInfo!.provinceCode,
        'provinceName': _provinceInfo!.provinceName,
        'cityName': city.cityName, // 通过 extra 传递原始城市名称
      },
    );
  }

  /// 处理博物馆卡片点击
  void _onMuseumTap(MuseumDetail museum) {
    if (museum.isVisited) {
      // 已打卡博物馆 - 查看详情
      context.push('/museum/${museum.id}');
    } else {
      // 未打卡博物馆 - 显示基本信息
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('🏛️ ${museum.name}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogInfo('地址', museum.address),
                _buildDialogInfo('等级', museum.level),
                _buildDialogInfo('类别', museum.category),
                _buildDialogInfo('开放时间', museum.openTime ?? '未知'),
                _buildDialogInfo('门票', museum.ticketPrice),
                const SizedBox(height: AppDimensions.paddingS),
                Text(
                  museum.description ?? '暂无描述',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('知道了'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // 导航到打卡页面（切换到打卡Tab）
                context.go('/checkin');
              },
              child: const Text('去打卡'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildDialogInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar.simple(
        title: _provinceInfo != null 
            ? '${_provinceInfo!.provinceName} · 博物馆'
            : '省份详情',
      ),
      body: _loading
          ? _buildLoadingState()
          : _error.isNotEmpty
              ? _buildErrorState()
              : _provinceInfo == null
                  ? _buildEmptyState()
                  : _buildContent(),
    );
  }

  /// 构建加载状态
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primaryLight),
          SizedBox(height: AppDimensions.paddingM),
          Text('加载中...'),
        ],
      ),
    );
  }

  /// 构建错误状态
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: AppDimensions.paddingM),
          Text(
            '加载失败',
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingS),
          Text(
            _error,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.paddingL),
          ElevatedButton(
            onPressed: _loadProvinceDetail,
            child: const Text('重新加载'),
          ),
        ],
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.location_off_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppDimensions.paddingM),
          const Text('省份数据加载失败'),
          const SizedBox(height: AppDimensions.paddingL),
          ElevatedButton(
            onPressed: _loadProvinceDetail,
            child: const Text('重新加载'),
          ),
        ],
      ),
    );
  }

  /// 构建主要内容
  Widget _buildContent() {
    return Column(
      children: [
        _buildProvinceHeader(),
        if (_viewMode == 'museums') _buildFilterSection(),
        Expanded(
          child: _viewMode == 'cities'
              ? _buildCitiesView()
              : _buildMuseumsView(),
        ),
      ],
    );
  }

  /// 构建省份头部
  Widget _buildProvinceHeader() {
    if (_provinceInfo == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(8, 10, 8, 0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // 标题
          Text(
            _provinceInfo!.provinceName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '博物馆分布',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 16),
          
          // 统计数据
          _buildStatsRow(),
          
          const SizedBox(height: 12),
          
          // 进度条
          Container(
            width: double.infinity, // 确保进度条占满整个宽度
            height: 6, // 8rpx ≈ 4px，这里用6px更明显
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3), // 半透明白色背景
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: _provinceInfo!.completionRate / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white, // 省份详情用纯白色填充
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Tab切换（匹配足迹地图样式）
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _tabController,
              onTap: (_) {
                setState(() {}); // 触发UI更新以改变统计显示
              },
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(11),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: AppColors.primary, // 选中时红色
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
                Tab(text: '城市分布'),
                Tab(text: '博物馆列表'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建统计数据行
  Widget _buildStatsRow() {
    if (_provinceInfo == null) return const SizedBox.shrink();

    if (_viewMode == 'cities') {
      return Row(
        children: [
          _buildStatItem(
            '${_provinceInfo!.unlockedCities}/${_provinceInfo!.totalCities}',
            '城市',
          ),
          const SizedBox(width: 8), // 卡片间距
          _buildStatItem(
            '${_provinceInfo!.visitedMuseums}/${_provinceInfo!.totalMuseums}',
            '已打卡',
          ),
          const SizedBox(width: 8), // 卡片间距
          _buildStatItem(
            '${_provinceInfo!.completionRate}%',
            '完成度',
          ),
        ],
      );
    } else {
      return Row(
        children: [
          _buildStatItem(
            '${_provinceInfo!.visitedMuseums}/${_provinceInfo!.totalMuseums}',
            '已打卡',
          ),
          const SizedBox(width: 8), // 卡片间距
          _buildStatItem(
            '${_provinceInfo!.totalMuseums - _provinceInfo!.visitedMuseums}',
            '待探索',
          ),
          const SizedBox(width: 8), // 卡片间距
          _buildStatItem(
            '${_provinceInfo!.completionRate}%',
            '完成度',
          ),
        ],
      );
    }
  }

  /// 构建统计项
  Widget _buildStatItem(String number, String label) {
    return Expanded( // 让卡片平均分配空间
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), // 缩小高度：14 → 12
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              number,
              style: const TextStyle(
                fontSize: 20, // 增大数字字体：16 → 20
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4), // 增加间距：3 → 4
            Text(
              label,
              style: TextStyle(
                fontSize: 12, // 增大标签字体：11 → 12
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建筛选区域（仅博物馆模式）
  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      color: AppColors.background,
      child: Row(
        children: [
          _buildFilterChip('全部', 'all'),
          const SizedBox(width: AppDimensions.paddingS),
          _buildFilterChip('已打卡', 'visited'),
          const SizedBox(width: AppDimensions.paddingS),
          _buildFilterChip('待探索', 'unvisited'),
        ],
      ),
    );
  }

  /// 构建筛选chip
  Widget _buildFilterChip(String label, String status) {
    final isActive = _filterStatus == status;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _filterStatus = status;
          });
          _updateFilteredMuseums();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? AppColors.primary : AppColors.backgroundDark,
              width: 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isActive ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  /// 构建城市列表视图
  Widget _buildCitiesView() {
    if (_provinceInfo == null || _provinceInfo!.cities.isEmpty) {
      return const Center(child: Text('暂无城市数据'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.0, // 与足迹地图保持一致
      ),
      itemCount: _provinceInfo!.cities.length,
      itemBuilder: (context, index) {
        final city = _provinceInfo!.cities[index];
        return _buildCityCard(city);
      },
    );
  }

  /// 构建城市卡片
  Widget _buildCityCard(CityDetail city) {
    final isUnlocked = city.visitedMuseums > 0;
    
    return GestureDetector(
      onTap: () => _onCityTap(city),
      child: Opacity(
        opacity: isUnlocked ? 1.0 : 0.7,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isUnlocked 
                  ? AppColors.primary 
                  : AppColors.surfaceTinted,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isUnlocked 
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.06),
                blurRadius: isUnlocked ? 12 : 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 16, 8, 12), // 与足迹地图保持一致
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 城市图标
                    Text(
                      isUnlocked ? '🏙️' : '🔒',
                      style: const TextStyle(fontSize: 16), // 32rpx = 16px
                    ),
                    const SizedBox(height: 4), // 与足迹地图保持一致
                    
                    // 城市名称
                    SizedBox(
                      width: double.infinity,
                      child: Text(
                        city.cityName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isUnlocked 
                              ? AppColors.textPrimary
                              : AppColors.textHint,
                          height: 1.0,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 24), // 与足迹地图保持一致
                    
                    // 统计信息
                    if (isUnlocked) ...[
                      SizedBox(
                        width: double.infinity,
                        child: Text(
                          '${city.visitedMuseums}/${city.totalMuseums}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                            height: 1.0,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 8), // 与足迹地图保持一致
                      // 进度条
                      Container(
                        width: double.infinity,
                        height: 3,
                        decoration: BoxDecoration(
                          color: AppColors.backgroundDark, // 灰色背景
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: city.totalMuseums > 0 
                              ? city.visitedMuseums / city.totalMuseums 
                              : 0,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.primaryDark,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4), // 进度条到底部间距
                    ] else ...[
                      SizedBox(
                        width: double.infinity,
                        child: Text(
                          '未解锁',
                          style: const TextStyle(
                            fontSize: 10,
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
              
              // ✨徽章
              if (isUnlocked)
                const Positioned(
                  top: 3,
                  right: 3,
                  child: Text('✨', style: TextStyle(fontSize: 14)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建博物馆列表视图
  Widget _buildMuseumsView() {
    if (_filteredMuseums.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.museum_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppDimensions.paddingM),
            Text(
              _filterStatus == 'visited' 
                  ? '暂无已打卡博物馆'
                  : _filterStatus == 'unvisited'
                      ? '暂无待探索博物馆'
                      : '暂无博物馆数据',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.85, // 调整卡片比例，使其不那么高
      ),
      itemCount: _filteredMuseums.length,
      itemBuilder: (context, index) {
        final museum = _filteredMuseums[index];
        return _buildMuseumCard(museum);
      },
    );
  }

  /// 构建博物馆卡片（匹配小程序样式）
  Widget _buildMuseumCard(MuseumDetail museum) {
    return GestureDetector(
      onTap: () => _onMuseumTap(museum),
      child: Opacity(
        opacity: museum.isVisited ? 1.0 : 0.8,
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 12), // 24rpx 16rpx
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10), // 20rpx
            border: Border.all(
              color: museum.isVisited 
                  ? AppColors.successDark // 已打卡：绿色边框
                  : AppColors.surfaceTinted, // 未打卡：灰色边框
              width: museum.isVisited ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // 主要内容
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 圆形Logo
                  Container(
                    width: 32, // 64rpx
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: museum.isVisited
                          ? const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [AppColors.primary, AppColors.primaryDark],
                            )
                          : null,
                      color: museum.isVisited ? null : AppColors.borderDark,
                    ),
                    child: const Center(
                      child: Text(
                        '🏛️',
                        style: TextStyle(fontSize: 16), // 32rpx
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8), // 16rpx
                  
                  // 博物馆名称
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 33), // 66rpx
                    child: Text(
                      museum.name,
                      style: TextStyle(
                        fontSize: 13, // 26rpx
                        fontWeight: FontWeight.w600,
                        color: museum.isVisited 
                            ? AppColors.textPrimary 
                            : AppColors.textHint,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // 详细信息（日期或等级）
                  if (museum.isVisited && museum.visitDate != null)
                    Text(
                      museum.visitDate!,
                      style: const TextStyle(
                        fontSize: 9, // 18rpx
                        color: AppColors.successDark, // 绿色
                      ),
                      textAlign: TextAlign.center,
                    )
                  else
                    Text(
                      museum.level,
                      style: const TextStyle(
                        fontSize: 12, // 24rpx
                        color: AppColors.textHint,
                      ),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
              
              // 等级标签（左上角）
              if (museum.level == '国家级' || museum.level == '国家一级')
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: museum.isVisited
                          ? (museum.level == '国家级' 
                              ? AppColors.warningLight 
                              : AppColors.warningLight)
                          : AppColors.border,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(10),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                    child: Text(
                      museum.level == '国家级' ? '一级' : '一级',
                      style: TextStyle(
                        fontSize: 9,
                        color: museum.isVisited 
                            ? Colors.white 
                            : AppColors.textTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              
              // 打卡标记（右上角）
              if (museum.isVisited)
                Positioned(
                  top: -3,
                  right: 4,
                  child: Container(
                    width: 12, // 24rpx
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.successDark,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.successDark.withValues(alpha: 0.4),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 8,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

