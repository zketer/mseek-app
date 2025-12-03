import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../core/constants/app_constants.dart';
import '../services/auth/auth_service.dart';
import '../services/api/user_service.dart';

/// 应用全局状态管理
class AppProvider extends ChangeNotifier {
  // 用户相关
  User? _currentUser;
  bool _isLoggedIn = false;
  String? _token;

  // 应用状态
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// 初始化应用状态
  Future<void> init() async {
    setLoading(true);
    
    try {
      // 从本地存储恢复登录状态
      await _loadUserFromStorage();
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  /// 从本地存储加载用户信息
  Future<void> _loadUserFromStorage() async {
    try {
      // DEBUG: print('📱 [AppProvider] 开始从本地存储加载用户信息');
      
      // 使用 AuthService 检查登录状态
      final authService = AuthService();
      final isLoggedIn = await authService.isLoggedIn();
      
      if (isLoggedIn) {
        final user = await authService.getCurrentUser();
        final token = await authService.getAccessToken();
        
        if (user != null && token != null) {
          _currentUser = user;
          _token = token;
          _isLoggedIn = true;
          // DEBUG: print('✅ [AppProvider] 用户已登录: ${user.nickname}');
        } else {
          // DEBUG: print('⚠️ [AppProvider] 登录状态异常，清除数据');
          await clearUserData();
          _currentUser = null;
          _token = null;
          _isLoggedIn = false;
        }
      } else {
        // DEBUG: print('ℹ️ [AppProvider] 用户未登录');
        _currentUser = null;
        _token = null;
        _isLoggedIn = false;
      }
      
      notifyListeners();
    } catch (e) {
      // DEBUG: print('❌ [AppProvider] 加载用户信息失败: $e');
      _currentUser = null;
      _token = null;
      _isLoggedIn = false;
      notifyListeners();
    }
  }
  
  /// 刷新用户状态（从API获取最新用户信息）
  Future<void> refreshUserState() async {
    try {
      // 检查是否已登录
      final authService = AuthService();
      final isLoggedIn = await authService.isLoggedIn();
      
      if (!isLoggedIn) {
        debugPrint('⚠️ [AppProvider] 用户未登录，无法刷新用户状态');
        return;
      }
      
      // 获取userId（优先从内存，其次从本地存储）
      int? userId = _currentUser?.id;
      if (userId == null) {
        final prefs = await SharedPreferences.getInstance();
        userId = prefs.getInt(AppConstants.keyUserId);
      }
      
      if (userId == null) {
        debugPrint('⚠️ [AppProvider] 无法获取userId，无法刷新用户状态');
        return;
      }
      
      debugPrint('🔄 [AppProvider] 开始从API获取最新用户信息: userId=$userId');
      
      // 通过userId从API获取完整的用户信息（包括头像等详细信息）
      final userService = UserService();
      final user = await userService.getUserById(userId);
      
      // 更新内存中的用户信息
      _currentUser = user;
      _isLoggedIn = true;
      
      // 同步到本地存储
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyUserInfo, jsonEncode(user.toJson()));
      
      debugPrint('✅ [AppProvider] 用户信息已刷新: ${user.nickname}, avatar: ${user.avatar}');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [AppProvider] 刷新用户信息失败: $e');
      // 如果获取失败，降级为从本地存储加载
      await _loadUserFromStorage();
    }
  }

  /// 设置当前用户（登录时调用）
  Future<void> setCurrentUser(User user) async {
    try {
      _currentUser = user;
      _isLoggedIn = true;

      // 保存到本地存储
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(AppConstants.keyUserId, user.id);
      await prefs.setString(AppConstants.keyUserInfo, jsonEncode(user.toJson()));

      clearError();
      notifyListeners();
    } catch (e) {
      setError(e.toString());
    }
  }

  /// 用户登录（保留兼容性）
  Future<void> login(LoginResponse loginResponse) async {
    try {
      _currentUser = loginResponse.userInfo;
      _token = loginResponse.accessToken;
      _isLoggedIn = true;

      // 保存到本地存储
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyToken, loginResponse.accessToken);
      await prefs.setInt(AppConstants.keyUserId, loginResponse.userInfo.id);
      await prefs.setString(AppConstants.keyUserInfo, jsonEncode(loginResponse.userInfo.toJson()));

      clearError();
      notifyListeners();
    } catch (e) {
      setError(e.toString());
    }
  }

  /// 用户退出登录
  Future<void> logout() async {
    try {
      await clearUserData();
      
      _currentUser = null;
      _token = null;
      _isLoggedIn = false;
      
      clearError();
      notifyListeners();
    } catch (e) {
      setError(e.toString());
    }
  }

  /// 清除用户数据
  Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyToken);
    await prefs.remove(AppConstants.keyUserId);
    await prefs.remove(AppConstants.keyUserInfo);
  }

  /// 更新用户信息
  void updateUser(User user) {
    debugPrint('📝 [AppProvider] 更新用户信息: ${user.nickname}, avatar: ${user.avatar}');
    _currentUser = user;
    notifyListeners();
    
    // 保存到本地存储
    _saveUserToStorage();
  }

  /// 保存用户信息到本地存储
  Future<void> _saveUserToStorage() async {
    if (_currentUser != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyUserInfo, jsonEncode(_currentUser!.toJson()));
    }
  }

  /// 设置加载状态
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// 设置错误信息
  void setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// 清除错误信息
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// 检查是否需要登录
  bool requiresLogin() {
    return !_isLoggedIn;
  }

  /// 获取用户显示名称
  String get userDisplayName {
    return _currentUser?.displayName ?? '游客';
  }

  /// 获取用户头像
  String get userAvatarUrl {
    return _currentUser?.avatarUrl ?? AppConstants.defaultAvatarImage;
  }

  /// 获取用户积分
  int get userPoints {
    return _currentUser?.points ?? 0;
  }

  /// 获取用户等级
  String get userLevel {
    return _currentUser?.levelText ?? '新手';
  }
}
