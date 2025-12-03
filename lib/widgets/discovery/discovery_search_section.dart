import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// 发现页面搜索栏组件 - 完全匹配小程序红色渐变样式
class DiscoverySearchSection extends StatelessWidget {
  final String searchKeyword;
  final ValueChanged<String> onSearchChanged;

  const DiscoverySearchSection({
    super.key,
    required this.searchKeyword,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // 粉色渐变背景，匹配小程序
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary, // #ff9999 鲜艳粉色
            AppColors.primaryDark, // #ffb3b3 浅粉色
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 15), // 20rpx 32rpx 30rpx转换
          child: Container(
            height: 35, // 70rpx转换
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFE).withValues(alpha: 0.95), // 更不透明的白色背景，更明显
              borderRadius: BorderRadius.circular(17.5), // 圆角搜索框
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08), // 更轻的阴影
                  blurRadius: 8, // 稍小的阴影
                  offset: const Offset(0, 2),
                ),
              ],
              // 添加边框让框更明显
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 0.5,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center, // 确保整行垂直居中
              children: [
                // 搜索图标 - 与输入框在同一行，统一背景
                const Padding(
                  padding: EdgeInsets.only(left: 15, right: 10), // 30rpx 20rpx转换
                  child: Icon(
                    Icons.search,
                    size: 18, // 保持18px，匹配小程序size="18"
                    color: AppColors.textHint, // 精确匹配小程序的#999颜色
                  ),
                ),
              
                // 搜索输入框 - 与图标共享背景，无边框，垂直居中
                Expanded(
                  child: TextField(
                    onChanged: onSearchChanged,
                    textAlignVertical: TextAlignVertical.center, // 文字垂直居中
                    decoration: InputDecoration(
                      hintText: '搜索博物馆名称...',
                      hintStyle: const TextStyle(
                        fontSize: 14, // 28rpx转换，匹配小程序
                        color: AppColors.textHint, // 使用与图标相同的颜色
                        fontWeight: FontWeight.normal,
                      ),
                      border: InputBorder.none, // 无边框，与背景融为一体
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero, // 去除所有内边距，依赖容器对齐
                      isDense: true,
                    ),
                    style: const TextStyle(
                      fontSize: 14, // 28rpx转换，匹配小程序
                      color: AppColors.textPrimary, // 精确匹配小程序的#333颜色
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
                // 右侧留白，匹配左侧
                const SizedBox(width: 15), // 与左侧padding保持对称
              ],
            ),
          ),
        ),
      ),
    );
  }
}
