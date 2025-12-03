/// 应用尺寸常量定义
/// 参考小程序设计规范：24rpx圆角，32rpx外边距，24rpx内边距
class AppDimensions {
  // 间距
  static const double paddingXXS = 4.0;   // 超小间距
  static const double paddingXS = 8.0;    // 小间距
  static const double paddingS = 12.0;    // 较小间距
  static const double paddingM = 16.0;    // 中等间距 (24rpx转换)
  static const double paddingL = 20.0;    // 较大间距
  static const double paddingXL = 24.0;   // 大间距 (32rpx转换)
  static const double paddingXXL = 32.0;  // 超大间距
  
  // 圆角
  static const double radiusXS = 4.0;     // 超小圆角
  static const double radiusS = 8.0;      // 小圆角
  static const double radiusM = 12.0;     // 中等圆角
  static const double radiusL = 16.0;     // 大圆角 (24rpx转换)
  static const double radiusXL = 20.0;    // 超大圆角
  static const double radiusXXL = 24.0;   // 极大圆角
  
  // 卡片相关
  static const double cardPadding = paddingM;     // 卡片内边距
  static const double cardMargin = paddingM;      // 卡片外边距
  static const double cardRadius = radiusL;       // 卡片圆角
  static const double cardElevation = 2.0;       // 卡片阴影高度
  
  // 按钮相关
  static const double buttonHeight = 48.0;        // 标准按钮高度
  static const double buttonHeightLarge = 56.0;   // 大按钮高度
  static const double buttonHeightSmall = 32.0;   // 小按钮高度
  static const double buttonRadius = radiusL;     // 按钮圆角
  
  // 输入框相关
  static const double inputHeight = 48.0;         // 输入框高度
  static const double inputRadius = radiusM;      // 输入框圆角
  
  // 图片相关
  static const double imageRadiusSmall = radiusS;  // 小图片圆角
  static const double imageRadiusLarge = radiusL;  // 大图片圆角
  
  // 头像相关
  static const double avatarSizeSmall = 32.0;     // 小头像
  static const double avatarSizeMedium = 48.0;    // 中等头像
  static const double avatarSizeLarge = 64.0;     // 大头像
  
  // 图标相关
  static const double iconSizeSmall = 16.0;       // 小图标
  static const double iconSizeMedium = 24.0;      // 中等图标
  static const double iconSizeLarge = 32.0;       // 大图标
  
  // TabBar相关
  static const double tabBarHeight = 60.0;        // TabBar高度
  static const double tabIconSize = 24.0;         // Tab图标大小
  
  // AppBar相关
  static const double appBarHeight = 56.0;        // AppBar高度
  
  // 轮播图相关
  static const double bannerHeight = 200.0;       // 轮播图高度
  static const double bannerRadius = radiusL;     // 轮播图圆角
  
  // 博物馆卡片
  static const double museumCardHeight = 120.0;   // 博物馆卡片高度
  static const double museumImageSize = 80.0;     // 博物馆图片大小
  
  // 展览卡片
  static const double exhibitionCardHeight = 140.0; // 展览卡片高度
  static const double exhibitionImageWidth = 100.0; // 展览图片宽度
}
