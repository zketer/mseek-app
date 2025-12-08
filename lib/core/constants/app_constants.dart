/// 应用常量定义
class AppConstants {
  // 应用信息
  static const String appName = '文博探索';
  static const String appVersion = '0.0.1';
  static const String appDescription = '发现身边的文化宝藏';
  
  // API相关 - 通过Gateway显式路由访问（更简洁）
  // 注意：使用 adb reverse 端口转发，模拟器通过localhost访问宿主机
  //       已执行: adb reverse tcp:8000 tcp:8000
  static const String baseUrl = 'http://localhost:8000';
  static const String apiVersion = 'v1';
  static const String museumServicePrefix = '/api/v1/museums/miniapp';
  
  // 存储键名
  static const String keyToken = 'auth_token';
  static const String keyUserId = 'user_id';
  static const String keyUserInfo = 'user_info';
  static const String keySettings = 'app_settings';
  static const String keySearchHistory = 'search_history';
  
  // 分页配置
  static const int defaultPageSize = 20;
  static const int maxSearchHistory = 10;
  
  // 图片配置
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const double imageQuality = 0.8;
  
  // 位置服务
  static const double defaultLatitude = 39.9042;  // 北京天安门
  static const double defaultLongitude = 116.4074;
  static const double nearbyRadius = 10.0; // 附近博物馆搜索半径(km)
  
  // 打卡距离限制
  static const double checkinDistanceLimit = 0.1; // 打卡距离限制(km)，100米
  static const double checkinDistanceLimitMeters = checkinDistanceLimit * 1000; // 转换为米 = 100
  
  // 轮播图配置
  static const int bannerAutoPlayDelay = 3; // 秒
  static const double bannerAspectRatio = 16 / 9;
  
  // 缓存配置
  static const Duration cacheExpiry = Duration(hours: 1);
  static const int maxCacheSize = 100 * 1024 * 1024; // 100MB
  
  // 网络超时
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // 动画时长
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration shortAnimationDuration = Duration(milliseconds: 150);
  
  // 路由名称
  static const String routeHome = '/';
  static const String routeLogin = '/login';
  static const String routeMuseumDetail = '/museum-detail';
  static const String routeExhibitionDetail = '/exhibition-detail';
  static const String routeCheckinAction = '/checkin-action';
  static const String routeProfile = '/profile';
  static const String routeSettings = '/settings';
  static const String routeFavorites = '/favorites';
  static const String routeHistory = '/history';
  static const String routeAchievements = '/achievements';
  static const String routeSearch = '/search';
  static const String routeMap = '/map';
  
  // 法务与合规页面
  static const String routeQualification = '/legal/qualification';
  static const String routeAgreement = '/legal/agreement';
  static const String routePrivacy = '/legal/privacy';
  static const String routeFeedback = '/feedback';
  
  // 错误消息
  static const String errorNetworkConnection = '网络连接失败，请检查网络设置';
  static const String errorServerError = '服务器错误，请稍后重试';
  static const String errorUnknown = '未知错误，请稍后重试';
  static const String errorLocationPermission = '需要位置权限才能使用该功能';
  static const String errorCameraPermission = '需要相机权限才能拍照';
  static const String errorStoragePermission = '需要存储权限才能保存图片';
  
  // 成功消息
  static const String successLogin = '登录成功';
  static const String successLogout = '已退出登录';
  static const String successCheckin = '打卡成功！';
  static const String successFavorite = '已添加到收藏';
  static const String successUnfavorite = '已取消收藏';
  
  // 展览状态
  static const String exhibitionStatusOngoing = '进行中';
  static const String exhibitionStatusUpcoming = '即将开始';
  static const String exhibitionStatusEnded = '已结束';
  
  // 博物馆类型标签颜色映射
  static const Map<String, String> categoryColorMap = {
    'TYPE_CULTURAL': '#e6f7ff',  // 文化文物系统 - 蓝色
    'TYPE_PRIVATE': '#f6ffed',   // 非国有博物馆 - 绿色
    'FOLK': '#fff7e6',           // 民俗类 - 橙色
    'SCIENCE': '#f0f5ff',        // 科技类 - 紫色
    'HISTORY': '#fef1f0',        // 历史类 - 红色
  };
  
  // 博物馆等级名称
  static const Map<int, String> levelNames = {
    1: '一级博物馆',
    2: '二级博物馆',
    3: '三级博物馆',
    4: '四级博物馆',
    5: '五级博物馆',
  };
  
  // 默认图片URL
  static const String defaultMuseumImage = 'assets/images/default_museum.jpg';
  static const String defaultExhibitionImage = 'assets/images/default_exhibition.jpg';
  static const String defaultAvatarImage = 'assets/images/default_avatar.jpg';
}
