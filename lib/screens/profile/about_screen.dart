import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../widgets/common/common_app_bar.dart';
import '../../core/utils/ui_helper.dart';

/// 关于我们页面
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  // 应用信息
  final Map<String, dynamic> _appInfo = {
    'name': '文博探索',
    'version': '0.0.1',
    'description': '发现文化宝藏，记录文博之旅',
  };

  // 协议与说明列表
  final List<Map<String, String>> _legalItems = [
    {
      'id': 'qualification',
      'title': '资质公示',
      'description': '查看平台相关资质证书和经营许可',
    },
    {
      'id': 'agreement',
      'title': '用户协议',
      'description': '了解用户权利义务和服务条款',
    },
    {
      'id': 'privacy',
      'title': '隐私权政策',
      'description': '了解我们如何保护您的隐私信息',
    },
  ];

  // 联系方式
  final List<Map<String, String>> _contactInfo = [
    {
      'type': 'email',
      'label': '邮箱联系',
      'value': 'museumseek@163.com',
      'action': 'copy',
    },
    {
      'type': 'phone',
      'label': '客服电话',
      'value': 'xxxxxxxxxxx',
      'action': 'call',
    },
    {
      'type': 'address',
      'label': '公司地址',
      'value': 'xxxxxxxxxxx',
      'action': 'copy',
    },
  ];

  // 更新日志
  final List<Map<String, dynamic>> _changelog = [
    {
      'version': '0.0.1',
      'date': '2025-11-11',
      'expanded': false,
      'features': [
        '全新发布文博探索应用',
        '支持GPS定位查找附近博物馆',
        '实现博物馆打卡功能',
        '展览信息实时推送',
        '个人成就系统上线',
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CommonAppBar.simple(
        title: '关于我们',
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 应用信息
            _buildAppSection(),

            // 协议与说明
            _buildLegalSection(),

            // 联系我们
            _buildContactSection(),

            // 更新日志
            _buildChangelogSection(),

            // 版权信息
            _buildCopyrightSection(),

            // 底部间距
            const SizedBox(height: AppDimensions.paddingXL),
          ],
        ),
      ),
    );
  }

  /// 构建应用信息部分
  Widget _buildAppSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppDimensions.paddingXL,
        AppDimensions.paddingXL,
        AppDimensions.paddingXL,
        AppDimensions.paddingXXL,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: '应用信息',
            subtitle: '版本与功能管理',
          ),
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
                _buildAppItem(
                  title: _appInfo['name'],
                  description: '版本 ${_appInfo['version']} | ${_appInfo['description']}',
                  onTap: null,
                ),
                _buildDivider(),
                _buildAppItem(
                  title: '检查更新',
                  description: '获取最新版本',
                  icon: Icons.download,
                  onTap: _onCheckUpdate,
                ),
                _buildDivider(),
                _buildAppItem(
                  title: '分享应用',
                  description: '推荐给朋友',
                  icon: Icons.share,
                  onTap: _onShareApp,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建协议与说明部分
  Widget _buildLegalSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppDimensions.paddingXL,
        0,
        AppDimensions.paddingXL,
        AppDimensions.paddingXXL,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: '协议与说明',
            subtitle: '了解平台规则与权益',
          ),
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
              children: _legalItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Column(
                  children: [
                    if (index > 0) _buildDivider(),
                    _buildLegalItem(
                      title: item['title']!,
                      description: item['description']!,
                      onTap: () => _onLegalItemTap(item['id']!),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建联系我们部分
  Widget _buildContactSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppDimensions.paddingXL,
        0,
        AppDimensions.paddingXL,
        AppDimensions.paddingXXL,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: '联系我们',
            subtitle: '我们期待您的反馈',
          ),
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
              children: _contactInfo.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Column(
                  children: [
                    if (index > 0) _buildDivider(),
                    _buildContactItem(
                      label: item['label']!,
                      value: item['value']!,
                      onTap: () => _onContactTap(item),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建更新日志部分
  Widget _buildChangelogSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppDimensions.paddingXL,
        0,
        AppDimensions.paddingXL,
        AppDimensions.paddingXXL,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: '更新日志',
            subtitle: '版本更新记录',
          ),
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
              children: _changelog.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Column(
                  children: [
                    if (index > 0) _buildDivider(),
                    _buildChangelogItem(item, index),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建版权信息部分
  Widget _buildCopyrightSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppDimensions.paddingXL,
        0,
        AppDimensions.paddingXL,
        AppDimensions.paddingXXL,
      ),
      child: const Padding(
        padding: EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          children: [
            Text(
              '© 2025 文博探索. All rights reserved.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4),
            Text(
              'xxxxxxxx科技有限公司',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建区域标题
  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingM),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            title,
            style: AppTextStyles.headlineMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            subtitle,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建应用信息项
  Widget _buildAppItem({
    required String title,
    required String description,
    IconData? icon,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (icon != null) ...[
              const SizedBox(width: AppDimensions.paddingS),
              Icon(
                icon,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建协议项
  Widget _buildLegalItem({
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.paddingS),
            const Icon(
              Icons.chevron_right,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建联系方式项
  Widget _buildContactItem({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.bodyLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建更新日志项
  Widget _buildChangelogItem(Map<String, dynamic> item, int index) {
    final isExpanded = item['expanded'] as bool;
    return Column(
      children: [
        InkWell(
          onTap: () => _onToggleChangelog(index),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'v${item['version']}',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Text(
                  item['date'],
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: AppDimensions.paddingS),
                AnimatedRotation(
                  duration: const Duration(milliseconds: 300),
                  turns: isExpanded ? 0.5 : 0,
                  child: const Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: isExpanded ? null : 0,
          child: isExpanded
              ? Container(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimensions.paddingM,
                    0,
                    AppDimensions.paddingM,
                    AppDimensions.paddingM,
                  ),
                  child: Column(
                    children: (item['features'] as List<String>).map((feature) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '•',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                feature,
                                style: AppTextStyles.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  /// 构建分割线
  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingM),
      color: AppColors.divider,
    );
  }

  /// 检查更新
  void _onCheckUpdate() {
    UIHelper.showSuccess(context, '已是最新版本');
  }

  /// 分享应用
  void _onShareApp() {
    UIHelper.showWarning(context, '分享功能开发中');
  }

  /// 协议项点击
  void _onLegalItemTap(String id) {
    switch (id) {
      case 'qualification':
        if (mounted) context.push(AppConstants.routeQualification);
        return;
      case 'agreement':
        if (mounted) context.push(AppConstants.routeAgreement);
        return;
      case 'privacy':
        if (mounted) context.push(AppConstants.routePrivacy);
        return;
    }
  }

  /// 联系方式点击
  void _onContactTap(Map<String, String> contact) {
    final action = contact['action'];
    final value = contact['value']!;
    
    switch (action) {
      case 'copy':
        Clipboard.setData(ClipboardData(text: value));
        UIHelper.showSuccess(context, '已复制到剪贴板');
        break;
      case 'call':
        _makePhoneCall(value);
        break;
      default:
        UIHelper.showWarning(context, '功能开发中');
    }
  }

  /// 拨打电话
  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw Exception('无法拨打电话');
      }
    } catch (e) {
      if (mounted) {
        UIHelper.showError(context, '拨打电话失败');
      }
    }
  }

  /// 切换更新日志展开状态
  void _onToggleChangelog(int index) {
    setState(() {
      _changelog[index]['expanded'] = !_changelog[index]['expanded'];
    });
  }
}
