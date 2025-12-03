import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// 设备信息助手类
/// 用于获取设备的唯一标识、名称、型号等信息
class DeviceInfoHelper {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  
  /// 获取设备唯一标识
  /// iOS: identifierForVendor
  /// Android: Android ID
  static Future<String> getDeviceId() async {
    try {
      if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'unknown_ios_device';
      } else if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return androidInfo.id;
      }
      return 'unknown_device';
    } catch (e) {
      print('❌ 获取设备ID失败: $e');
      return 'unknown_device';
    }
  }
  
  /// 获取设备名称
  /// iOS: name (如: "Lynn的iPhone")
  /// Android: model (如: "Xiaomi 13")
  static Future<String> getDeviceName() async {
    try {
      if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.name;
      } else if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return '${androidInfo.brand} ${androidInfo.model}';
      }
      return 'Unknown Device';
    } catch (e) {
      print('❌ 获取设备名称失败: $e');
      return 'Unknown Device';
    }
  }
  
  /// 获取设备型号
  /// iOS: model (如: "iPhone15,2")
  /// Android: model (如: "MI 13")
  static Future<String> getDeviceModel() async {
    try {
      if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.utsname.machine;
      } else if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return androidInfo.model;
      }
      return 'Unknown Model';
    } catch (e) {
      print('❌ 获取设备型号失败: $e');
      return 'Unknown Model';
    }
  }
  
  /// 获取操作系统版本
  /// iOS: systemVersion (如: "17.0")
  /// Android: version.release (如: "13")
  static Future<String> getOsVersion() async {
    try {
      if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return 'iOS ${iosInfo.systemVersion}';
      } else if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return 'Android ${androidInfo.version.release}';
      }
      return 'Unknown OS';
    } catch (e) {
      print('❌ 获取系统版本失败: $e');
      return 'Unknown OS';
    }
  }
  
  /// 获取APP版本
  static Future<String> getAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      print('❌ 获取APP版本失败: $e');
      return '1.0.0';
    }
  }
  
  /// 获取平台类型
  static String getPlatform() {
    if (Platform.isIOS) {
      return 'ios';
    } else if (Platform.isAndroid) {
      return 'android';
    }
    return 'unknown';
  }
  
  /// 获取完整的设备信息
  static Future<Map<String, String>> getDeviceInfo() async {
    return {
      'deviceId': await getDeviceId(),
      'deviceName': await getDeviceName(),
      'deviceModel': await getDeviceModel(),
      'osVersion': await getOsVersion(),
      'appVersion': await getAppVersion(),
      'platform': getPlatform(),
    };
  }
}
