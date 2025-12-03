import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../widgets/discovery/discovery_search_section.dart';
import '../../../widgets/discovery/discovery_category_tabs.dart';
import '../../../widgets/discovery/discovery_museum_list.dart';
import '../../../services/api/museum_service.dart';
import '../../../widgets/common/app_page_wrapper.dart';

/// 发现页面 - 完全匹配小程序设计的博物馆发现页面
class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> with AutomaticKeepAliveClientMixin {
  bool _isLoading = true;
  final _museumService = MuseumService();
  
  // 搜索和筛选状态
  String _searchKeyword = '';
  int _activeCategory = 0; // 0表示全部
  String _sortBy = 'hot';
  int _currentPage = 1;
  final int _pageSize = 10;
  
  // 分类数据
  List<Map<String, dynamic>> _categories = [];
  
  // 博物馆列表数据
  List<Map<String, dynamic>> _museums = [];
  int _total = 0;
  bool _hasMore = true;
  
  // 筛选弹窗状态
  bool _showFilterModal = false;
  int _filterCategory = 0;
  String _filterSort = 'hot';

  @override
  bool get wantKeepAlive => true;

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
    
    try {
      // 并发加载分类和博物馆数据
    // ignore: unused_local_variable
      final futures = await Future.wait([
        _loadCategories(),
        _loadMuseumList(true),
      ]);
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // DEBUG: print('数据加载失败: $e');
      // 不显示错误提示
    }
  }

  /// 加载分类列表
  Future<void> _loadCategories() async {
    try {
      final categories = await _museumService.getCategories();
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      // DEBUG: print('分类加载失败: $e');
    }
  }

  /// 加载博物馆列表
  Future<void> _loadMuseumList(bool reset) async {
    if (_isLoading && !reset) return;

    try {
      final currentPage = reset ? 1 : _currentPage;
      final categoryId = _activeCategory == 0 ? null : _activeCategory;
      
      final response = await _museumService.getMuseumPage(
        page: currentPage,
        pageSize: _pageSize,
        keyword: _searchKeyword.isEmpty ? null : _searchKeyword,
        categoryId: categoryId,
        sortBy: _sortBy,
      );

      // 生成显示标签
      final museums = (response['records'] as List).map((museum) {
        final Map<String, dynamic> museumData = Map<String, dynamic>.from(museum);
        museumData['tags'] = _generateDisplayTags(museumData);
        return museumData;
      }).toList();

      setState(() {
        if (reset) {
          _museums = museums;
          _currentPage = 2;
        } else {
          _museums.addAll(museums);
          _currentPage++;
        }
        _total = response['total'] ?? 0;
        _hasMore = museums.length == _pageSize;
      });

    } catch (e) {
      // DEBUG: print('博物馆列表加载失败: $e');
      // 不显示错误提示，空状态组件已经足够
    }
  }

  /// 生成显示标签
  List<Map<String, dynamic>> _generateDisplayTags(Map<String, dynamic> museum) {
    final List<Map<String, dynamic>> tags = [];

    // 1. 后端返回的标签
    if (museum['tags'] != null && museum['tags'] is List) {
      tags.addAll((museum['tags'] as List).cast<Map<String, dynamic>>());
    }

    // 2. 分类标签
    if (museum['categories'] != null && museum['categories'] is List) {
      for (final category in museum['categories']) {
        tags.add({
          'id': category['id'],
          'name': category['name'],
          'code': category['code'],
          'color': _getCategoryColor(category['code'] ?? ''),
        });
      }
    }

    // 3. 等级标签
    if (museum['level'] != null && museum['level'] > 0) {
      final levelNames = ['', '一级博物馆', '二级博物馆', '三级博物馆', '四级博物馆', '五级博物馆'];
      final level = museum['level'] as int;
      tags.add({
        'id': 9999 + level,
        'name': level < levelNames.length ? levelNames[level] : '$level级',
        'code': 'LEVEL_$level',
        'color': '#f6ffed',
      });
    }

    // 4. 免费标签
    if (museum['freeAdmission'] == 1) {
      tags.add({
        'id': 9998,
        'name': '免费参观',
        'code': 'FREE_ADMISSION',
        'color': '#fff2e8',
      });
    }

    return tags;
  }

  /// 获取分类标签颜色
  String _getCategoryColor(String categoryCode) {
    const colorMap = {
      'TYPE_CULTURAL': '#e6f7ff', // 文化文物系统 - 蓝色
      'TYPE_PRIVATE': '#f6ffed',  // 非国有博物馆 - 绿色
      'FOLK': '#fff7e6',          // 民俗类 - 橙色
      'SCIENCE': '#f0f5ff',       // 科技类 - 紫色
      'ART': '#fef1f0',           // 艺术类 - 红色
      'NATURE': '#f6ffed',        // 自然类 - 绿色
    };
    return colorMap[categoryCode] ?? '#fafafa';
  }

  /// 处理搜索
  void _onSearchChanged(String keyword) {
    setState(() {
      _searchKeyword = keyword;
    });
    _loadMuseumList(true);
  }

  /// 处理分类选择
  void _onCategoryChanged(int categoryId) {
    setState(() {
      _activeCategory = categoryId;
    });
    _loadMuseumList(true);
  }

  /// 处理刷新
  Future<void> _onRefresh() async {
    await _loadMuseumList(true);
  }

  /// 处理加载更多
  void _onLoadMore() {
    if (_hasMore && !_isLoading) {
      _loadMuseumList(false);
    }
  }

  /// 显示筛选弹窗
  void _showFilter() {
    setState(() {
      _showFilterModal = true;
    });
  }

  /// 关闭筛选弹窗
  void _hideFilter() {
    setState(() {
      _showFilterModal = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须调用，用于AutomaticKeepAliveClientMixin

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppPageWrapper(
        safeAreaTop: false, // 搜索栏组件内部已有 SafeArea
        safeAreaBottom: false, // 列表自己处理底部
        statusBarBrightness: Brightness.light, // 渐变背景是深色，使用浅色文字
        child: Stack(
          children: [
            Column(
              children: [
                // 搜索栏 - 红色渐变背景（组件内部已有 SafeArea）
                DiscoverySearchSection(
                  searchKeyword: _searchKeyword,
                  onSearchChanged: _onSearchChanged,
                ),
                
                // 分类标签栏
                DiscoveryCategoryTabs(
                  categories: _categories,
                  activeCategory: _activeCategory,
                  onCategoryChanged: _onCategoryChanged,
                  onFilterTap: _showFilter,
                ),
                
                // 博物馆列表
                Expanded(
                  child: DiscoveryMuseumList(
                    museums: _museums,
                    total: _total,
                    isLoading: _isLoading,
                    hasMore: _hasMore,
                    onRefresh: _onRefresh,
                    onLoadMore: _onLoadMore,
                  ),
                ),
              ],
            ),
            
            // 筛选弹窗
            if (_showFilterModal)
              _buildFilterModal(),
          ],
        ),
      ),
    );
  }

  /// 构建筛选弹窗
  Widget _buildFilterModal() {
    return GestureDetector(
      onTap: _hideFilter,
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {}, // 阻止冒泡
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 筛选标题
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.paddingM),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.backgroundDark,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '筛选条件',
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        GestureDetector(
                          onTap: _hideFilter,
                          child: const Icon(Icons.close, size: 20, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  
                  // 筛选内容
                  Padding(
                    padding: const EdgeInsets.all(AppDimensions.paddingM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 分类筛选
                        Text(
                          '博物馆分类',
                          style: AppTextStyles.titleSmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildFilterOption('全部', 0, _filterCategory == 0),
                            ..._categories.map((category) => 
                              _buildFilterOption(
                                category['name'], 
                                category['id'], 
                                _filterCategory == category['id']
                              )
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // 排序方式
                        Text(
                          '排序方式',
                          style: AppTextStyles.titleSmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildFilterOption('人气最高', 'hot', _filterSort == 'hot'),
                            _buildFilterOption('藏品最多', 'collection', _filterSort == 'collection'),
                          ],
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // 操作按钮
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _filterCategory = 0;
                                    _filterSort = 'hot';
                                  });
                                },
                                child: Container(
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.backgroundLight,
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '重置',
                                      style: AppTextStyles.titleSmall.copyWith(
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _activeCategory = _filterCategory;
                                    _sortBy = _filterSort;
                                  });
                                  _hideFilter();
                                  // TODO: 重新加载数据
                                },
                                child: Container(
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '确定',
                                      style: AppTextStyles.titleSmall.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建筛选选项
  Widget _buildFilterOption(String text, dynamic value, bool isActive) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (value is int) {
            _filterCategory = value;
          } else if (value is String) {
            _filterSort = value;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.errorBg : AppColors.backgroundLight,
          border: Border.all(
            color: isActive ? AppColors.primary : Colors.transparent,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: AppTextStyles.bodySmall.copyWith(
            color: isActive ? AppColors.primary : Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
