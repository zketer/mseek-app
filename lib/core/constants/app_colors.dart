import 'package:flutter/material.dart';

/// 应用颜色常量定义
/// 参考小程序mseek-mini的设计规范：粉色主题（加深版）
/// 所有颜色统一在此管理，禁止硬编码颜色值
class AppColors {
  // ==================== 主色调 ====================
  // 粉色系（加深后更鲜艳 #ff9999, #ffb3b3, #ff7a8a）
  static const Color primary = Color(0xFFFF9999);      // #ff9999 主色调（鲜艳粉色）
  static const Color primaryLight = Color(0xFFFF9999); // #ff9999 鲜艳粉色
  static const Color primaryDark = Color(0xFFFFB3B3);  // #ffb3b3 浅粉色  
  
  // 辅助色
  static const Color accent = Color(0xFFFF7A8A);       // #ff7a8a 粉红色（用于文本/图标）
  static const Color secondary = Color(0xFF8a8a8a);    // 次要文字色
  
  // ==================== 背景色系列 ====================
  static const Color background = Color(0xFFf5f5f5);     // #f5f5f5 页面背景（主）
  static const Color backgroundLight = Color(0xFFf8f8f8); // #f8f8f8 浅背景
  static const Color backgroundDark = Color(0xFFf0f0f0);  // #f0f0f0 深一点的背景
  static const Color surface = Color(0xFFffffff);        // #ffffff 卡片表面（白色）
  static const Color surfaceVariant = Color(0xFFfafafa); // #fafafa 表面变体
  static const Color surfaceGrey = Color(0xFFf8f9fa);    // #f8f9fa 灰色表面
  static const Color surfaceTinted = Color(0xFFe9ecef); // #e9ecef 有色表面
  
  // ==================== 文字颜色 ====================
  static const Color textPrimary = Color(0xFF333333);    // #333333 主要文字
  static const Color textSecondary = Color(0xFF666666);  // #666666 次要文字
  static const Color textTertiary = Color(0xFF888888);   // #888888 三级文字
  static const Color textHint = Color(0xFF999999);       // #999999 提示文字
  static const Color textDisabled = Color(0xFFcccccc);   // #cccccc 禁用文字
  static const Color textWhite = Color(0xFFffffff);      // #ffffff 白色文字
  static const Color textBlack = Color(0xFF000000);      // #000000 纯黑文字
  
  // ==================== 状态颜色 ====================
  // 成功 - 绿色系
  static const Color success = Color(0xFF52c41a);        // #52c41a 成功绿色（主）
  static const Color successLight = Color(0xFF66BB6A);   // #66BB6A 浅绿色
  static const Color successBg = Color(0xFFe8f5e8);      // #e8f5e8 成功背景色
  static const Color successBgLight = Color(0xFFf0f9f0); // #f0f9f0 更浅的成功背景
  static const Color successDark = Color(0xFF4CAF50);    // #4CAF50 深绿色
  
  // 警告 - 橙黄色系
  static const Color warning = Color(0xFFfaad14);        // #faad14 警告橙色
  static const Color warningLight = Color(0xFFFFCA28);   // #FFCA28 浅黄色
  static const Color warningDark = Color(0xFFFF9800);    // #FF9800 深橙色
  static const Color warningBg = Color(0xFFfff7e6);      // #fff7e6 警告背景色
  
  // 错误 - 红色系
  static const Color error = Color(0xFFf5222d);          // #f5222d 错误红色
  static const Color errorLight = Color(0xFFFF7043);     // #FF7043 浅红色
  static const Color errorBg = Color(0xFFffebee);        // #ffebee 错误背景色
  
  // 信息 - 蓝色系
  static const Color info = Color(0xFF1890ff);           // #1890ff 信息蓝色（主）
  static const Color infoLight = Color(0xFF42A5F5);      // #42A5F5 浅蓝色
  static const Color infoDark = Color(0xFF2196F3);       // #2196F3 深蓝色
  static const Color infoBg = Color(0xFFe6f7ff);         // #e6f7ff 信息背景色
  static const Color infoSky = Color(0xFF87CEEB);        // #87CEEB 天蓝色
  
