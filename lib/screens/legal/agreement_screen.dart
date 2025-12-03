import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';
import '../../widgets/common/common_app_bar.dart';

/// 用户协议（完全对齐小程序）
class AgreementScreen extends StatefulWidget {
  const AgreementScreen({super.key});

  @override
  State<AgreementScreen> createState() => _AgreementScreenState();
}

class _AgreementScreenState extends State<AgreementScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTop = false;

  // TODO: 待更新 - 协议最后更新时间
  static const String _lastUpdated = 'xxxx年xx月xx日';

  // TODO: 待更新 - 根据实际业务调整协议内容
  static const List<Map<String, String>> _sections = [
    {
      'title': '1. 协议的范围',
      'content': '本协议是您与xxxxx科技有限公司（以下简称"我们"或"文博探索"）之间关于您使用文博探索小程序服务所订立的协议。\n\n本协议描述我们与您之间关于文博探索服务使用的权利义务。"用户"是指使用文博探索服务的个人或组织。'
    },
    {
      'title': '2. 服务内容',
      'content': '文博探索为用户提供以下服务：\n\n• 博物馆信息查询和展示\n• 博物馆打卡功能\n• 展览信息推送\n• 个人文化足迹记录\n• 其他相关文化服务\n\n我们有权根据业务发展需要，增加、修改或终止部分服务功能。'
    },
    {
      'title': '3. 用户注册',
      'content': '用户在使用文博探索服务时，需要提供真实、准确、完整的个人信息。用户应当及时更新注册信息，确保其真实性、准确性和完整性。\n\n用户不得冒充他人，不得利用他人的名义发布任何信息，不得恶意使用注册账户导致其他用户误认。'
    },
    {
      'title': '4. 用户行为规范',
      'content': '用户在使用文博探索服务时，必须遵守相关法律法规，不得利用文博探索服务从事以下活动：\n\n• 发布违法、有害、威胁、辱骂、骚扰、侵害、中伤、粗俗、猥亵或其他道德上令人反感的内容\n• 发布虚假信息，误导其他用户\n• 侵犯他人知识产权或其他合法权益\n• 上传含有病毒、木马程序或其他恶意代码的文件\n• 干扰或破坏服务或与服务相连的服务器和网络'
    },
    {
      'title': '5. 知识产权',
      'content': '文博探索服务中包含的所有内容，包括但不限于文本、图片、音频、视频、软件、程序、版面设计等，均受著作权、商标权及其他知识产权法律法规的保护。\n\n未经我们明确书面同意，用户不得复制、传播、展示、镜像、上载、下载使用上述内容。'
    },
    {
      'title': '6. 隐私保护',
      'content': '我们重视用户的隐私保护。我们将按照《文博探索隐私权政策》的规定收集、使用、存储和分享用户信息。\n\n我们承诺不会将用户的个人信息出售、出租或以其他方式披露给第三方，除非获得用户的明确同意或法律法规另有规定。'
    },
    {
      'title': '7. 免责声明',
      'content': '用户理解并同意，文博探索服务可能会受到各种因素的影响，我们不保证服务不会中断，不保证服务的及时性、安全性、准确性。\n\n因以下原因导致的服务中断或受阻，我们不承担责任：\n• 受到计算机病毒、木马或其他恶意程序、黑客攻击的破坏\n• 用户或第三方软件、设备、技术、通信线路原因等\n• 因台风、地震、海啸、洪水、停电、战争、恐怖袭击等不可抗力原因'
    },
    {
      'title': '8. 协议的变更',
      'content': '我们有权在必要时修改本协议条款。协议条款一旦发生变动，我们将在相关页面上提示修改内容。\n\n如果不同意我们对本协议相关条款所做的修改，用户有权停止使用文博探索服务。如果用户继续使用文博探索服务，则视为用户接受我们对本协议相关条款所做的修改。'
    },
    {
      'title': '9. 其他',
      'content': '本协议的成立、生效、履行、解释及纠纷解决，适用中华人民共和国大陆地区法律。\n\n如就本协议内容或其执行发生任何争议，应尽量友好协商解决；协商不成时，则争议各方同意提交北京市海淀区人民法院管辖。'
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
      appBar: CommonAppBar.simple(title: '用户协议'),
      body: Stack(
        children: [
          ListView(
            controller: _scrollController,
            padding: EdgeInsets.zero,
            children: [
              // 协议标题区块
              _buildHeaderSection(),

              // 欢迎文字区块
              _buildWelcomeSection(),

              // 协议条款区块
              _buildSectionsContainer(),

              // 联系我们区块
              _buildContactSection(),

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

  // 协议标题区块
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
            '文博探索用户协议',
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
          '欢迎使用文博探索！在使用我们的服务前，请仔细阅读本用户协议。使用文博探索服务即表示您同意接受本协议的全部条款。',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            height: 1.8,
          ),
          textAlign: TextAlign.justify,
        ),
      ),
    );
  }

  // 协议条款区块
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

  // 联系我们区块
  Widget _buildContactSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.paddingM,
        AppDimensions.paddingL,
        AppDimensions.paddingM,
        AppDimensions.paddingL,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '联系我们',
              style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              '如果您对本协议有任何疑问，请通过以下方式联系我们：',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 10),
            _buildContactItem('邮箱：museumseek@163.com'),
            const SizedBox(height: 6),
            _buildContactItem('地址：xxx'),
          ],
        ),
      ),
    );
  }

  // 联系信息项
  Widget _buildContactItem(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
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


