/// 字符串工具类
/// 
/// 提供常用的字符串处理方法，包括：
/// - 空值判断
/// - 字符串截断
/// - 数字格式化
/// - 距离格式化
/// - 隐私信息脱敏
/// - 大小写转换
/// 
/// 使用示例：
/// ```dart
/// StringUtils.isEmpty(value);                  // 判断是否为空
/// StringUtils.truncate(longText, 50);          // 截断文字
/// StringUtils.formatNumber(1234567);           // 格式化数字：1,234,567
/// StringUtils.formatDistance(1500);            // 格式化距离：1.5公里
/// StringUtils.maskPhone('13800138000');        // 手机号脱敏：138****8000
/// StringUtils.maskName('张三');                 // 姓名脱敏：张*
/// ```
class StringUtils {
  /// 判断字符串是否为空
  /// 
  /// 空字符串、null、全空格都返回true
  /// 
  /// [value] 要判断的字符串
  static bool isEmpty(String? value) {
    return value == null || value.trim().isEmpty;
  }

  /// 判断字符串不为空
  /// 
  /// [value] 要判断的字符串
  static bool isNotEmpty(String? value) {
    return !isEmpty(value);
  }

  /// 截断字符串
  /// 
  /// 如果字符串长度超过maxLength，则截断并添加后缀
  /// 
  /// [value] 要截断的字符串
  /// [maxLength] 最大长度
  /// [suffix] 后缀，默认"..."
  /// 
  /// 返回：截断后的字符串
  static String truncate(String value, int maxLength, {String suffix = '...'}) {
    if (value.length <= maxLength) return value;
    return value.substring(0, maxLength) + suffix;
  }

