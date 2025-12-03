import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/museum.dart';

/// 博物馆详情页Tab组件
class MuseumDetailTabs extends StatefulWidget {
  final Museum museum;
  
  const MuseumDetailTabs({
    super.key,
    required this.museum,
  });

  @override
  State<MuseumDetailTabs> createState() => _MuseumDetailTabsState();
}

class _MuseumDetailTabsState extends State<MuseumDetailTabs> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final List<String> _tabs = ['展览', '评价', '相关'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab栏
        Container(
          color: AppColors.surface,
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.accent,
            labelColor: AppColors.accent,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: AppTextStyles.titleMedium,
            unselectedLabelStyle: AppTextStyles.bodyMedium,
            tabs: _tabs.map((title) => Tab(text: title)).toList(),
          ),
        ),
        
        // Tab内容
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildExhibitionsTab(),
              _buildReviewsTab(),
              _buildRelatedTab(),
            ],
          ),
        ),
      ],
    );
  }

  /// 展览Tab
  Widget _buildExhibitionsTab() {
    return ListView(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      children: [
        // 模拟展览数据
        _buildExhibitionItem(
          title: '古代青铜器展',
          period: '2024-01-01 至 2024-06-30',
          status: '进行中',
          statusColor: AppColors.success,
        ),
        const SizedBox(height: AppDimensions.paddingM),
        _buildExhibitionItem(
          title: '明清瓷器珍品展',
          period: '2024-03-15 至 2024-09-15',
          status: '即将开始',
          statusColor: AppColors.warning,
        ),
        const SizedBox(height: AppDimensions.paddingM),
        _buildExhibitionItem(
          title: '丝绸之路文物展',
          period: '2023-10-01 至 2024-02-29',
          status: '已结束',
          statusColor: AppColors.textHint,
        ),
      ],
    );
  }

  /// 评价Tab
  Widget _buildReviewsTab() {
    return ListView(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      children: [
        // 评分概览
        _buildRatingOverview(),
        const SizedBox(height: AppDimensions.paddingL),
        
        // 评价列表
        _buildReviewItem(
          username: '文化爱好者',
          rating: 5,
          comment: '非常棒的博物馆！文物丰富，讲解详细，值得多次参观。',
          date: '2024-01-15',
        ),
        const SizedBox(height: AppDimensions.paddingM),
        _buildReviewItem(
          username: '历史学者',
          rating: 4,
          comment: '展品很有价值，但是人太多了，希望能控制一下参观人数。',
          date: '2024-01-10',
        ),
      ],
    );
  }

  /// 相关Tab
  Widget _buildRelatedTab() {
    return ListView(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      children: [
        Text(
          '附近博物馆',
          style: AppTextStyles.titleMedium,
        ),
        const SizedBox(height: AppDimensions.paddingM),
        
        // 相关博物馆
        _buildRelatedMuseumItem(
          name: '中国国家博物馆',
          distance: '1.2km',
          rating: 4.8,
        ),
        const SizedBox(height: AppDimensions.paddingM),
        _buildRelatedMuseumItem(
          name: '首都博物馆',
          distance: '2.5km',
          rating: 4.6,
        ),
      ],
    );
  }

  /// 构建展览项
  Widget _buildExhibitionItem({
    required String title,
    required String period,
    required String status,
    required Color statusColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.titleMedium,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: AppTextStyles.labelSmall.copyWith(color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingS),
          Text(
            period,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  /// 构建评分概览
  Widget _buildRatingOverview() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(
                '4.8',
                style: AppTextStyles.headlineLarge.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < 4 ? Icons.star : Icons.star_border,
                    color: AppColors.warning,
                    size: 16,
                  );
                }),
              ),
              const SizedBox(height: 4),
              Text(
                '128条评价',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(width: AppDimensions.paddingL),
          Expanded(
            child: Column(
              children: [
                _buildRatingBar('5星', 80, AppColors.success),
                _buildRatingBar('4星', 15, AppColors.warning),
                _buildRatingBar('3星', 3, AppColors.info),
                _buildRatingBar('2星', 1, AppColors.error),
                _buildRatingBar('1星', 1, AppColors.error),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建评分条
  Widget _buildRatingBar(String label, int percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              label,
              style: AppTextStyles.labelSmall,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: percentage / 100,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$percentage%',
            style: AppTextStyles.labelSmall,
          ),
        ],
      ),
    );
  }

  /// 构建评价项
  Widget _buildReviewItem({
    required String username,
    required int rating,
    required String comment,
    required String date,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  username[0],
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.paddingS),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(username, style: AppTextStyles.bodyMedium),
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            index < rating ? Icons.star : Icons.star_border,
                            color: AppColors.warning,
                            size: 14,
                          );
                        }),
                        const SizedBox(width: 8),
                        Text(
                          date,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingS),
          Text(
            comment,
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }

  /// 构建相关博物馆项
  Widget _buildRelatedMuseumItem({
    required String name,
    required String distance,
    required double rating,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            child: const Icon(
              Icons.museum,
              color: AppColors.textWhite,
              size: 24,
            ),
          ),
          const SizedBox(width: AppDimensions.paddingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.bodyMedium),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, size: 14, color: AppColors.warning),
                    const SizedBox(width: 4),
                    Text(
                      rating.toString(),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.paddingM),
                    Text(
                      distance,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: AppColors.textHint,
            size: 20,
          ),
        ],
      ),
    );
  }
}
