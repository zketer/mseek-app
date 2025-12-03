import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../services/api/checkin_service.dart';
import '../../../widgets/common/common_app_bar.dart';
import '../../../core/utils/ui_helper.dart';

/// 城市详情页面
class CityDetailScreen extends StatefulWidget {
  final String provinceCode;
  final String provinceName;
  final String cityName;

  const CityDetailScreen({
    super.key,
    required this.provinceCode,
    required this.provinceName,
    required this.cityName,
  });

  @override
  State<CityDetailScreen> createState() => _CityDetailScreenState();
}

class _CityDetailScreenState extends State<CityDetailScreen> {
  final CheckinService _checkinService = CheckinService();
  
  CityMuseumDetail? _cityInfo;
  bool _loading = false;
  String _error = '';
  
  // 筛选状态
  String _filterStatus = 'all'; // all | visited | unvisited
  
  // 筛选后的博物馆列表
  List<MuseumDetail> _filteredMuseums = [];

  @override
  void initState() {
    super.initState();
    _loadCityDetail();
  }

  /// 加载城市详情
  Future<void> _loadCityDetail() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      // DEBUG: print('🔍 开始加载城市详情: ${widget.cityName}');
      
      // 调用省份详情API
      final provinceDetail = await _checkinService.getProvinceMuseumDetail(widget.provinceCode);
      
      // DEBUG: print('✅ 省份详情加载成功，开始筛选城市博物馆');
      
      // 筛选当前城市的博物馆
      final cityMuseums = provinceDetail.museums.where((museum) {
        if (museum.cityName.isEmpty) return false;
        
        // 精确匹配
        if (museum.cityName == widget.cityName) return true;
        
        // 去掉"市"后缀匹配
        final museumCityCore = museum.cityName.replaceAll(RegExp(r'市$'), '');
        final targetCityCore = widget.cityName.replaceAll(RegExp(r'市$'), '');
        if (museumCityCore == targetCityCore) return true;
        
        // 包含关系匹配
        if (museum.cityName.contains(targetCityCore) || targetCityCore.contains(museumCityCore)) {
          return true;
        }
        
        return false;
      }).toList();
      
      final visitedCount = cityMuseums.where((m) => m.isVisited).length;
      final completionRate = cityMuseums.isNotEmpty 
          ? ((visitedCount / cityMuseums.length) * 100).round()
          : 0;
      
      final cityInfo = CityMuseumDetail(
        provinceCode: widget.provinceCode,
        provinceName: widget.provinceName,
        cityName: widget.cityName,
        totalMuseums: cityMuseums.length,
        visitedMuseums: visitedCount,
        completionRate: completionRate,
        museums: cityMuseums,
      );
      
      // DEBUG: print('✅ 城市详情加载成功: ${cityInfo.totalMuseums}个博物馆，已打卡${cityInfo.visitedMuseums}个');
      
      setState(() {
        _cityInfo = cityInfo;
        _loading = false;
      });
      