  /// 格式化数字（添加千位分隔符）
  /// 
  /// 例如：1234567 -> 1,234,567
  /// 
  /// [value] 要格式化的数字
  /// 
  /// 返回：格式化后的字符串
  static String formatNumber(num value) {
    return value.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  /// 格式化距离
  /// 
  /// 根据距离值自动选择单位（米/公里）
  /// - 小于1000米：显示"XXX米"
  /// - 大于等于1000米：显示"X.X公里"
  /// 
  /// [meters] 距离（米）
  /// 
  /// 返回：格式化后的距离字符串
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)}米';
    } else {
      final km = meters / 1000;
      return '${km.toStringAsFixed(1)}公里';
    }
  }

  /// 格式化文件大小
  /// 
  /// 自动选择合适的单位（B/KB/MB/GB）
  /// 
  /// [bytes] 文件大小（字节）
  /// 
  /// 返回：格式化后的文件大小字符串
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '${bytes}B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)}KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
    }
  }

  /// 隐藏手机号中间4位
  /// 
  /// 例如：13800138000 -> 138****8000
  /// 
  /// [phone] 手机号
  /// 
  /// 返回：脱敏后的手机号
  static String maskPhone(String phone) {
    if (phone.length != 11) return phone;
    return phone.replaceRange(3, 7, '****');
  }

  /// 隐藏邮箱
  /// 
  /// 例如：example@gmail.com -> e****e@gmail.com
  /// 
  /// [email] 邮箱
  /// 
  /// 返回：脱敏后的邮箱
  static String maskEmail(String email) {
    if (!email.contains('@')) return email;
    final parts = email.split('@');
    final username = parts[0];
    if (username.length <= 2) {
      return '${username[0]}***@${parts[1]}';
    }
    return '${username[0]}${'*' * (username.length - 2)}${username[username.length - 1]}@${parts[1]}';
  }

  /// 隐藏姓名（只显示姓）
  /// 
  /// 例如：张三 -> 张*；李四五 -> 李**
  /// 
  /// [name] 姓名
  /// 
  /// 返回：脱敏后的姓名
  static String maskName(String name) {
    if (name.isEmpty) return name;
    return name[0] + '*' * (name.length - 1);
  }

  /// 隐藏身份证号
  /// 
  /// 例如：110101199001011234 -> 110101********1234
  /// 
  /// [idCard] 身份证号
  /// 
  /// 返回：脱敏后的身份证号
  static String maskIdCard(String idCard) {
    if (idCard.length < 8) return idCard;
    final start = idCard.substring(0, 6);
    final end = idCard.substring(idCard.length - 4);
    return '$start${'*' * (idCard.length - 10)}$end';
  }

  /// 首字母大写
  /// 
  /// 例如：hello -> Hello
  /// 
  /// [value] 要处理的字符串
  /// 
  /// 返回：首字母大写后的字符串
  static String capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  /// 每个单词首字母大写
  /// 
  /// 例如：hello world -> Hello World
  /// 
  /// [value] 要处理的字符串
  /// 
  /// 返回：每个单词首字母大写后的字符串
  static String capitalizeWords(String value) {
    if (value.isEmpty) return value;
    return value.split(' ').map((word) => capitalize(word)).join(' ');
  }

  /// 驼峰转下划线
  /// 
  /// 例如：userName -> user_name
  /// 
  /// [value] 要转换的字符串
  /// 
  /// 返回：下划线格式的字符串
  static String camelToSnake(String value) {
    return value.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    );
  }

  /// 下划线转驼峰
  /// 
  /// 例如：user_name -> userName
  /// 
  /// [value] 要转换的字符串
  /// 
  /// 返回：驼峰格式的字符串
  static String snakeToCamel(String value) {
    return value.replaceAllMapped(
      RegExp(r'_([a-z])'),
      (match) => match.group(1)!.toUpperCase(),
    );
  }

  /// 移除所有空格
  /// 
  /// [value] 要处理的字符串
  /// 
  /// 返回：移除空格后的字符串
  static String removeSpaces(String value) {
    return value.replaceAll(' ', '');
  }

  /// 移除所有换行符
  /// 
  /// [value] 要处理的字符串
  /// 
  /// 返回：移除换行符后的字符串
  static String removeNewLines(String value) {
    return value.replaceAll(RegExp(r'\r?\n'), '');
  }

  /// 移除HTML标签
  /// 
  /// [value] 要处理的字符串
  /// 
  /// 返回：移除HTML标签后的字符串
  static String removeHtmlTags(String value) {
    return value.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  /// 反转字符串
  /// 
  /// [value] 要反转的字符串
  /// 
  /// 返回：反转后的字符串
  static String reverse(String value) {
    return value.split('').reversed.join('');
  }

  /// 判断字符串是否包含中文
  /// 
  /// [value] 要判断的字符串
  static bool containsChinese(String value) {
    return RegExp(r'[\u4e00-\u9fa5]').hasMatch(value);
  }

  /// 判断字符串是否全是中文
  /// 
  /// [value] 要判断的字符串
  static bool isAllChinese(String value) {
    return RegExp(r'^[\u4e00-\u9fa5]+$').hasMatch(value);
  }

  /// 判断字符串是否是数字
  /// 
  /// [value] 要判断的字符串
  static bool isNumeric(String value) {
    return double.tryParse(value) != null;
  }

  /// 判断字符串是否是整数
  /// 
  /// [value] 要判断的字符串
  static bool isInteger(String value) {
    return int.tryParse(value) != null;
  }

  /// 判断字符串是否是邮箱
  /// 
  /// [value] 要判断的字符串
  static bool isEmail(String value) {
    return RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value);
  }

  /// 判断字符串是否是手机号
  /// 
  /// [value] 要判断的字符串
  static bool isPhone(String value) {
    return RegExp(r'^1[3-9]\d{9}$').hasMatch(value);
  }

  /// 判断字符串是否是URL
  /// 
  /// [value] 要判断的字符串
  static bool isUrl(String value) {
    return RegExp(r'^https?://[\w\-]+(\.[\w\-]+)+[/#?]?.*$').hasMatch(value);
  }

  /// 获取字符串的字节长度（中文算2个字节）
  /// 
  /// [value] 要计算的字符串
  /// 
  /// 返回：字节长度
  static int getByteLength(String value) {
    int length = 0;
    for (int i = 0; i < value.length; i++) {
      final code = value.codeUnitAt(i);
      if (code > 127) {
        length += 2;
      } else {
        length += 1;
      }
    }
    return length;
  }

  /// 按字节长度截断字符串（中文算2个字节）
  /// 
  /// [value] 要截断的字符串
  /// [maxByteLength] 最大字节长度
  /// [suffix] 后缀，默认"..."
  /// 
  /// 返回：截断后的字符串
  static String truncateByBytes(
    String value,
    int maxByteLength, {
    String suffix = '...',
  }) {
    int length = 0;
    int charIndex = 0;

    for (int i = 0; i < value.length; i++) {
      final code = value.codeUnitAt(i);
      if (code > 127) {
        length += 2;
      } else {
        length += 1;
      }

      if (length <= maxByteLength) {
        charIndex = i + 1;
      } else {
        break;
      }
    }

    if (charIndex >= value.length) {
      return value;
    }

    return value.substring(0, charIndex) + suffix;
  }

  /// 安全地解析整数
  /// 
  /// [value] 要解析的字符串
  /// [defaultValue] 解析失败时的默认值，默认0
  /// 
  /// 返回：解析后的整数
  static int parseInt(String? value, {int defaultValue = 0}) {
    if (value == null || value.isEmpty) return defaultValue;
    return int.tryParse(value) ?? defaultValue;
  }

  /// 安全地解析浮点数
  /// 
  /// [value] 要解析的字符串
  /// [defaultValue] 解析失败时的默认值，默认0.0
  /// 
  /// 返回：解析后的浮点数
  static double parseDouble(String? value, {double defaultValue = 0.0}) {
    if (value == null || value.isEmpty) return defaultValue;
    return double.tryParse(value) ?? defaultValue;
  }

  /// 生成随机字符串
  /// 
  /// [length] 字符串长度
  /// [includeNumbers] 是否包含数字，默认true
  /// [includeUppercase] 是否包含大写字母，默认true
  /// [includeLowercase] 是否包含小写字母，默认true
  /// 
  /// 返回：随机字符串
  static String random(
    int length, {
    bool includeNumbers = true,
    bool includeUppercase = true,
    bool includeLowercase = true,
  }) {
    String chars = '';
    if (includeNumbers) chars += '0123456789';
    if (includeUppercase) chars += 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    if (includeLowercase) chars += 'abcdefghijklmnopqrstuvwxyz';

    if (chars.isEmpty) return '';

    final random = DateTime.now().millisecondsSinceEpoch;
    final buffer = StringBuffer();

    for (int i = 0; i < length; i++) {
      final index = (random + i) % chars.length;
      buffer.write(chars[index]);
    }

    return buffer.toString();
  }
}

