import 'package:intl/intl.dart';

/// 日期时间工具类
/// 
/// 提供统一的日期时间格式化方法，包括：
/// - 各种格式的日期时间格式化
/// - 日期范围格式化
/// - 相对时间格式化
/// - 日期比较判断
/// 
/// 使用示例：
/// ```dart
/// DateUtils.formatDate(DateTime.now());              // 2024年10月21日
/// DateUtils.formatShortDate(DateTime.now());         // 10月21日
/// DateUtils.formatRelativeTime(checkinTime);         // 5分钟前
/// DateUtils.formatDateRange(startDate, endDate);     // 10月1日 - 10月7日
/// DateUtils.isToday(DateTime.now());                 // true
/// ```
class AppDateUtils {
  /// 格式化为：2024年10月21日
  /// 
  /// [date] 要格式化的日期
  static String formatDate(DateTime date) {
    return DateFormat('yyyy年MM月dd日').format(date);
  }

  /// 格式化为：10月21日
  /// 
  /// [date] 要格式化的日期
  static String formatShortDate(DateTime date) {
    return DateFormat('MM月dd日').format(date);
  }

  /// 格式化为：2024-10-21
  /// 
  /// [date] 要格式化的日期
  static String formatISODate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// 格式化为：10:30
  /// 
  /// [time] 要格式化的时间
  static String formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  /// 格式化为：10月21日 10:30
  /// 
  /// [dateTime] 要格式化的日期时间
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('MM月dd日 HH:mm').format(dateTime);
  }

  /// 格式化为：2024年10月21日 10:30
  /// 
  /// [dateTime] 要格式化的日期时间
  static String formatFullDateTime(DateTime dateTime) {
    return DateFormat('yyyy年MM月dd日 HH:mm').format(dateTime);
  }

  /// 格式化为：2024-10-21 10:30:45
  /// 
  /// [dateTime] 要格式化的日期时间
  static String formatISODateTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
  }

  /// 格式化日期范围
  /// 
  /// 根据开始和结束日期的年月情况，智能选择格式：
  /// - 同年同月：10月1日 - 7日
  /// - 同年不同月：10月1日 - 11月7日
  /// - 不同年：2024年10月1日 - 2025年1月7日
  /// 
  /// [start] 开始日期
  /// [end] 结束日期
  static String formatDateRange(DateTime start, DateTime end) {
    if (start.year == end.year && start.month == end.month) {
      // 同年同月：10月1日 - 7日
      return '${start.month}月${start.day}日 - ${end.day}日';
    } else if (start.year == end.year) {
      // 同年不同月：10月1日 - 11月7日
      return '${start.month}月${start.day}日 - ${end.month}月${end.day}日';
    } else {
      // 不同年：2024年10月1日 - 2025年1月7日
      return '${start.year}年${start.month}月${start.day}日 - '
          '${end.year}年${end.month}月${end.day}日';
    }
  }

  /// 格式化相对时间
  /// 
  /// 根据时间差返回友好的相对时间描述：
  /// - 刚刚（1分钟内）
  /// - X分钟前（1-59分钟）
  /// - X小时前（1-23小时）
  /// - 昨天（24-48小时）
  /// - X天前（2-6天）
  /// - 具体日期（7天以上）
  /// 
  /// [dateTime] 要格式化的时间
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return '刚刚';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays == 1) {
      return '昨天';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return formatDate(dateTime);
    }
  }

  /// 格式化相对时间（带时分）
  /// 
  /// 与 [formatRelativeTime] 类似，但对于昨天和今天会显示具体时间
  /// - 刚刚（1分钟内）
  /// - X分钟前（1-59分钟）
  /// - 今天 10:30（今天）
  /// - 昨天 10:30（昨天）
  /// - X天前（2-6天）
  /// - 具体日期（7天以上）
  /// 
  /// [dateTime] 要格式化的时间
  static String formatRelativeTimeWithClock(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return '刚刚';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (isToday(dateTime)) {
      return '今天 ${formatTime(dateTime)}';
    } else if (difference.inDays == 1) {
      return '昨天 ${formatTime(dateTime)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return formatDateTime(dateTime);
    }
  }

  /// 判断是否是今天
  /// 
  /// [date] 要判断的日期
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// 判断是否是同一天
  /// 
  /// [date1] 第一个日期
  /// [date2] 第二个日期
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// 判断是否是昨天
  /// 
  /// [date] 要判断的日期
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return isSameDay(date, yesterday);
  }

  /// 判断是否是本周
  /// 
  /// [date] 要判断的日期
  static bool isThisWeek(DateTime date) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    return date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
        date.isBefore(endOfWeek.add(const Duration(days: 1)));
  }

  /// 判断是否是本月
  /// 
  /// [date] 要判断的日期
  static bool isThisMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  /// 判断是否是本年
  /// 
  /// [date] 要判断的日期
  static bool isThisYear(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year;
  }

  /// 获取两个日期之间的天数差
  /// 
  /// [date1] 第一个日期
  /// [date2] 第二个日期
  /// 
  /// 返回：天数差（正数表示date1在date2之后）
  static int daysBetween(DateTime date1, DateTime date2) {
    final from = DateTime(date1.year, date1.month, date1.day);
    final to = DateTime(date2.year, date2.month, date2.day);
    return from.difference(to).inDays;
  }

  /// 获取星期几的中文名称
  /// 
  /// [date] 要获取的日期
  /// 
  /// 返回：星期一 ~ 星期日
  static String getWeekdayName(DateTime date) {
    const weekdays = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];
    return weekdays[date.weekday - 1];
  }

  /// 获取星期几的简称
  /// 
  /// [date] 要获取的日期
  /// 
  /// 返回：周一 ~ 周日
  static String getWeekdayShortName(DateTime date) {
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return weekdays[date.weekday - 1];
  }

  /// 获取月初日期
  /// 
  /// [date] 要获取的日期
  static DateTime getMonthStart(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// 获取月末日期
  /// 
  /// [date] 要获取的日期
  static DateTime getMonthEnd(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  /// 获取当月天数
  /// 
  /// [date] 要获取的日期
  static int getDaysInMonth(DateTime date) {
    return getMonthEnd(date).day;
  }

  /// 解析ISO格式日期字符串
  /// 
  /// [dateString] ISO格式的日期字符串（如：2024-10-21）
  /// 
  /// 返回：解析后的DateTime对象，解析失败返回null
  static DateTime? parseISODate(String dateString) {
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// 格式化时长
  /// 
  /// 将Duration格式化为友好的时长描述
  /// 
  /// [duration] 要格式化的时长
  /// 
  /// 返回：如 "2小时30分钟"、"45分钟"、"3天"
  static String formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}天';
    } else if (duration.inHours > 0) {
      final minutes = duration.inMinutes % 60;
      if (minutes > 0) {
        return '${duration.inHours}小时$minutes分钟';
      } else {
        return '${duration.inHours}小时';
      }
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}分钟';
    } else {
      return '${duration.inSeconds}秒';
    }
  }
}

