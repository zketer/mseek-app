import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'bottom_sheet_helper.dart';

/// 权限管理工具类
/// 
/// 提供统一的权限请求和处理方法，包括：
/// - 相机权限
/// - 相册权限
/// - 位置权限
/// - 存储权限
/// - 通知权限
/// 
/// 使用示例：
/// ```dart
/// // 请求相机权限
/// final granted = await PermissionHelper.requestCamera(context);
/// if (granted) {
///   // 可以使用相机
/// }
/// 
/// // 请求位置权限（带Dialog提示）
/// final granted = await PermissionHelper.requestLocation(
///   context,
///   showRationale: true,
/// );
/// ```
class PermissionHelper {
  /// 请求相机权限
  /// 
  /// [context] BuildContext
  /// [showRationale] 是否显示权限说明
  /// 
  /// 返回：true=已授权，false=未授权
  static Future<bool> requestCamera(
    BuildContext context, {
    bool showRationale = true,
  }) async {
    final status = await Permission.camera.status;

    // 已授权
    if (status.isGranted) {
      return true;
    }

    // 永久拒绝
    if (status.isPermanentlyDenied) {
      if (showRationale && context.mounted) {
        final confirmed = await BottomSheetHelper.showConfirm(
          context,
          title: '需要相机权限',
          content: '相机权限已被永久拒绝，请在设置中手动开启相机权限',
          confirmText: '去设置',
          cancelText: '取消',
          icon: Icons.camera_alt_outlined,
        );
        
        if (confirmed == true) {
          await openAppSettings();
        }
      }
      return false;
    }

    // 请求权限
    final result = await Permission.camera.request();
    return result.isGranted;
  }

  /// 请求相册权限
  /// 
  /// [context] BuildContext
  /// [showRationale] 是否显示权限说明
  /// 
  /// 返回：true=已授权，false=未授权
  static Future<bool> requestPhotos(
    BuildContext context, {
    bool showRationale = true,
  }) async {
    final status = await Permission.photos.status;

    // 已授权
    if (status.isGranted) {
      return true;
    }

    // 永久拒绝
    if (status.isPermanentlyDenied) {
      if (showRationale && context.mounted) {
        final confirmed = await BottomSheetHelper.showConfirm(
          context,
          title: '需要相册权限',
          content: '相册权限已被永久拒绝，请在设置中手动开启相册权限',
          confirmText: '去设置',
          cancelText: '取消',
          icon: Icons.photo_library_outlined,
        );
        
        if (confirmed == true) {
          await openAppSettings();
        }
      }
      return false;
    }

    // 请求权限
    final result = await Permission.photos.request();
    return result.isGranted;
  }

  /// 请求位置权限（简化版，用于非LocationService场景）
  /// 
  /// [context] BuildContext
  /// [showRationale] 是否显示权限说明
  /// 
  /// 返回：true=已授权，false=未授权
  static Future<bool> requestLocation(
    BuildContext context, {
    bool showRationale = true,
  }) async {
    // 检查定位服务
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (showRationale && context.mounted) {
        final confirmed = await BottomSheetHelper.showConfirm(
          context,
          title: '需要定位服务',
          content: '请在设置中开启定位服务',
          confirmText: '去设置',
          cancelText: '取消',
          icon: Icons.location_on_outlined,
        );
        
        if (confirmed == true) {
          await Geolocator.openLocationSettings();
        }
      }
      return false;
    }

    // 检查权限
    LocationPermission permission = await Geolocator.checkPermission();

    // 已授权
    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      return true;
    }

    // 永久拒绝
    if (permission == LocationPermission.deniedForever) {
      if (showRationale && context.mounted) {
        final confirmed = await BottomSheetHelper.showConfirm(
          context,
          title: '需要定位权限',
          content: '定位权限已被永久拒绝，请在设置中手动开启定位权限',
          confirmText: '去设置',
          cancelText: '取消',
          icon: Icons.location_on_outlined,
        );
        
        if (confirmed == true) {
          await Geolocator.openAppSettings();
        }
      }
      return false;
    }

    // 请求权限
    permission = await Geolocator.requestPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// 请求存储权限
  /// 
  /// [context] BuildContext
  /// [showRationale] 是否显示权限说明
  /// 
  /// 返回：true=已授权，false=未授权
  static Future<bool> requestStorage(
    BuildContext context, {
    bool showRationale = true,
  }) async {
    final status = await Permission.storage.status;

    // 已授权
    if (status.isGranted) {
      return true;
    }

    // 永久拒绝
    if (status.isPermanentlyDenied) {
      if (showRationale && context.mounted) {
        final confirmed = await BottomSheetHelper.showConfirm(
          context,
          title: '需要存储权限',
          content: '存储权限已被永久拒绝，请在设置中手动开启存储权限',
          confirmText: '去设置',
          cancelText: '取消',
          icon: Icons.folder_outlined,
        );
        
        if (confirmed == true) {
          await openAppSettings();
        }
      }
      return false;
    }

    // 请求权限
    final result = await Permission.storage.request();
    return result.isGranted;
  }

  /// 请求通知权限
  /// 
  /// [context] BuildContext
  /// [showRationale] 是否显示权限说明
  /// 
  /// 返回：true=已授权，false=未授权
  static Future<bool> requestNotification(
    BuildContext context, {
    bool showRationale = true,
  }) async {
    final status = await Permission.notification.status;

    // 已授权
    if (status.isGranted) {
      return true;
    }

    // 永久拒绝
    if (status.isPermanentlyDenied) {
      if (showRationale && context.mounted) {
        final confirmed = await BottomSheetHelper.showConfirm(
          context,
          title: '需要通知权限',
          content: '通知权限已被永久拒绝，请在设置中手动开启通知权限',
          confirmText: '去设置',
          cancelText: '取消',
          icon: Icons.notifications_outlined,
        );
        
        if (confirmed == true) {
          await openAppSettings();
        }
      }
      return false;
    }

    // 请求权限
    final result = await Permission.notification.request();
    return result.isGranted;
  }

  /// 检查相机权限状态（不请求）
  static Future<bool> hasCameraPermission() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  /// 检查相册权限状态（不请求）
  static Future<bool> hasPhotosPermission() async {
    final status = await Permission.photos.status;
    return status.isGranted;
  }

  /// 检查位置权限状态（不请求）
  static Future<bool> hasLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// 检查存储权限状态（不请求）
  static Future<bool> hasStoragePermission() async {
    final status = await Permission.storage.status;
    return status.isGranted;
  }

  /// 检查通知权限状态（不请求）
  static Future<bool> hasNotificationPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// 打开应用设置页面
  static Future<void> openSettings() async {
    await openAppSettings();
  }

  /// 批量请求权限
  /// 
  /// [permissions] 要请求的权限列表
  /// 
  /// 返回：Map<Permission, bool> 各权限的授权状态
  static Future<Map<Permission, bool>> requestMultiple(
    List<Permission> permissions,
  ) async {
    final statuses = await permissions.request();
    return statuses.map((key, value) => MapEntry(key, value.isGranted));
  }

  /// 检查是否所有权限都已授予
  /// 
  /// [permissions] 要检查的权限列表
  /// 
  /// 返回：true=全部已授权，false=至少有一个未授权
  static Future<bool> areAllGranted(List<Permission> permissions) async {
    for (final permission in permissions) {
      final status = await permission.status;
      if (!status.isGranted) {
        return false;
      }
    }
    return true;
  }
}

