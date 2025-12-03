import 'package:flutter/material.dart';
import '../../core/utils/ui_helper.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';

/// 打卡历史列表组件
class CheckinHistoryList extends StatelessWidget {
  const CheckinHistoryList({super.key});

  // 模拟打卡历史数据
  final List<CheckinRecord> _checkinHistory = const [
    CheckinRecord(
      id: 1,
      museumName: '故宫博物院',
      checkinTime: '2024-01-15 14:30',
      note: '太震撼了！紫禁城的建筑太美了',
      hasPhoto: true,
    ),
    CheckinRecord(
      id: 2,
      museumName: '中国国家博物馆',
      checkinTime: '2024-01-10 10:15',
      note: '学到了很多历史知识',
      hasPhoto: true,
    ),
    CheckinRecord(
      id: 3,
      museumName: '首都博物馆',
      checkinTime: '2024-01-05 16:45',
      note: '',
      hasPhoto: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (_checkinHistory.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      itemCount: _checkinHistory.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppDimensions.paddingM),
      itemBuilder: (context, index) {
        final record = _checkinHistory[index];
        return _buildCheckinItem(context, record);
      },
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: AppColors.textHint,
          ),
          SizedBox(height: AppDimensions.paddingM),
          Text(
            '还没有打卡记录',
            style: AppTextStyles.bodyLarge,
          ),
          SizedBox(height: AppDimensions.paddingS),
          Text(
            '快去附近的博物馆打卡吧！',
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }

  /// 构建打卡记录项
  Widget _buildCheckinItem(BuildContext context, CheckinRecord record) {
    return GestureDetector(
      onTap: () => _viewCheckinDetail(context, record),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头部信息
            Row(
              children: [
                // 博物馆图标
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                  child: const Icon(
                    Icons.museum,
                    color: AppColors.textWhite,
                    size: 20,
                  ),
                ),
                
                const SizedBox(width: AppDimensions.paddingM),
                
                // 博物馆名称和时间
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.museumName,
                        style: AppTextStyles.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        record.checkinTime,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 标识图标
                Row(
                  children: [
                    if (record.hasPhoto)
                      Container(
                        margin: const EdgeInsets.only(right: 4),
                        child: const Icon(
                          Icons.photo_camera,
                          size: 16,
                          color: AppColors.accent,
                        ),
                      ),
                    const Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: AppColors.textHint,
                    ),
                  ],
                ),
              ],
            ),
            
            // 打卡笔记
            if (record.note.isNotEmpty) ...[
              const SizedBox(height: AppDimensions.paddingS),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimensions.paddingS),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
                child: Text(
                  record.note,
                  style: AppTextStyles.bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            
            // 底部操作栏
            const SizedBox(height: AppDimensions.paddingS),
            Row(
              children: [
                // 点赞按钮
                _buildActionButton(
                  icon: Icons.thumb_up_outlined,
                  label: '0',
                  onTap: () => _likeCheckin(context, record),
                ),
                const SizedBox(width: AppDimensions.paddingM),
                
                // 评论按钮
                _buildActionButton(
                  icon: Icons.comment_outlined,
                  label: '0',
                  onTap: () => _commentCheckin(context, record),
                ),
                
                const Spacer(),
                
                // 分享按钮
                _buildActionButton(
                  icon: Icons.share_outlined,
                  label: '分享',
                  onTap: () => _shareCheckin(context, record),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建操作按钮
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// 查看打卡详情
  void _viewCheckinDetail(BuildContext context, CheckinRecord record) {
    UIHelper.showInfo(context, '查看打卡详情: ${record.museumName}');
    // TODO: 跳转到打卡详情页
  }

  /// 点赞打卡
  void _likeCheckin(BuildContext context, CheckinRecord record) {
    UIHelper.showSuccess(context, '点赞成功');
  }

  /// 评论打卡
  void _commentCheckin(BuildContext context, CheckinRecord record) {
    UIHelper.showInfo(context, '评论功能');
  }

  /// 分享打卡
  void _shareCheckin(BuildContext context, CheckinRecord record) {
    UIHelper.showInfo(context, '分享打卡记录');
  }
}

/// 打卡记录数据模型
class CheckinRecord {
  final int id;
  final String museumName;
  final String checkinTime;
  final String note;
  final bool hasPhoto;

  const CheckinRecord({
    required this.id,
    required this.museumName,
    required this.checkinTime,
    required this.note,
    required this.hasPhoto,
  });
}
