/// 表单验证工具类
/// 
/// 提供常用的表单验证方法，包括：
/// - 手机号验证
/// - 密码验证
/// - 邮箱验证
/// - 用户名验证
/// - 通用验证
/// 
/// 使用示例：
/// ```dart
/// TextFormField(
///   validator: Validators.validatePhone,
/// )
/// 
/// TextFormField(
///   validator: Validators.combine([
///     Validators.validateRequired,
///     (value) => Validators.validateLength(value, min: 6, max: 20),
///   ]),
/// )
/// ```
class Validators {
  /// 验证手机号
  /// 
  /// [value] 要验证的值
  /// 
  /// 返回：验证通过返回null，否则返回错误信息
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return '请输入手机号';
    }
    if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(value)) {
      return '请输入正确的手机号';
    }
    return null;
  }

  /// 验证密码
  /// 
  /// 规则：6-20位字符
  /// 
  /// [value] 要验证的值
  /// 
  /// 返回：验证通过返回null，否则返回错误信息
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return '请输入密码';
    }
    if (value.length < 6) {
      return '密码至少6位';
    }
    if (value.length > 20) {
      return '密码最多20位';
    }
    return null;
  }

  /// 验证强密码
  /// 
  /// 规则：8-20位，必须包含大小写字母和数字
  /// 
  /// [value] 要验证的值
  /// 
  /// 返回：验证通过返回null，否则返回错误信息
  static String? validateStrongPassword(String? value) {
    if (value == null || value.isEmpty) {
      return '请输入密码';
    }
    if (value.length < 8) {
      return '密码至少8位';
    }
    if (value.length > 20) {
      return '密码最多20位';
    }
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).+$').hasMatch(value)) {
      return '密码必须包含大小写字母和数字';
    }
    return null;
  }

  /// 验证邮箱
  /// 
  /// [value] 要验证的值
  /// 
  /// 返回：验证通过返回null，否则返回错误信息
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return '请输入邮箱';
    }
    if (!RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return '请输入正确的邮箱格式';
    }
    return null;
  }

  /// 验证用户名
  /// 
  /// 规则：4-20位，只能包含字母、数字和下划线
  /// 
  /// [value] 要验证的值
  /// 
  /// 返回：验证通过返回null，否则返回错误信息
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return '请输入用户名';
    }
    if (value.length < 4) {
      return '用户名至少4位';
    }
    if (value.length > 20) {
      return '用户名最多20位';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return '用户名只能包含字母、数字和下划线';
    }
    return null;
  }

  /// 验证邮箱验证码
  /// 
  /// 规则：6位数字
  /// 
  /// [value] 要验证的值
  /// 
  /// 返回：验证通过返回null，否则返回错误信息
  static String? validateEmailCode(String? value) {
    if (value == null || value.isEmpty) {
      return '请输入验证码';
    }
    if (!RegExp(r'^\d{6}$').hasMatch(value)) {
      return '验证码必须是6位数字';
    }
    return null;
  }

  /// 验证非空
  /// 
  /// [value] 要验证的值
  /// [fieldName] 字段名称，用于错误提示
  /// 
  /// 返回：验证通过返回null，否则返回错误信息
  static String? validateRequired(String? value, {String fieldName = '此项'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName不能为空';
    }
    return null;
  }

  /// 验证长度范围
  /// 
  /// [value] 要验证的值
  /// [min] 最小长度
  /// [max] 最大长度
  /// [fieldName] 字段名称，用于错误提示
  /// 
  /// 返回：验证通过返回null，否则返回错误信息
  static String? validateLength(
    String? value, {
    int? min,
    int? max,
    String fieldName = '此项',
  }) {
    if (value == null || value.isEmpty) {
      return '$fieldName不能为空';
    }
    if (min != null && value.length < min) {
      return '$fieldName至少$min位';
    }
    if (max != null && value.length > max) {
      return '$fieldName最多$max位';
    }
    return null;
  }

  /// 验证数字
  /// 
  /// [value] 要验证的值
  /// [fieldName] 字段名称，用于错误提示
  /// 
  /// 返回：验证通过返回null，否则返回错误信息
  static String? validateNumber(String? value, {String fieldName = '此项'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName不能为空';
    }
    if (double.tryParse(value) == null) {
      return '$fieldName必须是数字';
    }
    return null;
  }

  /// 验证整数
  /// 
  /// [value] 要验证的值
  /// [fieldName] 字段名称，用于错误提示
  /// 
  /// 返回：验证通过返回null，否则返回错误信息
  static String? validateInteger(String? value, {String fieldName = '此项'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName不能为空';
    }
    if (int.tryParse(value) == null) {
      return '$fieldName必须是整数';
    }
    return null;
  }

  /// 验证数字范围
  /// 
  /// [value] 要验证的值
  /// [min] 最小值
  /// [max] 最大值
  /// [fieldName] 字段名称，用于错误提示
  /// 
  /// 返回：验证通过返回null，否则返回错误信息
  static String? validateNumberRange(
    String? value, {
    double? min,
    double? max,
    String fieldName = '此项',
  }) {
    if (value == null || value.isEmpty) {
      return '$fieldName不能为空';
    }
    final number = double.tryParse(value);
    if (number == null) {
      return '$fieldName必须是数字';
    }
    if (min != null && number < min) {
      return '$fieldName不能小于$min';
    }
    if (max != null && number > max) {
      return '$fieldName不能大于$max';
    }
    return null;
  }

  /// 验证身份证号
  /// 
  /// 支持15位和18位身份证号
  /// 
  /// [value] 要验证的值
  /// 
  /// 返回：验证通过返回null，否则返回错误信息
  static String? validateIdCard(String? value) {
    if (value == null || value.isEmpty) {
      return '请输入身份证号';
    }
    if (!RegExp(r'^\d{15}$|^\d{17}[\dXx]$').hasMatch(value)) {
      return '请输入正确的身份证号';
    }
    return null;
  }

  /// 验证URL
  /// 
  /// [value] 要验证的值
  /// 
  /// 返回：验证通过返回null，否则返回错误信息
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return '请输入网址';
    }
    if (!RegExp(r'^https?://[\w\-]+(\.[\w\-]+)+[/#?]?.*$').hasMatch(value)) {
      return '请输入正确的网址格式';
    }
    return null;
  }

  /// 验证中文
  /// 
  /// [value] 要验证的值
  /// [fieldName] 字段名称，用于错误提示
  /// 
  /// 返回：验证通过返回null，否则返回错误信息
  static String? validateChinese(String? value, {String fieldName = '此项'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName不能为空';
    }
    if (!RegExp(r'^[\u4e00-\u9fa5]+$').hasMatch(value)) {
      return '$fieldName必须是中文';
    }
    return null;
  }

  /// 验证英文
  /// 
  /// [value] 要验证的值
  /// [fieldName] 字段名称，用于错误提示
  /// 
  /// 返回：验证通过返回null，否则返回错误信息
  static String? validateEnglish(String? value, {String fieldName = '此项'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName不能为空';
    }
    if (!RegExp(r'^[a-zA-Z]+$').hasMatch(value)) {
      return '$fieldName必须是英文字母';
    }
    return null;
  }

  /// 验证两次输入是否一致
  /// 
  /// 常用于密码确认
  /// 
  /// [value] 要验证的值
  /// [originalValue] 原始值
  /// [fieldName] 字段名称，用于错误提示
  /// 
  /// 返回：验证通过返回null，否则返回错误信息
  static String? validateConfirm(
    String? value,
    String? originalValue, {
    String fieldName = '两次输入',
  }) {
    if (value == null || value.isEmpty) {
      return '请再次输入';
    }
    if (value != originalValue) {
      return '$fieldName不一致';
    }
    return null;
  }

  /// 组合多个验证器
  /// 
  /// 按顺序执行验证，遇到第一个错误即返回
  /// 
  /// [validators] 验证器列表
  /// 
  /// 返回：组合后的验证函数
  /// 
  /// 使用示例：
  /// ```dart
  /// TextFormField(
  ///   validator: Validators.combine([
  ///     Validators.validateRequired,
  ///     (value) => Validators.validateLength(value, min: 6, max: 20),
  ///     (value) => Validators.validatePassword(value),
  ///   ]),
  /// )
  /// ```
  static String? Function(String?) combine(
    List<String? Function(String?)> validators,
  ) {
    return (value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }

  /// 可选验证（允许为空）
  /// 
  /// 如果值为空则跳过验证，否则执行指定的验证器
  /// 
  /// [validator] 要执行的验证器
  /// 
  /// 返回：包装后的验证函数
  /// 
  /// 使用示例：
  /// ```dart
  /// TextFormField(
  ///   validator: Validators.optional(Validators.validateEmail),
  /// )
  /// ```
  static String? Function(String?) optional(
    String? Function(String?) validator,
  ) {
    return (value) {
      if (value == null || value.trim().isEmpty) {
        return null;
      }
      return validator(value);
    };
  }

  /// 自定义验证
  /// 
  /// 根据自定义条件进行验证
  /// 
  /// [value] 要验证的值
  /// [condition] 验证条件函数，返回true表示验证通过
  /// [errorMessage] 验证失败时的错误信息
  /// 
  /// 返回：验证通过返回null，否则返回错误信息
  static String? validateCustom(
    String? value,
    bool Function(String?) condition,
    String errorMessage,
  ) {
    if (value == null || value.isEmpty) {
      return '不能为空';
    }
    if (!condition(value)) {
      return errorMessage;
    }
    return null;
  }
}

