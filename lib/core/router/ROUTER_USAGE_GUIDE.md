# 路由系统使用指南

> Flutter mseek 应用统一路由管理方案
> 基于 go_router + 参考小程序最佳实践

## 📋 目录

- [快速开始](#快速开始)
- [基础路由操作](#基础路由操作)
- [登录守卫](#登录守卫)
- [路由扩展方法](#路由扩展方法)
- [最佳实践](#最佳实践)
- [迁移指南](#迁移指南)

---

## 快速开始

### 1. 导入必要的包

```dart
import 'package:go_router/go_router.dart';
import '../../core/router/auth_guard.dart';
import '../../core/router/router_extensions.dart';
```

### 2. 基本页面跳转

```dart
// ✅ 推荐：使用扩展方法
context.goToMuseumDetail(123);
context.goToCheckinAction(456);

// ✅ 或者直接使用 go_router API
context.push('/museum/123');
context.go('/checkin');

// ❌ 避免使用旧式 Navigator API
Navigator.push(context, MaterialPageRoute(...));  // 不要这样用
```

### 3. 页面返回

```dart
// ✅ 推荐：使用 context.pop()
context.pop();

// ✅ 安全返回（如果无法返回则跳转到首页）
context.safePop();

// ⚠️ 对话框中可以使用 Navigator.pop
showDialog(
  context: context,
  builder: (dialogContext) => AlertDialog(
    actions: [
      TextButton(
        onPressed: () => Navigator.of(dialogContext).pop(),  // 这里可以用 Navigator
        child: Text('取消'),
      ),
    ],
  ),
);
```

---

## 基础路由操作

### 页面跳转

```dart
// 方式 1：使用路径
context.push('/museum/123');
context.go('/checkin');

// 方式 2：使用命名路由
context.pushNamed('museum-detail', pathParameters: {'id': '123'});
context.goNamed('login');

// 方式 3：使用扩展方法（推荐）
context.goToMuseumDetail(123);
context.goToCheckinAction(456, draftId: 789);
```

### go() vs push()

```dart
// go() - 替换当前路由栈
context.go('/profile');  // 用于主导航，清空历史

// push() - 保留历史，可以返回
context.push('/museum/123');  // 用于详情页，需要返回
```

### 返回操作

```dart
// 普通返回
context.pop();

// 带返回值
context.pop(result);

// 安全返回
context.safePop();  // 如果无法返回则跳转到首页

// 判断是否可以返回
if (context.canPop()) {
  context.pop();
}
```

---

## 登录守卫

### 1. 页面级登录验证

适用于整个页面都需要登录的场景：

```dart
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }
  
  Future<void> _checkAuth() async {
    // 检查页面访问权限
    final isAuthorized = await checkPageAuth(context, '我的收藏');
    if (!isAuthorized && mounted) {
      // 未登录会自动跳转到登录页，登录成功后会自动返回
      return;
    }
    
    // 已登录，继续加载数据
    _loadData();
  }
  
  void _loadData() {
    // 加载收藏数据
  }
}
```

### 2. 功能级登录验证

适用于页面内某个功能需要登录：

```dart
class ProfileScreen extends StatelessWidget {
  void _onFavoriteTap(BuildContext context) async {
    // 检查收藏功能权限
    final isLoggedIn = await AuthGuards.favorites(context);
    if (!isLoggedIn) {
      // 未登录会自动显示登录提示，用户点击"去登录"后跳转
      return;
    }
    
    // 已登录，跳转到收藏页面
    context.goToFavorites();
  }
  
  void _onAchievementTap(BuildContext context) async {
    // 使用预配置守卫
    if (await AuthGuards.achievements(context)) {
      // 已登录，继续操作
      context.goToAchievements();
    }
  }
}
```

### 3. 操作级登录验证

适用于需要登录后执行特定操作（如收藏、点赞）：

```dart
class MuseumDetailScreen extends StatelessWidget {
  Future<void> _onFavoriteButtonTap(BuildContext context) async {
    final isLoggedIn = await requireAuthForAction(
      context,
      '收藏博物馆',
      onSuccess: () {
        // 登录成功后执行收藏操作
        _addToFavorites();
      },
    );
    
    if (isLoggedIn) {
      // 已登录，直接执行操作
      _addToFavorites();
    }
  }
  
  void _addToFavorites() {
    // 收藏逻辑
  }
}
```

### 4. 自定义登录验证

```dart
Future<void> _onVipFeature(BuildContext context) async {
  final isLoggedIn = await requireAuth(
    context,
    options: AuthGuardOptions(
      title: 'VIP功能',
      content: '此功能需要登录后才能使用，立即登录享受VIP服务？',
      confirmText: '立即登录',
      showCancel: true,
      targetPath: '/vip-feature',  // 登录成功后跳转到这里
      onCancel: () {
        debugPrint('用户取消登录');
      },
    ),
  );
  
  if (isLoggedIn) {
    // 执行VIP功能
  }
}
```

### 5. 静默登录验证

不显示提示弹窗，直接跳转：

```dart
Future<void> _checkLoginSilently(BuildContext context) async {
  final isLoggedIn = await requireAuthSilent(context);
  if (!isLoggedIn) {
    // 已自动跳转到登录页
    return;
  }
  
  // 已登录，继续操作
}
```

### 6. 预配置守卫

系统提供了常用功能的预配置守卫：

```dart
// 成就徽章
await AuthGuards.achievements(context);

// 我的打卡
await AuthGuards.checkin(context);

// 打卡历史
await AuthGuards.history(context);

// 我的收藏
await AuthGuards.favorites(context);

// 个人中心
await AuthGuards.profile(context);

// 设置页面
await AuthGuards.settings(context);
```

### 7. 退出登录

```dart
// 基本退出（显示确认弹窗）
await performLogout(context);

// 自定义退出
await performLogout(
  context,
  options: LogoutOptions(
    showConfirm: true,
    confirmTitle: '确认退出',
    confirmContent: '退出后将清除所有本地数据，确定要退出吗？',
    redirectToHome: true,  // 退出后跳转到首页
    onSuccess: () {
      debugPrint('退出成功');
    },
    onError: (error) {
      debugPrint('退出失败: $error');
    },
  ),
);

// 静默退出（不显示确认弹窗）
await performLogout(
  context,
  options: LogoutOptions(showConfirm: false),
);
```

---

## 路由扩展方法

系统提供了丰富的路由扩展方法，简化常用跳转：

### 博物馆相关

```dart
context.goToMuseumDetail(123);           // 博物馆详情
context.goToNearbyMuseums();             // 同城博物馆
```

### 展览相关

```dart
context.goToExhibitionDetail(456);       // 展览详情
context.goToLatestExhibitions();         // 最新展览
```

### 打卡相关

```dart
context.goToCheckinAction(123);          // 打卡操作
context.goToCheckinAction(123, draftId: 456);  // 编辑草稿
context.goToCheckinHistory();            // 打卡历史
context.goToDraftList();                 // 草稿列表
context.goToCheckinTab();                // 跳转到打卡Tab
```

### 用户相关

```dart
context.goToLogin();                     // 登录页
context.goToLogin(redirectUrl: '/favorites');  // 登录后跳转
context.goToProfile();                   // 个人中心
context.goToFavorites();                 // 收藏夹
context.goToAchievements();              // 成就页面
context.goToSettings();                  // 设置
```

### 区域相关

```dart
context.goToProvinceDetail('110000');    // 省份详情
context.goToCityDetail(                  // 城市详情
  '北京市',
  provinceCode: '110000',
  provinceName: '北京',
);
```

### 其他

```dart
context.goToSearch();                    // 搜索
context.goToAbout();                     // 关于我们
context.goToFeedback();                  // 反馈建议
context.goToQualification();             // 资质证明
context.goToAgreement();                 // 用户协议
context.goToPrivacy();                   // 隐私政策
context.goHome();                        // 返回首页
context.safePop();                       // 安全返回
```

---

## 最佳实践

### 1. AppBar 返回按钮

```dart
// ✅ 推荐：让 go_router 自动处理
AppBar(
  // 不设置 leading，go_router 会自动显示返回按钮
  title: Text('博物馆详情'),
)

// ✅ 或者手动处理（使用 context.pop）
AppBar(
  leading: IconButton(
    icon: Icon(Icons.arrow_back),
    onPressed: () => context.pop(),  // 使用 go_router 的 pop
  ),
  title: Text('博物馆详情'),
)

// ❌ 避免使用 Navigator.pop
AppBar(
  leading: IconButton(
    icon: Icon(Icons.arrow_back),
    onPressed: () => Navigator.pop(context),  // 不要这样用
  ),
)
```

### 2. 对话框中的返回

对话框中可以继续使用 `Navigator.pop`：

```dart
showDialog(
  context: context,
  builder: (dialogContext) => AlertDialog(
    title: Text('确认删除'),
    content: Text('确定要删除这个收藏吗？'),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(dialogContext).pop(false),  // ✅ 这里可以用 Navigator
        child: Text('取消'),
      ),
      TextButton(
        onPressed: () => Navigator.of(dialogContext).pop(true),   // ✅ 这里可以用 Navigator
        child: Text('确定'),
      ),
    ],
  ),
);
```

### 3. 登录后自动返回

系统会自动处理登录后的跳转逻辑：

```dart
// 场景 1：从收藏页面跳转到登录
context.goToFavorites();  // 未登录，自动跳转到登录页

// 用户登录成功后，系统自动跳转回 /favorites

// 场景 2：使用守卫
if (await AuthGuards.favorites(context)) {
  // 已登录，继续操作
}
// 未登录，显示登录提示，用户确认后跳转到登录页
// 登录成功后，自动跳转回 /favorites
```

### 4. 路由参数传递

```dart
// 方式 1：路径参数
context.push('/museum/123');

// 方式 2：查询参数
context.push('/exhibition-detail?id=456');

// 方式 3：extra 参数（用于复杂对象）
context.pushNamed(
  'city-detail',
  pathParameters: {'cityName': 'beijing'},
  extra: {
    'cityName': '北京市',
    'provinceCode': '110000',
    'provinceName': '北京',
  },
);
```

### 5. 判断路由类型

```dart
// 判断是否是Tab页面
if (NavigationHelper.isTabPage('/checkin')) {
  // 是Tab页面
}

// 获取当前路由路径
final currentPath = NavigationHelper.getCurrentPath(context);

// 获取当前完整URL（包含查询参数）
final currentUrl = NavigationHelper.getCurrentUrl(context);
```

---

## 迁移指南

### 从旧式 Navigator API 迁移

| 旧API | 新API | 说明 |
|-------|-------|------|
| `Navigator.push(...)` | `context.push('/path')` | 推送新页面 |
| `Navigator.pushNamed(...)` | `context.pushNamed('name')` | 命名路由 |
| `Navigator.pop(...)` | `context.pop()` | 返回上一页 |
| `Navigator.pushReplacement(...)` | `context.go('/path')` | 替换当前页面 |
| `Navigator.of(context).canPop()` | `context.canPop()` | 判断是否可以返回 |

### 迁移步骤

1. **全局搜索 `Navigator.push`**，替换为 `context.push` 或扩展方法
2. **全局搜索 `Navigator.pop`**，仅替换页面级的返回（对话框保持不变）
3. **添加登录守卫**到需要登录的页面
4. **测试所有路由跳转**，确保返回按钮正常工作

### 示例迁移

**迁移前：**

```dart
// 旧代码
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => MuseumDetailScreen(museumId: 123),
  ),
);

// 返回
Navigator.pop(context);
```

**迁移后：**

```dart
// 新代码
context.goToMuseumDetail(123);

// 返回
context.pop();
```

---

## 常见问题

### Q: 什么时候使用 go()，什么时候使用 push()？

**A:** 
- `go()` - 用于主导航、Tab切换，会清空当前路由栈
- `push()` - 用于详情页、表单页，需要保留返回功能

### Q: AppBar 返回按钮不显示？

**A:** 确保使用 `context.push()` 而非 `context.go()`，go() 会清空历史导致无法返回。

### Q: 登录后无法返回原页面？

**A:** 确保：
1. 使用了 `requireAuth` 或 `AuthGuards`
2. 登录页面正确配置了 `redirectUrl` 参数
3. 登录成功后调用了 `_navigateToTarget()`

### Q: 对话框中应该用什么 pop？

**A:** 对话框中使用 `Navigator.of(dialogContext).pop()`，页面级返回使用 `context.pop()`。

### Q: 如何强制返回首页？

**A:** 使用 `context.go('/')` 或 `context.goHome()`。

---

## 技术对比

| 特性 | 小程序 | Flutter (go_router) |
|------|--------|---------------------|
| 页面跳转 | `wx.navigateTo` | `context.push()` |
| Tab切换 | `wx.switchTab` | `context.go()` |
| 返回 | `wx.navigateBack` | `context.pop()` |
| 替换页面 | `wx.redirectTo` | `context.go()` |
| 重新加载 | `wx.reLaunch` | `context.go()` |
| 登录守卫 | `auth-guard.ts` | `auth_guard.dart` |
| 路由参数 | query/options | queryParameters/extra |

---

## 总结

✅ **推荐做法：**
- 使用 go_router 的 `context.push/pop/go`
- 使用路由扩展方法简化调用
- 使用登录守卫保护需要登录的页面
- AppBar 让系统自动处理返回按钮

❌ **避免做法：**
- 不要在页面级使用 `Navigator.push/pop`
- 不要硬编码路径字符串
- 不要在多个地方重复登录检查逻辑

---

**版本**: v1.0  
**最后更新**: 2024-10-17  
**维护者**: lynn

