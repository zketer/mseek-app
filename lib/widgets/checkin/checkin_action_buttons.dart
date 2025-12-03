// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/ui_helper.dart';

/// 打卡操作按钮组件 - 底部弹出窗口
class CheckinActionButtons extends StatefulWidget {
  final String museumName;
  final VoidCallback onSuccess;

  const CheckinActionButtons({
    super.key,
    required this.museumName,
    required this.onSuccess,
  });

  @override
  State<CheckinActionButtons> createState() => _CheckinActionButtonsState();
}

class _CheckinActionButtonsState extends State<CheckinActionButtons> {
  bool _isLoading = false;
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusL),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: AppDimensions.paddingM,
            right: AppDimensions.paddingM,
            top: AppDimensions.paddingM,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppDimensions.paddingM,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 拖拽指示器
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              const SizedBox(height: AppDimensions.paddingM),
              
              // 标题
              Text(
                '打卡 ${widget.museumName}',
                style: AppTextStyles.titleLarge,
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppDimensions.paddingL),
              
              // 打卡照片区域
              _buildPhotoSection(),
              
              const SizedBox(height: AppDimensions.paddingL),
              
              // 打卡笔记输入
              _buildNoteSection(),
              
              const SizedBox(height: AppDimensions.paddingL),
              
              // 操作按钮
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建照片区域
  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '拍照打卡',
          style: AppTextStyles.titleMedium,
        ),
        const SizedBox(height: AppDimensions.paddingS),
        
        Row(
          children: [
            // 拍照按钮
            _buildPhotoButton(
              icon: Icons.camera_alt,
              label: '拍照',
              onTap: _takePhoto,
            ),
            const SizedBox(width: AppDimensions.paddingM),
            
            // 从相册选择
            _buildPhotoButton(
              icon: Icons.photo_library,
              label: '相册',
              onTap: _pickPhoto,
            ),
          ],
        ),
      ],
    );
  }

  /// 构建笔记区域
  Widget _buildNoteSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '打卡笔记（可选）',
          style: AppTextStyles.titleMedium,
        ),
        const SizedBox(height: AppDimensions.paddingS),
        
        TextField(
          controller: _noteController,
          maxLines: 3,
          maxLength: 200,
          decoration: InputDecoration(
            hintText: '分享你的参观感受...',
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textHint,
            ),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  /// 构建操作按钮
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingM),
            ),
            child: const Text('取消'),
          ),
        ),
        const SizedBox(width: AppDimensions.paddingM),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _performCheckin,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingM),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: AppColors.textWhite,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    '确认打卡',
                    style: TextStyle(color: AppColors.textWhite),
                  ),
          ),
        ),
      ],
    );
  }

  /// 构建拍照按钮
  Widget _buildPhotoButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: AppColors.primary,
              size: 28,
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

  /// 拍照
  void _takePhoto() {
    UIHelper.showInfo(context, '调用相机拍照');
    // TODO: 调用相机拍照
  }

  /// 从相册选择
  void _pickPhoto() {
    UIHelper.showInfo(context, '从相册选择照片');
    // TODO: 从相册选择照片
  }

  /// 执行打卡
  Future<void> _performCheckin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: 调用打卡API
      await Future.delayed(const Duration(seconds: 2));
      
      widget.onSuccess();
      Navigator.pop(context);
    } catch (e) {
      UIHelper.showError(context, '打卡失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
