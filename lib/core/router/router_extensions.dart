// 路由扩展方法
// 提供统一、类型安全的路由跳转API
// 
// 简化常用路由跳转，避免硬编码路径字符串
// 
// @author lynn
// @since 2024-10-17

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_constants.dart';

/// BuildContext 的路由扩展
extension AppRouterExtension on BuildContext {
  
  // ==================== 基础路由操作 ====================
  
  /// 安全返回（如果可以返回则返回，否则跳转到首页）
  void safePop() {
    if (canPop()) {
      pop();
    } else {
      go(AppConstants.routeHome);
    }
  }
  
  /// 返回到首页（底部Tab）
  void goHome() {
    go(AppConstants.routeHome);
  }
  
  // ==================== 博物馆相关 ====================
  
  /// 跳转到博物馆详情
  /// @param museumId 博物馆ID
  void goToMuseumDetail(int museumId) {
    push('/museum/$museumId');
  }
  
  /// 跳转到热门博物馆列表
  void goToHotMuseums() {
    push('/hot_museums');
  }
  
  /// 跳转到同城博物馆列表
  void goToNearbyMuseums() {
    push('/nearby-museums');
  }
  
  // ==================== 展览相关 ====================
  
  /// 跳转到展览详情
  /// @param exhibitionId 展览ID
  void goToExhibitionDetail(int exhibitionId) {
    push('${AppConstants.routeExhibitionDetail}?id=$exhibitionId');
  }
  
  /// 跳转到最新展览列表
  void goToLatestExhibitions() {
    push('/latest_exhibitions'); // 使用 push 而不是 go，保留导航栈
  }
  
  // ==================== 打卡相关 ====================
  
  /// 跳转到打卡操作页面
  /// @param museumId 博物馆ID
  /// @param draftId 草稿ID（可选）
  void goToCheckinAction(int museumId, {int? draftId}) {
    String url = '/checkin/action/$museumId';
    if (draftId != null) {
      url += '?draftId=$draftId';
    }
    push(url);
  }
  
  /// 跳转到打卡历史
  void goToCheckinHistory() {
    push(AppConstants.routeHistory);
  }
  
  /// 跳转到草稿列表
  void goToDraftList() {
    push('/drafts');
  }
  
  /// 跳转到打卡Tab
  void goToCheckinTab() {
    go('/checkin');
  }
  
  // ==================== 用户相关 ====================
  
  /// 跳转到登录页面
  /// @param redirectUrl 登录成功后的回调地址（可选）
  void goToLogin({String? redirectUrl}) {
    String url = AppConstants.routeLogin;
    if (redirectUrl != null) {
      url += '?redirect=${Uri.encodeComponent(redirectUrl)}';
    }
    push(url);
  }
  
  /// 跳转到个人中心
  void goToProfile() {
    go('/profile');
  }
  
  /// 跳转到收藏夹
  void goToFavorites() {
    push(AppConstants.routeFavorites);
  }
  
  /// 跳转到成就页面
  void goToAchievements() {
    push(AppConstants.routeAchievements);
  }
  
  /// 跳转到设置
  void goToSettings() {
    push(AppConstants.routeSettings);
  }
  
  // ==================== 区域相关 ====================
  
  /// 跳转到省份详情
  /// @param provinceCode 省份编码
  void goToProvinceDetail(String provinceCode) {
    push('/province/$provinceCode');
  }
  
  /// 跳转到城市详情
  /// @param cityName 城市名称
  /// @param provinceCode 省份编码（可选）
  /// @param provinceName 省份名称（可选）
  void goToCityDetail(
    String cityName, {
    String? provinceCode,
    String? provinceName,
  }) {
    // 使用extra参数传递额外信息，避免URL编码问题
    final extra = <String, dynamic>{
      'cityName': cityName,
      if (provinceCode != null) 'provinceCode': provinceCode,
      if (provinceName != null) 'provinceName': provinceName,
    };
    
    // URL路径参数中用 - 替代 /
    final cityPath = cityName.replaceAll('/', '-');
    pushNamed(
      'city-detail',
      pathParameters: {'cityName': cityPath},
      extra: extra,
    );
  }
  
  // ==================== 其他页面 ====================
  
  /// 跳转到搜索页面
  void goToSearch() {
    push(AppConstants.routeSearch);
  }
  
  /// 跳转到关于我们
  void goToAbout() {
    push('/about');
  }
  
  /// 跳转到反馈建议
  void goToFeedback() {
    push(AppConstants.routeFeedback);
  }
  
  // ==================== 法务相关 ====================
  
  /// 跳转到资质证明
  void goToQualification() {
    push(AppConstants.routeQualification);
  }
  
  /// 跳转到用户协议
  void goToAgreement() {
    push(AppConstants.routeAgreement);
  }
  
  /// 跳转到隐私政策
  void goToPrivacy() {
    push(AppConstants.routePrivacy);
  }
}

/// 导航辅助类
/// 提供一些常用的导航判断和操作
class NavigationHelper {
  /// 判断是否是Tab页面
  static bool isTabPage(String path) {
    return path == '/' || 
           path == '/discovery' || 
           path == '/checkin' || 
           path == '/profile';
  }
  
  /// 获取当前路由路径
  static String getCurrentPath(BuildContext context) {
    return GoRouterState.of(context).uri.path;
  }
  
  /// 获取当前完整URL（包含查询参数）
  static String getCurrentUrl(BuildContext context) {
    return GoRouterState.of(context).uri.toString();
  }
  
  /// 清空导航栈并跳转到指定页面
  static void replaceAll(BuildContext context, String path) {
    context.go(path);
  }
}

