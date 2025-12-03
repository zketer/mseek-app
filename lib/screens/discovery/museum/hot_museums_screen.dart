import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/museum.dart';
import '../../../services/api/museum_service.dart';
import '../../../widgets/common/toast_widget.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';

/// 热门博物馆列表页面
/// 对齐小程序样式和功能：支持搜索、两列网格布局、懒加载
class HotMuseumsScreen extends StatefulWidget {
  const HotMuseumsScreen({super.key});

  @override
  State<HotMuseumsScreen> createState() => _HotMuseumsScreenState();
}

class _HotMuseumsScreenState extends State<HotMuseumsScreen> {
  final MuseumService _museumService = MuseumService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<Museum> _museums = [];
  int _currentPage = 1;
  final int _pageSize = 10;
  int _total = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  String _searchKeyword = '';

  @override
  void initState() {
    super.initState();
    _loadHotMuseums(isRefresh: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// 滚动监听 - 无限滚动
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _loadHotMuseums(isRefresh: false);
      }
    }
  }

  /// 加载热门博物馆数据
  Future<void> _loadHotMuseums({required bool isRefresh}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final page = isRefresh ? 1 : _currentPage + 1;

      // DEBUG: print('🔥 [热门博物馆] 加载数据 - 页码: $page, 搜索: $_searchKeyword');

      final response = await _museumService.getHotMuseums(
        page: page,
        pageSize: _pageSize,
        name: _searchKeyword.isNotEmpty ? _searchKeyword : null,
      );

      if (mounted) {
        setState(() {
          if (isRefresh) {
            _museums = response.records;
            _currentPage = 1;
          } else {
            _museums.addAll(response.records);
            _currentPage = page;
          }
          _total = response.total;
          _hasMore = (_museums.length < response.total);
          _isLoading = false;
        });
        // DEBUG: print('✅ [热门博物馆] 加载成功 - 总数: $_total, 当前: ${_museums.length}');
      }
    } catch (e) {
      // DEBUG: print('❌ [热门博物馆] 加载失败: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ToastWidget.showError(
          context,
          '加载失败: ${e.toString().split(':').last.trim()}',
        );
      }
    }
  }

  /// 搜索输入
  void _onSearchInput(String value) {
    setState(() {
      _searchKeyword = value.trim();
    });
  }

  /// 搜索确认
  void _onSearchConfirm() {
    // DEBUG: print('🔍 [热门博物馆] 搜索: $_searchKeyword');
    _loadHotMuseums(isRefresh: true);
  }

  /// 清除搜索
  void _onSearchClear() {
    setState(() {
      _searchKeyword = '';
      _searchController.clear();
    });
    _loadHotMuseums(isRefresh: true);
  }

  /// 博物馆点击
  void _onMuseumTap(Museum museum) {
    context.push('/museum/${museum.id}');
  }

  /// 处理返回按钮
  void _handleBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          context.go('/');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(),
        body: _buildBody(),
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
      title: const Text(
        '热门博物馆',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: AppColors.textPrimary),
          onPressed: _navigateToSearch,
        ),
      ],
    );
  }

  /// 构建页面主体
  Widget _buildBody() {
    if (_isLoading && _museums.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Column(
      children: [
        // 博物馆列表
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _loadHotMuseums(isRefresh: true),
            color: AppColors.primaryLight, // 浅粉色刷新指示器，与首页一致
            child: ListView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              children: [
                if (_museums.isEmpty)
                  _buildEmptyState()
                else ...[
                  _buildMuseumsGrid(),
                  if (_isLoading && _hasMore) _buildLoadingMore(),
                  if (!_hasMore && _museums.isNotEmpty) _buildNoMore(),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }



  /// 构建博物馆网格
  Widget _buildMuseumsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.90, // 调整高宽比，匹配增大的图片高度
      ),
      itemCount: _museums.length,
      itemBuilder: (context, index) {
        return _buildMuseumCard(_museums[index], index);
      },
    );
  }

  /// 构建博物馆卡片 - 图片为主导的设计
  Widget _buildMuseumCard(Museum museum, int index) {
    return GestureDetector(
      onTap: () => _onMuseumTap(museum),
      child: Container(
        height: 160, // 保持合适的卡片高度
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // 背景图片
              Positioned.fill(
                child: _buildMuseumImage(museum),
              ),
              // 渐变遮罩
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.3),
                        Colors.black.withValues(alpha: 0.7),
                      ],
                      stops: const [0.0, 0.4, 0.7, 1.0],
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
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 博物馆名称
                      Text(
                        museum.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
                      const SizedBox(height: 4),
                      // 地址信息
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 12,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              museum.address ?? museum.cityName ?? '地址未知',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white70,
                                shadows: [
                                  Shadow(
                                    offset: Offset(0, 1),
                                    blurRadius: 2,
                                    color: Colors.black54,
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // 标签
                      Row(
                        children: [
                          if (museum.categories != null && museum.categories!.isNotEmpty)
                            _buildOverlayTag(museum.categories!.first.name, AppColors.primary),
                          if (museum.level == 1) ...[
                            const SizedBox(width: 4),
                            _buildOverlayTag('一级博物馆', AppColors.warning),
                          ],
                          if (museum.freeAdmission == 1) ...[
                            const SizedBox(width: 4),
                            _buildOverlayTag('免费参观', AppColors.success),
                          ],
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

  /// 构建博物馆图片 - 全尺寸背景
  Widget _buildMuseumImage(Museum museum) {
    final imageUrl = museum.imageUrls?.isNotEmpty == true
        ? museum.imageUrls!.first
        : museum.imageUrl;

    return imageUrl != null && imageUrl.isNotEmpty
        ? CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            memCacheWidth: 400,
            memCacheHeight: 320,
            errorWidget: (context, url, error) => _buildDefaultBackground(),
          )
        : _buildDefaultBackground();
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
          color: Colors.white.withValues(alpha: 0.7),
          size: AppDimensions.iconSizeLarge,
        ),
      ),
    );
  }

  /// 构建叠加标签
  Widget _buildOverlayTag(String text, Color backgroundColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// 显示全屏搜索
  void _navigateToSearch() {
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
              hintText: '搜索热门博物馆...',
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
                  '热门搜索',
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
                  _buildSearchTag('故宫博物院'),
                  _buildSearchTag('中国国家博物馆'),
                  _buildSearchTag('上海博物馆'),
                  _buildSearchTag('南京博物院'),
                  _buildSearchTag('陕西历史博物馆'),
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

  /// 构建加载更多
  Widget _buildLoadingMore() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
          SizedBox(width: 10),
          Text(
            '加载更多...',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  /// 构建没有更多
  Widget _buildNoMore() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Text(
          '已显示全部热门博物馆',
          style: TextStyle(fontSize: 13, color: AppColors.textHint),
        ),
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 100),
        child: Column(
          children: [
            const Text(
              '🏛️',
              style: TextStyle(fontSize: 60),
            ),
            const SizedBox(height: 15),
            const Text(
              '暂无热门博物馆',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '还没有用户打卡记录',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _onSearchClear,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                '清除搜索',
                style: TextStyle(fontSize: 14, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

