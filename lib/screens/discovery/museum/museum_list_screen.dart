import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/discovery/discovery_museum_list.dart';
import '../../../widgets/common/common_app_bar.dart';
import '../../../core/utils/ui_helper.dart';

/// 博物馆列表页面
class MuseumListScreen extends StatefulWidget {
  final String? title;
  final String? categoryCode;
  final String? cityCode;
  
  const MuseumListScreen({
    super.key,
    this.title,
    this.categoryCode,
    this.cityCode,
  });

  @override
  State<MuseumListScreen> createState() => _MuseumListScreenState();
}

class _MuseumListScreenState extends State<MuseumListScreen> {
  // 状态管理
  List<Map<String, dynamic>> _museums = [];
  int _total = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  /// 加载数据
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    // TODO: 实现实际的数据加载逻辑
    await Future.delayed(const Duration(milliseconds: 500));
    
    setState(() {
      _isLoading = false;
      _museums = [];
      _total = 0;
      _hasMore = false;
    });
  }
  
  /// 刷新数据
  Future<void> _onRefresh() async {
    await _loadData();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CommonAppBar.withSearch(
        title: widget.title ?? '博物馆列表',
        onSearchPressed: () {
          // TODO: 跳转到搜索页
          UIHelper.showInfo(context, '搜索功能');
        },
        additionalActions: [
          IconButton(
            icon: const Icon(
              Icons.filter_list,
              color: AppColors.textSecondary,
              size: 24,
            ),
            onPressed: () {
              // TODO: 显示筛选对话框
              UIHelper.showInfo(context, '筛选功能');
            },
          ),
        ],
      ),
      body: DiscoveryMuseumList(
        museums: _museums,
        total: _total,
        isLoading: _isLoading,
        hasMore: _hasMore,
        onRefresh: _onRefresh,
      ),
    );
  }
}
