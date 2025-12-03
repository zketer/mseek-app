import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/ui_helper.dart';
import '../../../core/utils/bottom_sheet_helper.dart';
import '../../../core/utils/date_utils.dart';
import '../../../services/api/checkin_service.dart';
import '../../../services/auth/auth_service.dart';
import '../../../widgets/common/common_app_bar.dart';
import '../../../core/constants/app_dimensions.dart';

/// 暂存草稿列表页面 - 完全匹配小程序设计
class DraftListScreen extends StatefulWidget {
  const DraftListScreen({super.key});

  @override
  State<DraftListScreen> createState() => _DraftListScreenState();
}

class _DraftListScreenState extends State<DraftListScreen> {
  final CheckinService _checkinService = CheckinService();
  final AuthService _authService = AuthService();
  
  List<CheckinRecord> _draftList = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _checkLoginAndLoad();
  }

  /// 检查登录状态并加载数据
  Future<void> _checkLoginAndLoad() async {
    final isLoggedIn = await _authService.isLoggedIn();
    
    if (!isLoggedIn) {
      if (mounted) {
        final confirmed = await BottomSheetHelper.showConfirm(
          context,
          title: '需要登录',
          content: '查看暂存草稿需要登录后使用，是否前往登录？',
          confirmText: '去登录',
          cancelText: '取消',
          icon: Icons.lock_outline,
        );
        
        if (confirmed == true) {
          if (!mounted) return;
          context.go('/login?redirect=/drafts');
        } else {
          if (!mounted) return;
          context.go('/');
        }
      }
      return;
    }
    
    _loadDraftList();
  }

  /// 加载暂存草稿列表
  Future<void> _loadDraftList() async {
    setState(() {
      _loading = true;
    });

    try {
      // DEBUG: print('🔄 开始加载草稿列表...');
      
      final pageResult = await _checkinService.getUserCheckinRecords(
        page: 1,
        pageSize: 100, // 加载所有草稿
        isDraft: true, // 只查询草稿
      );

      final draftList = pageResult.records;
      
      // 按保存时间降序排列
      draftList.sort((a, b) {
        final aTime = DateTime.tryParse(a.checkInDate) ?? DateTime.now();
        final bTime = DateTime.tryParse(b.checkInDate) ?? DateTime.now();
        return bTime.compareTo(aTime);
      });

      setState(() {
        _draftList = draftList;
        _loading = false;
      });

      // DEBUG: print('✅ 草稿列表加载完成，共 ${draftList.length} 条');
    } catch (e) {
      // DEBUG: print('❌ 加载草稿列表失败: $e');
      setState(() {
        _loading = false;
      });
      if (mounted) {
        // 不显示错误提示
      }
    }
  }

  /// 格式化保存时间
  String _formatSaveTime(String checkInDate) {
    try {
      final saveTime = DateTime.parse(checkInDate);
      return AppDateUtils.formatRelativeTime(saveTime);
    } catch (e) {
      return '未知时间';
    }
  }

  /// 格式化评分显示
  String _formatRating(double? rating) {
    if (rating == null || rating == 0) return '';
    
    final ratingMap = {
      1.0: '很差',
      2.0: '一般',
      3.0: '不错',
      4.0: '很好',
      5.0: '极佳',
    };
    
    return ratingMap[rating] ?? '';
  }

  /// 点击草稿项，跳转到编辑页面
  void _onDraftTap(CheckinRecord draft) {
    context.go('/checkin/action/${draft.museumId}?draftId=${draft.id}');
  }

  /// 删除草稿项
  Future<void> _onDeleteDraft(CheckinRecord draft) async {
    final confirmed = await BottomSheetHelper.showConfirm(
      context,
      title: '确认删除',
      content: '确定要删除这个暂存草稿吗？删除后无法恢复',
      confirmText: '确定删除',
      cancelText: '取消',
      isDangerous: true,
      icon: Icons.delete_outline,
    );

    if (confirmed != true) return;

    try {
      // DEBUG: print('🗑️ [草稿列表] 开始删除草稿: ID=${draft.id}, 博物馆=${draft.museumName}');
      
      final success = await _checkinService.deleteDraft(draft.id);
      
      // DEBUG: print('📊 [草稿列表] deleteDraft返回结果: $success');
      
      if (mounted) {
        if (success) {
          UIHelper.showSuccess(context, '已删除');
        } else {
          UIHelper.showError(context, '删除失败');
        }
      }
      
      // 刷新列表
      // DEBUG: print('🔄 [草稿列表] 开始刷新列表...');
      await _loadDraftList();
      // DEBUG: print('✅ [草稿列表] 列表刷新完成');
      
      // DEBUG: print('✅ [草稿列表] 草稿删除流程完成');
    } catch (e) {
      // DEBUG: print('❌ 删除草稿失败: $e');
      if (mounted) {
        // 不显示错误提示
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CommonAppBar(
        title: '暂存草稿',
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryLight))
          : RefreshIndicator(
              onRefresh: _loadDraftList,
              child: _draftList.isEmpty
                  ? _buildEmptyState()
                  : _buildDraftList(),
            ),
    );
  }

  /// 构建草稿列表
  Widget _buildDraftList() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      itemCount: _draftList.length,
      itemBuilder: (context, index) {
        final draft = _draftList[index];
        return _buildDraftItem(draft);
      },
    );
  }

  /// 构建草稿项
  Widget _buildDraftItem(CheckinRecord draft) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 主内容区域
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _onDraftTap(draft),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 博物馆名称
                    Text(
                      draft.museumName,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // 感受预览
                    Text(
                      draft.notes != null && draft.notes!.isNotEmpty
                          ? (draft.notes!.length > 30 
                              ? '${draft.notes!.substring(0, 30)}...' 
                              : draft.notes!)
                          : '暂无感受内容',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // 元信息
                    Row(
                      children: [
                        // 保存时间
                        Text(
                          _formatSaveTime(draft.checkInDate),
                          style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 12,
                            color: AppColors.textHint,
                          ),
                        ),
                        
                        const SizedBox(width: 12),
                        
                        // 标签
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              // 照片数量
                              if (draft.photos != null && draft.photos!.isNotEmpty)
                                _buildTag('${draft.photos!.length}张照片'),
                              
                              // 评分
                              if (draft.rating != null && draft.rating! > 0)
                                _buildTag(_formatRating(draft.rating)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // 删除按钮
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => _onDeleteDraft(draft),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: Colors.red,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建标签
  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: AppTextStyles.bodySmall.copyWith(
          fontSize: 11,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '📝',
            style: TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无草稿',
            style: AppTextStyles.titleMedium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '您还没有保存任何打卡草稿',
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 14,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}

