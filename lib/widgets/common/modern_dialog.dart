import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// 现代化Dialog组件 - 统一的圆角样式（图标和标题左对齐）
/// 
/// 使用示例：
/// ```dart
/// ModernDialog.show(
///   context,
///   title: '提示',
///   content: '这是内容',
///   confirmText: '确定',
/// );
/// ```
class ModernDialog {
  /// 显示单按钮Dialog（仅确认按钮）
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String content,
    String confirmText = '确定',
    IconData? icon,
    Color? iconColor,
    VoidCallback? onConfirm,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75, // 最大高度75%屏幕
              maxWidth: 400, // 最大宽度400px
            ),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 图标和标题在同一行（左侧）
                Row(
                  children: [
                    // 图标（如果有）
                    if (icon != null) ...[
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: (iconColor ?? AppColors.primary).withAlpha(25),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          size: 24,
                          color: iconColor ?? AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    
                    // 标题
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // 内容（可滚动，支持长文本）
                Flexible(
                  child: SingleChildScrollView(
                    child: Text(
                      content,
                      textAlign: TextAlign.left,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // 确定按钮
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop(true);
                      onConfirm?.call();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      confirmText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 显示双按钮Dialog（取消+确认）
  static Future<bool?> showConfirm(
    BuildContext context, {
    required String title,
    required String content,
    String cancelText = '取消',
    String confirmText = '确定',
    IconData? icon,
    Color? iconColor,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75, // 最大高度75%屏幕
              maxWidth: 400, // 最大宽度400px
            ),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 图标和标题在同一行（左侧）
                Row(
                  children: [
                    // 图标（如果有）
                    if (icon != null) ...[
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: (iconColor ?? AppColors.primary).withAlpha(25),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          size: 24,
                          color: iconColor ?? AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    
                    // 标题
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // 内容（可滚动，支持长文本）
                Flexible(
                  child: SingleChildScrollView(
                    child: Text(
                      content,
                      textAlign: TextAlign.left,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // 按钮组
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop(false);
                          onCancel?.call();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(
                            color: AppColors.divider,
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          cancelText,
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop(true);
                          onConfirm?.call();
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          confirmText,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 显示信息Dialog（带图标，单按钮）
  static Future<bool?> showInfo(
    BuildContext context, {
    required String title,
    required String content,
    String confirmText = '我知道了',
    IconData icon = Icons.info_outline,
    Color? iconColor,
  }) {
    return show(
      context,
      title: title,
      content: content,
      confirmText: confirmText,
      icon: icon,
      iconColor: iconColor ?? AppColors.primary,
    );
  }

  /// 显示警告Dialog（带警告图标，单按钮）
  static Future<bool?> showWarning(
    BuildContext context, {
    required String title,
    required String content,
    String confirmText = '我知道了',
  }) {
    return show(
      context,
      title: title,
      content: content,
      confirmText: confirmText,
      icon: Icons.warning_amber_rounded,
      iconColor: AppColors.warningLight,
    );
  }

  /// 显示错误Dialog（带错误图标，单按钮）
  static Future<bool?> showError(
    BuildContext context, {
    required String title,
    required String content,
    String confirmText = '我知道了',
  }) {
    return show(
      context,
      title: title,
      content: content,
      confirmText: confirmText,
      icon: Icons.error_outline,
      iconColor: AppColors.error,
    );
  }

  /// 显示成功Dialog（带成功图标，单按钮）
  static Future<bool?> showSuccess(
    BuildContext context, {
    required String title,
    required String content,
    String confirmText = '好的',
  }) {
    return show(
      context,
      title: title,
      content: content,
      confirmText: confirmText,
      icon: Icons.check_circle_outline,
      iconColor: AppColors.successDark,
    );
  }
}
