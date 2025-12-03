import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// 统一的收藏按钮组件
/// 使用展览详情页的小圆角方框样式
class UnifiedFavoriteButton extends StatelessWidget {
  final bool isFavorited;
  final VoidCallback onTap;
  final double size; // 按钮大小（默认24）
  
  const UnifiedFavoriteButton({
    super.key,
    required this.isFavorited,
    required this.onTap,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    final double iconSize = size * 0.67; // Icon大小约为容器的2/3
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(size / 2), // 圆角为size的一半
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.surfaceGrey,
          border: Border.all(color: AppColors.surfaceTinted),
          borderRadius: BorderRadius.circular(size / 2),
        ),
        child: Icon(
          isFavorited ? Icons.favorite : Icons.favorite_border,
          size: iconSize,
          color: isFavorited ? AppColors.primary : Colors.grey,
        ),
      ),
    );
  }
}

