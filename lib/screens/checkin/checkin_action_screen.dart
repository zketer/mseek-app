import 'dart:io';
import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/checkin_utils.dart';
import '../../../core/utils/ui_helper.dart';
import '../../../core/utils/bottom_sheet_helper.dart';
import '../../../services/api/checkin_service.dart';
import '../../../services/api/museum_service.dart';
import '../../../services/auth/auth_service.dart';
import '../../../models/museum.dart';
import '../../../widgets/common/common_app_bar.dart';
import '../../../core/constants/app_dimensions.dart';

/// 打卡操作页面 - 完全匹配小程序设计
class CheckinActionScreen extends StatefulWidget {
  final int museumId;
  final int? draftId; // 草稿ID（如果是编辑草稿）

  const CheckinActionScreen({
    super.key,
    required this.museumId,
    this.draftId,
  });

  @override
  State<CheckinActionScreen> createState() => _CheckinActionScreenState();
}

class _CheckinActionScreenState extends State<CheckinActionScreen> {
  final CheckinService _checkinService = CheckinService();
  final MuseumService _museumService = MuseumService();
  final AuthService _authService = AuthService();
  final ImagePicker _imagePicker = ImagePicker();
  
  Museum? _museum;
  bool _loading = false;
  bool _submitting = false;
  Position? _currentPosition; // 当前位置
  
  // 打卡数据
  final List<String> _photos = [];
  final TextEditingController _feelingController = TextEditingController();
  final TextEditingController _companionController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  double _rating = 0;
  String? _selectedMood;
  String? _selectedWeather;
  final List<String> _companions = [];
  final List<String> _tags = [];

  // 评分选项
  final List<Map<String, dynamic>> _ratingOptions = [
    {'value': 1.0, 'label': '很差'},
    {'value': 2.0, 'label': '一般'},
    {'value': 3.0, 'label': '不错'},
    {'value': 4.0, 'label': '很好'},
    {'value': 5.0, 'label': '极佳'},
  ];

  // 心情选项
  final List<Map<String, String>> _moodOptions = [
    {'value': 'excited', 'label': '兴奋', 'emoji': '😆'},
    {'value': 'happy', 'label': '开心', 'emoji': '😊'},
    {'value': 'peaceful', 'label': '平静', 'emoji': '😌'},
    {'value': 'thoughtful', 'label': '沉思', 'emoji': '🤔'},
    {'value': 'amazed', 'label': '震撼', 'emoji': '😲'},
  ];

  // 天气选项
  final List<Map<String, String>> _weatherOptions = [
    {'value': 'sunny', 'label': '晴朗', 'emoji': '☀️'},
    {'value': 'cloudy', 'label': '多云', 'emoji': '☁️'},
    {'value': 'rainy', 'label': '下雨', 'emoji': '🌧️'},
    {'value': 'snowy', 'label': '下雪', 'emoji': '❄️'},
    {'value': 'windy', 'label': '有风', 'emoji': '💨'},
  ];

  @override
  void initState() {
    super.initState();
    _checkLoginAndLoad();
  }

