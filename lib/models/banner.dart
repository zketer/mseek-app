import 'package:json_annotation/json_annotation.dart';

part 'banner.g.dart';

/// 轮播图数据模型
@JsonSerializable()
class Banner {
  final int id;
  final String title;
  final String? subtitle;
  final String imageUrl;
  final String? linkType; // 'none', 'museum', 'exhibition', 'external'
  final String? linkValue; // 链接值
  final int? sortOrder;
  final int? status; // 0=禁用，1=启用
  final DateTime? createAt;
  final DateTime? updateAt;

  const Banner({
    required this.id,
    required this.title,
    this.subtitle,
    required this.imageUrl,
    this.linkType,
    this.linkValue,
    this.sortOrder,
    this.status,
    this.createAt,
    this.updateAt,
  });

  factory Banner.fromJson(Map<String, dynamic> json) => _$BannerFromJson(json);
  Map<String, dynamic> toJson() => _$BannerToJson(this);

  /// 是否有链接
  bool get hasLink => linkType != null && linkType != 'none' && linkValue != null;
  
  /// 获取跳转路径（用于Flutter路由）
  String? get routePath {
    if (!hasLink) return null;
    
    switch (linkType) {
      case 'museum':
        return '/museum/$linkValue';
      case 'exhibition':
        return '/exhibition-detail?id=$linkValue';
      case 'external':
        // 外部链接暂时不处理
        return null;
      default:
        return null;
    }
  }

  /// 复制并更新字段
  Banner copyWith({
    int? id,
    String? title,
    String? subtitle,
    String? imageUrl,
    String? linkType,
    String? linkValue,
    int? sortOrder,
    int? status,
    DateTime? createAt,
    DateTime? updateAt,
  }) {
    return Banner(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      imageUrl: imageUrl ?? this.imageUrl,
      linkType: linkType ?? this.linkType,
      linkValue: linkValue ?? this.linkValue,
      sortOrder: sortOrder ?? this.sortOrder,
      status: status ?? this.status,
      createAt: createAt ?? this.createAt,
      updateAt: updateAt ?? this.updateAt,
    );
  }
}
