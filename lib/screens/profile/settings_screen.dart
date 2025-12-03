import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/router/auth_guard.dart';
import '../../../core/utils/ui_helper.dart';
import '../../../core/utils/bottom_sheet_helper.dart';
import '../../../widgets/common/common_app_bar.dart';
import '../../services/auth/biometric_auth_service.dart';

/// 设置页面（完全对齐小程序）
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with WidgetsBindingObserver {
  // 设置项状态
  bool _pushNotification = true;
  bool _checkinReminder = false;
  bool _locationService = true;
  bool _dataSync = true;
  bool _biometricLogin = false;
  bool _biometricAvailable = false;
  String _biometricName = '生物识别';

  @override
  void initState() {
    super.initState();
    _loadUserSettings();
    // 监听应用生命周期
    WidgetsBinding.instance.addObserver(this);
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // 当应用从后台返回前台时，重新检查权限
    if (state == AppLifecycleState.resumed) {
      _checkLocationPermission();
    }
  }

  // 加载用户设置
  void _loadUserSettings() async {
    // 加载生物识别状态
    final available = await BiometricAuthService.isBiometricAvailable();
    final enabled = await BiometricAuthService.isBiometricEnabled();
    final name = await BiometricAuthService.getSupportedBiometricName();
    
    // 检查位置权限状态
    await _checkLocationPermission();
    
    setState(() {
      _biometricAvailable = available;
      _biometricLogin = enabled;
      _biometricName = name;
    });
  }
  
  // 检查位置权限状态
  Future<void> _checkLocationPermission() async {
    try {
      // 检查定位服务是否启用
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _locationService = false);
        return;
      }
      
      // 检查权限
      final permission = await Geolocator.checkPermission();
      final hasPermission = permission == LocationPermission.always ||
                           permission == LocationPermission.whileInUse;
      
      setState(() => _locationService = hasPermission);
    } catch (e) {
      print('❌ 检查位置权限失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CommonAppBar.simple(title: '设置'),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        children: [
          // 通知设置分组
          _buildSettingGroup(
            title: '通知设置',
            items: [
              _SettingItem(
                id: 'pushNotification',
                title: '推送通知',
                description: '接收展览、活动等相关通知',
                type: _SettingType.switchType,
                value: _pushNotification,
                icon: Icons.notifications_outlined,
                onChanged: (value) => setState(() => _pushNotification = value!),
              ),
              _SettingItem(
                id: 'checkinReminder',
                title: '打卡提醒',
                description: '定时提醒您进行博物馆打卡',
                type: _SettingType.switchType,
                value: _checkinReminder,
                icon: Icons.alarm,
                onChanged: (value) => setState(() => _checkinReminder = value!),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.paddingL),

          // 隐私设置分组
          _buildSettingGroup(
            title: '隐私与安全',
            items: [
              // 生物识别登录（如果设备支持）
              if (_biometricAvailable)
                _SettingItem(
                  id: 'biometricLogin',
                  title: '$_biometricName登录',
                  description: _biometricLogin 
                      ? '已启用，可使用$_biometricName快速登录' 
                      : '启用后可使用$_biometricName快速登录',
                  type: _SettingType.switchType,
                  value: _biometricLogin,
                  icon: Icons.fingerprint,
                  onChanged: (value) => _handleBiometricToggle(value!),
                ),
              _SettingItem(
                id: 'locationService',
                title: '位置服务',
                description: '用于查找附近博物馆和打卡定位',
                type: _SettingType.switchType,
                value: _locationService,
                icon: Icons.location_on_outlined,
                onChanged: (value) => _handleLocationServiceToggle(value!),
              ),
              _SettingItem(
                id: 'dataSync',
                title: '数据同步',
                description: '同步打卡记录和收藏数据',
                type: _SettingType.switchType,
                value: _dataSync,
                icon: Icons.sync,
                onChanged: (value) => setState(() => _dataSync = value!),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.paddingL),

          // 应用设置分组
          _buildSettingGroup(
            title: '应用设置',
            items: [
              _SettingItem(
                id: 'language',
                title: '语言设置',
                description: '当前：简体中文',
                type: _SettingType.navigation,
                icon: Icons.language,
                onTap: () => _showComingSoon('语言设置'),
              ),
              _SettingItem(
                id: 'theme',
                title: '主题设置',
                description: '当前：跟随系统',
                type: _SettingType.navigation,
                icon: Icons.palette_outlined,
                onTap: () => _showComingSoon('主题设置'),
              ),
              _SettingItem(
                id: 'cache',
                title: '清除缓存',
                description: '清除应用缓存数据',
                type: _SettingType.action,
                icon: Icons.delete_outline,
                isDestructive: true,
                onTap: _clearCache,
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.paddingL),

          // 账户管理分组
          _buildSettingGroup(
            title: '账户管理',
            items: [
              _SettingItem(
                id: 'logout',
                title: '退出登录',
                description: '退出当前账户',
                type: _SettingType.action,
                icon: Icons.logout,
                isDestructive: true,
                onTap: _logout,
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.paddingXL),

          // 版本信息
          _buildVersionInfo(),

          const SizedBox(height: AppDimensions.paddingL),
        ],
      ),
    );
  }

  // 构建设置分组
  Widget _buildSettingGroup({
    required String title,
    required List<_SettingItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 分组标题
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            title,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),

        // 设置项列表
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 5,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            children: List.generate(
              items.length,
              (index) => Column(
                children: [
                  _buildSettingItem(items[index]),
                  if (index < items.length - 1)
                    Divider(
                      height: 1,
                      color: AppColors.backgroundDark,
                      indent: AppDimensions.cardPadding,
                      endIndent: 0,
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 构建单个设置项
  Widget _buildSettingItem(_SettingItem item) {
    return InkWell(
      onTap: item.onTap,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.cardPadding),
        child: Row(
          children: [
            // 图标
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: item.isDestructive
                    ? AppColors.errorBg
                    : AppColors.backgroundLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                item.icon,
                size: 20,
                color: item.isDestructive
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
            ),

            const SizedBox(width: 12),

            // 标题和描述
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: item.isDestructive
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  if (item.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.description!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // 控件
            _buildControl(item),
          ],
        ),
      ),
    );
  }

  // 构建控件（开关/箭头）
  Widget _buildControl(_SettingItem item) {
    switch (item.type) {
      case _SettingType.switchType:
        return Transform.scale(
          scale: 0.8,
          child: Switch(
            value: item.value as bool,
            onChanged: item.onChanged,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            thumbColor: WidgetStateProperty.all(Colors.white),
            trackColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.primary;
              }
              return AppColors.divider;
            }),
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
          ),
        );

      case _SettingType.navigation:
        return Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppColors.textHint,
        );

      case _SettingType.action:
        return Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: item.isDestructive
              ? AppColors.primary
              : AppColors.textHint,
        );
    }
  }

  // 构建版本信息
  Widget _buildVersionInfo() {
    return Column(
      children: [
        Text(
          '文博探索 v0.0.1',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '© 2025 文博探索团队',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textHint,
          ),
        ),
      ],
    );
  }

  // 处理生物识别登录切换
  Future<void> _handleBiometricToggle(bool enabled) async {
    if (enabled) {
      // 启用生物识别登录
      // 1. 先进行指纹验证，确认是本人操作
      print('🔐 开始指纹验证...');
      final authenticated = await BiometricAuthService.authenticate(
        reason: '验证身份以启用$_biometricName登录',
      );
      
      if (!authenticated) {
        print('❌ 指纹验证失败或取消');
        if (mounted) {
          UIHelper.showError(context, '验证失败，无法启用$_biometricName登录');
        }
        return;
      }
      
      print('✅ 指纹验证成功');
      
      // 2. 检查是否已登录
      if (!mounted) return;
      
      final prefs = await SharedPreferences.getInstance();
      final userInfoStr = prefs.getString(AppConstants.keyUserInfo);
      
      if (userInfoStr != null) {
        // 已登录，直接标记为已启用（不需要保存密码）
        try {
          final userInfo = jsonDecode(userInfoStr);
          final username = userInfo['username'] as String?;
          
          if (username != null) {
            print('📱 用户已登录，直接启用指纹登录: $username');
            
            // 只标记已启用，不保存密码
            await prefs.setBool('biometric_enabled', true);
            
            setState(() => _biometricLogin = true);
            if (mounted) {
              UIHelper.showSuccess(context, '$_biometricName登录已启用\n下次可以使用$_biometricName快速登录');
            }
            return;
          }
        } catch (e) {
          print('❌ 解析用户信息失败: $e');
        }
      }
      
      // 未登录用户，需要输入账号密码
      if (!mounted) return;
      
      final credentials = await showDialog<Map<String, String>>(
        context: context,
        builder: (context) => _BiometricSetupDialog(biometricName: _biometricName),
      );
      
      if (credentials != null) {
        // 保存凭据
        final success = await BiometricAuthService.saveBiometricCredentials(
          credentials['username']!,
          credentials['password']!,
        );
        
        if (success && mounted) {
          setState(() => _biometricLogin = true);
          UIHelper.showSuccess(context, '$_biometricName登录已启用');
        } else if (mounted) {
          UIHelper.showError(context, '启用失败，请重试');
        }
      }
    } else {
      // 禁用生物识别登录
      final confirmed = await BottomSheetHelper.showConfirm(
        context,
        title: '禁用$_biometricName登录',
        content: '禁用后需要使用账号密码登录',
        confirmText: '确定禁用',
        cancelText: '再想想',
        icon: Icons.fingerprint,
      );
      
      if (confirmed == true) {
        await BiometricAuthService.disableBiometricLogin();
        setState(() => _biometricLogin = false);
        if (mounted) {
          UIHelper.showSuccess(context, '$_biometricName登录已禁用');
        }
      }
    }
  }

  // 处理位置服务切换
  Future<void> _handleLocationServiceToggle(bool enabled) async {
    if (enabled) {
      // 用户想要开启位置服务
      try {
        // 1. 检查定位服务是否启用
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          // 定位服务未启用，提示用户打开
          if (!mounted) return;
          final confirmed = await BottomSheetHelper.showConfirm(
            context,
            title: '定位服务未开启',
            content: '需要在系统设置中开启定位服务才能使用此功能',
            confirmText: '去设置',
            cancelText: '再想想',
            icon: Icons.location_on_outlined,
          );
          
          if (confirmed == true) {
            await Geolocator.openLocationSettings();
            // 返回后会自动通过生命周期回调检查权限
          }
          if (!mounted) return;
          return;
        }
        
        // 2. 检查权限
        LocationPermission permission = await Geolocator.checkPermission();
        
        // 如果权限被永久拒绝，引导用户去应用设置
        if (permission == LocationPermission.deniedForever) {
          if (!mounted) return;
          final confirmed = await BottomSheetHelper.showConfirm(
            context,
            title: '需要位置权限',
            content: '位置权限已被永久拒绝，请在应用设置中手动开启',
            confirmText: '去设置',
            cancelText: '再想想',
            icon: Icons.location_on_outlined,
          );
          
          if (confirmed == true) {
            await Geolocator.openAppSettings();
            // 返回后会自动通过生命周期回调检查权限
          }
          if (mounted) {
            return;
          }
        }
        
        // 如果权限被拒绝，请求权限
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          
          if (permission == LocationPermission.denied) {
            if (mounted) {
              UIHelper.showError(context, '位置权限被拒绝');
            }
            setState(() => _locationService = false);
            return;
          }
        }
        
        // 权限已授予
        if (permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse) {
          setState(() => _locationService = true);
          if (mounted) {
            UIHelper.showSuccess(context, '位置服务已开启');
          }
        }
      } catch (e) {
        print('❌ 开启位置服务失败: $e');
        if (mounted) {
          UIHelper.showError(context, '开启位置服务失败');
        }
        setState(() => _locationService = false);
      }
    } else {
      // 用户想要关闭位置服务
      final confirmed = await BottomSheetHelper.showConfirm(
        context,
        title: '关闭位置权限',
        content: '关闭后将无法使用附近博物馆、打卡等功能，需要在系统设置中关闭位置权限',
        confirmText: '去设置',
        cancelText: '再想想',
        icon: Icons.location_off_outlined,
      );
      
      if (confirmed == true) {
        // 打开应用设置，让用户手动关闭权限
        await Geolocator.openAppSettings();
        // 返回后会自动通过生命周期回调检查权限
      }
    }
  }

  // 清除缓存
  Future<void> _clearCache() async {
    final confirmed = await BottomSheetHelper.showConfirm(
      context,
      title: '清除缓存',
      content: '确定要清除应用缓存吗？这不会影响您的个人数据',
      confirmText: '确定清除',
      cancelText: '取消',
      icon: Icons.delete_outline,
    );
    
    if (confirmed == true) {
      // TODO: 实际清除缓存逻辑
      if (!mounted) return;
      UIHelper.showSuccess(context, '缓存已清除');
    }
  }

  // 退出登录
  Future<void> _logout() async {
    final confirmed = await BottomSheetHelper.showConfirm(
      context,
      title: '确认退出',
      content: '退出后需要重新登录才能使用相关功能',
      confirmText: '确定退出',
      cancelText: '再想想',
      icon: Icons.logout,
    );
    
    if (confirmed == true && mounted) {
      // 使用 AuthGuard 的退出登录功能
      await performLogout(
        context,
        options: const LogoutOptions(
          showConfirm: false,  // 已经在上面显示过确认对话框了
          redirectToHome: true,
        ),
      );
    }
  }

  // 显示开发中提示
  void _showComingSoon(String feature) {
    UIHelper.showInfo(context, '$feature 暂不支持');
  }
}

