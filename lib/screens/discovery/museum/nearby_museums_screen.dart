import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/location_service.dart';
import '../../../core/utils/ui_helper.dart';
import '../../../core/utils/bottom_sheet_helper.dart';
import '../../../models/museum.dart';
import '../../../services/api/museum_service.dart';
import '../../../services/api/http_client.dart';
import '../../../widgets/common/common_app_bar.dart';

/// 同城博物馆页面 - 匹配小程序功能
class NearbyMuseumsScreen extends StatefulWidget {
  const NearbyMuseumsScreen({super.key});

  @override
  State<NearbyMuseumsScreen> createState() => _NearbyMuseumsScreenState();
}

class _NearbyMuseumsScreenState extends State<NearbyMuseumsScreen> {
  // ignore: unused_field
  final MuseumService _museumService = MuseumService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // 位置信息
  Position? _currentPosition;
  String _cityName = '定位中...'; // 非空类型，定位失败显示"定位失败"
  bool _locationError = false;
  // ignore: unused_field
  String _locationErrorMessage = '';

  // 博物馆列表
  List<Museum> _museums = [];
  int _total = 0;
  int _page = 1;
  final int _pageSize = 10;
  bool _loading = false;
  bool _hasMore = true;

  // 搜索
  String _searchKeyword = '';

