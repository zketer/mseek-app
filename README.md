# MSeek-app 文博探索移动应用

<div align="center">

<img src="assets/images/logo.png" width="120" alt="MSeek Logo" style="border-radius: 20px;" />

**基于 Flutter 的跨平台博物馆探索与打卡应用**

探索身边的文化宝藏 · 记录每一次博物馆之旅

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart&logoColor=white)](https://dart.dev/)
[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android-lightgrey.svg)](https://flutter.dev/)
[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](./LICENSE)

</div>

---

## 📱 应用展示

<div align="center">
  <img src="assets/images/image1.jpg" width="250" alt="首页展示" style="margin: 0 10px;" />
  <img src="assets/images/image2.jpg" width="250" alt="发现页面" style="margin: 0 10px;" />
  <img src="assets/images/image3.jpg" width="250" alt="打卡功能" style="margin: 0 10px;" />
</div>

---

## 📋 项目简介

**MSeek-app 文博探索移动应用** 是一款基于 Flutter 开发的跨平台博物馆探索与打卡应用，支持 iOS 和 Android 平台。应用提供博物馆浏览、地理位置打卡、社交分享、成就系统等丰富功能，为用户带来全新的博物馆参观体验。

### ✨ 核心特色

- 🎯 **跨平台开发**: 一套代码同时运行在 iOS 和 Android 平台
- 🚀 **高性能**: 基于 Flutter 框架，提供流畅的用户体验
- 📱 **响应式设计**: 完美适配不同尺寸的移动设备
- 🔄 **状态管理**: 使用 Provider 实现高效的状态管理
- 🌍 **多语言支持**: 支持中英文切换
- 🔒 **安全认证**: JWT 认证，保障用户数据安全

### 🎯 主要功能

#### 🏠 首页模块
- **轮播推荐**: 展示热门博物馆和精选展览
- **系统公告**: 实时推送活动和系统消息
- **快速入口**: 同城博物馆、成就徽章、我的打卡、我的收藏等
- **热门博物馆**: 展示人气博物馆，支持标签筛选
- **最新展览**: 展示正在进行和即将开始的展览

#### 🔍 发现模块
- **全国博物馆**: 浏览全国范围内的博物馆
- **分类筛选**: 按博物馆类型、等级等维度筛选
- **搜索功能**: 支持博物馆名称关键词搜索
- **排序方式**: 人气、评分、距离等多种排序
- **详情查看**: 查看博物馆详细信息、展览、开放时间等

#### ✅ 打卡模块
- **位置定位**: 自动获取用户当前位置
- **附近博物馆**: 显示指定范围内可打卡的博物馆
- **距离筛选**: 支持 1km、5km、10km 范围选择
- **打卡验证**: 基于 GPS 位置验证是否在博物馆附近
- **照片上传**: 拍照记录参观瞬间
- **打卡历史**: 查看个人打卡记录和统计
- **草稿箱**: 暂存未完成的打卡记录

#### 👤 个人中心
- **用户信息**: 展示用户头像、昵称、积分等
- **我的收藏**: 管理收藏的博物馆
- **打卡历史**: 查看历史打卡记录
- **成就徽章**: 查看已获得的成就
- **积分商城**: 使用积分兑换奖品
- **设置中心**: 个人信息设置、隐私设置等

## 🚀 快速开始

### � 环境要求

| 工具/环境 | 版本要求 | 说明 |
|---------|---------|------|
| Flutter SDK | 3.0.0+ | [安装指南](https://flutter.dev/docs/get-started/install) |
| Dart SDK | 3.0.0+ | 包含在 Flutter SDK 中 |
| Android Studio | 2021.3+ 或 VS Code | 开发 IDE |
| Xcode | 14.0+ | 仅 iOS 开发需要 |
| Java | 11+ | Android 开发需要 |
| CocoaPods | 1.11.0+ | iOS 依赖管理 |

### � 安装步骤

1. **克隆项目**
   ```bash
   git clone https://github.com/zketer/mseek-app.git
   cd mseek-app
   ```

2. **安装依赖**
   ```bash
   flutter pub get
   ```

3. **配置环境变量**
   - 复制 `.env.example` 文件为 `.env`
   - 根据实际情况修改配置
   ```bash
   cp .env.example .env
   ```

4. **运行项目**
   - 确保已连接设备或启动模拟器
   ```bash
   # 运行到 iOS 模拟器
   flutter run -d ios
   
   # 运行到 Android 模拟器
   flutter run -d android
   
   # 运行到已连接的设备
   flutter run
   ```

5. **构建发布版本**
   ```bash
   # 构建 Android APK
   flutter build apk --release
   
   # 构建 Android App Bundle (Google Play 上架)
   flutter build appbundle
   
   # 构建 iOS 应用
   flutter build ios --release
   ```

> **注意**: 发布到应用商店需要配置相应的开发者账号和证书

## 📁 项目结构

```
mseek-app/
├── lib/                       # Flutter 应用代码
│   ├── main.dart             # 应用入口文件
│   │
│   ├── core/                 # 核心功能
│   │   ├── config/          # 配置文件 - API地址、超时时间等
│   │   ├── constants/       # 常量定义
│   │   ├── services/        # 核心服务 - HTTP、认证、位置等
│   │   ├── utils/           # 工具函数
│   │   └── widgets/         # 通用组件
│   │
│   ├── screens/             # 页面目录
│   │   ├── home/           # 首页 - 轮播图、公告、热门博物馆、最新展览
│   │   ├── discovery/      # 发现页 - 全国博物馆列表、搜索、筛选
│   │   ├── checkin/        # 打卡页 - 附近博物馆、打卡功能
│   │   ├── profile/        # 个人中心 - 用户信息、收藏、历史
│   │   ├── login/          # 登录页 - 认证登录
│   │   ├── museum/         # 博物馆相关页面
│   │   │   ├── detail/    # 博物馆详情
│   │   │   ├── list/      # 博物馆列表
│   │   │   └── nearby/    # 附近博物馆
│   │   ├── exhibition/     # 展览相关页面
│   │   │   ├── detail/    # 展览详情
│   │   │   └── list/      # 展览列表
│   │   ├── user/           # 用户相关页面
│   │   │   ├── profile/   # 个人资料
│   │   │   ├── favorites/ # 我的收藏
│   │   │   └── history/   # 打卡历史
│   │   ├── achievements/   # 成就徽章页
│   │   ├── checkin_action/ # 打卡操作页
│   │   ├── checkin_detail/ # 打卡详情页
│   │   ├── draft_list/     # 草稿箱
│   │   ├── search/         # 搜索页
│   │   ├── map/            # 地图页
│   │   ├── settings/       # 设置页
│   │   └── ...             # 其他页面
│   │
│   ├── services/            # API 服务层
│   │   ├── auth_service.dart       # 认证服务 - 登录、登出、token管理
│   │   └── museum_service.dart     # 博物馆服务 - 博物馆、展览、打卡等API
│   │
│   ├── models/              # 数据模型
│   ├── providers/           # 状态管理 (Provider)
│   ├── widgets/             # 自定义组件
│   └── utils/               # 工具函数
│
├── assets/                  # 静态资源文件
│   ├── images/             # 图片资源
│   ├── icons/              # 应用图标
│   └── fonts/              # 字体文件
│
├── android/                # Android 平台特定代码
├── ios/                    # iOS 平台特定代码
├── web/                    # Web 平台特定代码
├── linux/                  # Linux 平台特定代码
├── macos/                  # macOS 平台特定代码
├── windows/                # Windows 平台特定代码
│
├── test/                   # 测试代码
│   ├── unit/              # 单元测试
│   ├── widget/            # 组件测试
│   └── integration_test/  # 集成测试
│
├── .gitignore             # Git 忽略配置
├── analysis_options.yaml  # 代码分析配置
├── pubspec.lock           # 依赖锁定文件
├── pubspec.yaml           # 项目配置文件
└── README.md              # 项目说明文档
```

## 🔧 技术栈

### 前端技术

| 技术 | 说明 | 版本 |
|-----|------|------|
| Flutter | 跨平台 UI 框架 | 3.0.0+ |
| Dart | 编程语言 | 3.0.0+ |

### 核心能力

- **网络请求**: 基于 `Dio` 封装的 HTTP 客户端
- **状态管理**: 使用 `Provider` 实现高效的状态管理
- **路由管理**: 使用 `GoRouter` 进行声明式路由管理
- **权限管理**: 基于 `permission_handler` 的权限控制
- **位置服务**: 使用 `geolocator` 的 GPS 定位 API
- **本地存储**: 使用 `shared_preferences` 和 `flutter_secure_storage`

## 📝 开发规范

### 命名规范

| 类型 | 规范 | 示例 |
|-----|------|------|
| 页面目录 | 小写短横线分隔 | `museum-detail/` |
| 组件目录 | 小写短横线分隔 | `museum-card/` |
| Dart 文件 | 小驼峰命名 | `museumService.dart` |
| 接口定义 | 大驼峰命名 | `class Museum {}` |
| 常量 | 大写下划线分隔 | `API_BASE_URL` |

### 代码规范

- ✅ 使用 Dart 官方代码规范
- ✅ 遵循 Flutter 开发最佳实践
- ✅ 统一使用 2 空格缩进
- ✅ 使用 async/await 处理异步操作
- ✅ 添加必要的注释和文档
- ✅ 错误处理要完善，避免程序崩溃

### 提交规范

```bash
# 功能开发
git commit -m "feat: 添加博物馆详情页"

# Bug 修复
git commit -m "fix: 修复打卡距离计算错误"

# 文档更新
git commit -m "docs: 更新 README 文档"

# 样式调整
git commit -m "style: 优化首页布局"
```

## ⚙️ 配置说明

### 1. 环境配置

编辑 `lib/core/config/env.dart`：

```dart
// 开发环境
const developmentConfig = {
  'apiBaseUrl': 'http://localhost:8000',  // 本地开发服务器
  'timeout': 10000,
  'debug': true,
  'name': '开发环境'
};

// 生产环境
const productionConfig = {
  'apiBaseUrl': 'https://api.your-domain.com',  // 生产服务器
  'timeout': 15000,
  'debug': false,
  'name': '生产环境'
};
```

### 2. 权限配置

#### Android 配置

在 `android/app/src/main/AndroidManifest.xml` 中配置权限：

```xml
<manifest>
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
</manifest>
```

#### iOS 配置

在 `ios/Runner/Info.plist` 中配置权限：

```xml
<key>NSCameraUsageDescription</key>
<string>需要访问相机以拍摄博物馆照片</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>需要获取您的位置以查找附近的博物馆</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>需要访问相册以选择照片</string>
```

### 3. 第三方服务配置

- **微信登录**: 配置 App ID 和 Universal Link
- **支付宝登录**: 配置 App ID 和 Scheme
- **高德地图**: 配置 iOS 和 Android 的 API Key

## 🐛 常见问题

### 1. 依赖安装失败

**问题**: `flutter pub get` 失败或下载缓慢

**解决方案**:
```bash
# 清理缓存
flutter clean
flutter pub cache repair

# 重新获取依赖
flutter pub get

# 使用国内镜像（可选）
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
```

### 2. iOS 构建失败

**问题**: iOS 构建时报错

**解决方案**:
```bash
# 清理 iOS 构建缓存
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..

# 重新构建
flutter clean
flutter build ios

# 如果还是失败，尝试更新 CocoaPods
sudo gem install cocoapods
pod repo update
```

### 3. Android 构建失败

**问题**: Android 构建时报错

**解决方案**:
```bash
# 清理 Android 构建缓存
cd android
./gradlew clean
cd ..

# 重新构建
flutter clean
flutter build apk

# 如果是 Gradle 下载慢，配置国内镜像
# 编辑 android/build.gradle，添加阿里云镜像
```

### 4. 定位权限问题

**问题**: 无法获取位置信息

**解决方案**:
1. 检查 `AndroidManifest.xml` 和 `Info.plist` 中的权限配置
2. 确保已请求运行时权限
3. 在真机上测试（模拟器可能不支持定位）

### 5. 图片上传失败

**问题**: 图片选择或上传失败

**解决方案**:
1. 检查相机和相册权限
2. 确认后端接口是否正常
3. 检查图片大小是否超过限制

### 6. 第三方登录失败

**问题**: 微信或支付宝登录失败

**解决方案**:
1. 检查 App ID 和 App Secret 配置
2. 确认包名和签名是否正确
3. 在真机上测试（模拟器不支持第三方登录）

---

## 📚 相关文档

### 📖 项目文档

- 📘 **开发文档**: 详细的开发指南和最佳实践
- 📗 **API 对接说明**: 后端 API 接口文档

### 🔗 外部资源

| 资源 | 链接 | 说明 |
|-----|------|------|
| Flutter 官方文档 | [查看](https://flutter.dev/docs) | Flutter 开发指南 |
| Dart 官方文档 | [查看](https://dart.dev/guides) | Dart 语言参考 |
| Provider 文档 | [查看](https://pub.dev/packages/provider) | 状态管理库 |
| GoRouter 文档 | [查看](https://pub.dev/packages/go_router) | 路由管理库 |

---

## 🤝 贡献指南

欢迎贡献代码、提出问题和建议！

### 贡献流程

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'feat: 添加某个功能'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 提交 Pull Request

### 问题反馈

- 🐛 **Bug 反馈**: [提交 Issue](https://github.com/zketer/mseek-app/issues)
- 💡 **功能建议**: [提交 Issue](https://github.com/zketer/mseek-app/issues)
- 💬 **技术讨论**: [GitHub Discussions](https://github.com/zketer/mseek-app/discussions)

---

## 👥 开发团队

- **项目维护**: zlynn
- **联系邮箱**: museumseek@163.com
- **GitHub**: [@zketer](https://github.com/zketer)

---

## 📄 开源协议

本项目采用 [Apache License 2.0](./LICENSE) 开源协议

```
Apache License 2.0

Copyright (c) 2024 MSeek Team

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

---

## 🌟 致谢

感谢所有为这个项目做出贡献的开发者！

如果这个项目对你有帮助，欢迎 Star ⭐️

---

<div align="center">

**MSeek 博物馆打卡应用**

探索文化 · 记录足迹 · 分享美好

Made with ❤️ by zlynn

---

**最后更新**: 2025-12-03  
**当前版本**: v0.0.1-beta

</div>
