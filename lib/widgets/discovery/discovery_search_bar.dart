import 'package:flutter/material.dart';
import '../../core/utils/ui_helper.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';

/// 发现页搜索栏组件 - 带粉色渐变背景
class DiscoverySearchBar extends StatelessWidget {
  const DiscoverySearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      // 粉色渐变背景
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary, // #ff6b6b
            AppColors.primaryDark, // #ff8e8e
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 40,
          margin: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingM,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95), // 半透明白色背景
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            decoration: InputDecoration(
              hintText: '搜索博物馆、展览...',
              hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.textHint,
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingM,
                vertical: AppDimensions.paddingS,
              ),
            ),
            onTap: () {
              // TODO: 跳转到搜索页面
              UIHelper.showInfo(context, '跳转到搜索页面');
            },
            readOnly: true, // 只读，点击跳转到专门的搜索页
          ),
        ),
      ),
    );
  }
}