  @override
  void dispose() {
    _feelingController.dispose();
    _companionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  /// 检查登录状态并加载数据
  Future<void> _checkLoginAndLoad() async {
    final isLoggedIn = await _authService.isLoggedIn();
    
    if (!isLoggedIn) {
      if (mounted) {
        final confirmed = await BottomSheetHelper.showConfirm(
          context,
          title: '需要登录',
          content: '打卡功能需要登录后使用，是否前往登录？',
          confirmText: '去登录',
          cancelText: '取消',
          icon: Icons.lock_outline,
        );
        
        if (confirmed == true) {
          if (!mounted) return;
          context.go('/login?redirect=/checkin/action/${widget.museumId}');
        } else {
          if (!mounted) return;
          context.go('/');
        }
      }
      return;
    }
    
    // 并发加载博物馆信息、位置信息和草稿数据
    final futures = <Future>[
      _loadMuseumInfo(),
      _loadCurrentLocation(),
    ];
    
    // 如果有草稿ID，加载草稿数据
    if (widget.draftId != null) {
      futures.add(_loadDraftData());
    }
    
    await Future.wait(futures);
  }

  /// 获取当前位置
  Future<void> _loadCurrentLocation() async {
    try {
      // 检查定位服务是否启用
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // DEBUG: print('⚠️ 定位服务未启用');
        return;
      }

      // 检查定位权限
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // DEBUG: print('⚠️ 定位权限被拒绝');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // DEBUG: print('⚠️ 定位权限被永久拒绝');
        return;
      }

      // 获取当前位置（8秒超时）
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          // DEBUG: print('⚠️ 获取位置超时');
          throw TimeoutException('获取位置超时');
        },
      );

      // DEBUG: print('✅ 获取位置成功: ${_currentPosition?.latitude}, ${_currentPosition?.longitude}');
      
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      // DEBUG: print('❌ 获取位置失败: $e');
      // 即使获取位置失败，也不阻止用户继续操作
    }
  }

  /// 加载博物馆信息
  Future<void> _loadMuseumInfo() async {
    setState(() {
      _loading = true;
    });

    try {
      // DEBUG: print('🔄 加载博物馆信息: ${widget.museumId}');
      
      final museum = await _museumService.getMuseumDetail(widget.museumId);
      
      setState(() {
        _museum = museum;
        _loading = false;
      });

      // DEBUG: print('✅ 博物馆信息加载完成: ${museum.name}');
      // DEBUG: print('📍 省份: ${museum.provinceName}, 城市: ${museum.cityName}');
      // DEBUG: print('📍 详细地址: ${museum.address}');
    } catch (e) {
      // DEBUG: print('❌ 加载博物馆信息失败: $e');
      setState(() {
        _loading = false;
      });
      if (mounted) {
        // 加载失败直接返回，不显示错误提示
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) context.pop();
        });
      }
    }
  }

  /// 加载草稿数据
  Future<void> _loadDraftData() async {
    try {
      // DEBUG: print('🔄 [草稿加载] 开始加载草稿数据: draftId=${widget.draftId}');
      
      final drafts = await _checkinService.getUserCheckinRecords(
        page: 1,
        pageSize: 100,  // 增加页大小，确保能找到
        isDraft: true,
      );
      
      // DEBUG: print('📦 [草稿加载] 获取到 ${drafts.records.length} 条草稿');
      
      final draft = drafts.records.firstWhere(
        (d) => d.id == widget.draftId,
        orElse: () => throw Exception('草稿未找到: ID=${widget.draftId}'),
      );
      
      // DEBUG: print('✅ [草稿加载] 找到草稿: ${draft.museumName}');
      // DEBUG: print('📸 [草稿加载] 照片: ${draft.photos?.length ?? 0} 张');
      
      // ignore: unused_local_variable
      final notesPreview = draft.notes != null && draft.notes!.isNotEmpty
          ? (draft.notes!.length > 20 ? '${draft.notes!.substring(0, 20)}...' : draft.notes!)
          : '(无)';
      // DEBUG: print('📝 [草稿加载] 感受: $notesPreview');
      
      // DEBUG: print('⭐ [草稿加载] 评分: ${draft.rating}');
      // DEBUG: print('😊 [草稿加载] 心情: ${draft.mood ?? "(未选择)"}');
      // DEBUG: print('🌤️ [草稿加载] 天气: ${draft.weather ?? "(未选择)"}');
      // DEBUG: print('👥 [草稿加载] 同行人: ${draft.companions?.length ?? 0} 人');
      // DEBUG: print('🏷️ [草稿加载] 标签: ${draft.tags?.length ?? 0} 个');
      
      setState(() {
        // 加载照片
        if (draft.photos != null && draft.photos!.isNotEmpty) {
          _photos.clear();
          _photos.addAll(draft.photos!);
        }
        
        // 加载感受
        _feelingController.text = draft.notes ?? '';
        
        // 加载评分
        _rating = draft.rating ?? 0;
        
        // 加载心情
        if (draft.mood != null && draft.mood!.isNotEmpty) {
          _selectedMood = draft.mood!;
        }
        
        // 加载天气
        if (draft.weather != null && draft.weather!.isNotEmpty) {
          _selectedWeather = draft.weather!;
        }
        
        // 加载同行人
        if (draft.companions != null && draft.companions!.isNotEmpty) {
          _companions.clear();
          _companions.addAll(draft.companions!);
        }
        
        // 加载标签
        if (draft.tags != null && draft.tags!.isNotEmpty) {
          _tags.clear();
          _tags.addAll(draft.tags!);
        }
      });

      // DEBUG: print('✅ [草稿加载] 草稿数据加载完成并应用到UI');
    } catch (e) {
      // DEBUG: print('❌ [草稿加载] 加载草稿数据失败: $e');
      // 不显示错误提示，页面会显示空状态
    }
  }

  /// 选择照片
  Future<void> _pickPhotos() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();
      
      if (images.isNotEmpty) {
        setState(() {
          _photos.addAll(images.map((image) => image.path));
          // 限制最多9张照片
          if (_photos.length > 9) {
            _photos.removeRange(9, _photos.length);
          }
        });
      }
    } catch (e) {
      // DEBUG: print('选择照片失败: $e');
    }
  }

  /// 删除照片
  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
  }

  /// 添加同行伙伴
  void _addCompanion() {
    final companion = _companionController.text.trim();
    print('👥 尝试添加同行人: "$companion"');
    if (companion.isNotEmpty && !_companions.contains(companion)) {
      setState(() {
        _companions.add(companion);
        _companionController.clear();
      });
      print('✅ 同行人添加成功，当前列表: $_companions');
    } else if (companion.isEmpty) {
      print('⚠️ 同行人输入为空，未添加');
    } else {
      print('⚠️ 同行人已存在，未添加');
    }
  }

  /// 删除同行伙伴
  void _removeCompanion(int index) {
    final removed = _companions[index];
    setState(() {
      _companions.removeAt(index);
    });
    print('🗑️ 删除同行人: "$removed"，当前列表: $_companions');
  }

  /// 添加标签
  void _addTag() {
    final tag = _tagController.text.trim();
    print('🏷️ 尝试添加标签: "$tag"');
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
      print('✅ 标签添加成功，当前列表: $_tags');
    } else if (tag.isEmpty) {
      print('⚠️ 标签输入为空，未添加');
    } else {
      print('⚠️ 标签已存在，未添加');
    }
  }

  /// 删除标签
  void _removeTag(int index) {
    final removed = _tags[index];
    setState(() {
      _tags.removeAt(index);
    });
    print('🗑️ 删除标签: "$removed"，当前列表: $_tags');
  }

  /// 验证必填字段
  bool _validateRequiredFields() {
    // 验证评分（必填）
    if (_rating == 0) {
      UIHelper.showWarning(context, '请选择评分');
      return false;
    }
    
    // 验证心情（必填）
    if (_selectedMood?.isEmpty ?? true) {
      UIHelper.showWarning(context, '请选择心情');
      return false;
    }
    
    // 验证天气（必填）
    if (_selectedWeather?.isEmpty ?? true) {
      UIHelper.showWarning(context, '请选择天气');
      return false;
    }
    
    // 验证感受（必填）
    if (_feelingController.text.trim().isEmpty) {
      UIHelper.showWarning(context, '请填写打卡感受');
      return false;
    }
    
    // 照片不是必填项
    
    return true;
  }

  /// 提交打卡（匹配小程序逻辑）
  Future<void> _submitCheckin() async {
    if (!_validateRequiredFields()) {
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      print('');
      print('🔄 ==================== 开始提交打卡 ====================');
      print('📋 博物馆信息:');
      print('   ID: ${widget.museumId}');
      print('   名称: ${_museum!.name}');
      
      // 拼接完整地址：省·市·详细地址（用·分隔）
      final fullAddress = [
        _museum!.provinceName ?? '',
        _museum!.cityName ?? '',
        _museum!.address ?? '',
      ].where((s) => s.isNotEmpty).join('·');
      
      print('📍 地址信息:');
      print('   省份: ${_museum!.provinceName}');
      print('   城市: ${_museum!.cityName}');
      print('   详细地址: ${_museum!.address}');
      print('   完整地址: $fullAddress');
      print('   经度: ${_currentPosition?.longitude}');
      print('   纬度: ${_currentPosition?.latitude}');
      
      print('📸 打卡内容:');
      print('   照片数量: ${_photos.length}');
      print('   照片列表: $_photos');
      print('   感受文字: ${_feelingController.text.trim()}');
      print('   评分: $_rating');
      
      print('😊 心情天气:');
      print('   心情: $_selectedMood');
      print('   天气: $_selectedWeather');
      
      print('👥 同行人信息:');
      print('   同行人列表: $_companions');
      print('   同行人数量: ${_companions.length}');
      print('   是否为空: ${_companions.isEmpty}');
      print('   提交值: ${_companions.isNotEmpty ? _companions : null}');
      
      print('🏷️ 标签信息:');
      print('   标签列表: $_tags');
      print('   标签数量: ${_tags.length}');
      print('   是否为空: ${_tags.isEmpty}');
      print('   提交值: ${_tags.isNotEmpty ? _tags : null}');
      
      // 调用后端打卡API
      await _checkinService.submitCheckin(
        museumId: widget.museumId,
        museumName: _museum!.name,
        photos: _photos,
        feeling: _feelingController.text.trim(),
        rating: _rating,
        mood: _selectedMood,
        weather: _selectedWeather,
        companions: _companions.isNotEmpty ? _companions : null,
        tags: _tags.isNotEmpty ? _tags : null,
        longitude: _currentPosition?.longitude,
        latitude: _currentPosition?.latitude,
        address: fullAddress, // 使用拼接的完整地址
      );
      
      print('✅ 打卡提交成功！');
      print('==================== 提交完成 ====================');
      print('');
      
      if (mounted) {
        // 直接返回到打卡页面，不显示提示
        context.go('/checkin');
      }
    } catch (e) {
      print('❌ 打卡提交失败: $e');
      print('❌ 错误堆栈: ${StackTrace.current}');
      print('==================== 提交失败 ====================');
      print('');
      setState(() {
        _submitting = false;
      });
      // 不显示错误提示
    }
  }

  /// 暂存草稿（匹配小程序逻辑）
  Future<void> _saveDraft() async {
    setState(() {
      _submitting = true;
    });

    try {
      print('');
      print('💾 ==================== 开始暂存草稿 ====================');
      print('📋 博物馆信息:');
      print('   ID: ${widget.museumId}');
      print('   名称: ${_museum!.name}');
      print('   草稿ID: ${widget.draftId}');
      
      // 拼接完整地址：省·市·详细地址（用·分隔）
      final fullAddress = [
        _museum!.provinceName ?? '',
        _museum!.cityName ?? '',
        _museum!.address ?? '',
      ].where((s) => s.isNotEmpty).join('·');
      
      print('📍 地址信息:');
      print('   完整地址: $fullAddress');
      
      print('📸 打卡内容:');
      print('   照片数量: ${_photos.length}');
      print('   感受文字: ${_feelingController.text.trim()}');
      print('   评分: $_rating');
      print('   心情: $_selectedMood');
      print('   天气: $_selectedWeather');
      
      print('👥 同行人信息:');
      print('   同行人列表: $_companions');
      print('   提交值: ${_companions.isNotEmpty ? _companions : null}');
      
      print('🏷️ 标签信息:');
      print('   标签列表: $_tags');
      print('   提交值: ${_tags.isNotEmpty ? _tags : null}');
      
      // 调用后端暂存API
      await _checkinService.saveDraft(
        museumId: widget.museumId,
        museumName: _museum!.name,
        photos: _photos,
        feeling: _feelingController.text.trim(),
        rating: _rating,
        mood: _selectedMood,
        weather: _selectedWeather,
        companions: _companions.isNotEmpty ? _companions : null,
        tags: _tags.isNotEmpty ? _tags : null,
        longitude: _currentPosition?.longitude,
        latitude: _currentPosition?.latitude,
        address: fullAddress, // 使用拼接的完整地址
        draftId: widget.draftId, // 如果是编辑已有草稿，传递草稿ID
      );
      
      print('✅ 草稿暂存成功！');
      print('==================== 暂存完成 ====================');
      print('');
      
      if (mounted) {
        // 直接返回到打卡页面，不显示提示
        context.go('/checkin');
      }
    } catch (e) {
      print('❌ 草稿暂存失败: $e');
      print('❌ 错误堆栈: ${StackTrace.current}');
      print('==================== 暂存失败 ====================');
      print('');
      setState(() {
        _submitting = false;
      });
      // 不显示错误提示
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CommonAppBar(
        title: _museum?.name ?? '打卡',
        actions: [
          // 暂存按钮
          TextButton(
            onPressed: _submitting ? null : _saveDraft,
            child: Text(
              '暂存',
              style: TextStyle(
                color: _submitting ? Colors.grey : AppColors.primary,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryLight))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 博物馆信息卡片
                  _buildMuseumCard(),
                  
                  const SizedBox(height: 16),
                  
                  // 照片上传
                  _buildPhotoSection(),
                  
                  const SizedBox(height: 16),
                  
                  // 感受输入
                  _buildFeelingSection(),
                  
                  const SizedBox(height: 16),
                  
                  // 评分、心情、天气（合并在一个卡片中）
                  _buildRatingMoodWeatherSection(),
                  
                  const SizedBox(height: 16),
                  
                  // 同行伙伴
                  _buildCompanionSection(),
                  
                  const SizedBox(height: 16),
                  
                  // 标签
                  _buildTagSection(),
                  
                  const SizedBox(height: 32),
                  
                  // 提交按钮
                  _buildSubmitButton(),
                  
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  /// 构建博物馆信息卡片
  Widget _buildMuseumCard() {
    if (_museum == null) return const SizedBox();
    
    // 计算距离状态
    double? distanceKm;
    bool canCheckin = false;
    if (_currentPosition != null && _museum!.longitude != null && _museum!.latitude != null) {
      distanceKm = _calculateDistance(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        _museum!.latitude!,
        _museum!.longitude!,
      );
      // 使用工具类判断是否可以打卡
      canCheckin = CheckinUtils.canCheckinByDistance(distanceKm);
    }
    
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _museum!.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _museum!.address ?? '地址未知',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          if (distanceKm != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '距离您 ${_formatDistance(distanceKm)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: canCheckin ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  canCheckin ? '可打卡' : '距离过远',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// 计算两点间距离（Haversine公式）
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  /// 格式化距离
  String _formatDistance(double km) {
    if (km < 1) {
      return '${(km * 1000).toInt()}m';
    } else {
      return '${km.toStringAsFixed(1)}km';
    }
  }

  /// 构建照片上传区域
  Widget _buildPhotoSection() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '打卡照片',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              if (_photos.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  '(${_photos.length}张)',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          
          // 空状态显示
          if (_photos.isEmpty)
            _buildEmptyPhotoState()
          else
            // 照片网格
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._photos.asMap().entries.map((entry) {
                  final index = entry.key;
                  final photo = entry.value;
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(photo),
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removePhoto(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                // ignore: unnecessary_to_list_in_spreads
                }).toList(),
                if (_photos.length < 9)
                  GestureDetector(
                    onTap: _pickPhotos,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                        color: Colors.grey[400]!,
                        style: BorderStyle.solid,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 32,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '添加照片',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建照片空状态
  Widget _buildEmptyPhotoState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Column(
          children: [
            // 相机图标
            const Text(
              '📷',
              style: TextStyle(fontSize: 40),
            ),
            const SizedBox(height: 12),
            Text(
              '还没有添加照片哦',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            // 添加照片按钮
            ElevatedButton(
              onPressed: _pickPhotos,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '添加照片',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建感受输入区域
  Widget _buildFeelingSection() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '打卡感受',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _feelingController,
            maxLines: 5,
            maxLength: 500,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: '分享您的参观感受...',
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
              filled: true,
              fillColor: AppColors.surfaceGrey,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(12),
              counterStyle: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建评分、心情、天气选择区域（合并在一个卡片中）
  Widget _buildRatingMoodWeatherSection() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 评分
          Row(
            children: [
              const Text(
                '评分',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: _ratingOptions.map((option) {
              final value = option['value'] as double;
              final label = option['label'] as String;
              final isSelected = _rating == value;
              
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _rating = value;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isSelected ? '★' : '☆',
                            style: TextStyle(
                              fontSize: 14,
                              color: isSelected ? AppColors.primary : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            label,
                            style: TextStyle(
                              color: isSelected ? AppColors.primary : Colors.grey[700],
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 24),
          
          // 心情
          Row(
            children: [
              const Text(
                '心情',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: _moodOptions.map((option) {
              final value = option['value']!;
              final label = option['label']!;
              final emoji = option['emoji']!;
              final isSelected = _selectedMood == value;
              
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedMood = isSelected ? null : value;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(emoji, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 4),
                          Text(
                            label,
                            style: TextStyle(
                              color: isSelected ? AppColors.primary : Colors.grey[700],
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 24),
          
          // 天气
          Row(
            children: [
              const Text(
                '天气',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: _weatherOptions.map((option) {
              final value = option['value']!;
              final label = option['label']!;
              final emoji = option['emoji']!;
              final isSelected = _selectedWeather == value;
              
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedWeather = isSelected ? null : value;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(emoji, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 4),
                          Text(
                            label,
                            style: TextStyle(
                              color: isSelected ? AppColors.primary : Colors.grey[700],
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// 构建同行伙伴区域
  Widget _buildCompanionSection() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '同行伙伴',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _companionController,
                  decoration: InputDecoration(
                    hintText: '添加同行伙伴',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceGrey,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onSubmitted: (_) => _addCompanion(),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 70,
                child: ElevatedButton(
                  onPressed: _addCompanion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('添加', style: TextStyle(fontSize: 14)),
                ),
              ),
            ],
          ),
          if (_companions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _companions.asMap().entries.map((entry) {
                final index = entry.key;
                final companion = entry.value;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        companion,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => _removeCompanion(index),
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建标签区域
  Widget _buildTagSection() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '标签',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _tagController,
                  decoration: InputDecoration(
                    hintText: '添加标签',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceGrey,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onSubmitted: (_) => _addTag(),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 70,
                child: ElevatedButton(
                  onPressed: _addTag,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('添加', style: TextStyle(fontSize: 14)),
                ),
              ),
            ],
          ),
          if (_tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tags.asMap().entries.map((entry) {
                final index = entry.key;
                final tag = entry.value;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '#$tag',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => _removeTag(index),
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建提交按钮
  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        gradient: _submitting
            ? null
            : const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        color: _submitting ? AppColors.background : null,
        borderRadius: BorderRadius.circular(24),
      ),
      child: ElevatedButton(
        onPressed: _submitting ? null : _submitCheckin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: _submitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.borderDark),
                  strokeWidth: 2,
                ),
              )
            : const Text(
                '立即打卡',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}

