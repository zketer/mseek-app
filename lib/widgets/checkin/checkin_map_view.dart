import 'package:flutter/material.dart';
import '../../core/utils/ui_helper.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';

/// 打卡页地图视图组件
class CheckinMapView extends StatelessWidget {
  const CheckinMapView({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: 集成真实地图SDK（如高德地图、百度地图等）
    // 这里先用模拟视图
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF667EEA),
            Color(0xFF764BA2),
          ],
        ),
      ),
      child: Stack(
        children: [
          // 地图网格背景
          _buildMapGrid(),
          
          // 博物馆标记点
          _buildMuseumMarkers(),
          
          // 用户位置标记
          _buildUserLocationMarker(),
          
          // 地图控制按钮
          _buildMapControls(context),
        ],
      ),
    );
  }

  /// 构建地图网格背景
  Widget _buildMapGrid() {
    return Positioned.fill(
      child: CustomPaint(
        painter: MapGridPainter(),
      ),
    );
  }

  /// 构建博物馆标记点
  Widget _buildMuseumMarkers() {
    return Stack(
      children: [
        // 故宫博物院标记
        Positioned(
          top: 80,
          left: 120,
          child: _buildMarker(
            icon: Icons.museum,
            color: AppColors.accent,
            label: '故宫',
            isNearby: true,
          ),
        ),
        
        // 国家博物馆标记
        Positioned(
          top: 140,
          right: 100,
          child: _buildMarker(
            icon: Icons.account_balance,
            color: AppColors.info,
            label: '国博',
            isNearby: false,
          ),
        ),
        
        // 首都博物馆标记
        Positioned(
          bottom: 100,
          left: 80,
          child: _buildMarker(
            icon: Icons.museum,
            color: AppColors.warning,
            label: '首博',
            isNearby: false,
          ),
        ),
      ],
    );
  }

  /// 构建用户位置标记
  Widget _buildUserLocationMarker() {
    return Positioned(
      top: 120,
      left: 180,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.accent, width: 3),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.person,
            size: 12,
            color: AppColors.accent,
          ),
        ),
      ),
    );
  }

  /// 构建地图控制按钮
  Widget _buildMapControls(BuildContext context) {
    return Positioned(
      bottom: AppDimensions.paddingM,
      right: AppDimensions.paddingM,
      child: Column(
        children: [
          _buildControlButton(
            icon: Icons.my_location,
            onTap: () {
              UIHelper.showInfo(context, '定位到当前位置');
            },
          ),
          const SizedBox(height: AppDimensions.paddingS),
          _buildControlButton(
            icon: Icons.zoom_in,
            onTap: () {
              UIHelper.showInfo(context, '放大地图');
            },
          ),
          const SizedBox(height: AppDimensions.paddingS),
          _buildControlButton(
            icon: Icons.zoom_out,
            onTap: () {
              UIHelper.showInfo(context, '缩小地图');
            },
          ),
        ],
      ),
    );
  }

  /// 构建标记点
  Widget _buildMarker({
    required IconData icon,
    required Color color,
    required String label,
    required bool isNearby,
  }) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.surface, width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(
            icon,
            color: AppColors.surface,
            size: 20,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (isNearby)
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '可打卡',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.surface,
                fontSize: 8,
              ),
            ),
          ),
      ],
    );
  }

  /// 构建控制按钮
  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: AppColors.textPrimary,
          size: 24,
        ),
      ),
    );
  }
}

/// 地图网格绘制器
class MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.surface.withValues(alpha: 0.1)
      ..strokeWidth = 1.0;

    // 绘制网格线
    const gridSize = 40.0;
    
    // 垂直线
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
    
    // 水平线
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
