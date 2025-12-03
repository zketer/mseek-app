import 'package:flutter/material.dart';
import '../../core/utils/ui_helper.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/museum.dart';

/// 博物馆详情信息组件
class MuseumDetailInfo extends StatelessWidget {
  final Museum museum;
  
  const MuseumDetailInfo({
    super.key,
    required this.museum,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppDimensions.paddingM),
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 基本信息
          _buildBasicInfo(),
          
          const SizedBox(height: AppDimensions.paddingM),
          
          // 标签信息
          if (museum.tags != null && museum.tags!.isNotEmpty)
            _buildTags(),
          
          const SizedBox(height: AppDimensions.paddingM),
          
          // 开放时间和门票信息
          _buildTicketInfo(),
          
          const SizedBox(height: AppDimensions.paddingM),
          
          // 快捷操作
          _buildQuickActions(context),
        ],
      ),
    );
  }

  /// 构建基本信息
  Widget _buildBasicInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '基本信息',
          style: AppTextStyles.titleMedium,
        ),
        const SizedBox(height: AppDimensions.paddingS),
        
        // 分类信息
        if (museum.categories != null && museum.categories!.isNotEmpty)
          _buildInfoRow(
            icon: Icons.category,
            label: '分类',
            value: museum.categories!.map((c) => c.name).join('、'),
          ),
        
        // 等级信息
        if (museum.levelName.isNotEmpty)
          _buildInfoRow(
            icon: Icons.star,
            label: '等级',
            value: museum.levelName,
          ),
        
        // 地址信息
        if (museum.address != null)
          _buildInfoRow(
            icon: Icons.location_on,
            label: '地址',
            value: museum.address!,
            isExpandable: true,
          ),
      ],
    );
  }

  /// 构建标签
  Widget _buildTags() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '特色标签',
          style: AppTextStyles.titleMedium,
        ),
        const SizedBox(height: AppDimensions.paddingS),
        
        Wrap(
          spacing: AppDimensions.paddingS,
          runSpacing: AppDimensions.paddingS,
          children: museum.tags!.map((tag) {
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingS,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: tag.color != null 
                    ? Color(int.parse(tag.color!.replaceFirst('#', '0xFF')))
                    : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                tag.name,
                style: AppTextStyles.labelSmall.copyWith(
                  color: tag.color != null 
                      ? AppColors.textWhite
                      : AppColors.primary,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 构建门票信息
  Widget _buildTicketInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '参观信息',
          style: AppTextStyles.titleMedium,
        ),
        const SizedBox(height: AppDimensions.paddingS),
        
        // 门票价格
        _buildInfoRow(
          icon: Icons.local_activity,
          label: '门票',
          value: museum.formattedPrice,
          valueColor: museum.isFree ? AppColors.success : AppColors.accent,
        ),
        
        // 开放时间（模拟数据）
        _buildInfoRow(
          icon: Icons.access_time,
          label: '开放时间',
          value: '09:00 - 17:00（周一闭馆）',
        ),
        
        // 建议游览时间（模拟数据）
        _buildInfoRow(
          icon: Icons.schedule,
          label: '建议游览',
          value: '2-3小时',
        ),
      ],
    );
  }

  /// 构建快捷操作
  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '快捷操作',
          style: AppTextStyles.titleMedium,
        ),
        const SizedBox(height: AppDimensions.paddingS),
        
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.navigation,
                label: '导航',
                onTap: () => _navigate(context),
              ),
            ),
            const SizedBox(width: AppDimensions.paddingM),
            Expanded(
              child: _buildActionButton(
                icon: Icons.call,
                label: '电话',
                onTap: () => _makeCall(context),
              ),
            ),
            const SizedBox(width: AppDimensions.paddingM),
            Expanded(
              child: _buildActionButton(
                icon: Icons.web,
                label: '官网',
                onTap: () => _openWebsite(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建信息行
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool isExpandable = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: AppDimensions.paddingS),
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                color: valueColor ?? AppColors.textPrimary,
                fontWeight: valueColor != null ? FontWeight.w500 : null,
              ),
              maxLines: isExpandable ? null : 2,
              overflow: isExpandable ? null : TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建操作按钮
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingS),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: AppColors.primary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 导航功能
  void _navigate(BuildContext context) {
    UIHelper.showInfo(context, '打开地图导航');
    // TODO: 调用地图导航
  }

  /// 拨打电话
  void _makeCall(BuildContext context) {
    UIHelper.showInfo(context, '拨打电话功能');
    // TODO: 拨打电话
  }

  /// 打开官网
  void _openWebsite(BuildContext context) {
    UIHelper.showInfo(context, '打开官网');
    // TODO: 打开官网
  }
}
