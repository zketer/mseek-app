import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/ui_helper.dart';
import '../../core/utils/validators.dart';
import '../../core/utils/image_utils.dart';
import '../../widgets/common/common_app_bar.dart';
import '../../widgets/common/toast_widget.dart';
import '../../services/auth/auth_service.dart';
import '../../services/auth/biometric_auth_service.dart';
import '../../providers/app_provider.dart';

/// 登录页面
class LoginScreen extends StatefulWidget {
  /// 登录成功后的重定向URL（可选）
  final String? redirectUrl;
  
  const LoginScreen({
    super.key,
    this.redirectUrl,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _captchaController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  final AuthService authService = AuthService();
  
  String? _captchaKey;
  String? _captchaImage;
  
  // 生物识别相关
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  String _biometricName = '指纹';

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _loadCaptcha();
    _checkBiometricSupport();
  }
  
  /// 检查生物识别支持
  Future<void> _checkBiometricSupport() async {
    final available = await BiometricAuthService.isBiometricAvailable();
    final enabled = await BiometricAuthService.isBiometricEnabled();
    final name = await BiometricAuthService.getSupportedBiometricName();
    
    setState(() {
      _biometricAvailable = available;
      _biometricEnabled = enabled;
      _biometricName = name;
    });
    
    print('🔐 生物识别状态: available=$available, enabled=$enabled, name=$name');
  }
  
  /// 检查登录状态，如果已登录则直接跳转
  Future<void> _checkLoginStatus() async {
    if (await authService.isLoggedIn()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToTarget();
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _captchaController.dispose();
    super.dispose();
  }
  
  /// 加载图形验证码
  Future<void> _loadCaptcha() async {
    try {
      final captchaResponse = await authService.getCaptcha();
      setState(() {
        _captchaKey = captchaResponse.captchaKey;
        _captchaImage = captchaResponse.captchaImage;
      });
    } catch (e) {
      // 验证码加载失败不影响登录流程
      debugPrint('加载验证码失败: ${e.toString()}');
    }
  }
  
  /// 登录成功后的跳转逻辑
  void _navigateToTarget() {
    if (!mounted) return;
    
    // 优先使用回调地址，但要避免循环重定向到登录页
    if (widget.redirectUrl != null && 
        widget.redirectUrl!.isNotEmpty &&
        !widget.redirectUrl!.contains('/login')) {
      debugPrint('登录成功，跳转到回调地址: ${widget.redirectUrl}');
      // 使用 pushReplacement 替换登录页，避免路由栈问题
      context.pushReplacement(widget.redirectUrl!);
      return;
    }
    
    // 检查是否可以返回上一页
    if (context.canPop()) {
      context.pop();
    } else {
      // 无法返回，跳转到首页
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CommonAppBar.simple(
        title: '登录',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppDimensions.paddingXL),
                
                // 应用Logo
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Icon(
                      Icons.museum,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                ),
                
                const SizedBox(height: AppDimensions.paddingL),
                
                // 欢迎文字
                Text(
                  '欢迎回来',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headlineLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                
                const SizedBox(height: AppDimensions.paddingS),
                
                Text(
                  '登录您的账户，开始文化探索之旅',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                
                const SizedBox(height: AppDimensions.paddingXL * 2),
                
                // 用户名输入框
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: '用户名',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                  validator: (value) => Validators.validateRequired(value, fieldName: '用户名或手机号'),
                ),
                
                const SizedBox(height: AppDimensions.paddingL),
                
                // 密码输入框
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                  validator: Validators.validatePassword,
                ),
                
                const SizedBox(height: AppDimensions.paddingM),

                // 图形验证码（可选）
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _captchaController,
                        decoration: InputDecoration(
                          labelText: '验证码',
                          hintText: '请输入验证码',
                          prefixIcon: const Icon(Icons.security),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                          ),
                          filled: true,
                          fillColor: AppColors.surface,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.paddingS),
                    GestureDetector(
                      onTap: _loadCaptcha,
                      child: Container(
                        width: 120,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                          border: Border.all(
                            color: AppColors.border,
                            width: 1,
                          ),
                        ),
                        child: _captchaImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                                child: ImageUtils.buildBase64Image(
                                  _captchaImage!,
                                  fit: BoxFit.contain,
                                ),
                              )
                            : const Center(
                                child: Text(
                                  '点击刷新',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppDimensions.paddingL),
                
                // 注册和忘记密码
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 立即注册
                    TextButton(
                      onPressed: _onRegisterTapped,
                      child: Text(
                        '立即注册',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    
                    // 忘记密码
                    TextButton(
                      onPressed: _onForgotPasswordTapped,
                      child: Text(
                        '忘记密码',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppDimensions.paddingM),
                
                // 账号密码登录按钮 - 主要登录方式
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _onLoginTapped,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            '登录',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                
                const SizedBox(height: AppDimensions.paddingL),
                
                // 其他登录方式分隔线
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingM,
                      ),
                      child: Text(
                        '其他登录方式',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                
                const SizedBox(height: AppDimensions.paddingM),
                
                // 第三方登录按钮
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 指纹登录按钮（如果已启用）
                    if (_biometricAvailable && _biometricEnabled) ...[
                      _buildThirdPartyLoginButton(
                        icon: Icons.fingerprint,
                        iconColor: Colors.white,
                        backgroundColor: AppColors.primary,
                        onPressed: _isLoading ? null : _handleBiometricLogin,
                      ),
                      const SizedBox(width: AppDimensions.paddingL),
                    ],
                    
                    // 微信登录圆形按钮
                    _buildThirdPartyLoginButton(
                      icon: Icons.wechat,
                      iconColor: Colors.white,
                      backgroundColor: AppColors.checkinSuccess,
                      onPressed: _isLoading ? null : _onWechatLoginTapped,
                    ),
                    
                    const SizedBox(width: AppDimensions.paddingL),
                    
                    // 支付宝登录圆形按钮
                    _buildThirdPartyLoginButton(
                      iconAsset: 'assets/icons/alipay.png',
                      iconColor: Colors.white,
                      backgroundColor: const Color(0xFF1678FF), // 支付宝官方蓝色
                      onPressed: _isLoading ? null : _onAlipayLoginTapped,
                    ),
                  ],
                ),
                
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 处理微信登录按钮点击
  void _onWechatLoginTapped() async {
    // 暂时禁用微信登录，显示友好提示
    if (mounted) {
      UIHelper.showInfo(
        context, 
        '微信登录开发中'
      );
    }
    return;
    
    /* 
    // 完整的微信登录实现（待启用）
    setState(() {
      _isLoading = true;
    });

    try {
      // 调用微信登录
      final loginResponse = await authService.wechatLogin();
      
      // 更新全局用户状态
      if (mounted) {
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        
        await appProvider.setCurrentUser(loginResponse.userInfo);
        
        // 刷新用户状态
        await appProvider.refreshUserState();
        
        // 显示成功提示（使用 Toast）
        if (mounted) {
          ToastWidget.showSuccess(context, '登录成功');
        }
        
        // DEBUG: print('✅ [LoginScreen] 微信登录成功，用户状态已更新');
        
        // 延迟跳转，避免Navigator冲突
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _navigateToTarget();
          }
        });
      }
    } catch (e) {
      // 登录失败，刷新验证码（验证码已被后端消耗）
      if (mounted) {
        UIHelper.showError(context, e.toString());
        Future.microtask(() {
          if (mounted) {
            _captchaController.clear();
            _loadCaptcha();
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
    */
  }

  /// 处理账号密码登录按钮点击
  void _onLoginTapped() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 调用账号密码登录
      final loginResponse = await authService.accountLogin(
        _usernameController.text,
        _passwordController.text,
        captcha: _captchaController.text.trim().isNotEmpty 
            ? _captchaController.text.trim() 
            : null,
        captchaKey: _captchaKey,
      );
      
      // 更新全局用户状态
      if (mounted) {
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        
        await appProvider.setCurrentUser(loginResponse.userInfo);
        
        // 刷新用户状态
        await appProvider.refreshUserState();
        
        // 显示成功提示（使用 Toast）
        if (mounted) {
          ToastWidget.showSuccess(context, '登录成功');
        }
        
        // DEBUG: print('✅ [LoginScreen] 登录成功，用户状态已更新');
        
        // 询问是否启用指纹登录（等待用户选择完成）
        if (mounted && _biometricAvailable && !_biometricEnabled) {
          await _askToEnableBiometric();
        }
        
        // 延迟跳转，避免Navigator冲突
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _navigateToTarget();
          }
        });
      }
    } catch (e) {
      // 登录失败，刷新验证码（验证码已被后端消耗）
      if (mounted) {
        UIHelper.showError(context, e.toString());
        Future.microtask(() {
          if (mounted) {
            _captchaController.clear();
            _loadCaptcha();
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 构建第三方登录圆形按钮
  Widget _buildThirdPartyLoginButton({
    IconData? icon,
    String? iconAsset,
    required Color iconColor,
    required Color backgroundColor,
    required VoidCallback? onPressed,
  }) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(28),
          child: Center(
            child: iconAsset != null
                ? Image.asset(
                    iconAsset,
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                  )
                : Icon(
                    icon!,
                    color: iconColor,
                    size: 28,
                  ),
          ),
        ),
      ),
    );
  }

  /// 处理支付宝登录按钮点击
  void _onAlipayLoginTapped() async {
    // 暂时禁用支付宝登录，显示友好提示
    if (mounted) {
      UIHelper.showInfo(
        context, 
        '支付宝登录开发中'
      );
    }
    return;
    
    /* 
    // 完整的支付宝登录实现（待启用）
    setState(() {
      _isLoading = true;
    });

    try {
      // 调用支付宝登录
      final loginResponse = await authService.alipayLogin();
      
      // 更新全局用户状态
      if (mounted) {
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        
        await appProvider.setCurrentUser(loginResponse.userInfo);
        
        // 刷新用户状态
        await appProvider.refreshUserState();
        
        // 显示成功提示
        if (mounted) {
          ToastWidget.showSuccess(context, '登录成功');
        }
        
        print('✅ [LoginScreen] 支付宝登录成功，用户状态已更新');
        
        // 延迟跳转，避免Navigator冲突
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _navigateToTarget();
          }
        });
      }
    } catch (e) {
      // 登录失败
      if (mounted) {
        UIHelper.showError(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
    */
  }

  /// 处理注册按钮点击
  void _onRegisterTapped() {
    context.push('/register');
  }

  /// 处理忘记密码点击
  void _onForgotPasswordTapped() {
    context.push('/reset-password');
  }
  
  /// 处理指纹登录
  Future<void> _handleBiometricLogin() async {
    try {
      print('🔐 开始指纹登录...');
      
      // 获取保存的凭据
      final credentials = await BiometricAuthService.getSavedCredentials();
      
      if (credentials == null) {
        print('⚠️ 未获取到凭据，取消指纹登录');
        return;
      }
      
      setState(() {
        _isLoading = true;
      });
      
      // 使用保存的凭据登录
      final loginResponse = await authService.accountLogin(
        credentials['username']!,
        credentials['password']!,
      );
      
      // 更新全局用户状态
      if (mounted) {
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        await appProvider.setCurrentUser(loginResponse.userInfo);
        await appProvider.refreshUserState();
        
        if (mounted) {
          ToastWidget.showSuccess(context, '$_biometricName登录成功');
        }
        
        print('✅ 指纹登录成功');
        
        // 延迟跳转
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _navigateToTarget();
          }
        });
      }
    } catch (e) {
      print('❌ 指纹登录失败: $e');
      if (mounted) {
        UIHelper.showError(context, '登录失败: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  /// 询问是否启用指纹登录
  Future<void> _askToEnableBiometric() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('启用$_biometricName登录'),
        content: Text('是否启用$_biometricName快速登录？下次可以直接使用$_biometricName登录，无需输入密码。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('暂不启用'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('启用'),
          ),
        ],
      ),
    );
    
    if (result == true) {
      final success = await BiometricAuthService.enableBiometricLogin(
        _usernameController.text,
        _passwordController.text,
      );
      
      if (success && mounted) {
        setState(() {
          _biometricEnabled = true;
        });
        ToastWidget.showSuccess(context, '$_biometricName登录已启用');
      }
    }
  }
}
