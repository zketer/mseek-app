import '../constants/app_constants.dart';

/// 打卡相关工具类
class CheckinUtils {
  /// 判断距离是否在打卡范围内
  /// 
  /// [distanceKm] 距离（公里）
  /// 返回 true 表示可以打卡，false 表示距离过远
  static bool canCheckinByDistance(double distanceKm) {
    return distanceKm <= AppConstants.checkinDistanceLimit;
  }

  /// 从距离字符串判断是否可以打卡
  /// 
  /// [distanceStr] 距离字符串，如 "1.2km", "500m"
  /// 返回 true 表示可以打卡，false 表示距离过远
  static bool canCheckinByDistanceString(String? distanceStr) {
    if (distanceStr == null || distanceStr.isEmpty) {
      return false;
    }

    try {
      if (distanceStr.endsWith('m')) {
        final meters = double.tryParse(distanceStr.replaceAll('m', '').trim()) ?? 99999;
        return meters <= AppConstants.checkinDistanceLimitMeters;
      } else if (distanceStr.endsWith('km')) {
        final km = double.tryParse(distanceStr.replaceAll('km', '').trim()) ?? 99999;
        return canCheckinByDistance(km);
      } else {
        // 如果没有单位，尝试解析为km
        final km = double.tryParse(distanceStr.trim()) ?? 99999;
        return canCheckinByDistance(km);
      }
    } catch (e) {
      // 解析失败，返回false
      return false;
    }
  }

  /// 获取打卡距离限制文本描述
  static String getDistanceLimitDescription() {
    if (AppConstants.checkinDistanceLimit < 1) {
      return '${(AppConstants.checkinDistanceLimit * 1000).toInt()}米内可打卡';
    } else {
      return '${AppConstants.checkinDistanceLimit.toStringAsFixed(0)}公里内可打卡';
    }
  }

  /// 获取距离状态文本
  /// 
  /// [distanceStr] 距离字符串
  /// 返回 "可打卡" 或 "距离过远"
  static String getDistanceStatusText(String? distanceStr) {
    return canCheckinByDistanceString(distanceStr) ? '可打卡' : '距离过远';
  }

  /// 获取距离状态的颜色值
  /// 
  /// [distanceStr] 距离字符串
  /// 返回对应的颜色（绿色表示可打卡，灰色表示距离过远）
  static int getDistanceStatusColor(String? distanceStr) {
    return canCheckinByDistanceString(distanceStr) ? 0xFF4ECDC4 : 0xFF999999;
  }
}
