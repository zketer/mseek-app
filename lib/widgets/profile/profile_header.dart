// ignore_for_file: use_build_context_synchronously
// ignore_for_file: unnecessary_non_null_assertion
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/router/auth_guard.dart';
import '../../core/utils/error_handler.dart';
import '../../core/utils/ui_helper.dart';
import '../../core/utils/bottom_sheet_helper.dart';
import '../../providers/app_provider.dart';
import '../../services/api/user_service.dart';

/// 我的页面头部组件 - 用户头像和基本信息
class ProfileHeader extends StatefulWidget {
  const ProfileHeader({super.key});

  @override
  State<ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<ProfileHeader> {
  /// 是否正在上传头像
  bool _isUploadingAvatar = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final user = appProvider.currentUser;
        final isLoggedIn = appProvider.isLoggedIn;

        return Container(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          child: Column(
            children: [
              
              // 用户头像和信息
              Row(
                children: [
                  // 头像（带编辑标识）
                  GestureDetector(
                    onTap: isLoggedIn ? () => _editProfile(context) : () => _showLogin(context),
                    child: Stack(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(
                              color: AppColors.textWhite.withValues(alpha: 0.3),
                              width: 3,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(37),
                            child: user?.avatar != null
                                ? _buildAvatarImage(user!.avatar!)
                                : _buildDefaultAvatar(),
                          ),
                        ),
                        // 头像编辑标识
                        if (isLoggedIn)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.textWhite,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: AppColors.textWhite,
                                size: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: AppDimensions.paddingM),
                  
                  // 用户信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isLoggedIn) ...[
                          // 用户昵称
                          GestureDetector(
                            onTap: () => _editProfile(context),
                            child: Text(
                              user?.nickname ?? user?.username ?? '用户',
                              style: AppTextStyles.headlineSmall.copyWith(
                                color: AppColors.textWhite,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // 等级信息
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Lv.${user?.level ?? 1}',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textWhite,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                user?.levelText ?? '文化新手',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textWhite.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // 用户ID
                          Text(
                            'ID: ${user?.id ?? '未设置'}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textWhite.withValues(alpha: 0.7),
                            ),
                          ),
                        ] else ...[
                          // 未登录状态 - 只显示点击登录，不显示等级和ID
                          GestureDetector(
                            onTap: () => _showLogin(context),
                            child: Text(
                              '点击登录',
                              style: AppTextStyles.headlineSmall.copyWith(
                                color: AppColors.textWhite,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // 登录提示
                          Text(
                            '登录后可享受更多功能',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textWhite.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// 构建头像图片（支持base64和网络URL）
  Widget _buildAvatarImage(String avatar) {
    try {
      // 判断是否为base64格式
      if (avatar.startsWith('data:image')) {
        // 提取base64数据
        final base64String = avatar.split(',').last;
        final Uint8List bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
        );
      } else {
        // 普通网络URL
        return Image.network(
          avatar,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
        );
      }
    } catch (e) {
      debugPrint('头像加载失败: $e');
      return _buildDefaultAvatar();
    }
  }

  /// 构建默认头像
  Widget _buildDefaultAvatar() {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: const Icon(
        Icons.person,
        color: AppColors.textWhite,
        size: 40,
      ),
    );
  }

  /// 显示设置
  // TODO: Implement settings dialog
  // ignore: unused_element
  void _showSettings(BuildContext context) {
    UIHelper.showInfo(context, '打开设置页面');
    // TODO: 跳转到设置页面
  }

  /// 编辑资料 - 显示头像操作菜单（更换头像、退出登录）
  /// 与小程序 onAvatarTap 逻辑保持一致
  void _editProfile(BuildContext context) {
    // 保存外层的 context，避免 BottomSheet 关闭后 context 失效
    final outerContext = context;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 顶部指示器
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // 更换头像选项
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt,
                    color: AppColors.primary,
                  ),
                  title: const Text(
                    '更换头像',
                    style: AppTextStyles.bodyLarge,
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _changeAvatar(outerContext);
                  },
                ),
                
                const Divider(height: 1),
                
                // 退出登录选项
                ListTile(
                  leading: const Icon(
                    Icons.logout,
                    color: AppColors.error,
                  ),
                  title: const Text(
                    '退出登录',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 16,
                    ),
                  ),
                  onTap: () {
                    // DEBUG: print('🚪 [ProfileHeader] 点击退出登录按钮');
                    // 先关闭 BottomSheet
                    Navigator.pop(sheetContext);
                    // 使用外层的 context 调用退出登录
                    _performLogout(outerContext);
                  },
                ),
                
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
  
  /// 更换头像 - 完整实现
  Future<void> _changeAvatar(BuildContext context) async {
    // 防止重复上传
    if (_isUploadingAvatar) return;
    
    try {
      // 1. 选择图片来源
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 顶部指示器
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  // 拍照选项
                  ListTile(
                    leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                    title: const Text('拍照', style: AppTextStyles.bodyLarge),
                    onTap: () => Navigator.pop(context, ImageSource.camera),
                  ),
                  
                  const Divider(height: 1),
                  
                  // 从相册选择
                  ListTile(
                    leading: const Icon(Icons.photo_library, color: AppColors.primary),
                    title: const Text('从相册选择', style: AppTextStyles.bodyLarge),
                    onTap: () => Navigator.pop(context, ImageSource.gallery),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // 取消按钮
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('取消'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      if (source == null) return;

      // 2. 选择图片
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) return;

      // 3. 获取当前用户ID
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final userId = appProvider.currentUser?.id;
      
      if (userId == null) {
        throw Exception('无法获取用户ID');
      }
      
      // 4. 显示loading overlay（使用Overlay而不是Dialog，避免Navigator冲突）
      if (!context.mounted) return;
      _isUploadingAvatar = true;
      
      // 使用Overlay显示loading
      final overlay = Overlay.of(context);
      final overlayEntry = OverlayEntry(
        builder: (context) => Container(
          color: Colors.black54,
          child: const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                    SizedBox(height: 16),
                    Text(
                      '正在上传头像...',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      overlay.insert(overlayEntry);

      try {
        // 5. 上传头像
        final userService = UserService();
        await userService.updateAvatar(File(image.path), userId);

        // 6. 强制从后端重新获取最新的用户信息（不使用缓存降级）
        try {
          final userService = UserService();
          final updatedUser = await userService.getUserById(userId);

          // 更新 AppProvider 中的用户信息
          await appProvider.setCurrentUser(updatedUser);

          debugPrint('✅ [ProfileHeader] 用户信息已强制刷新: ${updatedUser.nickname}');
        } catch (refreshError) {
          debugPrint('⚠️ [ProfileHeader] 强制刷新用户信息失败，使用原有逻辑: $refreshError');
          // 降级到原有逻辑
        await appProvider.refreshUserState();
        }

        // 7. 移除loading overlay
        overlayEntry.remove();
        _isUploadingAvatar = false;

        // 8. 头像更新成功（静默更新，无提示）
        debugPrint('✅ [ProfileHeader] 头像更新成功');
      } catch (uploadError) {
        // 移除loading overlay
        overlayEntry.remove();
        _isUploadingAvatar = false;
        
        // 重新抛出异常，让外层catch处理
        rethrow;
      }
    } catch (e) {
      // 确保loading状态被重置
      _isUploadingAvatar = false;
      
      // 显示错误提示
      if (context.mounted) {
        final errorMessage = ErrorHandler.getUserFriendlyMessage(e);
        UIHelper.showError(context, errorMessage);
      }
      
      debugPrint('更换头像失败: $e');
    }
  }
  
  /// 执行退出登录 - 完全对齐小程序逻辑
  Future<void> _performLogout(BuildContext context) async {
    // DEBUG: print('🚪 [ProfileHeader] 准备退出登录');
    
    // 1. 显示确认底部卡片
    final confirmed = await BottomSheetHelper.showConfirm(
      context,
      title: '确认退出',
      content: '退出后需要重新登录才能使用相关功能',
      confirmText: '确定退出',
      cancelText: '再想想',
      icon: Icons.logout,
    );
    
    if (confirmed != true) {
      // DEBUG: print('ℹ️ [ProfileHeader] 用户取消退出');
      return;
    }
    
    // DEBUG: print('✅ [ProfileHeader] 用户确认退出');
    
    // 2. 调用退出登录（不显示确认对话框，不自动跳转）
    final success = await performLogout(
      context,
      options: const LogoutOptions(
        showConfirm: false,      // 已经显示过确认对话框了
        redirectToHome: false,   // 不自动跳转，手动控制
        showLoading: false,      // 不显示加载对话框
      ),
    );
    
    // DEBUG: print('🔄 [ProfileHeader] performLogout返回: $success');
    
    if (!success) {
      // DEBUG: print('❌ [ProfileHeader] 退出登录失败');
      return;
    }
    
    // DEBUG: print('✅ [ProfileHeader] 退出登录成功，准备跳转首页');
    
    // 3. 跳转到首页（使用 go 而不是 push，清空导航栈）
    if (context.mounted) {
      context.go('/');
      // DEBUG: print('✅ [ProfileHeader] 已跳转到首页');
    }
  }

  /// 显示登录
  /// 跳转到登录页面 - 与小程序逻辑保持一致
  void _showLogin(BuildContext context) {
    context.go(AppConstants.routeLogin);
  }
}
