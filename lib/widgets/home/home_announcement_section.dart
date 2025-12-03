// ignore_for_file: dead_null_aware_expression
import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/announcement.dart';
import '../common/modern_dialog.dart';

/// 首页公告栏组件 - 完全匹配小程序：小图标+垂直滚动+4秒自动播放+循环
class HomeAnnouncementSection extends StatefulWidget {
  final List<Announcement> announcements;

  const HomeAnnouncementSection({
    super.key,
    required this.announcements,
  });

  @override
  State<HomeAnnouncementSection> createState() => _HomeAnnouncementSectionState();
}

class _HomeAnnouncementSectionState extends State<HomeAnnouncementSection> {
  late PageController _pageController;
  Timer? _timer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    // 如果有多个公告，启动自动播放
    if (widget.announcements.length > 1) {
      _startAutoPlay();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  /// 启动自动播放 - 匹配小程序4秒间隔
  void _startAutoPlay() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_currentIndex < widget.announcements.length - 1) {
        _currentIndex++;
      } else {
        _currentIndex = 0; // 循环播放
      }
      
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentIndex,
          duration: const Duration(milliseconds: 300), // 匹配小程序300毫秒动画
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.announcements.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingM),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingM,
        vertical: AppDimensions.paddingS,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 公告图标 - 小程序样式
          Icon(
            Icons.info_outline,
            color: AppColors.primary, // 小程序使用的红色 #ff6b6b
            size: 16,
          ),
          const SizedBox(width: AppDimensions.paddingS),
          
          // 公告内容 - 垂直滚动
          Expanded(
            child: SizedBox(
              height: 20, // 固定高度匹配小程序 40rpx
              child: PageView.builder(
                controller: _pageController, // 添加控制器
                scrollDirection: Axis.vertical,
                itemCount: widget.announcements.length,
                physics: const PageScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final announcement = widget.announcements[index];
                  final dateStr = announcement.formattedPublishDate;
                  final displayText = dateStr.isNotEmpty 
                      ? '${announcement.title ?? '暂无标题'}  $dateStr'
                      : announcement.title ?? '暂无标题';
                  
                  return GestureDetector(
                    onTap: () => _onAnnouncementTapped(context, announcement),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        displayText,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12, // 24rpx转换为12px
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 处理公告点击事件
  void _onAnnouncementTapped(BuildContext context, Announcement announcement) {
    final dateStr = announcement.formattedPublishDate;
    final contentWithDate = dateStr.isNotEmpty
        ? '${announcement.content ?? '暂无内容'}\n\n发布时间：$dateStr'
        : announcement.content ?? '暂无内容';
    
    ModernDialog.showInfo(
      context,
      title: announcement.title ?? '系统通知',
      content: contentWithDate,
      confirmText: '我知道了',
    );
  }
}
