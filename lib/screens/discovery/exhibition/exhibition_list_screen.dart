import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/exhibition.dart';
import '../../../services/api/exhibition_service.dart';
import '../../../core/constants/app_dimensions.dart';

/// 展览列表页面 - 对齐小程序样式
class ExhibitionListScreen extends StatefulWidget {
  final String? title;
  final int? museumId;
  
  const ExhibitionListScreen({
    super.key,
    this.title,
    this.museumId,
  });

  @override
  State<ExhibitionListScreen> createState() => _ExhibitionListScreenState();
}

class _ExhibitionListScreenState extends State<ExhibitionListScreen> {
  final ExhibitionService _exhibitionService = ExhibitionService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  
  List<Exhibition> _exhibitions = [];
  int _total = 0;
  int _currentPage = 1;
  final int _pageSize = 10;
  bool _isLoading = false;
  bool _hasMore = true;
  
  // 搜索和筛选
  String _searchKeyword = '';
  int? _activeStatus; // null=全部, 0=已结束, 1=进行中, 2=即将开始

  @override
  void initState() {
    super.initState();
    _loadExhibitionList(reset: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// 滚动监听 - 上拉加载更多
  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _loadExhibitionList(reset: false);
      }
    }
  }

  /// 加载展览列表
  Future<void> _loadExhibitionList({required bool reset}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final page = reset ? 1 : _currentPage + 1;
      
      // DEBUG: print('🎨 [展览列表] 加载数据 - 页码: $page, 搜索: $_searchKeyword, 状态: $_activeStatus');
      
      final response = await _exhibitionService.getAllExhibitions(
        page: page,
        pageSize: _pageSize,
        title: _searchKeyword.isNotEmpty ? _searchKeyword : null,
        status: _activeStatus,
        museumId: widget.museumId,
      );

      if (mounted) {
        setState(() {
          if (reset) {
            _exhibitions = response.records;
            _currentPage = 1;
          } else {
            _exhibitions.addAll(response.records);
            _currentPage = page;
          }
          _total = response.total;
          _hasMore = _exhibitions.length < _total;
          _isLoading = false;
        });

        // DEBUG: print('✅ [展览列表] 加载成功 - 总数: $_total, 当前: ${_exhibitions.length}');
      }
    } catch (e) {
      // DEBUG: print('❌ [展览列表] 加载失败: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // 不显示错误提示，空状态组件已经足够
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          // 如果没有成功pop，跳转到首页
          context.go('/');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(),
        body: _buildList(),
      ),
    );
  }

  /// 构建 AppBar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: _handleBack,
      ),
      title: Text(
        widget.title ?? '最新展览',
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list, color: AppColors.textPrimary),
          onPressed: _showFilterDialog,
        ),
        IconButton(
          icon: const Icon(Icons.search, color: AppColors.textPrimary),
          onPressed: _onSearchPressed,
        ),
      ],
    );
  }

  /// 处理返回按钮 - 安全的返回逻辑
  void _handleBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }


  /// 构建列表
  Widget _buildList() {
    return RefreshIndicator(
      onRefresh: () => _loadExhibitionList(reset: true),
      color: AppColors.primaryLight, // 浅粉色刷新指示器，与首页一致
      child: _buildScrollableContent(),
    );
  }

  /// 构建可滚动内容
  Widget _buildScrollableContent() {
    if (_exhibitions.isEmpty && !_isLoading) {
      return _buildEmptyStateScrollable();
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingM, vertical: 8),
      itemCount: _exhibitions.length + (_isLoading ? 1 : 0) + (_exhibitions.isNotEmpty ? 1 : 0),
      itemBuilder: (context, index) {
        // 列表头部（展览数量）
        if (index == 0 && _exhibitions.isNotEmpty) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '找到 $_total 个展览',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }

        // 调整索引（因为有头部）
        final exhibitionIndex = _exhibitions.isNotEmpty ? index - 1 : index;

        // 加载指示器
        if (exhibitionIndex >= _exhibitions.length) {
          return _buildLoadingIndicator();
        }

        // 展览卡片
        final exhibition = _exhibitions[exhibitionIndex];
        return _buildExhibitionCard(exhibition);
      },
    );
  }

  /// 构建展览卡片 - 图片为主的卡片设计，参考同城博物馆样式
  Widget _buildExhibitionCard(Exhibition exhibition) {
    return GestureDetector(
      onTap: () => _onExhibitionTap(exhibition),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 180, // 稍微小于博物馆卡片的200px
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // 背景图片
              Positioned.fill(
                child: _getExhibitionImageUrl(exhibition) != null
                    ? CachedNetworkImage(
                        imageUrl: _getExhibitionImageUrl(exhibition)!,
                        fit: BoxFit.cover,
                        memCacheWidth: 600,
                        memCacheHeight: 360,
                        errorWidget: (context, url, error) => _buildDefaultBackground(),
                      )
                    : _buildDefaultBackground(),
              ),
              // 渐变遮罩 - 增强底部遮罩
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.4),
                        Colors.black.withValues(alpha: 0.8),
                      ],
                      stops: const [0.0, 0.3, 0.6, 1.0],
                    ),
                  ),
                ),
              ),
              // 底部信息叠加
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 展览标题
                      Text(
                        exhibition.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 4,
                              color: Colors.black54,
                            ),
                            Shadow(
                              offset: Offset(0, 0),
                              blurRadius: 8,
                              color: Colors.black38,
                            ),
                          ],
                        ),
                        maxLines: 1, // 改为单行显示
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // 博物馆名称
                      if (exhibition.museumName != null)
                        Text(
                          exhibition.museumName!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 3,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 8),
                      // 底部标签和展期
                      Row(
                        children: [
                          // 状态标签
                          _buildOverlayTag(exhibition.exhibitionStatus, _getStatusBackgroundColor(exhibition.exhibitionStatus)),
                          if (exhibition.isPermanent == 1) ...[
                            const SizedBox(width: 6),
                            _buildOverlayTag('常设', AppColors.tagFolk),
                          ],
                          if (exhibition.ticketPrice == null || exhibition.ticketPrice == 0) ...[
                            const SizedBox(width: 6),
                            _buildOverlayTag('免费', AppColors.success),
                          ],
                          const Spacer(),
                          // 展期信息（右侧）
                          if (exhibition.isPermanent != 1 && exhibition.startDate != null && exhibition.endDate != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${exhibition.formattedStartDate} - ${exhibition.formattedEndDate}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 获取状态背景颜色
  Color _getStatusBackgroundColor(String status) {
    switch (status) {
      case '进行中':
        return AppColors.successBg;
      case '即将开始':
        return AppColors.infoBg;
      case '已结束':
        return AppColors.background;
      default:
        return AppColors.background;
    }
  }

  /// 获取状态文字颜色
  Color _getStatusTextColor(String status) {
    switch (status) {
      case '进行中':
        return AppColors.success;
      case '即将开始':
        return AppColors.info;
      case '已结束':
        return AppColors.textHint;
      default:
        return AppColors.textHint;
    }
  }

  /// 加载指示器
  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      alignment: Alignment.center,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          SizedBox(height: 8),
          Text(
            '加载中...',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建可滚动的空状态
  Widget _buildEmptyStateScrollable() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
        _buildEmptyStateContent(),
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
      ],
    );
  }

  /// 空状态
  Widget _buildEmptyState() {
    return Center(
      child: _buildEmptyStateContent(),
    );
  }

  /// 空状态内容
  Widget _buildEmptyStateContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.museum_outlined,
          size: 80,
          color: Colors.grey[300],
        ),
        const SizedBox(height: 16),
        Text(
          '暂无展览信息',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  /// 搜索输入变化
  void _onSearchInput(String value) {
    setState(() {
      _searchKeyword = value;
    });
  }

  /// 搜索确认
  void _onSearchConfirm() {
    setState(() {
      _searchKeyword = _searchController.text;
    });
    _loadExhibitionList(reset: true);
  }

  /// 清除搜索
  void _onSearchClear() {
    _searchController.clear();
    setState(() {
      _searchKeyword = '';
    });
    _loadExhibitionList(reset: true);
  }

  /// 显示筛选对话框
  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '筛选展览',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '展览状态',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _buildDialogFilterChip('全部', null, setDialogState),
                  _buildDialogFilterChip('进行中', 1, setDialogState),
                  _buildDialogFilterChip('即将开始', 2, setDialogState),
                  _buildDialogFilterChip('已结束', 0, setDialogState),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _activeStatus = null;
                        });
                        Navigator.pop(context);
                        _loadExhibitionList(reset: true);
                      },
                      child: const Text('重置'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _loadExhibitionList(reset: true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('确定'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建对话框内的筛选标签
  Widget _buildDialogFilterChip(String label, int? status, StateSetter setDialogState) {
    final isActive = _activeStatus == status;
    return GestureDetector(
      onTap: () {
        setDialogState(() {
          _activeStatus = status;
        });
        setState(() {
          _activeStatus = status;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.primary : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : AppColors.textSecondary,
            fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  /// 构建筛选标签
  Widget _buildFilterChip(String label, int? status) {
    final isActive = _activeStatus == status;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeStatus = status;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.primary : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : AppColors.textSecondary,
            fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  /// 显示全屏搜索
  void _onSearchPressed() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => _buildFullScreenSearch(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // 从上往下滑入的动画
          const begin = Offset(0.0, -1.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  /// 构建全屏搜索界面
  Widget _buildFullScreenSearch() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: '搜索展览名称...',
              hintStyle: TextStyle(color: AppColors.textHint, fontSize: 14),
              prefixIcon: Icon(Icons.search, color: AppColors.textHint, size: 20),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            onChanged: _onSearchInput,
            onSubmitted: (_) {
              _onSearchConfirm();
              Navigator.of(context).pop();
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _onSearchConfirm();
              Navigator.of(context).pop();
            },
            child: const Text(
              '搜索',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索历史或热门搜索
          if (_searchKeyword.isEmpty) ...[
            const Padding(
              padding: EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '热门展览',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildSearchTag('梵高展'),
                  _buildSearchTag('敦煌艺术展'),
                  _buildSearchTag('青铜器展'),
                  _buildSearchTag('书画展'),
                  _buildSearchTag('古代文物展'),
                ],
              ),
            ),
          ],
          // 搜索结果区域
          if (_searchKeyword.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '搜索结果',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            // 这里可以显示搜索结果
            const Expanded(
              child: Center(
                child: Text(
                  '搜索功能开发中...',
                  style: TextStyle(
                    color: AppColors.textHint,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建搜索标签
  Widget _buildSearchTag(String text) {
    return GestureDetector(
      onTap: () {
        _searchController.text = text;
        _onSearchInput(text);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  /// 获取展览图片URL - 优先级：images.first → coverImage → null
  String? _getExhibitionImageUrl(Exhibition exhibition) {
    // 1. 优先使用 images 的第一张图片
    if (exhibition.images != null && exhibition.images!.isNotEmpty) {
      return exhibition.images!.first;
    }
    
    // 2. 备用：使用 coverImage 字段
    if (exhibition.coverImage != null && exhibition.coverImage!.isNotEmpty) {
      return exhibition.coverImage;
    }
    
    return null;
  }

  /// 构建默认背景
  Widget _buildDefaultBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: Center(
        child: Icon(
          Icons.museum,
          color: AppColors.textWhite.withValues(alpha: 0.7),
          size: AppDimensions.iconSizeLarge,
        ),
      ),
    );
  }

  /// 构建叠加标签
  Widget _buildOverlayTag(String text, Color backgroundColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }



  /// 展览点击
  void _onExhibitionTap(Exhibition exhibition) {
    context.push('${AppConstants.routeExhibitionDetail}?id=${exhibition.id}');
  }
}

