import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/ui_helper.dart';
import '../../core/utils/bottom_sheet_helper.dart';
import '../../widgets/common/common_app_bar.dart';

/// 资质公示（对齐小程序）
class QualificationScreen extends StatelessWidget {
  const QualificationScreen({super.key});

  // 公司信息数据（使用占位符）
  static const String _companyName = 'xxxxx科技有限公司';
  static const String _creditCode = '91XXXXXXXXXXXXXX';
  static const String _businessScope = '软件开发、信息技术服务、文化传播';
  static const String _address = 'xxx省xxx市xxx区xxx街道xxx号';
  static const String _registrationDate = 'xxxx年xx月xx日';
  static const String _registrationCapital = 'xxx万元';
  static const String _legalRepresentative = 'xxx';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CommonAppBar.simple(title: '资质公示'),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingM,  // 左右16px (32rpx)
          vertical: AppDimensions.paddingL,    // 上下20px (40rpx)
        ),
        children: [
          // 营业执照区块
          _buildLicenseSection(context),

          const SizedBox(height: AppDimensions.paddingL),  // 20px间距

          // 企业基本信息
          _buildCompanyInfoSection(context),

          const SizedBox(height: AppDimensions.paddingL),  // 20px间距

          // 企业信息查询（可点击的卡片）
          _buildQueryCard(context),

          const SizedBox(height: AppDimensions.paddingL),  // 20px间距

          // 说明
          _buildNoteSection(),
          
          const SizedBox(height: AppDimensions.paddingL),  // 底部留白
        ],
      ),
    );
  }

  // 营业执照区块
  Widget _buildLicenseSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题行
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('营业执照', style: AppTextStyles.titleMedium),
              Text(
                '点击可查看大图',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
              ),
            ],
          ),
        ),
        // 营业执照卡片
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(AppDimensions.cardPadding),
          child: Column(
            children: [
              // 图片占位（可点击查看大图）
              GestureDetector(
                onTap: () => _onPreviewLicense(context),
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundDark,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    border: Border.all(color: AppColors.backgroundDark, width: 1),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.image_outlined, size: 64, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '<!-- 待更新：使用真实营业执照图片 -->',
                style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 企业基本信息区块
  Widget _buildCompanyInfoSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text('企业基本信息', style: AppTextStyles.titleMedium),
        ),
        // 信息列表
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _infoRow('企业名称', _companyName),
              _divider(),
              _infoRowWithCopy(
                context,
                '统一社会信用代码',
                _creditCode,
              ),
              _divider(),
              _infoRow('经营范围', _businessScope),
              _divider(),
              _infoRow('注册地址', _address),
              _divider(),
              _infoRow('注册日期', _registrationDate),
              _divider(),
              _infoRow('注册资本', _registrationCapital),
              _divider(),
              _infoRow('法定代表人', _legalRepresentative),
            ],
          ),
        ),
      ],
    );
  }

  // 企业信息查询卡片（对齐小程序）
  Widget _buildQueryCard(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await BottomSheetHelper.showInfo(
          context,
          title: '查询企业信息',
          content: '可在国家企业信用信息公示系统查询详细信息',
          buttonText: '知道了',
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppDimensions.cardPadding),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '企业信息查询',
                    style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '可在国家企业信用信息公示系统查询更多详细信息',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }

  // 说明区块
  Widget _buildNoteSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppDimensions.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '说明',
            style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            '以上信息均为真实有效，如有变更将及时更新。企业资质信息可通过国家企业信用信息公示系统进行验证。',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // 信息行（左标签 + 右值）
  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.cardPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 使用 Flexible 让标签可以自动扩展，但不换行
          Flexible(
            flex: 0,  // 不占用剩余空间，只占用内容所需空间
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              overflow: TextOverflow.visible,
              maxLines: 1,  // 强制单行
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  // 带复制功能的信息行（统一社会信用代码专用）
  Widget _infoRowWithCopy(BuildContext context, String label, String value) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: value));
        UIHelper.showSuccess(context, '已复制到剪贴板');
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.cardPadding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 使用 Flexible 让标签可以自动扩展，但不换行
            Flexible(
              flex: 0,  // 不占用剩余空间，只占用内容所需空间
              child: Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                overflow: TextOverflow.visible,
                maxLines: 1,  // 强制单行
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value,
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 分割线
  Widget _divider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.cardPadding),
      color: AppColors.backgroundDark,
    );
  }

  // 预览营业执照大图
  void _onPreviewLicense(BuildContext context) {
    // TODO: 待更新为真实营业执照图片后，使用图片查看器
    // 目前显示占位提示
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 占位图片
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(dialogContext).size.height * 0.7,
              ),
              decoration: BoxDecoration(
                color: AppColors.backgroundDark,
                borderRadius: BorderRadius.circular(AppDimensions.radiusL),
              ),
              padding: const EdgeInsets.all(60),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.image_outlined, size: 120, color: Colors.grey),
                  SizedBox(height: 20),
                  Text(
                    '<!-- 待更新：使用真实营业执照图片 -->',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // 关闭按钮
            IconButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              icon: const Icon(Icons.close, color: Colors.white, size: 32),
            ),
          ],
        ),
      ),
    );
  }
}


