import 'package:json_annotation/json_annotation.dart';
import '../core/utils/date_utils.dart';

part 'exhibition.g.dart';

/// 展览数据模型
@JsonSerializable()
class Exhibition {
  final int id;
  final String title;
  final String? subtitle;
  final String? description;
  final String? coverImage;
  final String? startDate;
  final String? endDate;
  final int? isPermanent; // 0=临时展览，1=常设展览
  final int? museumId;
  final String? museumName;
  final String? location;
  final double? ticketPrice;
  final int? freeAdmission; // 0=收费，1=免费
  final int? enabled; // 0=禁用，1=启用 (重命名避免冲突)
  @JsonKey(name: 'imageUrls') // API返回的字段名是imageUrls
  final List<String>? images;
  final int? viewCount;
  final DateTime? createAt;
  final DateTime? updateAt;

  const Exhibition({
    required this.id,
    required this.title,
    this.subtitle,
    this.description,
    this.coverImage,
    this.startDate,
    this.endDate,
    this.isPermanent,
    this.museumId,
    this.museumName,
    this.location,
    this.ticketPrice,
    this.freeAdmission,
    this.enabled,
    this.images,
    this.viewCount,
    this.createAt,
    this.updateAt,
  });

  factory Exhibition.fromJson(Map<String, dynamic> json) => _$ExhibitionFromJson(json);
  Map<String, dynamic> toJson() => _$ExhibitionToJson(this);

  /// 是否为常设展览
  bool get isPermament => isPermanent == 1;
  
  /// 是否免费参观
  bool get isFree => freeAdmission == 1;
  
  /// 获取格式化票价
  String get formattedPrice {
    if (isFree) return '免费';
    if (ticketPrice == null || ticketPrice! <= 0) return '暂无信息';
    return '¥${ticketPrice!.toStringAsFixed(0)}';
  }
  
  /// 获取展览状态
  String get exhibitionStatus {
    if (isPermament) return '进行中'; // 匹配小程序逻辑：常设展览显示为"进行中"
    
    if (startDate == null || endDate == null) return '时间待定';
    
    final now = DateTime.now();
    final start = DateTime.parse(startDate!);
    final end = DateTime.parse(endDate!);
    
    if (now.isBefore(start)) {
      return '即将开始';
    } else if (now.isAfter(end)) {
      return '已结束';
    } else {
      return '进行中';
    }
  }
  
  /// 获取格式化日期
  String get formattedDateRange {
    if (isPermament) return '长期展出';
    
    if (startDate == null || endDate == null) return '时间待定';
    
    final start = DateTime.parse(startDate!);
    final end = DateTime.parse(endDate!);
    
    return AppDateUtils.formatDateRange(start, end);
  }
  
  /// 格式化开始日期 (例如: 10月21日)
  String get formattedStartDate {
    if (startDate == null) return '';
    try {
      final date = DateTime.parse(startDate!);
      return AppDateUtils.formatShortDate(date);
    } catch (e) {
      return startDate!;
    }
  }

  /// 格式化结束日期 (例如: 10月21日)
  String get formattedEndDate {
    if (endDate == null) return '';
    try {
      final date = DateTime.parse(endDate!);
      return AppDateUtils.formatShortDate(date);
    } catch (e) {
      return endDate!;
    }
  }
  
  /// 获取展览状态别名，用于向后兼容
  String get status => exhibitionStatus;
  
  /// 获取状态颜色
  String get statusColor {
    switch (exhibitionStatus) {
      case '进行中':
      case '常设展览':
        return '#52c41a'; // 绿色
      case '即将开始':
        return '#1890ff'; // 蓝色
      case '已结束':
        return '#8c8c8c'; // 灰色
      default:
        return '#8c8c8c'; // 默认灰色
    }
  }

  /// 复制并更新字段
  Exhibition copyWith({
    int? id,
    String? title,
    String? subtitle,
    String? description,
    String? coverImage,
    String? startDate,
    String? endDate,
    int? isPermanent,
    int? museumId,
    String? museumName,
    String? location,
    double? ticketPrice,
    int? freeAdmission,
    int? enabled,
    List<String>? images,
    int? viewCount,
    DateTime? createAt,
    DateTime? updateAt,
  }) {
    return Exhibition(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      coverImage: coverImage ?? this.coverImage,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isPermanent: isPermanent ?? this.isPermanent,
      museumId: museumId ?? this.museumId,
      museumName: museumName ?? this.museumName,
      location: location ?? this.location,
      ticketPrice: ticketPrice ?? this.ticketPrice,
      freeAdmission: freeAdmission ?? this.freeAdmission,
      enabled: enabled ?? this.enabled,
      images: images ?? this.images,
      viewCount: viewCount ?? this.viewCount,
      createAt: createAt ?? this.createAt,
      updateAt: updateAt ?? this.updateAt,
    );
  }
}
