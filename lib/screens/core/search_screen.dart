import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/ui_helper.dart';

/// 搜索页面
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  List<String> _searchHistory = [
    '故宫博物院',
    '唐代文物展',
    '青铜器',
    '国家博物馆',
  ];

  List<String> _hotKeywords = [
    '故宫',
    '兵马俑',
    '青铜器',
    '瓷器',
    '书画',
    '考古',
    '文物',
    '历史',
  ];

  @override
  void initState() {
    super.initState();
    // 自动获取焦点
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        titleSpacing: 0,
        title: Container(
          height: 40,
          margin: const EdgeInsets.only(right: AppDimensions.paddingM),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _focusNode,
            decoration: InputDecoration(
              hintText: '搜索博物馆、展览...',
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textHint,
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.textHint,
                size: 20,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                      icon: const Icon(
                        Icons.clear,
                        color: AppColors.textHint,
                        size: 20,
                      ),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingS,
                vertical: AppDimensions.paddingS,
              ),
            ),
            onChanged: (value) {
              setState(() {});
            },
            onSubmitted: _performSearch,
          ),
        ),
      ),
      body: _searchController.text.isEmpty
          ? _buildEmptyState()
          : _buildSearchResults(),
    );
  }

  /// 构建空状态（搜索历史和热门关键词）
  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 搜索历史
          if (_searchHistory.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '搜索历史',
                  style: AppTextStyles.titleMedium,
                ),
                TextButton(
                  onPressed: _clearHistory,
                  child: Text(
                    '清空',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingS),
            
            // 历史记录列表
            ...(_searchHistory.map((keyword) => _buildHistoryItem(keyword))),
            
            const SizedBox(height: AppDimensions.paddingL),
          ],
          
          // 热门搜索
          Text(
            '热门搜索',
            style: AppTextStyles.titleMedium,
          ),
          const SizedBox(height: AppDimensions.paddingM),
          
          // 热门关键词标签
          Wrap(
            spacing: AppDimensions.paddingS,
            runSpacing: AppDimensions.paddingS,
            children: _hotKeywords.map((keyword) => _buildKeywordChip(keyword)).toList(),
          ),
        ],
      ),
    );
  }

  /// 构建搜索结果
  Widget _buildSearchResults() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primaryLight),
          SizedBox(height: AppDimensions.paddingM),
          Text('搜索中...', style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }

  /// 构建历史记录项
  Widget _buildHistoryItem(String keyword) {
    return ListTile(
      leading: const Icon(
        Icons.history,
        color: AppColors.textHint,
        size: 20,
      ),
      title: Text(
        keyword,
        style: AppTextStyles.bodyMedium,
      ),
      trailing: IconButton(
        onPressed: () => _removeFromHistory(keyword),
        icon: const Icon(
          Icons.close,
          color: AppColors.textHint,
          size: 16,
        ),
      ),
      onTap: () => _performSearch(keyword),
      contentPadding: EdgeInsets.zero,
    );
  }

  /// 构建关键词标签
  Widget _buildKeywordChip(String keyword) {
    return GestureDetector(
      onTap: () => _performSearch(keyword),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingM,
          vertical: AppDimensions.paddingS,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          keyword,
          style: AppTextStyles.bodyMedium,
        ),
      ),
    );
  }

  /// 执行搜索
  void _performSearch(String keyword) {
    if (keyword.trim().isEmpty) return;
    
    // 添加到搜索历史
    if (!_searchHistory.contains(keyword)) {
      setState(() {
        _searchHistory.insert(0, keyword);
        if (_searchHistory.length > 10) {
          _searchHistory = _searchHistory.take(10).toList();
        }
      });
    }
    
    _searchController.text = keyword;
    
    // TODO: 执行实际搜索
    UIHelper.showInfo(context, '搜索: $keyword');
  }

  /// 清空搜索历史
  void _clearHistory() {
    setState(() {
      _searchHistory.clear();
    });
  }

  /// 从历史记录中移除
  void _removeFromHistory(String keyword) {
    setState(() {
      _searchHistory.remove(keyword);
    });
  }
}
