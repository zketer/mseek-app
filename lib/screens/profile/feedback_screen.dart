import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/ui_helper.dart';
import '../../../core/utils/bottom_sheet_helper.dart';
import '../../../widgets/common/common_app_bar.dart';

/// 反馈建议页面（完全对齐小程序）
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  
  String _selectedType = '';
  // ignore: unused_field
  String _selectedTypeName = '';
  bool _submitting = false;

  // 反馈类型
  static const List<Map<String, dynamic>> _feedbackTypes = [
    {'id': 'bug', 'name': '问题反馈', 'icon': Icons.warning_amber_rounded},
    {'id': 'feature', 'name': '功能建议', 'icon': Icons.check_circle_outline},
    {'id': 'content', 'name': '内容建议', 'icon': Icons.info_outline},
    {'id': 'other', 'name': '其他建议', 'icon': Icons.circle_outlined},
  ];

  @override
  void dispose() {
    _contentController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CommonAppBar.simple(title: '反馈建议'),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // 页面头部（渐变背景）
          _buildHeader(),

          // 反馈类型选择
          _buildTypeSection(),

          // 反馈内容输入
          _buildContentSection(),

          // 联系方式输入
          _buildContactSection(),

          // 提交按钮区域
          _buildSubmitSection(),

          // 温馨提示
          _buildTipsSection(),

          // 底部间距
          const SizedBox(height: AppDimensions.paddingL),
        ],
      ),
    );
  }

  // 页面头部
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingM,
        vertical: AppDimensions.paddingL,
      ),
      child: Column(
        children: [
          Text(
            '反馈建议',
            style: AppTextStyles.titleLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '您的建议是我们前进的动力',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  // 反馈类型选择区域
  Widget _buildTypeSection() {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '反馈类型',
            style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            '请选择您要反馈的类型',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          // 网格布局（2列）
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.5,
            ),
            itemCount: _feedbackTypes.length,
            itemBuilder: (context, index) {
              final type = _feedbackTypes[index];
              final isSelected = _selectedType == type['id'];
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedType = type['id'] as String;
                    _selectedTypeName = type['name'] as String;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.backgroundDark,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.3)
                            : Colors.black.withValues(alpha: 0.05),
                        blurRadius: isSelected ? 12 : 5,
                        offset: Offset(0, isSelected ? 4 : 1),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              type['icon'] as IconData,
                              size: 24,
                              color: isSelected ? Colors.white : AppColors.primary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              type['name'] as String,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: isSelected ? Colors.white : AppColors.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 12,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // 反馈内容输入区域
  Widget _buildContentSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.paddingM,
        0,
        AppDimensions.paddingM,
        AppDimensions.paddingM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '反馈内容',
            style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            '详细描述您遇到的问题或建议',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            padding: const EdgeInsets.all(AppDimensions.cardPadding),
            child: Column(
              children: [
                TextField(
                  controller: _contentController,
                  maxLines: 6,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    hintText: '请详细描述您的问题或建议，至少10个字符...',
                    border: InputBorder.none,
                    counterText: '',
                  ),
                  style: AppTextStyles.bodyMedium,
                  onChanged: (value) => setState(() {}),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    '${_contentController.text.length}/500',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 联系方式输入区域
  Widget _buildContactSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.paddingM,
        0,
        AppDimensions.paddingM,
        AppDimensions.paddingM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '联系方式',
            style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            '可选，方便我们与您联系',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.cardPadding,
              vertical: 8,
            ),
            child: TextField(
              controller: _contactController,
              maxLength: 50,
              decoration: const InputDecoration(
                hintText: '请输入您的邮箱或微信号（可选）',
                border: InputBorder.none,
                counterText: '',
              ),
              style: AppTextStyles.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  // 提交按钮区域
  Widget _buildSubmitSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingM),
      child: Row(
        children: [
          // 清空按钮
          Expanded(
            flex: 1,
            child: GestureDetector(
              onTap: _onClearForm,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.primary, width: 1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
                child: Text(
                  '清空',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // 提交按钮
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: _submitting ? null : _onSubmitFeedback,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  _submitting ? '提交中...' : '提交反馈',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 温馨提示区域
  Widget _buildTipsSection() {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppDimensions.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  '温馨提示',
                  style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...[
              '• 我们会认真对待每一条反馈',
              '• 通常在3-5个工作日内回复',
              '• 您的信息将严格保密',
              '• 反馈将发送至：museumseek@163.com',
              '• 感谢您对文博探索的支持',
            ].map((text) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                text,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  // 清空表单
  Future<void> _onClearForm() async {
    if (_selectedType.isEmpty &&
        _contentController.text.isEmpty &&
        _contactController.text.isEmpty) {
      UIHelper.showInfo(context, '表单已经是空的');
      return;
    }

    final confirmed = await BottomSheetHelper.showConfirm(
      context,
      title: '确认清空',
      content: '确定要清空当前填写的内容吗？',
      confirmText: '确定清空',
      cancelText: '取消',
      isDangerous: true,
      icon: Icons.delete_outline,
    );

    if (confirmed == true) {
      setState(() {
        _selectedType = '';
        _selectedTypeName = '';
        _contentController.clear();
        _contactController.clear();
      });
      if (!mounted) return;
      UIHelper.showInfo(context, '已清空');
    }
  }

  // 提交反馈
  void _onSubmitFeedback() {
    // 表单验证
    if (_selectedType.isEmpty) {
      UIHelper.showInfo(context, '请选择反馈类型');
      return;
    }

    if (_contentController.text.trim().isEmpty) {
      UIHelper.showInfo(context, '请输入反馈内容');
      return;
    }

    if (_contentController.text.trim().length < 10) {
      UIHelper.showInfo(context, '反馈内容至少10个字符');
      return;
    }

    setState(() => _submitting = true);

    // TODO: 实现实际的提交逻辑（调用API）
    // 这里模拟提交过程
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      
      setState(() => _submitting = false);
      
      UIHelper.showSuccess(context, '提交成功，感谢您的反馈！');

      // 清空表单
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        setState(() {
          _selectedType = '';
          _selectedTypeName = '';
          _contentController.clear();
          _contactController.clear();
        });
      });
    });
  }
}

