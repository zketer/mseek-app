import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:fluwx/fluwx.dart'; // TODO: 完成SDK配置后启用
// import 'package:tobias/tobias.dart' as tobias; // TODO: 完成支付宝SDK配置后启用
import '../api/http_client.dart';
import '../../models/user.dart';
import '../../utils/device_info_helper.dart';

/// 登录响应模型
class LoginResponse {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;
  final User userInfo;

  LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    required this.userInfo,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      tokenType: json['tokenType'],
      expiresIn: json['expiresIn'],
      userInfo: User.fromJson(json['userInfo']),
    );
  }
}

/// 微信用户信息模型
class WechatUserInfo {
  final String nickName;
  final String avatarUrl;
  final int gender;
  final String? country;
  final String? province;
  final String? city;
  final String? language;

  WechatUserInfo({
    required this.nickName,
    required this.avatarUrl,
    required this.gender,
    this.country,
    this.province,
    this.city,
    this.language,
  });

  Map<String, dynamic> toJson() {
    return {
      'nickName': nickName,
      'avatarUrl': avatarUrl,
      'gender': gender,
      'country': country,
      'province': province,
      'city': city,
      'language': language,
    };
  }
}

/// 图形验证码响应模型
class CaptchaResponse {
  final String captchaKey;
  final String captchaImage; // Base64编码的图片
  final int? expiresIn;

  CaptchaResponse({
    required this.captchaKey,
    required this.captchaImage,
    this.expiresIn,
  });

  factory CaptchaResponse.fromJson(Map<String, dynamic> json) {
    return CaptchaResponse(
      captchaKey: json['captchaKey'],
      captchaImage: json['captchaImage'],
      expiresIn: json['expiresIn'],
    );
  }
}

/// 认证服务
class AuthService {
  // 单例模式
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();
  
  static const String _accessTokenKey = 'auth_token'; // 与HttpClient保持一致
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userInfoKey = 'user_info';
  static const String _tokenExpiresAtKey = 'token_expires_at';

  final HttpClient _httpClient = HttpClient();

  /// 账号密码登录
  Future<LoginResponse> accountLogin(String username, String password, {String? captcha, String? captchaKey}) async {
    try {
      // DEBUG: print('🔐 开始账号密码登录: $username');
      
      // 获取设备信息
      final deviceInfo = await DeviceInfoHelper.getDeviceInfo();
      
      final requestData = {
        'username': username,
        'password': password,
        // 添加设备信息（支持长期登录）
        'deviceId': deviceInfo['deviceId'],
        'deviceName': deviceInfo['deviceName'],
        'deviceModel': deviceInfo['deviceModel'],
        'osVersion': deviceInfo['osVersion'],
        'appVersion': deviceInfo['appVersion'],
        'platform': deviceInfo['platform'],
      };
      
      // 如果提供了验证码，添加到请求中
      if (captcha != null && captchaKey != null) {
        requestData['captcha'] = captcha;
        requestData['captchaKey'] = captchaKey;
      }
      
      print('📱 设备信息: ${deviceInfo['deviceName']} (${deviceInfo['platform']})');
      
      final response = await _httpClient.post('/api/v1/auth/login', data: requestData);

      // DEBUG: print('📡 登录响应: ${response.data}');

      if (response.data['code'] == 200 && response.data['data'] != null) {
        final loginData = response.data['data'];
        
        // 🔍 调试日志：打印后端返回的用户信息
        print('📦 登录响应数据: ${loginData['userInfo']}');
        
        // 直接使用后端返回的用户信息，不从JWT中解析
        final userInfo = User.fromJson(loginData['userInfo']);
        
        // 🔍 调试日志：打印解析后的用户信息
        print('👤 用户信息: id=${userInfo.id}, username=${userInfo.username}, nickname=${userInfo.nickname}');
        
        // 创建LoginResponse对象
        final loginResponse = LoginResponse(
          accessToken: loginData['accessToken'],
          refreshToken: loginData['refreshToken'], 
          tokenType: loginData['tokenType'] ?? 'Bearer',
          expiresIn: loginData['expiresIn'] ?? 7200,
          userInfo: userInfo,
        );
        
        await _saveAuthInfo(loginResponse);
        
        // 打印 Token 过期时间信息
        return loginResponse;
      } else {
        final errorMsg = response.data['message'] ?? '登录失败';
        // DEBUG: print('❌ 登录失败: $errorMsg');
        throw Exception(errorMsg);
      }
    } catch (e) {
      // DEBUG: print('❌ 登录异常: ${e.toString()}');
      
      // 友好的错误提示
      String errorMsg = '登录失败';
      final eStr = e.toString();
      if (eStr.contains('用户名或密码错误')) {
        errorMsg = '用户名或密码错误';
      } else if (eStr.contains('账号被锁定')) {
        errorMsg = '账号被锁定，请联系客服';
      } else if (eStr.contains('网络')) {
        errorMsg = '网络连接失败';
      } else if (eStr.contains('Connection')) {
        errorMsg = '无法连接到服务器，请检查网络';
      } else {
        errorMsg = eStr.replaceAll('Exception: ', '');
      }
      
      throw Exception(errorMsg);
    }
  }