  @override
  void initState() {
    super.initState();
    // DEBUG: print('🚀 同城博物馆页面初始化');
    _scrollController.addListener(_onScroll);
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// 滚动监听 - 加载更多
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (_hasMore && !_loading) {
        _loadNearbyMuseums();
      }
    }
  }

  /// 获取当前位置（使用统一定位服务）
  /// 
  /// [forceRefresh] 是否强制刷新（忽略缓存）
  /// - false（默认）: 正常加载，可使用5分钟缓存，快速显示
  /// - true: 强制重新定位（用户主动点击刷新按钮时）
  Future<void> _getCurrentLocation({bool forceRefresh = false}) async {
    // DEBUG: print('📍 [同城博物馆] 开始定位...');
    setState(() {
      _loading = true;
      _locationError = false;
    });

    try {
      // 使用统一定位服务
      // 根据 forceRefresh 参数决定是否使用缓存
      final result = await LocationService.getCurrentLocation(
        desiredAccuracy: LocationAccuracy.high,
        timeoutSeconds: 10,
        useCachedPosition: !forceRefresh,  // 强制刷新时不使用缓存
      );

      // 处理定位结果
      if (result.success && result.position != null) {
        // 定位成功
        // DEBUG: print('✅ [同城博物馆] 定位成功');
        setState(() {
          _currentPosition = result.position;
          _cityName = '定位中...'; // 暂时设置，加载博物馆时会从API获取真实城市名
          _loading = false;
        });

        // 加载附近博物馆
        // DEBUG: print('📍 [同城博物馆] 开始加载附近博物馆...');
        _loadNearbyMuseums(reset: true);

      } else {
        // 定位失败
        // DEBUG: print('❌ [同城博物馆] 定位失败: ${result.errorMessage}');
        setState(() {
          _locationError = true;
          _locationErrorMessage = result.errorMessage ?? '定位失败';
          _cityName = '定位失败';
          _loading = false;
          _currentPosition = null;
        });

        // 根据错误类型显示对应对话框
        if (result.errorType == LocationErrorType.serviceDisabled) {
          _showLocationServiceDialog();
        } else if (result.errorType == LocationErrorType.permissionDenied) {
          _showPermissionDeniedDialog();
        } else if (result.errorType == LocationErrorType.permissionDeniedForever) {
          _showPermissionDeniedForeverDialog();
        } else if (mounted) {
          UIHelper.showError(context, result.errorMessage ?? "定位失败");
        }
      }

    } catch (e) {
      // 定位失败
      // DEBUG: print('❌ [同城博物馆] 定位异常: $e');
      setState(() {
        _locationError = true;
        _locationErrorMessage = e.toString();
        _cityName = '定位失败';
        _loading = false;
        _currentPosition = null;
      });
    }
  }

  /// 加载附近博物馆
  Future<void> _loadNearbyMuseums({bool reset = false}) async {
    // 如果当前位置为空，跳过加载
    if (_currentPosition == null) {
      // DEBUG: print('⚠️ 跳过加载：position=$_currentPosition');
      return;
    }
    
    // 如果正在加载且不是重置操作，跳过加载（避免重复请求）
    if (_loading && !reset) {
      // DEBUG: print('⚠️ 跳过加载：已经在加载中');
      return;
    }

    setState(() {
      _loading = true;
      if (reset) {
        _page = 1;
        _museums.clear();
        _hasMore = true;
      }
    });

    try {
      // DEBUG: print('🌐 调用API获取同城博物馆...');
      // DEBUG: print('📍 坐标: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');
      // DEBUG: print('📏 radius: 1000km（全城市范围）, page: $_page, pageSize: $_pageSize');
      // DEBUG: print('🔍 搜索关键词: ${_searchKeyword.isNotEmpty ? _searchKeyword : "无"}');
      
      // 直接调用HTTP Client获取完整响应（包含location信息）
      final httpClient = HttpClient();
      final queryParams = <String, dynamic>{
        'latitude': _currentPosition!.latitude,
        'longitude': _currentPosition!.longitude,
        'radius': 1000,  // 1000km范围，覆盖整个城市（同城博物馆不限制距离）
        'page': _page,
        'pageSize': _pageSize,
      };
      
      if (_searchKeyword.isNotEmpty) {
        queryParams['name'] = _searchKeyword;
      }
      
      final response = await httpClient.get(
        '/api/v1/museums/miniapp/museums/nearby',
        queryParameters: queryParams,
      );
      
      final apiResponse = response.data;
      final responseData = apiResponse['data'] as Map<String, dynamic>;
      
      // 提取location信息并更新城市名称
      final locationData = responseData['location'] as Map<String, dynamic>?;
      if (locationData != null && reset) { // 只在第一次加载时更新城市名称
        // 安全获取字符串字段（处理可能的数组或其他类型）
        String getStringValue(dynamic value) {
          if (value == null) return '';
          
          // 处理数组类型
          if (value is List) {
            if (value.isEmpty) return '';  // 空数组返回空字符串
            return value[0].toString();     // 非空数组取第一个元素
          }
          
          // 处理字符串类型
          if (value is String) {
            // 过滤掉字符串形式的空数组 "[]"
            if (value == '[]' || value.isEmpty) return '';
            return value;
          }
          
          return ''; // 其他情况返回空字符串
        }
        
        final province = getStringValue(locationData['province']);
        final cityName = getStringValue(locationData['cityName']);
        final district = getStringValue(locationData['district']);
        
        // 同城博物馆：只显示市名即可
        // 如果cityName为空（直辖市），则显示省份名
        final locationText = cityName.isNotEmpty ? cityName : province;
        
        // DEBUG: print('📍 解析到城市: $locationText');
        
        // 缓存城市信息到LocationService，避免下次调用高德API
        LocationService.setCachedCityInfo(
          cityCode: locationData['cityCode']?.toString(),
          cityName: cityName,
          province: province,
          district: district,
        );
        
        setState(() {
          _cityName = cityName.isNotEmpty 
              ? cityName 
              : (province.isNotEmpty ? province : '未知位置');
        });
      }
      
      // 解析博物馆列表
      final museumsData = responseData['museums'] as Map<String, dynamic>?;
      final records = (museumsData?['records'] as List<dynamic>?) ?? [];
      final museums = records
          .map((json) => Museum.fromJson(json as Map<String, dynamic>))
          .toList();

      // DEBUG: print('✅ API返回 ${museums.length} 家博物馆');
      if (museums.isNotEmpty) {
        // DEBUG: print('📊 第一家博物馆: ${museums.first.name}, distance=${museums.first.distance}');
      }

      setState(() {
        if (reset) {
          _museums = museums;
        } else {
          _museums.addAll(museums);
        }
        _total = museums.length; // TODO: 从API获取总数
        _hasMore = museums.length == _pageSize;
        _page++;
        _loading = false;
      });

      // DEBUG: print('✅ 博物馆列表加载完成');
    } catch (e) {
      // DEBUG: print('❌ 加载博物馆失败: $e');
      setState(() {
        _loading = false;
      });
      // 不显示错误提示，空状态组件已经足够
    }
  }

  /// 显示定位服务对话框
  Future<void> _showLocationServiceDialog() async {
    final confirmed = await BottomSheetHelper.showConfirm(
      context,
      title: '需要定位服务',
      content: '请在设置中开启定位服务，以获取附近的博物馆信息',
      confirmText: '去设置',
      cancelText: '取消',
      icon: Icons.location_on_outlined,
    );
    
    if (confirmed == true) {
      Geolocator.openLocationSettings();
    }
  }

  /// 显示权限拒绝对话框
  Future<void> _showPermissionDeniedDialog() async {
    final confirmed = await BottomSheetHelper.showConfirm(
      context,
      title: '需要定位权限',
      content: '为了为您推荐附近的博物馆，需要获取您的位置信息',
      confirmText: '去设置',
      cancelText: '取消',
      icon: Icons.location_on_outlined,
    );
    
    if (confirmed == true) {
      Geolocator.requestPermission();
    }
  }

  /// 显示权限永久拒绝对话框
  Future<void> _showPermissionDeniedForeverDialog() async {
    final confirmed = await BottomSheetHelper.showConfirm(
      context,
      title: '需要定位权限',
      content: '定位权限已被永久拒绝，请在设置中手动开启定位权限',
      confirmText: '去设置',
      cancelText: '取消',
      icon: Icons.location_on_outlined,
    );
    
    if (confirmed == true) {
      Geolocator.openAppSettings();
    }
  }

  /// 搜索确认
  void _onSearchConfirm() {
    setState(() {
      _searchKeyword = _searchController.text;
    });
    _loadNearbyMuseums(reset: true);
  }

  /// 清除搜索
  void _onSearchClear() {
    setState(() {
      _searchController.clear();
      _searchKeyword = '';
    });
    _loadNearbyMuseums(reset: true);
  }

  /// 搜索输入变化
  void _onSearchInput(String value) {
    setState(() {
      _searchKeyword = value;
    });
  }

  /// 显示搜索对话框
  void _showSearchDialog() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => _buildFullScreenSearch(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, -1.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  /// 构建全屏搜索界面
  Widget _buildFullScreenSearch() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: '搜索同城博物馆...',
              hintStyle: TextStyle(color: AppColors.textHint, fontSize: 14),
              prefixIcon: Icon(Icons.search, color: AppColors.textHint, size: 20),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            onChanged: _onSearchInput,
            onSubmitted: (_) {
              _onSearchConfirm();
              Navigator.of(context).pop();
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _onSearchConfirm();
              Navigator.of(context).pop();
            },
            child: const Text(
              '搜索',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_searchKeyword.isEmpty) ...[
            const Padding(
              padding: EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '热门博物馆',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildSearchTag('故宫博物院'),
                  _buildSearchTag('中国国家博物馆'),
                  _buildSearchTag('上海博物馆'),
                  _buildSearchTag('南京博物院'),
                  _buildSearchTag('陕西历史博物馆'),
                ],
              ),
            ),
          ],
          if (_searchKeyword.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '搜索结果',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            const Expanded(
              child: Center(
                child: Text(
                  '搜索功能开发中...',
                  style: TextStyle(
                    color: AppColors.textHint,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建搜索标签
  Widget _buildSearchTag(String text) {
    return GestureDetector(
      onTap: () {
        _searchController.text = text;
        _onSearchInput(text);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  /// 用户主动触发重新定位（清除缓存）
  Future<void> _retryLocation() async {
    // DEBUG: print('🔄 [同城博物馆] 用户主动重新定位');
    
    // 清除所有缓存，强制获取新位置和城市信息
    LocationService.clearCache();
    LocationService.clearCachedCityInfo();
    
    // 重置状态
    setState(() {
      _cityName = '定位中...';
      _locationError = false;
      _currentPosition = null;
      _museums.clear(); // 清空列表
    });
    
    // 获取新位置，传入 forceRefresh=true 强制重新定位
    await _getCurrentLocation(forceRefresh: true);
  }

  /// 下拉刷新（清除缓存强制重新定位）
  Future<void> _onRefresh() async {
    print('🔄 [同城博物馆] 开始下拉刷新');
    
    // 清除所有缓存，强制获取新位置和城市信息
    LocationService.clearCache();
    LocationService.clearCachedCityInfo();
    
    // 不清空现有数据，保持用户体验
    setState(() {
      _locationError = false;
      _currentPosition = null;
      // 不清空 _museums，保持现有数据显示
    });
    
    // 强制重新定位
    await _getCurrentLocation(forceRefresh: true);
    
    print('✅ [同城博物馆] 下拉刷新完成');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  /// 构建 AppBar
  PreferredSizeWidget _buildAppBar() {
    // 获取城市名称，去掉"市"字
    String cityDisplayName = _cityName;
    if (cityDisplayName.endsWith('市')) {
      cityDisplayName = cityDisplayName.substring(0, cityDisplayName.length - 1);
    }
    
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/');
          }
        },
      ),
      title: Text(
        _locationError ? '同城博物馆' : '同城博物馆 · $cityDisplayName',
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: AppColors.textPrimary),
          onPressed: _showSearchDialog,
        ),
      ],
    );
  }


  /// 构建主体内容
  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppColors.primaryLight, // 浅粉色刷新指示器，与首页一致
      child: _buildScrollableContent(),
    );
  }

  /// 构建可滚动内容
  Widget _buildScrollableContent() {
    if (_locationError) {
      return _buildLocationErrorScrollable();
    }

    if (_loading && _museums.isEmpty) {
      return _buildLoadingStateScrollable();
    }

    if (_museums.isEmpty) {
      return _buildEmptyStateScrollable();
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingM),
      itemCount: _museums.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          // 列表头部 - 总数（匹配小程序）
          return Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 12),
            child: Text(
              '同城共有 $_total 家博物馆',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          );
        }

        final museum = _museums[index - 1];
        return _buildMuseumCard(museum);
      },
    );
  }

  /// 构建可滚动的定位错误状态
  Widget _buildLocationErrorScrollable() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
        _buildLocationErrorContent(),
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
      ],
    );
  }

  /// 构建可滚动的加载状态
  Widget _buildLoadingStateScrollable() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
        _buildLoadingStateContent(),
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
      ],
    );
  }

  /// 构建可滚动的空状态
  Widget _buildEmptyStateScrollable() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
        _buildEmptyStateContent(),
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
      ],
    );
  }

  /// 构建定位错误内容
  Widget _buildLocationErrorContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📍', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text(
            '需要定位权限',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '为了为您展示同城的博物馆\n需要获取您的位置信息',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _retryLocation,
            child: const Text('重新定位'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Geolocator.openAppSettings(),
            child: const Text('打开设置'),
          ),
        ],
      ),
    );
  }

  /// 构建定位错误状态
  Widget _buildLocationError() {
    return Center(
      child: _buildLocationErrorContent(),
    );
  }

  /// 构建加载状态内容
  Widget _buildLoadingStateContent() {
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

  /// 构建加载状态
  Widget _buildLoadingState() {
    return Center(
      child: _buildLoadingStateContent(),
    );
  }

  /// 构建空状态内容
  Widget _buildEmptyStateContent() {
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
          const Text('同城暂无博物馆'),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _onRefresh,
            child: const Text('刷新'),
          ),
        ],
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Center(
      child: _buildEmptyStateContent(),
    );
  }

  /// 构建博物馆卡片 - 图片为主的卡片设计
  Widget _buildMuseumCard(Museum museum) {
    return GestureDetector(
      onTap: () {
        // 跳转到博物馆详情页
        context.push('/museum/${museum.id}');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 200, // 固定高度，让图片更突出
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // 背景图片（全覆盖）
              Positioned.fill(
                child: _getMuseumImageUrl(museum) != null
                    ? CachedNetworkImage(
                        imageUrl: _getMuseumImageUrl(museum)!,
                        fit: BoxFit.cover,
                        memCacheWidth: 600, // 适配卡片宽度
                        memCacheHeight: 400, // 适配卡片高度
                        errorWidget: (context, url, error) => _buildDefaultBackground(),
                      )
                    : _buildDefaultBackground(),
              ),
              
              // 渐变遮罩（从透明到半透明黑色）
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.3),
                        Colors.black.withValues(alpha: 0.7),
                      ],
                      stops: const [0.0, 0.4, 0.7, 1.0],
                    ),
                  ),
                ),
              ),
              
              // 底部信息区域
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 博物馆名称
                      Text(
                        museum.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 3,
                              color: Colors.black26,
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 6),
                      
                      // 地址信息
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              museum.address ?? museum.cityName ?? '地址未知',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white70,
                                shadows: [
                                  Shadow(
                                    offset: Offset(0, 1),
                                    blurRadius: 2,
                                    color: Colors.black26,
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // 标签和距离信息（同一行）
                      Row(
                        children: [
                          // 标签组
                          if (museum.categories != null && museum.categories!.isNotEmpty)
                            _buildOverlayTag(museum.categories!.first.name, AppColors.primary),
                          if (museum.level == 1) ...[
                            const SizedBox(width: 6),
                            _buildOverlayTag('一级博物馆', AppColors.warning),
                          ],
                          if (museum.freeAdmission == 1) ...[
                            const SizedBox(width: 6),
                            _buildOverlayTag('免费参观', AppColors.success),
                          ],
                          
                          // 弹性空间，将距离推到右侧
                          const Spacer(),
                          
                          // 距离标签
                          if (museum.distance != null && museum.distance!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                museum.distance!,
                                style: const TextStyle(
                                  fontSize: 12,
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建元数据标签（灰色背景）
  Widget _buildMetaTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  /// 构建默认图片
  Widget _buildDefaultImage() {
    return const Center(
      child: Text('🏛️', style: TextStyle(fontSize: 48)),
    );
  }

  /// 构建默认背景（用于卡片背景）
  Widget _buildDefaultBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.8),
            AppColors.primaryDark.withValues(alpha: 0.9),
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.museum,
          size: 64,
          color: Colors.white70,
        ),
      ),
    );
  }

  /// 构建叠加标签（用于图片上的标签）
  Widget _buildOverlayTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }

  /// 构建标签（带边框）
  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  /// 获取博物馆图片URL - 优先级：imageUrls.first → imageUrl → coverImage → null
  String? _getMuseumImageUrl(Museum museum) {
    // 1. 优先使用 imageUrls 的第一张图片
    if (museum.imageUrls != null && museum.imageUrls!.isNotEmpty) {
      return museum.imageUrls!.first;
    }
    
    // 2. 备用：使用 imageUrl 字段
    if (museum.imageUrl != null && museum.imageUrl!.isNotEmpty) {
      return museum.imageUrl;
    }
    
    // 3. 备用：使用 coverImage 字段
    if (museum.coverImage != null && museum.coverImage!.isNotEmpty) {
      return museum.coverImage;
    }
    
    return null;
  }
}

