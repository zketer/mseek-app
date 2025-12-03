import 'package:json_annotation/json_annotation.dart';

part 'announcement.g.dart';

/// 时间戳转换器 - 将毫秒时间戳转换为 DateTime
class TimestampConverter implements JsonConverter<DateTime?, int?> {
  const TimestampConverter();

  @override
  DateTime? fromJson(int? timestamp) {
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  @override
  int? toJson(DateTime? dateTime) {
    return dateTime?.millisecondsSinceEpoch;
  }
}

/// 公告数据模型
@JsonSerializable()
class Announcement {
  final int id;
  final String title;
  final String? content;
  final String? type; // 'GENERAL', 'maintenance', 'activity', 'urgent'
  final int? priority; // 优先级，数字越大优先级越高
  final int? status; // 0=禁用，1=启用
  
  @TimestampConverter()
  final DateTime? publishTime; // 发布时间
  
  final DateTime? startTime; // 开始显示时间
  final DateTime? endTime; // 结束显示时间
  final DateTime? createAt;
  final DateTime? updateAt;

  const Announcement({
    required this.id,
    required this.title,
    this.content,
    this.type,
    this.priority,
    this.status,
    this.publishTime,
    this.startTime,
    this.endTime,
    this.createAt,
    this.updateAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) => _$AnnouncementFromJson(json);
  Map<String, dynamic> toJson() => _$AnnouncementToJson(this);

  /// 获取公告类型对应的显示文本
  String get typeText {
    switch (type) {
      case 'maintenance':
        return '系统维护';
      case 'activity':
        return '活动公告';
      case 'urgent':
        return '紧急通知';
      case 'GENERAL':
      default:
        return '系统公告';
    }
  }
  
  /// 获取公告类型对应的颜色
  String get typeColor {
    switch (type) {
      case 'maintenance':
        return '#faad14'; // 警告橙色
      case 'activity':
        return '#52c41a'; // 成功绿色
      case 'urgent':
        return '#f5222d'; // 错误红色
      case 'GENERAL':
      default:
        return '#1890ff'; // 信息蓝色
    }
  }
  
  /// 获取显示内容（优先显示content，如果没有则显示title）
  String get displayContent => content ?? title;

  /// 格式化发布时间为 年-月-日
  String get formattedPublishDate {
    if (publishTime == null) return '';
    return '${publishTime!.year}-${publishTime!.month.toString().padLeft(2, '0')}-${publishTime!.day.toString().padLeft(2, '0')}';
  }

  /// 复制并更新字段
  Announcement copyWith({
    int? id,
    String? title,
    String? content,
    String? type,
    int? priority,
    int? status,
    DateTime? publishTime,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? createAt,
    DateTime? updateAt,
  }) {
    return Announcement(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      publishTime: publishTime ?? this.publishTime,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      createAt: createAt ?? this.createAt,
      updateAt: updateAt ?? this.updateAt,
    );
  }
}
