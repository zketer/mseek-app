import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';
import '../../widgets/common/common_app_bar.dart';

/// 隐私权政策（完全对齐小程序）
class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTop = false;

  // TODO: 待更新 - 政策最后更新时间
  static const String _lastUpdated = 'xxxx年xx月xx日';

  // TODO: 待更新 - 根据实际业务调整隐私政策内容
  static const List<Map<String, String>> _sections = [
    {
      'title': '1. 我们收集的信息',
      'content': '为了向您提供更好的服务，我们可能会收集以下信息：\n\n• 基本信息：昵称、头像等微信授权信息\n• 位置信息：用于推荐附近的博物馆和展览\n• 使用信息：您在使用文博探索服务时产生的操作记录\n• 设备信息：设备型号、操作系统版本等技术信息\n\n我们承诺只收集为提供服务所必需的信息，不会收集与服务无关的个人信息。'
    },
    {
      'title': '2. 信息的使用',
      'content': '我们使用收集的信息用于以下目的：\n\n• 提供、维护和改进文博探索服务\n• 为您推荐个性化的博物馆和展览内容\n• 处理您的反馈和客服请求\n• 发送服务相关的通知和更新\n• 进行数据分析以改善用户体验\n• 保障服务安全，防范欺诈行为\n\n我们不会将您的个人信息用于本政策未明确说明的其他用途。'
    },
    {
      'title': '3. 信息的分享',
      'content': '我们不会出售、出租或以其他方式披露您的个人信息给第三方，除非：\n\n• 获得您的明确同意\n• 为完成服务所必需（如地图服务提供商）\n• 法律法规要求或政府部门要求\n• 为保护我们或其他用户的合法权益\n\n当需要与第三方分享信息时，我们会确保第三方遵守相应的保密义务。'
    },
    {
      'title': '4. 信息的存储',
      'content': '我们会采取合理的安全措施保护您的个人信息：\n\n• 使用加密技术保护数据传输安全\n• 对存储的个人信息进行加密处理\n• 限制有权访问个人信息的人员范围\n• 定期审查信息收集、存储和处理实践\n\n您的个人信息将存储在中华人民共和国境内的安全服务器上。'
    },
    {
      'title': '5. 您的权利',
      'content': '关于您的个人信息，您拥有以下权利：\n\n• 知情权：了解我们如何收集、使用您的个人信息\n• 访问权：查看我们持有的关于您的个人信息\n• 更正权：要求更正不准确的个人信息\n• 删除权：要求删除不再需要的个人信息\n• 限制处理权：在特定情况下限制我们处理您的信息\n\n如需行使上述权利，请通过本政策提供的联系方式与我们联系。'
    },
    {
      'title': '6. 未成年人保护',
      'content': '我们非常重视未成年人的个人信息保护：\n\n• 不会主动收集未满14周岁儿童的个人信息\n• 如发现在未获得父母同意的情况下收集了儿童信息，会尽快删除\n• 建议未成年人在父母或监护人指导下使用我们的服务\n• 如果您是未成年人的父母或监护人，请监督孩子的网络活动\n\n如您对未成年人信息处理有任何疑问，请及时联系我们。'
    },
    {
      'title': '7. Cookie和类似技术',
      'content': '为改善用户体验，我们可能使用Cookie和类似技术：\n\n• 记住您的偏好设置\n• 分析服务使用情况\n• 提供个性化内容推荐\n• 确保服务安全稳定运行\n\n您可以通过设备设置管理或删除Cookie，但这可能影响某些服务功能的正常使用。'
    },
    {
      'title': '8. 政策更新',
      'content': '我们可能会不时更新本隐私权政策：\n\n• 重大变更时，我们会通过适当方式通知您\n• 轻微调整时，我们会在本页面更新修订日期\n• 继续使用服务即表示您接受更新后的政策\n• 如不同意变更内容，您可以停止使用我们的服务\n\n我们建议您定期查看本政策以了解最新信息保护实践。'
    },
    {
      'title': '9. 联系我们',
      'content': '如果您对本隐私权政策有任何疑问、意见或建议，请通过以下方式联系我们：\n\n• 邮箱：museumseek@163.com\n• 地址：xxx\n• 我们将在收到您的反馈后尽快回复\n\n我们设有专门的个人信息保护团队，负责处理隐私相关事务。'
    },
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // 滚动超过200像素后显示返回顶部按钮
    if (_scrollController.offset > 200 && !_showBackToTop) {
      setState(() => _showBackToTop = true);
    } else if (_scrollController.offset <= 200 && _showBackToTop) {
      setState(() => _showBackToTop = false);
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CommonAppBar.simple(title: '隐私权政策'),
      body: Stack(
        children: [
          ListView(
            controller: _scrollController,
            padding: EdgeInsets.zero,
            children: [
              // 政策标题区块
              _buildHeaderSection(),

              // 欢迎文字区块
              _buildWelcomeSection(),

              // 重要提醒区块
              _buildImportantNotice(),

              // 政策条款区块
              _buildSectionsContainer(),

              // 生效日期区块
              _buildEffectiveSection(),

              // 底部间距
              const SizedBox(height: AppDimensions.paddingL),
            ],
          ),

          // 返回顶部按钮
          if (_showBackToTop) _buildBackToTopButton(),
        ],
      ),
    );
  }

  // 政策标题区块
  Widget _buildHeaderSection() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.backgroundDark, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingM,
        vertical: AppDimensions.paddingL,
      ),
      child: Column(
        children: [
          Text(
            '文博探索隐私权政策',
            style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            '最后更新：$_lastUpdated',
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // 欢迎文字区块
  Widget _buildWelcomeSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.paddingM,
        AppDimensions.paddingL,
        AppDimensions.paddingM,
        AppDimensions.paddingM,
      ),
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
        child: Text(
          '我们深知个人信息对您的重要性，并会尽全力保护您的个人信息安全可靠。本隐私权政策将帮助您了解我们如何收集、使用、存储和分享您的个人信息。',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            height: 1.8,
          ),
          textAlign: TextAlign.justify,
        ),
      ),
    );
  }

  // 重要提醒区块
  Widget _buildImportantNotice() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.paddingM,
        0,
        AppDimensions.paddingM,
        AppDimensions.paddingM,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.errorBg, AppColors.errorBg],
          ),
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          border: const Border(
            left: BorderSide(color: AppColors.primary, width: 4),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppDimensions.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, size: 20, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  '重要提醒',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '请您在使用文博探索服务前，仔细阅读并充分理解本政策。如果您不同意本政策的任何内容，请立即停止使用我们的服务。',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 政策条款区块
  Widget _buildSectionsContainer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingM),
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
        child: Column(
          children: _sections.asMap().entries.map((entry) {
            final index = entry.key;
            final section = entry.value;
            final isLast = index == _sections.length - 1;
            
            return Container(
              padding: const EdgeInsets.all(AppDimensions.cardPadding),
              decoration: BoxDecoration(
                border: Border(
                  bottom: isLast
                      ? BorderSide.none
                      : const BorderSide(color: AppColors.backgroundDark, width: 1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section['title']!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    section['content']!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.8,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // 生效日期区块
  Widget _buildEffectiveSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.paddingM,
        AppDimensions.paddingL,
        AppDimensions.paddingM,
        AppDimensions.paddingL,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.successBg, AppColors.successBgLight],
          ),
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          border: const Border(
            left: BorderSide(color: AppColors.infoSky, width: 4),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.infoSky.withValues(alpha: 0.1),
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
              '生效日期',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.infoSky,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '本隐私权政策自$_lastUpdated起生效。我们保留在法律允许的范围内修改本政策的权利。',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 返回顶部按钮
  Widget _buildBackToTopButton() {
    return Positioned(
      right: AppDimensions.paddingM,
      bottom: 60,
      child: GestureDetector(
        onTap: _scrollToTop,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.textSecondary,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.arrow_upward, size: 16, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                '返回顶部',
                style: AppTextStyles.caption.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
