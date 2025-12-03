import 'package:json_annotation/json_annotation.dart';

part 'museum.g.dart';

/// 博物馆数据模型
@JsonSerializable()
class Museum {
  final int id;
  final String name;
  final String? address;
  final double? longitude;
  final double? latitude;
  final String? openTime;
  final double? ticketPrice;
  final String? ticketDescription; // 门票说明
  final int? freeAdmission; // 0=收费，1=免费
  final int? level; // 博物馆等级
  final String? phone;
  final String? website;
  final String? description;
  final int? capacity; // 日接待能力
  final int? collectionCount; // 藏品总数
  final int? preciousItems; // 珍贵文物数量
  final int? exhibitions; // 年度展览数量
  final String? coverImage;
  final String? imageUrl;
  final double? rating;
  final int? visitCount;
  final int? status; // 0=禁用，1=启用
  final List<MuseumCategory>? categories;
  final List<TagInfo>? tags;
  final String? cityCode;
  final String? cityName;
  final String? districtCode; // 区县代码
  final String? districtName; // 区县名称
  final String? provinceCode;
  final String? provinceName;
  final String? type; // 博物馆类型
  final int? educationActivities; // 教育活动数量
  final int? annualVisitors; // 年度访客数
  final List<String>? imageUrls; // 图片URL列表
  
  // 客户端计算字段
  final String? distance; // 距离用户的距离
  final bool? isFavorite; // 是否收藏
  final bool? isCheckedIn; // 是否已打卡

  const Museum({
    required this.id,
    required this.name,
    this.address,
    this.longitude,
    this.latitude,
    this.openTime,
    this.ticketPrice,
    this.ticketDescription,
    this.freeAdmission,
    this.level,
    this.phone,
    this.website,
    this.description,
    this.capacity,
    this.collectionCount,
    this.preciousItems,
    this.exhibitions,
    this.coverImage,
    this.imageUrl,
    this.rating,
    this.visitCount,
    this.status,
    this.categories,
    this.tags,
    this.cityCode,
    this.cityName,
    this.districtCode,
    this.districtName,
    this.provinceCode,
    this.provinceName,
    this.type,
    this.educationActivities,
    this.annualVisitors,
    this.imageUrls,
    this.distance,
    this.isFavorite,
    this.isCheckedIn,
  });

  factory Museum.fromJson(Map<String, dynamic> json) => _$MuseumFromJson(json);
  Map<String, dynamic> toJson() => _$MuseumToJson(this);

  /// 是否免费参观
  bool get isFree => freeAdmission == 1;
  
  /// 获取格式化票价
  String get formattedPrice {
    if (isFree) return '免费';
    if (ticketPrice == null || ticketPrice! <= 0) return '暂无信息';
    return '¥${ticketPrice!.toStringAsFixed(0)}';
  }
  
  /// 获取博物馆等级名称
  String get levelName {
    if (level == null || level! <= 0) return '';
    const levelNames = ['', '一级博物馆', '二级博物馆', '三级博物馆', '四级博物馆', '五级博物馆'];
    return level! < levelNames.length ? levelNames[level!] : '${level!}级博物馆';
  }

  /// 复制并更新字段
  Museum copyWith({
    int? id,
    String? name,
    String? address,
    double? longitude,
    double? latitude,
    String? openTime,
    double? ticketPrice,
    String? ticketDescription,
    int? freeAdmission,
    int? level,
    String? phone,
    String? website,
    String? description,
    int? capacity,
    int? collectionCount,
    int? preciousItems,
    int? exhibitions,
    String? coverImage,
    String? imageUrl,
    double? rating,
    int? visitCount,
    int? status,
    List<MuseumCategory>? categories,
    List<TagInfo>? tags,
    String? cityCode,
    String? cityName,
    String? districtCode,
    String? districtName,
    String? provinceCode,
    String? provinceName,
    String? type,
    int? educationActivities,
    int? annualVisitors,
    List<String>? imageUrls,
    String? distance,
    bool? isFavorite,
    bool? isCheckedIn,
  }) {
    return Museum(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      longitude: longitude ?? this.longitude,
      latitude: latitude ?? this.latitude,
      openTime: openTime ?? this.openTime,
      ticketPrice: ticketPrice ?? this.ticketPrice,
      ticketDescription: ticketDescription ?? this.ticketDescription,
      freeAdmission: freeAdmission ?? this.freeAdmission,
      level: level ?? this.level,
      phone: phone ?? this.phone,
      website: website ?? this.website,
      description: description ?? this.description,
      capacity: capacity ?? this.capacity,
      collectionCount: collectionCount ?? this.collectionCount,
      preciousItems: preciousItems ?? this.preciousItems,
      exhibitions: exhibitions ?? this.exhibitions,
      coverImage: coverImage ?? this.coverImage,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      visitCount: visitCount ?? this.visitCount,
      status: status ?? this.status,
      categories: categories ?? this.categories,
      tags: tags ?? this.tags,
      cityCode: cityCode ?? this.cityCode,
      cityName: cityName ?? this.cityName,
      districtCode: districtCode ?? this.districtCode,
      districtName: districtName ?? this.districtName,
      provinceCode: provinceCode ?? this.provinceCode,
      provinceName: provinceName ?? this.provinceName,
      type: type ?? this.type,
      educationActivities: educationActivities ?? this.educationActivities,
      annualVisitors: annualVisitors ?? this.annualVisitors,
      imageUrls: imageUrls ?? this.imageUrls,
      distance: distance ?? this.distance,
      isFavorite: isFavorite ?? this.isFavorite,
      isCheckedIn: isCheckedIn ?? this.isCheckedIn,
    );
  }
}

/// 博物馆分类
@JsonSerializable()
class MuseumCategory {
  final int id;
  final String name;
  final String code;
  final String? description;

  const MuseumCategory({
    required this.id,
    required this.name,
    required this.code,
    this.description,
  });

  factory MuseumCategory.fromJson(Map<String, dynamic> json) => _$MuseumCategoryFromJson(json);
  Map<String, dynamic> toJson() => _$MuseumCategoryToJson(this);
}

/// 标签信息
@JsonSerializable()
class TagInfo {
  final int id;
  final String name;
  final String code;
  final String? color;

  const TagInfo({
    required this.id,
    required this.name,
    required this.code,
    this.color,
  });

  factory TagInfo.fromJson(Map<String, dynamic> json) => _$TagInfoFromJson(json);
  Map<String, dynamic> toJson() => _$TagInfoToJson(this);
}
