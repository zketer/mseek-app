// ignore_for_file: use_build_context_synchronously
// ignore_for_file: dead_null_aware_expression
import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/services/location_service.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/checkin_utils.dart';
import '../../../core/utils/ui_helper.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/router/auth_guard.dart';
import '../../../models/museum.dart';
import '../../../services/api/museum_service.dart';
import '../../../services/api/checkin_service.dart';
import '../../../services/api/http_client.dart';
import '../../../services/auth/auth_service.dart';
import '../../../widgets/common/modern_dialog.dart';
import '../../../widgets/common/simple_empty_state.dart';
import '../../../widgets/checkin/checkin_card_skeleton.dart';
import '../../../widgets/common/app_page_wrapper.dart';

/// 打卡页面 - 完全匹配小程序设计的简洁布局
class CheckinScreen extends StatefulWidget {
  const CheckinScreen({super.key});

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  // ignore: unused_field
  final MuseumService _museumService = MuseumService();
  final CheckinService _checkinService = CheckinService();
  final AuthService _authService = AuthService();
  
  // ignore: unused_field
  bool _isLocationEnabled = false;
  String _currentLocation = '正在获取位置...';
  Position? _currentPosition;
  bool _locationError = false; // 定位是否失败
  int _selectedDistance = 10; // 选中的距离范围（公里）
  int _draftCount = 0; // 暂存草稿数量（从API加载）
  bool _isLoggedIn = true;
  bool _isLoadingNearby = false;
  // ignore: unused_field
  bool _isLoadingHistory = false;
  // ignore: unused_field
  bool _isLoadingDraft = false;
  
  // 初始加载状态（包括定位+数据加载）
  bool _isInitialLoading = true;

  // 最近的博物馆（动态更新）
  Map<String, dynamic>? _nearestMuseum;

  // 最近打卡记录 - 从API加载
  List<Map<String, dynamic>> _checkinHistory = [];

  // 真实数据 - 附近博物馆
  List<Museum> _nearbyMuseums = [];

  @override
  void initState() {
    super.initState();
    // 异步初始化，不阻塞UI
    _initializeData();
  }
  