/// 生物识别设置对话框
class _BiometricSetupDialog extends StatefulWidget {
  final String biometricName;
  
  const _BiometricSetupDialog({required this.biometricName});
  
  @override
  State<_BiometricSetupDialog> createState() => _BiometricSetupDialogState();
}

class _BiometricSetupDialogState extends State<_BiometricSetupDialog> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('启用${widget.biometricName}登录'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '请输入您的账号密码以启用${widget.biometricName}登录',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingL),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: '用户名',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入用户名';
                }
                return null;
              },
            ),
            const SizedBox(height: AppDimensions.paddingM),
            TextFormField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                labelText: '密码',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入密码';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop({
                'username': _usernameController.text,
                'password': _passwordController.text,
              });
            }
          },
          child: const Text('确定'),
        ),
      ],
    );
  }
}

/// 密码确认对话框（用于已登录用户）
class _PasswordConfirmDialog extends StatefulWidget {
  final String username;
  final String biometricName;
  
  const _PasswordConfirmDialog({
    required this.username,
    required this.biometricName,
  });
  
  @override
  State<_PasswordConfirmDialog> createState() => _PasswordConfirmDialogState();
}

class _PasswordConfirmDialogState extends State<_PasswordConfirmDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  
  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('启用${widget.biometricName}登录'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '当前账号：${widget.username}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingS),
            Text(
              '请输入密码以确认启用${widget.biometricName}登录',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingL),
            TextFormField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              autofocus: true,
              decoration: InputDecoration(
                labelText: '密码',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入密码';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop(_passwordController.text);
            }
          },
          child: const Text('确定'),
        ),
      ],
    );
  }
}

// 设置项类型枚举
enum _SettingType {
  switchType, // 开关类型
  navigation, // 导航类型
  action, // 操作类型
}

// 设置项数据模型
class _SettingItem {
  final String id;
  final String title;
  final String? description;
  final _SettingType type;
  final dynamic value;
  final IconData icon;
  final bool isDestructive;
  final VoidCallback? onTap;
  final ValueChanged<bool?>? onChanged;

  _SettingItem({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    this.value,
    required this.icon,
    this.isDestructive = false,
    this.onTap,
    this.onChanged,
  });
}