  // ==================== UI元素颜色 ====================
  // 分割线和边框
  static const Color divider = Color(0xFFe8e8e8);        // #e8e8e8 分割线
  static const Color dividerLight = Color(0xFFf0f0f0);   // #f0f0f0 浅分割线
  static const Color border = Color(0xFFd9d9d9);         // #d9d9d9 边框
  static const Color borderLight = Color(0xFFe0e0e0);    // #e0e0e0 浅边框
  static const Color borderDark = Color(0xFFbfbfbf);     // #bfbfbf 深边框
  
  // 阴影色
  static const Color shadow = Color(0x1F000000);         // 卡片阴影（半透明黑）
  static const Color shadowLight = Color(0x0A000000);    // 轻阴影
  
  // 遮罩层
  static const Color overlay = Color(0x80000000);        // 半透明黑色遮罩
  static const Color overlayLight = Color(0x40000000);   // 浅遮罩
  
  // ==================== 功能性颜色 ====================
  // 激活/选中状态
  static const Color active = Color(0xFFFF9999);         // 激活状态（使用主色）
  static const Color inactive = Color(0xFFd3d3d3);       // 未激活状态（灰色）
  
  // 徽章/标记
  static const Color badge = Color(0xFFFF6B6B);          // 徽章红色
  static const Color badgeDot = Color(0xFFFF4444);       // 小红点
  
  // 评分/星级
  static const Color rating = Color(0xFFFFD700);         // 金色星星
  
  // 链接
  static const Color link = Color(0xFF1890ff);           // 链接蓝色
  static const Color linkVisited = Color(0xFF9C27B0);    // 已访问链接（紫色）
  
  // ==================== 特殊场景颜色 ====================
  // 打卡相关
  static const Color checkinSuccess = Color(0xFF07C160); // 打卡成功绿
  static const Color checkinPending = Color(0xFFFF9800); // 待打卡橙
  
  // 博物馆等级
  static const Color level1 = Color(0xFF2196F3);         // 一级博物馆（蓝色）
  static const Color level2 = Color(0xFF4CAF50);         // 二级博物馆（绿色）
  static const Color level3 = Color(0xFFFF9800);         // 三级博物馆（橙色）
  
  // 标签颜色 - 根据小程序博物馆标签设计
  static const Color tagCultural = Color(0xFFe6f7ff);    // 文化文物 - 蓝色
  static const Color tagCulturalText = Color(0xFF1890ff); // 文化文物文字
  static const Color tagPrivate = Color(0xFFf6ffed);     // 非国有 - 绿色
  static const Color tagPrivateText = Color(0xFF52c41a); // 非国有文字
  static const Color tagFolk = Color(0xFFfff7e6);        // 民俗类 - 橙色
  static const Color tagFolkText = Color(0xFFfa8c16);    // 民俗类文字
  static const Color tagScience = Color(0xFFf0f5ff);     // 科技类 - 紫色
  static const Color tagScienceText = Color(0xFF5c6bc0); // 科技类文字
  static const Color tagHistory = Color(0xFFfef1f0);     // 历史类 - 红色
  static const Color tagHistoryText = Color(0xFFee5a52); // 历史类文字
  static const Color tagFree = Color(0xFFfff2e8);        // 免费参观 - 浅橙
  static const Color tagFreeText = Color(0xFFff9800);    // 免费参观文字
  
  // ==================== 渐变色 ====================
  // 主色调渐变
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryLight, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // 卡片渐变
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFffffff), Color(0xFFf8f9fa)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  // 青色渐变（用于特殊场景）
  static const LinearGradient cyanGradient = LinearGradient(
    colors: [Color(0xFF00F2FE), Color(0xFF4ECDC4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // 蓝色渐变
  static const LinearGradient blueGradient = LinearGradient(
    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // 绿色渐变
  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF66BB6A), Color(0xFF4CAF50)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // ==================== 废弃颜色提醒 ====================
  // 以下颜色已废弃，请使用新的命名
  @Deprecated('使用 primary 或 primaryLight 代替')
  static const Color oldPrimary = Color(0xFFFF6B6B); // 旧的主色（已弃用）
}