  /// 初始化数据 - 并发加载所有数据
  Future<void> _initializeData() async {
    final totalStopwatch = Stopwatch()..start();
    print('⏱️ [性能监控] 开始加载打卡页面数据');
    
    setState(() {
      _isInitialLoading = true;
    });
    
    try {
      // 并发执行定位和用户数据加载
      await Future.wait([
        _initLocation(),
        _loadRecentCheckins(),
        _loadDraftCount(),
      ], eagerError: false);
      
      totalStopwatch.stop();
      print('⏱️ [性能监控] 打卡页面总耗时: ${totalStopwatch.elapsedMilliseconds}ms');
    } finally {
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
        });
      }
    }
  }

  /// 初始化位置服务（智能缓存策略）
  /// 策略：优先使用缓存位置，只有缓存过期或不存在时才重新定位
  /// - 有新鲜缓存（5分钟内）：直接使用，秒开（<100ms）
  /// - 无缓存或过期：使用LastKnownPosition立即显示，后台定位一次
  /// 
  /// [forceRefresh] 是否强制刷新（忽略缓存）
  /// - false（默认）: 正常加载，可使用5分钟缓存，快速显示
  /// - true: 强制重新定位（用户主动点击刷新按钮时）
  Future<void> _initLocation({bool forceRefresh = false}) async {
    final stopwatch = Stopwatch()..start();
    try {
      if (forceRefresh) {
        print('📍 [性能监控] 🔄 强制刷新定位（不使用缓存）...');
      } else {
        print('📍 [性能监控] 开始智能定位（可使用5分钟缓存）...');
      }

      // 根据 forceRefresh 参数决定是否使用缓存：
      // - 正常打开页面：useCachedPosition=true，可使用5分钟缓存，快速显示（<1秒）
      // - 用户点击刷新：useCachedPosition=false，强制重新获取GPS，确保准确（3-5秒）
      final cachedResult = await LocationService.getCurrentLocation(
        desiredAccuracy: LocationAccuracy.high,
        timeoutSeconds: 8,
        useCachedPosition: !forceRefresh,  // 强制刷新时不使用缓存
      );
      
      stopwatch.stop();
      
      if (cachedResult.success && cachedResult.position != null) {
        print('✅ [性能监控] 定位成功，耗时: ${stopwatch.elapsedMilliseconds}ms');
        
        setState(() {
          _currentPosition = cachedResult.position;
          _isLocationEnabled = true;
          _currentLocation = '定位成功';
          _locationError = false;
        });

        // 加载附近博物馆
        _loadNearbyMuseums();
      } else {
        print('❌ [性能监控] 定位失败: ${cachedResult.errorMessage}，耗时: ${stopwatch.elapsedMilliseconds}ms');
        setState(() {
          _currentPosition = null;
          _isLocationEnabled = false;
          _currentLocation = cachedResult.errorMessage ?? '定位失败';
          _locationError = true;
        });
      }
      
    } catch (e) {
      stopwatch.stop();
      print('❌ [性能监控] 定位异常: $e, 耗时: ${stopwatch.elapsedMilliseconds}ms');
      setState(() {
        _currentLocation = '位置获取失败';
        _locationError = true;
      });
    }
  }

  /// 计算两点间距离（Haversine公式）
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371.0; // 地球半径（公里）
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
            sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  /// 格式化距离显示
  String _formatDistance(double km) {
    if (km < 1) {
      return '${(km * 1000).round()}m';
    } else {
      return '${km.toStringAsFixed(1)}km';
    }
  }

  /// 加载附近博物馆（完全匹配小程序逻辑）
  Future<void> _loadNearbyMuseums() async {
    final stopwatch = Stopwatch()..start();
    
    if (_currentPosition == null) {
      print('⚠️ [性能监控] 当前位置为空，无法加载附近博物馆');
      return;
    }

    print('🔄 [性能监控] 开始加载附近博物馆...');
    print('📍 [性能监控] 坐标: (${_currentPosition!.latitude}, ${_currentPosition!.longitude})');
    print('📏 [性能监控] 筛选距离: ${_selectedDistance}km');

    setState(() {
      _isLoadingNearby = true;
    });

    try {
      // 获取缓存的城市信息（优化：避免重复调用高德API）
      final cachedCityInfo = LocationService.getCachedCityInfo();
      print('🔍 [性能监控] 城市缓存: $cachedCityInfo');
      
      final apiStopwatch = Stopwatch()..start();
      // 直接调用API获取完整响应数据（包含location信息）
      final httpClient = HttpClient();
      final response = await httpClient.get(
        '/api/v1/museums/miniapp/museums/nearby',
        queryParameters: {
          'latitude': _currentPosition!.latitude,
          'longitude': _currentPosition!.longitude,
          'radius': _selectedDistance, // 使用用户选择的距离
          'page': 1,
          'pageSize': 20,  // 优化：从100减少到20，减少0.3-0.5秒
          // 优化：传递缓存的城市信息，避免后端调用高德API
          if (cachedCityInfo['cityCode'] != null) 'cityCode': cachedCityInfo['cityCode'],
          if (cachedCityInfo['cityName'] != null) 'cityName': cachedCityInfo['cityName'],
        },
      );
      
      apiStopwatch.stop();
      print('🌐 [性能监控] API响应耗时: ${apiStopwatch.elapsedMilliseconds}ms');
      
      final apiResponse = response.data;
      final responseData = apiResponse['data'] as Map<String, dynamic>;
      
      // 提取location信息并更新定位显示
      final locationData = responseData['location'] as Map<String, dynamic>?;
      if (locationData != null) {
        // DEBUG: print('🔍 [调试] location原始数据: $locationData');
        
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
        
        // DEBUG: print('🔍 [调试] province="$province", cityName="$cityName", district="$district"');
        
        // 拼接显示文本：优先显示市名，没有市名才显示省名（直辖市情况）
        final parts = <String>[];
        
        // 优先显示市名，如果没有市名则显示省名（直辖市）
        if (cityName.isNotEmpty) {
          parts.add(cityName);
        } else if (province.isNotEmpty) {
          parts.add(province);
        }
        
        // 添加区名
        if (district.isNotEmpty) {
          parts.add(district);
        }
        
        final locationText = parts.join('·');
        
        // DEBUG: print('📍 [定位] 解析到位置: $locationText');
        
        // 优化：缓存城市信息到LocationService，避免下次调用高德API
        LocationService.setCachedCityInfo(
          cityCode: locationData['cityCode']?.toString(),
          cityName: cityName,
          province: province,
          district: district,
        );
        
        setState(() {
          _currentLocation = locationText.isNotEmpty ? locationText : '定位成功';
        });
      }
      
      // 解析博物馆列表
      final museumsData = responseData['museums'] as Map<String, dynamic>?;
      final records = (museumsData?['records'] as List<dynamic>?) ?? [];
      final museums = records
          .map((json) => Museum.fromJson(json as Map<String, dynamic>))
          .toList();

      // DEBUG: print('✅ API返回 ${museums.length} 家博物馆');

      // ✅ 后端已根据radius过滤并返回distance，前端直接使用
      // 如果后端没有返回distance，前端兜底计算（正常情况下不会走到这里）
      final processedMuseums = museums.map((museum) {
        // 如果后端已返回distance且不为空，直接使用
        if (museum.distance != null && museum.distance!.isNotEmpty) {
          return museum;
        }
        
        // 兜底：如果后端没返回distance，前端计算（理论上不会发生）
        if (museum.latitude != null && museum.longitude != null) {
          final distanceKm = _calculateDistance(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            museum.latitude!,
            museum.longitude!,
          );
          return museum.copyWith(distance: _formatDistance(distanceKm));
        }
        
        // 没有坐标信息，返回原数据
        return museum;
      })
      // ✅ 不再需要前端过滤！后端已经根据radius参数过滤了
      // 后端返回的museums已经全部在指定radius范围内
      .take(10)
      .toList();

      // DEBUG: print('📏 筛选后: ${processedMuseums.length} 家博物馆在 ${_selectedDistance}km 内');
      if (processedMuseums.isNotEmpty) {
        // DEBUG: print('📊 第一家: ${processedMuseums.first.name}, distance=${processedMuseums.first.distance}');
      }

      // 更新最近的博物馆（距离最近的）
      Map<String, dynamic>? nearestMuseum;
      if (processedMuseums.isNotEmpty) {
        final closest = processedMuseums.first;
        final distanceStr = closest.distance ?? '未知';
        
        // 使用工具类判断是否可以打卡
        final canCheckin = CheckinUtils.canCheckinByDistanceString(distanceStr);
        
        nearestMuseum = {
          'id': closest.id,
          'name': closest.name,
          'imageUrls': closest.imageUrls,
          'imageUrl': closest.imageUrl,
          'coverImage': closest.coverImage,
          'distance': distanceStr,
          'canCheckin': canCheckin,
        };
        // DEBUG: print('🎯 更新最近博物馆: ${closest.name}, 距离=${distanceStr}, canCheckin=$canCheckin');
      } else {
        nearestMuseum = {
          'id': 0,
          'name': '该地区暂无博物馆',
          'image': null,
          'distance': '无数据',
          'canCheckin': false,
        };
        // DEBUG: print('⚠️ 附近无博物馆');
      }

      setState(() {
        _nearbyMuseums = processedMuseums;
        _nearestMuseum = nearestMuseum;
        _isLoadingNearby = false;
      });
      
      stopwatch.stop();
      print('🏛️ [性能监控] 加载附近博物馆完成，总耗时: ${stopwatch.elapsedMilliseconds}ms');
    } catch (e) {
      stopwatch.stop();
      print('❌ [性能监控] 加载附近博物馆失败: $e, 耗时: ${stopwatch.elapsedMilliseconds}ms');
      setState(() {
        _isLoadingNearby = false;
      });
    }
  }

  /// 加载最近打卡记录（匹配小程序逻辑）
  Future<void> _loadRecentCheckins() async {
    final stopwatch = Stopwatch()..start();
    print('📝 [性能监控] 开始加载最近打卡记录...');
    
    // 检查登录状态
    final isLoggedIn = await _authService.isLoggedIn();
    if (!isLoggedIn) {
      stopwatch.stop();
      print('⚠️ [性能监控] 未登录，跳过加载打卡记录，耗时: ${stopwatch.elapsedMilliseconds}ms');
      setState(() {
        _isLoggedIn = false;
        _checkinHistory = [];
      });
      return;
    }

    setState(() {
      _isLoadingHistory = true;
      _isLoggedIn = true;
    });

    try {
      // 获取最近5条正式打卡记录
      final pageResult = await _checkinService.getUserCheckinRecords(
        page: 1,
        pageSize: 5,
        isDraft: false, // 只获取正式打卡记录
      );

      // DEBUG: print('✅ API返回 ${pageResult.records.length} 条打卡记录');

      // 转换数据格式
      final checkinHistory = pageResult.records.map((record) {
        return {
          'id': record.id,
          'museumName': record.museumName ?? '未知博物馆',
          'image': null, // 使用默认图片
          'checkinTime': _formatCheckinTime(record.checkInDate),
          'points': _calculatePoints(record), // 根据打卡记录计算积分
        };
      }).toList();

      setState(() {
        _checkinHistory = checkinHistory;
        _isLoadingHistory = false;
      });

      stopwatch.stop();
      print('✅ [性能监控] 最近打卡记录加载完成，共 ${checkinHistory.length} 条，耗时: ${stopwatch.elapsedMilliseconds}ms');
    } catch (e) {
      stopwatch.stop();
      print('❌ [性能监控] 加载最近打卡记录失败: $e, 耗时: ${stopwatch.elapsedMilliseconds}ms');
      setState(() {
        _checkinHistory = [];
        _isLoadingHistory = false;
      });
    }
  }

  /// 格式化打卡时间显示
  String _formatCheckinTime(dynamic checkinTime) {
    if (checkinTime == null) return '未知时间';
    
    try {
      final DateTime dateTime;
      if (checkinTime is String) {
        dateTime = DateTime.parse(checkinTime);
      } else if (checkinTime is DateTime) {
        dateTime = checkinTime;
      } else {
        return '未知时间';
      }

      return AppDateUtils.formatRelativeTimeWithClock(dateTime);
    } catch (e) {
      return '未知时间';
    }
  }

  /// 计算积分
  int _calculatePoints(CheckinRecord record) {
    // 基础积分
    int points = 10;
    
    // 根据打卡记录的完整度增加积分
    if (record.photos != null && record.photos!.isNotEmpty) {
      points += 5; // 有照片
    }
    if (record.notes != null && record.notes!.isNotEmpty) {
      points += 5; // 有笔记
    }
    
    return points;
  }

  /// 加载暂存草稿数量（匹配小程序逻辑）
  Future<void> _loadDraftCount() async {
    final stopwatch = Stopwatch()..start();
    print('📋 [性能监控] 开始加载草稿数量...');
    
    // 检查登录状态
    final isLoggedIn = await _authService.isLoggedIn();
    if (!isLoggedIn) {
      stopwatch.stop();
      print('⚠️ [性能监控] 未登录，跳过加载草稿数量，耗时: ${stopwatch.elapsedMilliseconds}ms');
      setState(() {
        _isLoggedIn = false;
        _draftCount = 0;
      });
      return;
    }

    setState(() {
      _isLoadingDraft = true;
      _isLoggedIn = true;
    });

    try {
      // 获取草稿记录
      final pageResult = await _checkinService.getUserCheckinRecords(
        page: 1,
        pageSize: 1, // 只需要获取总数，不需要具体记录
        isDraft: true, // 只查询草稿
      );

      final draftCount = pageResult.total; // 使用total字段获取总数

      setState(() {
        _draftCount = draftCount;
        _isLoadingDraft = false;
      });

      stopwatch.stop();
      print('✅ [性能监控] 草稿数量加载完成：$draftCount 个，耗时: ${stopwatch.elapsedMilliseconds}ms');
    } catch (e) {
      stopwatch.stop();
      print('❌ [性能监控] 加载草稿数量失败: $e, 耗时: ${stopwatch.elapsedMilliseconds}ms');
      setState(() {
        _draftCount = 0;
        _isLoadingDraft = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // 匹配小程序背景色
      body: AppPageWrapper(
        safeAreaTop: false, // 打卡页不使用顶部安全区域，让内容延伸到状态栏
        child: _isInitialLoading 
          ? _buildLoadingState() 
          : SingleChildScrollView(
              child: Column(
                children: [
                  // 添加状态栏高度的占位
                  SizedBox(height: MediaQuery.of(context).padding.top),
                  // 打卡卡片
                  _buildCheckinCard(),
                  
                  // 暂存卡片
                  if (_isLoggedIn && _draftCount > 0) _buildDraftCard(),
                  
                  // 最近打卡记录
                  _buildHistorySection(),
                  
                  // 附近博物馆
                  _buildNearbySection(),
                  
                  // 底部间距
                  const SizedBox(height: 80),
                ],
              ),
            ),
      ),
    );
  }
  
  /// 构建加载状态（骨架屏）
  Widget _buildLoadingState() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // 打卡卡片骨架
          const CheckinCardSkeleton(),
          
          // 提示文字
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryLight),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '正在获取位置和附近博物馆...',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建主打卡卡片 - 完全匹配小程序设计
  Widget _buildCheckinCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16), // 顶部不需要边距，因为已经有状态栏占位
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), // 32rpx
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 卡片头部 - 位置信息
          _buildLocationHeader(),
          
          // 卡片内容 - 博物馆信息
          _buildMuseumContent(),
          
          // 卡片操作 - 打卡按钮
          _buildActionButtons(),
        ],
      ),
    );
  }

  /// 构建位置信息头部
  Widget _buildLocationHeader() {
    // 定位成功且不显示错误时，隐藏位置信息头部
    if (!_locationError && _currentLocation == '定位成功') {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM), // 32rpx
      child: Row(
        children: [
          // 定位信息 + 刷新按钮（作为一个整体，紧凑布局）
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '📍',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 6),
              Text(
                _currentLocation,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 14, // 28rpx
                ),
              ),
              const SizedBox(width: 6),
              // 刷新按钮（紧贴定位文字）
              GestureDetector(
                onTap: _refreshLocation,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.refresh,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }

  /// 构建博物馆内容
  Widget _buildMuseumContent() {
    // 如果定位失败，显示空状态
    if (_locationError) {
      return Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: SimpleEmptyState(
          icon: Icons.location_off_outlined,
          message: _currentLocation,
          subtitle: '请检查定位权限或刷新重试',
        ),
      );
    }
    
    // 如果没有最近的博物馆且不在加载中，显示无数据状态
    // 注意：这里不显示loading，避免与下方"附近博物馆"区域的loading重复
    if (_nearestMuseum == null && !_isLoadingNearby) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Center(
          child: SimpleEmptyState(
            icon: Icons.museum_outlined,
            message: '附近暂无博物馆',
            subtitle: '试试调整搜索范围',
          ),
        ),
      );
    }
    
    // 如果正在加载且没有数据，显示占位符（避免布局跳动）
    if (_nearestMuseum == null && _isLoadingNearby) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: SizedBox(
          height: 80,
          child: Center(
            child: Text(
              '正在加载...',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), // 32rpx 0 32rpx 32rpx
      child: Row(
        children: [
          // 博物馆图片
          ClipRRect(
            borderRadius: BorderRadius.circular(8), // 16rpx
            child: SizedBox(
              width: 80, // 160rpx
              height: 80,
              child: _getMuseumImageUrl(_nearestMuseum!) != null
                  ? CachedNetworkImage(
                      imageUrl: _getMuseumImageUrl(_nearestMuseum!)!,
                      fit: BoxFit.cover,
                      memCacheWidth: 160, // 限制内存缓存尺寸（80px * 2 = 160）
                      memCacheHeight: 160, // 限制内存缓存尺寸（80px * 2 = 160）
                      placeholder: (context, url) => Container(
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                        ),
                        child: const Icon(
                          Icons.museum,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                        ),
                        child: const Icon(
                          Icons.museum,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                      ),
                      child: const Icon(
                        Icons.museum,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
            ),
          ),
          
          const SizedBox(width: 16), // 32rpx
          
          // 博物馆信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 博物馆名称
                Text(
                  _nearestMuseum!['name'],
                  style: AppTextStyles.titleMedium.copyWith(
                    fontSize: 16, // 32rpx
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 8), // 16rpx
                
                // 距离信息
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 12, // 24rpx
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4), // 8rpx
                    Text(
                      '距离${_nearestMuseum!['distance']}',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 12, // 24rpx
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8), // 16rpx
                
                // 状态信息
                Row(
                  children: [
                    Container(
                      width: 8, // 16rpx
                      height: 8,
                      decoration: BoxDecoration(
                        color: _nearestMuseum!['canCheckin'] 
                            ? AppColors.infoSky 
                            : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8), // 16rpx
                    Text(
                      _nearestMuseum!['canCheckin'] ? '在打卡范围内' : '距离过远，无法打卡',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 12, // 24rpx
                        color: _nearestMuseum!['canCheckin'] 
                            ? AppColors.infoSky
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建操作按钮
  Widget _buildActionButtons() {
    // 如果定位失败或没有博物馆数据，隐藏按钮
    if (_locationError || _nearestMuseum == null) {
      return const SizedBox.shrink();
    }
    
    final canCheckin = _nearestMuseum!['canCheckin'] ?? false;
    final buttonText = canCheckin ? '立即打卡' : '前往博物馆';
    
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), // 32rpx 0 32rpx 32rpx
      child: SizedBox(
        width: double.infinity,
        height: 44, // 88rpx
        child: ElevatedButton(
          onPressed: canCheckin ? _performCheckin : _navigateToMuseum,
          style: ElevatedButton.styleFrom(
            backgroundColor: canCheckin 
                ? AppColors.infoSky 
                : Colors.grey[400],
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22), // 44rpx
            ),
          ),
          child: Text(
            buttonText,
            style: AppTextStyles.titleMedium.copyWith(
              fontSize: 16, // 32rpx
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  /// 构建暂存卡片
  Widget _buildDraftCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16), // 32rpx 0 32rpx 32rpx
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12), // 24rpx
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _viewDraftList,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingM), // 32rpx
            child: Row(
              children: [
                const Text(
                  '📝',
                  style: TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12), // 24rpx
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '暂存草稿',
                        style: AppTextStyles.titleMedium.copyWith(
                          fontSize: 15, // 30rpx
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4), // 8rpx
                      Text(
                        '$_draftCount个未完成的打卡',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 12, // 24rpx
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建最近打卡记录部分
  Widget _buildHistorySection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16), // 32rpx 0 32rpx 32rpx
      child: Column(
        children: [
          // 标题栏
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4), // 8rpx
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '最近打卡',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontSize: 16, // 32rpx
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: _viewHistory,
                  child: Text(
                    '查看全部',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 13, // 26rpx
                      color: AppColors.textHint, // 灰色
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12), // 24rpx
          
          // 打卡记录列表
          if (_checkinHistory.isNotEmpty)
            ..._checkinHistory.map((item) => _buildHistoryItem(item))
          else
            _buildEmptyHistory(),
        ],
      ),
    );
  }

  /// 构建历史记录项
  Widget _buildHistoryItem(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12), // 24rpx
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12), // 24rpx
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _viewHistoryDetail(item['id']),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12), // 24rpx
            child: Row(
              children: [
                // 博物馆图片
                ClipRRect(
                  borderRadius: BorderRadius.circular(8), // 16rpx
                  child: SizedBox(
                    width: 50, // 100rpx
                    height: 50,
                    child: _getMuseumImageUrl(item) != null
                        ? CachedNetworkImage(
                            imageUrl: _getMuseumImageUrl(item)!,
                            fit: BoxFit.cover,
                            memCacheWidth: 100, // 限制内存缓存尺寸（50px * 2 = 100）
                            memCacheHeight: 100, // 限制内存缓存尺寸（50px * 2 = 100）
                            placeholder: (context, url) => Container(
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                              ),
                              child: const Icon(
                                Icons.museum,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                              ),
                              child: const Icon(
                                Icons.museum,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                            ),
                            child: const Icon(
                              Icons.museum,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                  ),
                ),
                
                const SizedBox(width: 12), // 24rpx
                
                // 打卡信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['museumName'],
                        style: AppTextStyles.titleMedium.copyWith(
                          fontSize: 14, // 28rpx
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4), // 8rpx
                      Text(
                        item['checkinTime'],
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 12, // 24rpx
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 积分
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // 16rpx 8rpx
                  decoration: BoxDecoration(
                    color: AppColors.infoSky.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12), // 24rpx
                  ),
                  child: Text(
                    '+${item['points']}积分',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 11, // 22rpx
                      color: AppColors.infoSky,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建空历史状态
  Widget _buildEmptyHistory() {
    return Container(
      padding: const EdgeInsets.all(40), // 80rpx
      child: Column(
        children: [
          Icon(
            Icons.access_time,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16), // 32rpx
          Text(
            '还没有打卡记录',
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 14, // 28rpx
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8), // 16rpx
          Text(
            '去发现页面找找心仪的博物馆吧',
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 12, // 24rpx
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建附近博物馆部分
  Widget _buildNearbySection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16), // 32rpx 0 32rpx 32rpx
      child: Column(
        children: [
          // 标题栏和距离选择器
          _buildNearbySectionHeader(),
          
          const SizedBox(height: 12), // 24rpx
          
          // 附近博物馆列表
          // 只在非初始加载时显示loading（初始加载已经有全屏loading了）
          if (_isLoadingNearby && !_isInitialLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: AppColors.primaryLight),
              ),
            )
          else if (_nearbyMuseums.isEmpty && !_isLoadingNearby)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingL),
              child: SimpleEmptyState(
                icon: Icons.museum_outlined,
                message: '附近暂无博物馆',
                subtitle: '试试调整搜索范围',
                iconSize: 48,
              ),
            )
          else
            ..._nearbyMuseums.map((museum) => _buildNearbyMuseumItem(museum)),
        ],
      ),
    );
  }

  /// 构建附近博物馆标题栏
  Widget _buildNearbySectionHeader() {
    return Row(
      children: [
        Text(
          '附近博物馆',
          style: AppTextStyles.titleMedium.copyWith(
            fontSize: 16, // 32rpx
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        
        const Spacer(),
        
        // 距离选择器
        Row(
          children: [
            Text(
              '范围',
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 13, // 26rpx
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(width: 8), // 16rpx
            
            // 距离选项
            Row(
              children: [10, 30, 50].map((distance) {
                final isSelected = _selectedDistance == distance;
                return GestureDetector(
                  onTap: () => _onDistanceSelect(distance),
                  child: Container(
                    margin: const EdgeInsets.only(right: 4), // 8rpx
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // 16rpx 8rpx
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.infoSky : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12), // 24rpx
                    ),
                    child: Text(
                      distance.toString(),
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 11, // 22rpx
                        color: isSelected ? Colors.white : Colors.grey[600],
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(width: 4), // 8rpx
            Text(
              'km',
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 13, // 26rpx
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建附近博物馆项
  Widget _buildNearbyMuseumItem(Museum museum) {
    // 使用工具类判断是否可打卡
    final canCheckin = CheckinUtils.canCheckinByDistanceString(museum.distance);

    return Container(
      margin: const EdgeInsets.only(bottom: 12), // 24rpx
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12), // 24rpx
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (canCheckin) {
              // 可以打卡，跳转到打卡页面
              context.go('/checkin/action/${museum.id}');
            } else {
              // 不能打卡，跳转到博物馆详情
              _viewMuseumDetail(museum.id);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12), // 24rpx
            child: Row(
              children: [
                // 博物馆图片
                ClipRRect(
                  borderRadius: BorderRadius.circular(8), // 16rpx
                  child: SizedBox(
                    width: 60, // 120rpx
                    height: 60,
                    child: _getMuseumImageUrlFromMuseum(museum) != null
                        ? CachedNetworkImage(
                            imageUrl: _getMuseumImageUrlFromMuseum(museum)!,
                            fit: BoxFit.cover,
                            memCacheWidth: 120, // 限制内存缓存尺寸（60px * 2 = 120）
                            memCacheHeight: 120, // 限制内存缓存尺寸（60px * 2 = 120）
                            placeholder: (context, url) => Container(
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                              ),
                              child: const Icon(Icons.museum, color: Colors.white, size: 28),
                            ),
                            errorWidget: (context, url, error) => Container(
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                              ),
                              child: const Icon(Icons.museum, color: Colors.white, size: 28),
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                            ),
                            child: const Icon(Icons.museum, color: Colors.white, size: 28),
                          ),
                  ),
                ),
                
                const SizedBox(width: 12), // 24rpx
                
                // 博物馆信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        museum.name,
                        style: AppTextStyles.titleMedium.copyWith(
                          fontSize: 14, // 28rpx
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6), // 12rpx
                      
                      // 距离信息
                      if (museum.distance != null && museum.distance!.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 12, // 24rpx
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4), // 8rpx
                            Text(
                              '距离${museum.distance}',
                              style: AppTextStyles.bodySmall.copyWith(
                                fontSize: 12, // 24rpx
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 6), // 12rpx
                      
                      // 状态信息
                      Row(
                        children: [
                          Container(
                            width: 6, // 12rpx
                            height: 6,
                            decoration: BoxDecoration(
                              color: canCheckin 
                                  ? AppColors.infoSky 
                                  : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6), // 12rpx
                          Text(
                            canCheckin ? '可打卡' : '距离过远',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 11, // 22rpx
                              color: canCheckin 
                                  ? AppColors.infoSky
                                  : Colors.grey[600],
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
        ),
      ),
    );
  }

  /// 刷新位置
  void _refreshLocation() {
    // 清除所有缓存，强制获取新位置和城市信息
    LocationService.clearCache();
    LocationService.clearCachedCityInfo();
    
    setState(() {
      _currentLocation = '正在获取位置...';
      _isLocationEnabled = false;
    });
    
    // 传入 forceRefresh=true，强制重新定位，不使用任何缓存
    _initLocation(forceRefresh: true);
  }

  /// 执行打卡 - 添加登录检查
  Future<void> _performCheckin() async {
    if (_nearestMuseum == null) {
      UIHelper.showInfo(context, '正在加载博物馆信息，请稍候...');
      return;
    }
    
    final museumId = _nearestMuseum!['id'] as int;
    if (museumId == 0) {
      UIHelper.showInfo(context, '该地区暂无可打卡的博物馆');
      return;
    }
    
    // 检查登录状态
    final isLoggedIn = await _authService.isLoggedIn();
    if (!isLoggedIn) {
      // 使用统一的登录提示框
      if (mounted) {
        await requireAuth(
          context,
          options: AuthGuardOptions(
            title: '登录后打卡',
            content: '记录您的博物馆之旅，解锁更多精彩功能',
            confirmText: '去登录',
            showCancel: true,
            targetPath: '/checkin/action/$museumId',
          ),
        );
      }
      return;
    }
    
    // DEBUG: print('🎯 导航到打卡页面，博物馆ID: $museumId, 名称: ${_nearestMuseum!['name']}');
    if (mounted) {
      context.go('/checkin/action/$museumId');
    }
  }

  /// 前往博物馆
  void _navigateToMuseum() {
    UIHelper.showInfo(context, '导航到博物馆');
    // TODO: 打开地图导航
  }

  /// 查看暂存列表（匹配小程序逻辑）
  void _viewDraftList() async {
    // 再次检查登录状态（防御性编程）
    final isLoggedIn = await _authService.isLoggedIn();
    if (!isLoggedIn) {
      if (mounted) {
        final confirmed = await ModernDialog.showConfirm(
          context,
          title: '需要登录',
          content: '查看暂存草稿需要登录后使用，是否前往登录？',
          cancelText: '取消',
          confirmText: '去登录',
          icon: Icons.lock_outline,
          iconColor: AppColors.primary,
        );
        
        if (confirmed == true && mounted) {
          context.go('/login?redirect=/drafts');
        }
      }
      return;
    }
    
    // 跳转到草稿列表页面
    context.go('/drafts');
  }

  /// 查看历史记录
  void _viewHistory() {
    context.go('/history');
  }

  /// 查看历史详情
  void _viewHistoryDetail(int id) {
    context.push('/checkin/detail/$id');
  }

  /// 查看博物馆详情
  void _viewMuseumDetail(int museumId) {
    context.push('/museum/$museumId');
  }

  /// 距离选择事件
  void _onDistanceSelect(int distance) {
    setState(() {
      _selectedDistance = distance;
    });
    // 刷新附近博物馆列表
    _loadNearbyMuseums();
  }

  /// 获取博物馆图片URL - 优先级：imageUrls.first → imageUrl → coverImage → null
  String? _getMuseumImageUrl(Map<String, dynamic> museum) {
    // 1. 优先使用 imageUrls 的第一张图片
    if (museum['imageUrls'] != null && museum['imageUrls'] is List && (museum['imageUrls'] as List).isNotEmpty) {
      return museum['imageUrls'][0] as String?;
    }
    
    // 2. 备用：使用 imageUrl 字段
    if (museum['imageUrl'] != null && museum['imageUrl'].toString().isNotEmpty) {
      return museum['imageUrl'] as String?;
    }
    
    // 3. 备用：使用 coverImage 字段
    if (museum['coverImage'] != null && museum['coverImage'].toString().isNotEmpty) {
      return museum['coverImage'] as String?;
    }
    
    // 4. 兼容旧的 image 字段
    if (museum['image'] != null && museum['image'].toString().isNotEmpty) {
      return museum['image'] as String?;
    }
    
    return null;
  }

  /// 获取博物馆图片URL（Museum对象版本） - 优先级：imageUrls.first → imageUrl → coverImage → null
  String? _getMuseumImageUrlFromMuseum(Museum museum) {
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