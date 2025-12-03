import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

/// Dialog工具类
/// 
/// 提供统一的对话框方法，包括：
/// - 确认对话框
/// - 信息对话框
/// - 加载对话框
/// - 底部选择器
/// - 输入对话框
/// 
/// 使用示例：
/// ```dart
/// // 确认对话框
/// final confirmed = await DialogHelper.showConfirm(
///   context,
///   title: '删除确认',
///   content: '确定要删除吗？',
///   isDanger: true,
/// );
/// 
/// // 加载对话框
/// DialogHelper.showLoadingDialog(context);
/// // 操作完成后
/// DialogHelper.hideLoadingDialog(context);
/// ```
class DialogHelper {
  /// 显示确认对话框
  /// 
  /// [context] 上下文
  /// [title] 标题
  /// [content] 内容
  /// [confirmText] 确认按钮文字，默认"确定"
  /// [cancelText] 取消按钮文字，默认"取消"
  /// [confirmColor] 确认按钮颜色
  /// [isDanger] 是否为危险操作（红色确认按钮），默认false
  /// 
  /// 返回：用户点击确定返回true，取消返回false，点击外部返回null
  static Future<bool?> showConfirm(
    BuildContext context, {
    required String title,
    required String content,
    String confirmText = '确定',
    String cancelText = '取消',
    Color? confirmColor,
    bool isDanger = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: AppTextStyles.titleMedium),
        content: Text(content, style: AppTextStyles.bodyMedium),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              cancelText,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: isDanger
                  ? Colors.red
                  : confirmColor ?? AppColors.primary,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  /// 显示信息对话框
  /// 
  /// [context] 上下文
  /// [title] 标题
  /// [content] 内容
  /// [buttonText] 按钮文字，默认"知道了"
  static Future<void> showInfo(
    BuildContext context, {
    required String title,
    required String content,
    String buttonText = '知道了',
  }) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: AppTextStyles.titleMedium),
        content: Text(content, style: AppTextStyles.bodyMedium),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  /// 显示加载对话框
  /// 
  /// [context] 上下文
  /// [message] 加载消息，默认"加载中..."
  /// 
  /// 注意：需要手动调用 [hideLoadingDialog] 关闭
  static Future<void> showLoadingDialog(
    BuildContext context, {
    String message = '加载中...',
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(message, style: AppTextStyles.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }

  /// 关闭加载对话框
  /// 
  /// [context] 上下文
  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  /// 显示底部选择器
  /// 
  /// [context] 上下文
  /// [child] 底部内容组件
  /// [isScrollControlled] 是否可滚动，默认true
  /// 
  /// 返回：选择的结果，类型为泛型T
  static Future<T?> showBottomSheet<T>(
    BuildContext context, {
    required Widget child,
    bool isScrollControlled = true,
    bool isDismissible = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: child,
      ),
    );
  }

  /// 显示输入对话框
  /// 
  /// [context] 上下文
  /// [title] 标题
  /// [hint] 输入框提示
  /// [initialValue] 初始值
  /// [maxLines] 最大行数，默认1
  /// [maxLength] 最大长度
  /// [keyboardType] 键盘类型
  /// [validator] 验证函数
  /// 
  /// 返回：用户输入的文字，取消返回null
  static Future<String?> showInput(
    BuildContext context, {
    required String title,
    required String hint,
    String? initialValue,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final controller = TextEditingController(text: initialValue);
    final formKey = GlobalKey<FormState>();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: AppTextStyles.titleMedium),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            maxLines: maxLines,
            maxLength: maxLength,
            keyboardType: keyboardType,
            autofocus: true,
            validator: validator,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(context, controller.text);
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 显示列表选择对话框
  /// 
  /// [context] 上下文
  /// [title] 标题
  /// [items] 选项列表
  /// [selectedIndex] 当前选中的索引
  /// 
  /// 返回：用户选择的索引，取消返回null
  static Future<int?> showListDialog(
    BuildContext context, {
    required String title,
    required List<String> items,
    int? selectedIndex,
  }) {
    return showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: AppTextStyles.titleMedium),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final isSelected = index == selectedIndex;
              return ListTile(
                title: Text(items[index]),
                trailing: isSelected
                    ? Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.pop(context, index),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  /// 显示自定义对话框
  /// 
  /// [context] 上下文
  /// [child] 对话框内容
  /// [barrierDismissible] 点击外部是否可关闭，默认true
  static Future<T?> showCustomDialog<T>(
    BuildContext context, {
    required Widget child,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: child,
      ),
    );
  }
}

