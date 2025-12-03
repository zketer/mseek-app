import 'dart:async';
import 'package:flutter/material.dart';
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

/// 重置密码页面
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _emailCodeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _captchaController = TextEditingController();
  
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _isSendingCode = false;
  final ValueNotifier<int> _countdownNotifier = ValueNotifier<int>(0);
  Timer? _countdownTimer;
  
  final AuthService _authService = AuthService();
  String? _captchaKey;
  String? _captchaImage;

  @override
  void initState() {
    super.initState();
    _loadCaptcha();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _emailCodeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _captchaController.dispose();
    _countdownTimer?.cancel();
    _countdownNotifier.dispose();
    super.dispose();
  }

  /// 加载图形验证码
  Future<void> _loadCaptcha() async {
    try {
      final captchaResponse = await _authService.getCaptcha();
      setState(() {
        _captchaKey = captchaResponse.captchaKey;
        _captchaImage = captchaResponse.captchaImage;
      });
    } catch (e) {
      if (mounted) {
        UIHelper.showError(context, '加载验证码失败: ${e.toString()}');
      }
    }
  }

  /// 发送邮箱验证码
  Future<void> _sendEmailCode() async {
    // 验证邮箱格式
    final email = _emailController.text.trim();
    final emailError = Validators.validateEmail(email);
    if (emailError != null) {
      UIHelper.showWarning(context, emailError);
      return;
    }

    setState(() {
      _isSendingCode = true;
    });

    try {
      await _authService.sendEmailCode(email, 'reset');
      
      if (mounted) {
        ToastWidget.showSuccess(context, '验证码已发送到您的邮箱');
        
        // 开始倒计时（使用ValueNotifier，避免全局setState）
        _countdownNotifier.value = 60;
        
        _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (_countdownNotifier.value > 0) {
            _countdownNotifier.value--;
          } else {
            timer.cancel();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        UIHelper.showError(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingCode = false;
        });
      }
    }
  }

  /// 处理重置密码
  Future<void> _onResetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 验证验证码
    if (_captchaController.text.trim().isEmpty) {
      UIHelper.showWarning(context, '请输入图形验证码');
      return;
    }

    // 验证邮箱验证码
    if (_emailCodeController.text.trim().isEmpty) {
      UIHelper.showWarning(context, '请输入邮箱验证码');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.resetPassword(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        code: _emailCodeController.text.trim(),
        newPassword: _newPasswordController.text,
        confirmPassword: _confirmPasswordController.text,
        captcha: _captchaController.text.trim(),
        captchaKey: _captchaKey!,
      );

      if (mounted) {
        ToastWidget.showSuccess(context, '密码重置成功，请使用新密码登录');

        // 延迟跳转到登录页
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            context.go('/login');
          }
        });
      }
    } catch (e) {
      // 重置密码失败，刷新验证码（验证码已被后端消耗）
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CommonAppBar.simple(
        title: '重置密码',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppDimensions.paddingL),

                // 提示文字
                Text(
                  '请填写账号信息以重置密码',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: AppDimensions.paddingXL),

                // 用户名输入框
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: '用户名 *',
                    hintText: '请输入用户名',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                  validator: Validators.validateUsername,
                ),

                const SizedBox(height: AppDimensions.paddingM),

                // 邮箱输入框
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: '邮箱 *',
                    hintText: '请输入注册时的邮箱地址',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                  validator: Validators.validateEmail,
                ),

                const SizedBox(height: AppDimensions.paddingM),

                // 邮箱验证码输入框
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _emailCodeController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: InputDecoration(
                          labelText: '邮箱验证码 *',
                          hintText: '请输入6位数字验证码',
                          prefixIcon: const Icon(Icons.verified_user),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                          ),
                          filled: true,
                          fillColor: AppColors.surface,
                          counterText: '', // 隐藏字符计数
                        ),
                        validator: Validators.validateEmailCode,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.paddingS),
                    ValueListenableBuilder<int>(
                      valueListenable: _countdownNotifier,
                      builder: (context, countdown, child) {
                        return SizedBox(
                          width: 120,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: (_isSendingCode || countdown > 0) ? null : _sendEmailCode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                              ),
                            ),
                            child: _isSendingCode
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    countdown > 0 ? '${countdown}s' : '获取验证码',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: AppDimensions.paddingM),

                // 新密码输入框
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: !_isNewPasswordVisible,
                  decoration: InputDecoration(
                    labelText: '新密码 *',
                    hintText: '请输入新密码',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isNewPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isNewPasswordVisible = !_isNewPasswordVisible;
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

                // 确认新密码输入框
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_isConfirmPasswordVisible,
                  decoration: InputDecoration(
                    labelText: '确认新密码 *',
                    hintText: '请再次输入新密码',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请再次输入新密码';
                    }
                    if (value != _newPasswordController.text) {
                      return '两次输入的密码不一致';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppDimensions.paddingM),

                // 图形验证码
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _captchaController,
                        decoration: InputDecoration(
                          labelText: '图形验证码 *',
                          hintText: '请输入验证码',
                          prefixIcon: const Icon(Icons.security),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                          ),
                          filled: true,
                          fillColor: AppColors.surface,
                        ),
                        validator: (value) => Validators.validateRequired(value, fieldName: '验证码'),
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

                const SizedBox(height: AppDimensions.paddingXL),

                // 重置密码按钮
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _onResetPassword,
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
                            '重置密码',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: AppDimensions.paddingM),

                // 返回登录
                Center(
                  child: TextButton(
                    onPressed: () => context.pop(),
                    child: Text(
                      '返回登录',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
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
}