      _updateFilteredMuseums();
      
    } catch (error) {
      // DEBUG: print('❌ 加载城市详情失败: $error');
      
      setState(() {
        _error = error.toString();
        _loading = false;
      });
      
      if (mounted) {
        UIHelper.showError(context, '加载失败: $error');
      }
    }
  }

  /// 更新筛选后的博物馆列表
  void _updateFilteredMuseums() {
    if (_cityInfo == null) {
      setState(() {
        _filteredMuseums = [];
      });
      return;
    }

    var museums = _cityInfo!.museums;

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
                const SizedBox(height: 8),
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
        title: _cityInfo != null 
            ? '${_cityInfo!.cityName} · 博物馆'
            : '城市详情',
      ),
      body: _loading
          ? _buildLoadingState()
          : _error.isNotEmpty
              ? _buildErrorState()
              : _cityInfo == null
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
          SizedBox(height: 16),
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
          const SizedBox(height: 16),
          Text(
            '加载失败',
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadCityDetail,
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
          const SizedBox(height: 16),
          const Text('城市数据加载失败'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadCityDetail,
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
        _buildCityHeader(),
        _buildFilterSection(),
        Expanded(child: _buildMuseumsView()),
      ],
    );
  }

  /// 构建城市头部
  Widget _buildCityHeader() {
    if (_cityInfo == null) return const SizedBox.shrink();

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
            _cityInfo!.cityName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_cityInfo!.provinceName} · 博物馆足迹',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 16),
          
          // 统计数据
          Row(
            children: [
              _buildStatItem(
                '${_cityInfo!.visitedMuseums}',
                '已打卡',
              ),
              const SizedBox(width: 8), // 卡片间距
              _buildStatItem(
                '${_cityInfo!.totalMuseums - _cityInfo!.visitedMuseums}',
                '待探索',
              ),
              const SizedBox(width: 8), // 卡片间距
              _buildStatItem(
                '${_cityInfo!.completionRate}%',
                '完成度',
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // 进度条
          Container(
            width: double.infinity, // 确保进度条占满整个宽度
            height: 6, // 8rpx ≈ 4px，这里用6px更明显
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25), // 半透明白色背景
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: _cityInfo!.completionRate / 100,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.white,
                      AppColors.info, // 青色
                    ],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
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

  /// 构建筛选区域
  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      color: AppColors.background,
      child: Row(
        children: [
          _buildFilterChip('全部', 'all'),
          const SizedBox(width: 8),
          _buildFilterChip('已打卡', 'visited'),
          const SizedBox(width: 8),
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
            const SizedBox(height: 16),
            Text(
              _filterStatus == 'visited' 
                  ? '暂无已打卡博物馆'
                  : _filterStatus == 'unvisited'
                      ? '暂无待探索博物馆'
                      : '该城市暂无博物馆数据',
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
        crossAxisCount: 2, // 城市详情每行2个卡片
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.0, // 增加比例，让卡片更矮
      ),
      itemCount: _filteredMuseums.length,
      itemBuilder: (context, index) {
        final museum = _filteredMuseums[index];
        return _buildMuseumCard(museum);
      },
    );
  }

  /// 构建博物馆卡片（城市详情样式）
  Widget _buildMuseumCard(MuseumDetail museum) {
    return GestureDetector(
      onTap: () => _onMuseumTap(museum),
      child: Container(
        decoration: BoxDecoration(
          color: museum.isVisited ? Colors.white : AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: museum.isVisited 
              ? Border.all(color: AppColors.infoDark, width: 2) // 蓝色边框
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 博物馆Logo区域
            Container(
              height: 85, // 减少高度，让卡片更紧凑
              decoration: BoxDecoration(
                color: museum.isVisited 
                    ? AppColors.infoSky // 已打卡：天蓝色背景
                    : AppColors.inactive, // 未打卡：灰色背景
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10),
                ),
              ),
              child: Stack(
                children: [
                  // 默认图标
                  Center(
                    child: ColorFiltered(
                      colorFilter: museum.isVisited
                          ? const ColorFilter.mode(
                              Colors.transparent,
                              BlendMode.multiply,
                            )
                          : const ColorFilter.matrix(<double>[
                              0.2126, 0.7152, 0.0722, 0, 0,
                              0.2126, 0.7152, 0.0722, 0, 0,
                              0.2126, 0.7152, 0.0722, 0, 0,
                              0,      0,      0,      1, 0,
                            ]), // 灰度滤镜
                      child: const Text('🏛️', style: TextStyle(fontSize: 42)), // 减小图标
                    ),
                  ),
                  
                  // 打卡标识（右上角蓝色勾）
                  if (museum.isVisited)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.infoDark, // 蓝色勾
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  
                  // 等级标签（左上角）
                  if (museum.level == '国家级' || museum.level == '国家一级' || museum.level.contains('一级'))
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: museum.level == '国家级' 
                              ? AppColors.primary
                              : AppColors.infoDark, // 一级用蓝色
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          museum.level == '国家级' ? '国' : '一级',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // 博物馆信息
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 6), // 减少上下padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center, // 居中对齐
                  mainAxisAlignment: MainAxisAlignment.center, // 居中，使用固定间距
                  children: [
                    // 博物馆名称
                    Text(
                      museum.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: museum.isVisited 
                            ? AppColors.textPrimary 
                            : AppColors.textHint, // 未打卡：灰色文字
                      ),
                      textAlign: TextAlign.center, // 文字居中
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6), // 固定间距
                    
                    // 日期/等级信息（确保对齐）
                    SizedBox(
                      width: double.infinity, // 确保占满宽度
                      height: 16, // 固定高度确保对齐
                      child: Center( // 使用 Center 确保内容居中
                        child: museum.isVisited
                            ? (museum.visitDate != null
                                ? Text(
                                    museum.visitDate!,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.infoDark, // 蓝色日期
                                      fontWeight: FontWeight.w500,
                                      height: 1.2,
                                    ),
                                    textAlign: TextAlign.center,
                                  )
                                : const SizedBox.shrink())
                            : Text(
                                museum.level,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textHint,
                                  height: 1.2,
                                ),
                                textAlign: TextAlign.center,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 城市博物馆详情模型
class CityMuseumDetail {
  final String provinceCode;
  final String provinceName;
  final String cityName;
  final int totalMuseums;
  final int visitedMuseums;
  final int completionRate;
  final List<MuseumDetail> museums;

  CityMuseumDetail({
    required this.provinceCode,
    required this.provinceName,
    required this.cityName,
    required this.totalMuseums,
    required this.visitedMuseums,
    required this.completionRate,
    required this.museums,
  });
}

