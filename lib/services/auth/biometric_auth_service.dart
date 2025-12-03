import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 生物识别认证服务
/// 支持指纹和面容识别快速登录
class BiometricAuthService {
  static final LocalAuthentication _localAuth = LocalAuthentication();
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );
  
  // Storage keys
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _usernameKey = 'biometric_username';
  static const String _passwordKey = 'biometric_password';
  
  /// 检查设备是否支持生物识别
  static Future<bool> isBiometricAvailable() async {
    try {
      return await _localAuth.canCheckBiometrics && 
             await _localAuth.isDeviceSupported();
    } catch (e) {
      print('❌ 检查生物识别支持失败: $e');
      return false;
    }
  }
  
  /// 获取可用的生物识别类型
  /// 返回: [fingerprint, face, iris]
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      print('❌ 获取生物识别类型失败: $e');
      return [];
    }
  }
  
  /// 执行生物识别认证
  /// 
  /// [reason] 显示给用户的认证原因
  /// 返回: true-认证成功，false-认证失败
  static Future<bool> authenticate({String reason = '验证指纹以继续'}) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true, // 认证失败后不自动关闭对话框
          biometricOnly: true, // 只使用生物识别，不使用PIN码
        ),
      );
    } catch (e) {
      print('❌ 生物识别认证失败: $e');
      return false;
    }
  }
  
  /// 检查是否已启用生物识别登录
  static Future<bool> isBiometricEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_biometricEnabledKey) ?? false;
    } catch (e) {
      print('❌ 检查生物识别状态失败: $e');
      return false;
    }
  }
  
  /// 启用生物识别登录（带验证）
  /// 
  /// [username] 用户名
  /// [password] 密码（加密存储）
  static Future<bool> enableBiometricLogin(String username, String password) async {
    try {
      // 先进行一次生物识别验证
      final authenticated = await authenticate(reason: '验证身份以启用生物识别登录');
      
      if (!authenticated) {
        return false;
      }
      
      // 验证成功后保存凭据
      return await _saveBiometricCredentials(username, password);
    } catch (e) {
      print('❌ 启用生物识别登录失败: $e');
      return false;
    }
  }
  
  /// 保存生物识别凭据（不验证，用于已经验证过的场景）
  /// 
  /// [username] 用户名
  /// [password] 密码（加密存储）
  static Future<bool> _saveBiometricCredentials(String username, String password) async {
    try {
      // 使用安全存储保存凭据（加密存储）
      await _secureStorage.write(key: _usernameKey, value: username);
      await _secureStorage.write(key: _passwordKey, value: password);
      
      // 标记已启用
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_biometricEnabledKey, true);
      
      print('✅ 生物识别登录已启用: username=$username');
      return true;
    } catch (e) {
      print('❌ 保存生物识别凭据失败: $e');
      return false;
    }
  }
  
  /// 保存生物识别凭据（公开方法，用于外部已验证的场景）
  static Future<bool> saveBiometricCredentials(String username, String password) async {
    return await _saveBiometricCredentials(username, password);
  }
  
  /// 禁用生物识别登录
  static Future<void> disableBiometricLogin() async {
    try {
      // 删除安全存储的凭据
      await _secureStorage.delete(key: _usernameKey);
      await _secureStorage.delete(key: _passwordKey);
      
      // 标记已禁用
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_biometricEnabledKey, false);
      
      print('✅ 生物识别登录已禁用');
    } catch (e) {
      print('❌ 禁用生物识别登录失败: $e');
    }
  }
  
  /// 获取保存的登录凭据
  /// 
  /// 返回: {'username': '...', 'password': '...'}
  /// 如果未保存或认证失败，返回 null
  static Future<Map<String, String>?> getSavedCredentials() async {
    try {
      // 检查是否启用
      if (!await isBiometricEnabled()) {
        print('⚠️ 生物识别登录未启用');
        return null;
      }
      
      // 进行生物识别认证
      print('🔐 开始生物识别认证...');
      final authenticated = await authenticate(reason: '使用指纹快速登录');
      
      if (!authenticated) {
        print('❌ 生物识别认证失败');
        return null;
      }
      
      // 从安全存储获取凭据
      final username = await _secureStorage.read(key: _usernameKey);
      final password = await _secureStorage.read(key: _passwordKey);
      
      if (username == null || password == null) {
        print('⚠️ 未找到保存的凭据');
        return null;
      }
      
      print('✅ 成功获取保存的凭据: username=$username');
      return {
        'username': username,
        'password': password,
      };
    } catch (e) {
      print('❌ 获取保存的凭据失败: $e');
      return null;
    }
  }
  
  /// 获取生物识别类型的友好名称
  static String getBiometricTypeName(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return '面容识别';
      case BiometricType.fingerprint:
        return '指纹识别';
      case BiometricType.iris:
        return '虹膜识别';
      case BiometricType.weak:
        return '弱生物识别';
      case BiometricType.strong:
        return '强生物识别';
    }
  }
  
  /// 获取当前设备支持的生物识别名称
  static Future<String> getSupportedBiometricName() async {
    final biometrics = await getAvailableBiometrics();
    
    if (biometrics.isEmpty) {
      return '生物识别';
    }
    
    // 优先显示面容和指纹
    if (biometrics.contains(BiometricType.face)) {
      return '面容识别';
    }
    
    if (biometrics.contains(BiometricType.fingerprint)) {
      return '指纹识别';
    }
    
    return getBiometricTypeName(biometrics.first);
  }
}