  /// 获取图形验证码
  Future<CaptchaResponse> getCaptcha() async {
    try {
      final response = await _httpClient.get('/api/v1/auth/captcha');

      if (response.data['code'] == 200 && response.data['data'] != null) {
        return CaptchaResponse.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? '获取验证码失败');
      }
    } catch (e) {
      throw Exception('获取验证码失败: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  /// 发送邮箱验证码
  Future<void> sendEmailCode(String email, String type) async {
    try {
      final response = await _httpClient.post('/api/v1/auth/send-code', data: {
        'email': email,
        'type': type, // 'register' 或 'reset'
      });

      if (response.data['code'] != 200) {
        throw Exception(response.data['message'] ?? '发送验证码失败');
      }
    } catch (e) {
      throw Exception('发送验证码失败: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  /// 用户注册
  Future<LoginResponse> register({
    required String username,
    required String password,
    required String confirmPassword,
    required String email,
    required String code,
    required String captcha,
    required String captchaKey,
    String? nickname,
    String? phone,
  }) async {
    try {
      final requestData = {
        'username': username,
        'password': password,
        'confirmPassword': confirmPassword,
        'email': email,
        'code': code,
        'captcha': captcha,
        'captchaKey': captchaKey,
      };

      if (nickname != null && nickname.isNotEmpty) {
        requestData['nickname'] = nickname;
      }
      if (phone != null && phone.isNotEmpty) {
        requestData['phone'] = phone;
      }

      final response = await _httpClient.post('/api/v1/auth/register', data: requestData);

      if (response.data['code'] == 200 && response.data['data'] != null) {
        final loginData = response.data['data'];
        
        // 🔍 调试日志：打印后端返回的用户信息
        print('📦 注册响应数据: ${loginData['userInfo']}');
        
        // 直接使用后端返回的用户信息，不从JWT中解析
        final userInfo = User.fromJson(loginData['userInfo']);
        
        // 🔍 调试日志：打印解析后的用户信息
        print('👤 用户信息: id=${userInfo.id}, username=${userInfo.username}, nickname=${userInfo.nickname}');
        
        // 创建LoginResponse对象
        final loginResponse = LoginResponse(
          accessToken: loginData['accessToken'],
          refreshToken: loginData['refreshToken'], 
          tokenType: loginData['tokenType'] ?? 'Bearer',
          expiresIn: loginData['expiresIn'] ?? 7200,
          userInfo: userInfo,
        );
        
        await _saveAuthInfo(loginResponse);
        return loginResponse;
      } else {
        throw Exception(response.data['message'] ?? '注册失败');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// 重置密码
  Future<void> resetPassword({
    required String username,
    required String email,
    required String code,
    required String newPassword,
    required String confirmPassword,
    required String captcha,
    required String captchaKey,
  }) async {
    try {
      final response = await _httpClient.post('/api/v1/auth/reset-password', data: {
        'username': username,
        'email': email,
        'code': code,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
        'captcha': captcha,
        'captchaKey': captchaKey,
      });

      if (response.data['code'] != 200) {
        throw Exception(response.data['message'] ?? '重置密码失败');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// 微信登录
  Future<LoginResponse> wechatLogin() async {
    try {
      // TODO: 微信SDK集成需要完整配置后才能使用
      // 临时实现，提示用户功能开发中
      throw Exception('微信登录功能需要完成SDK配置，请先使用账号密码登录');
      
      /* 
      // 完整的微信登录实现（需要SDK配置完成后启用）
      // 检查微信是否安装
      final isInstalled = await isWeChatInstalled();
      if (!isInstalled) {
        throw Exception('请先安装微信客户端');
      }

      // 发起微信授权登录
      final result = await sendWeChatAuth(
        scope: "snsapi_userinfo", 
        state: "wechat_sdk_demo",
      );

      if (result.isSuccessful && result.code != null) {
        // 调用后端接口，使用微信返回的code进行登录
        final response = await _httpClient.post('/api/v1/auth/oauth2/wechat/app', data: {
          'code': result.code,
        });

        if (response.data['success'] == true && response.data['data'] != null) {
          final loginResponse = LoginResponse.fromJson(response.data['data']);
          await _saveAuthInfo(loginResponse);
          return loginResponse;
        } else {
          throw Exception(response.data['message'] ?? '微信登录失败');
        }
      } else {
        // 用户取消授权或授权失败
        if (result.errorCode == WeChatAuthErrorCode.AUTH_DENIED) {
          throw Exception('用户取消授权');
        } else {
          throw Exception('微信授权失败: ${result.errorCode}');
        }
      }
      */
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('微信登录失败: ${e.toString()}');
    }
  }

  /// 支付宝登录
  /// 
  /// 注意：由于 tobias SDK 版本兼容性问题，暂时使用 URL Launcher 方式
  /// 这种方式会跳转到支付宝网页进行授权
  Future<LoginResponse> alipayLogin() async {
    try {
      print('🔐 开始支付宝登录');
      
      // TODO: 后续可以升级 tobias 版本或使用其他支付宝登录方案
      // 当前使用简化版本：提示用户功能开发中
      throw Exception('暂不支持支付宝登录\n您可以使用账号密码登录');
      
      /*
      // 完整的 App 登录实现（待 tobias SDK 适配完成后启用）
      // 1. 调用后端获取授权URL
      final urlResponse = await _httpClient.get('/api/v1/auth/oauth2/authorize/alipay');
      
      if (urlResponse.data['code'] != 200 || urlResponse.data['data'] == null) {
        throw Exception(urlResponse.data['message'] ?? '获取授权URL失败');
      }
      
      String authUrl = urlResponse.data['data'];
      print('📡 获取授权URL成功: $authUrl');
      
      // 2. 调用支付宝SDK进行授权
      // final authResult = await Tobias.aliPay(authUrl);
      
      // 3. 解析授权结果并发送给后端
      // 4. 返回登录响应
      */
      
    } catch (e) {
      print('❌ 支付宝登录失败: ${e.toString()}');
      if (e is Exception) {
        rethrow;
      }
      throw Exception('支付宝登录失败: ${e.toString()}');
    }
  }
  
  /// 解析支付宝返回结果
  // TODO: 完成支付宝SDK配置后启用
  // ignore: unused_element
  Map<String, String> _parseAlipayResult(String result) {
    final map = <String, String>{};
    
    // 支付宝返回格式: resultStatus={状态码}&memo={描述}&result={授权信息}
    final pairs = result.split('&');
    for (final pair in pairs) {
      final keyValue = pair.split('=');
      if (keyValue.length == 2) {
        map[keyValue[0]] = Uri.decodeComponent(keyValue[1]);
      }
    }
    
    return map;
  }
  
  /// 从result中提取auth_code
  // TODO: 完成支付宝SDK配置后启用
  // ignore: unused_element
  String? _extractAuthCode(String result) {
    try {
      // result是一个JSON字符串,解析它
      final resultJson = jsonDecode(result);
      return resultJson['auth_code'] as String?;
    } catch (e) {
      // 如果解析失败，尝试从字符串中提取
      final match = RegExp(r'"auth_code":"([^"]+)"').firstMatch(result);
      return match?.group(1);
    }
  }

  /// 初始化微信SDK
  static Future<void> initWechat({required String appId, String? universalLink}) async {
    try {
      // TODO: 需要完成微信SDK配置后启用
      // DEBUG: print('微信SDK初始化跳过 - 需要完成配置');
      /*
      await registerWxApi(
        appId: appId,
        doOnAndroid: true,
        doOnIOS: true,
        universalLink: universalLink,
      );
      // DEBUG: print('微信SDK初始化成功');
      */
    } catch (e) {
      // DEBUG: print('微信SDK初始化失败: $e');
      throw Exception('微信SDK初始化失败');
    }
  }

  /// 刷新令牌
  Future<LoginResponse> refreshToken() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null) {
      throw Exception('没有刷新令牌');
    }

    try {
      final response = await _httpClient.post(
        '/api/v1/auth/refresh',
        queryParameters: {'refreshToken': refreshToken},
      );

      if (response.data['code'] == 200 && response.data['data'] != null) {
        final loginData = response.data['data'];
        
        // 优先使用后端返回的用户信息，如果没有则从JWT token中解析
        final userInfo = loginData['userInfo'] != null 
            ? User.fromJson(loginData['userInfo'])
            : _parseUserFromToken(loginData['accessToken']);
        
        print('🔄 刷新令牌成功: id=${userInfo.id}, username=${userInfo.username}');
        
        // 创建LoginResponse对象
        final loginResponse = LoginResponse(
          accessToken: loginData['accessToken'],
          refreshToken: loginData['refreshToken'], 
          tokenType: loginData['tokenType'] ?? 'Bearer',
          expiresIn: loginData['expiresIn'] ?? 7200,
          userInfo: userInfo,
        );
        
        await _saveAuthInfo(loginResponse);
        return loginResponse;
      } else {
        throw Exception(response.data['message'] ?? '刷新令牌失败');
      }
    } catch (e) {
      // 刷新失败，清除本地认证信息
      await clearAuthInfo();
      throw Exception('刷新令牌失败: ${e.toString()}');
    }
  }

  /// 登出
  Future<void> logout() async {
    try {
      final accessToken = await getAccessToken();
      if (accessToken != null) {
        // DEBUG: print('🚪 开始退出登录，token: ${accessToken.substring(0, 20)}...');
        
        try {
          await _httpClient.post('/api/v1/auth/logout', data: {});
          // DEBUG: print('✅ 退出登录API调用成功');
        } catch (apiError) {
          // DEBUG: print('⚠️ 退出登录API调用失败: $apiError');
          // 即使API失败也继续清除本地数据
        }
      } else {
        // DEBUG: print('ℹ️ 没有访问令牌，直接清除本地数据');
      }
    } catch (e) {
      // DEBUG: print('❌ 登出异常: $e');
    } finally {
      // 无论请求是否成功，都清除本地认证信息
      await clearAuthInfo();
      // DEBUG: print('✅ 本地认证信息已清除');
    }
  }

  /// 检查是否已登录
  Future<bool> isLoggedIn() async {
    final accessToken = await getAccessToken();
    final expiresAt = await _getTokenExpiresAt();

    if (accessToken == null || expiresAt == null) {
      print('⚠️ Token 检查: Token 不存在');
      return false;
    }

    // 检查令牌是否过期（提前5分钟）
    final now = DateTime.now().millisecondsSinceEpoch;
    const advanceTime = 5 * 60 * 1000; // 提前5分钟
    final isValid = now < (expiresAt - advanceTime);
    
    final remainingSeconds = ((expiresAt - now) / 1000).round();
    final remainingMinutes = (remainingSeconds / 60).toStringAsFixed(1);
    
    if (isValid) {
      print('✅ Token 有效: 剩余 $remainingSeconds 秒 ($remainingMinutes 分钟)');
    } else {
      print('⚠️ Token 已过期或即将过期: 剩余 $remainingSeconds 秒');
    }
    
    return isValid;
  }

  /// 获取当前用户信息
  Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userInfoStr = prefs.getString(_userInfoKey);
      if (userInfoStr != null) {
        final userJson = jsonDecode(userInfoStr);
        return User.fromJson(userJson);
      }
      return null;
    } catch (e) {
      // DEBUG: print('获取用户信息失败: $e');
      return null;
    }
  }

  /// 获取当前用户ID
  Future<int?> getCurrentUserId() async {
    try {
      final userInfo = await getCurrentUser();
      return userInfo?.id;
    } catch (e) {
      // DEBUG: print('获取用户ID失败: $e');
      return null;
    }
  }

  /// 获取访问令牌
  Future<String?> getAccessToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_accessTokenKey);
    } catch (e) {
      // DEBUG: print('获取访问令牌失败: $e');
      return null;
    }
  }

  /// 获取刷新令牌
  Future<String?> getRefreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_refreshTokenKey);
    } catch (e) {
      // DEBUG: print('获取刷新令牌失败: $e');
      return null;
    }
  }

  /// 获取令牌过期时间
  Future<int?> _getTokenExpiresAt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final expiresAtStr = prefs.getString(_tokenExpiresAtKey);
      return expiresAtStr != null ? int.tryParse(expiresAtStr) : null;
    } catch (e) {
      // DEBUG: print('获取令牌过期时间失败: $e');
      return null;
    }
  }

  /// 保存认证信息
  Future<void> _saveAuthInfo(LoginResponse loginResponse) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setString(_accessTokenKey, loginResponse.accessToken);
      await prefs.setString(_refreshTokenKey, loginResponse.refreshToken);
      await prefs.setString(_userInfoKey, jsonEncode(loginResponse.userInfo.toJson()));
      
      // 计算过期时间戳
      final expiresAt = DateTime.now().millisecondsSinceEpoch + (loginResponse.expiresIn * 1000);
      await prefs.setString(_tokenExpiresAtKey, expiresAt.toString());
      
      // DEBUG: print('✅ 认证信息保存成功');
      // DEBUG: print('   - AccessToken: ${loginResponse.accessToken.substring(0, 20)}...');
      // DEBUG: print('   - RefreshToken: ${loginResponse.refreshToken.substring(0, 20)}...');
      // DEBUG: print('   - UserInfo: ${loginResponse.userInfo.nickname}');
      // DEBUG: print('   - ExpiresAt: ${DateTime.fromMillisecondsSinceEpoch(expiresAt)}');
    } catch (e) {
      // DEBUG: print('❌ 保存认证信息失败: $e');
      throw Exception('保存认证信息失败');
    }
  }

  /// 清除认证信息
  Future<void> clearAuthInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.remove(_accessTokenKey);
      await prefs.remove(_refreshTokenKey);
      await prefs.remove(_userInfoKey);
      await prefs.remove(_tokenExpiresAtKey);
      
      // DEBUG: print('✅ 认证信息清除成功');
      // DEBUG: print('   - AccessToken: 已清除');
      // DEBUG: print('   - RefreshToken: 已清除');
      // DEBUG: print('   - UserInfo: 已清除');
      // DEBUG: print('   - TokenExpiresAt: 已清除');
    } catch (e) {
      // DEBUG: print('❌ 清除认证信息失败: $e');
    }
  }

  /// 确保有效令牌
  Future<bool> ensureValidToken() async {
    if (await isLoggedIn()) {
      return true;
    }

    // 尝试刷新令牌
    print('🔄 Token 已过期，开始自动刷新...');
    try {
      await refreshToken();
      print('✅ Token 自动刷新成功！');
      return true;
    } catch (e) {
      print('❌ Token 自动刷新失败: $e');
      return false;
    }
  }

  /// 需要登录的API调用包装器
  Future<T> withAuth<T>(Future<T> Function() apiCall) async {
    // 确保有效令牌
    final hasValidToken = await ensureValidToken();
    if (!hasValidToken) {
      throw Exception('用户未登录或令牌已过期');
    }

    try {
      return await apiCall();
    } catch (e) {
      // 如果返回401，说明令牌无效，尝试刷新
      if (e.toString().contains('401')) {
        try {
          await refreshToken();
          return await apiCall();
        } catch (refreshError) {
          // DEBUG: print('令牌刷新失败，需要重新登录: $refreshError');
          await clearAuthInfo();
          throw Exception('登录已过期，请重新登录');
        }
      }
      rethrow;
    }
  }

  /// 从JWT token中解析用户信息（fallback方法，优先使用后端返回的userInfo）
  User _parseUserFromToken(String token) {
    try {
      // JWT token格式: header.payload.signature
      final parts = token.split('.');
      if (parts.length != 3) {
        throw Exception('Invalid JWT token format');
      }

      // 解码payload（Base64Url）
      final payload = parts[1];
      // Base64Url解码不需要padding，直接解码
      final decodedBytes = base64Url.decode(payload);
      final payloadMap = jsonDecode(utf8.decode(decodedBytes));

      // 🔍 调试日志：打印JWT payload内容
      print('📦 从JWT解析用户信息: $payloadMap');

      // 从JWT payload中提取基本用户信息
      // 注意：JWT中的sub字段是username
      final username = payloadMap['sub'] as String?;
      if (username == null) {
        throw Exception('JWT token中缺少sub(username)字段');
      }

      // 暂时生成一个临时ID（refreshToken时会重新加载完整用户信息）
      return User(
        id: 0, // 临时ID
        username: username,
        nickname: username, // 使用username作为nickname
        lastLoginTime: DateTime.now(),
        createAt: DateTime.now(),
        updateAt: DateTime.now(),
      );
    } catch (e) {
      print('❌ 从JWT解析用户信息失败: $e');
      throw Exception('解析用户信息失败，请重新登录');
    }
  }

  /// 从JWT token中解析过期时间
  // ignore: unused_element
  int _parseExpiresFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        return 7200; // 默认2小时
      }

      final payload = parts[1];
      // Base64Url解码不需要padding，直接解码
      final decodedBytes = base64Url.decode(payload);
      final payloadMap = jsonDecode(utf8.decode(decodedBytes));

      final exp = payloadMap['exp'];
      final iat = payloadMap['iat'];
      if (exp != null && iat != null) {
        return exp - iat; // 返回token有效期（秒）
      }
      return 7200; // 默认2小时
    } catch (e) {
      // DEBUG: print('解析JWT过期时间失败: $e');
      return 7200; // 默认2小时
    }
  }
}

/// 全局认证服务实例
final authService = AuthService();
