import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

/// 辅助函数：同时支持userId和id字段名
Object? _readUserId(Map json, String key) {
  // 优先使用userId，如果不存在则使用id
  return json['userId'] ?? json['id'];
}

/// 时间字段转换器：将后端返回的格式化字符串转换为DateTime
/// 后端通过 @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss", timezone = "GMT+8") 返回时间
/// 支持多种输入类型：String, int(时间戳), Map等
DateTime? _dateTimeFromJson(dynamic dateValue) {
  if (dateValue == null) return null;
  
  try {
    // 1. 如果是字符串，直接解析
    if (dateValue is String) {
      if (dateValue.isEmpty) return null;
      // 支持ISO 8601格式和自定义格式
      return DateTime.parse(dateValue.replaceAll(' ', 'T'));
    }
    
    // 2. 如果是数字（时间戳），转换为DateTime
    if (dateValue is int) {
      return DateTime.fromMillisecondsSinceEpoch(dateValue);
    }
    
    // 3. 如果是Map，可能是复杂对象（不太可能，但做兜底处理）
    if (dateValue is Map) {
      print('⚠️ 时间字段收到Map类型，尝试提取: $dateValue');
      return null;
    }
    
    // 4. 其他类型，尝试转为字符串再解析
    final dateStr = dateValue.toString();
    if (dateStr.isNotEmpty && dateStr != 'null') {
      return DateTime.parse(dateStr.replaceAll(' ', 'T'));
    }
    
    return null;
  } catch (e) {
    print('⚠️ 解析时间字段失败: $dateValue (${dateValue.runtimeType}), 错误: $e');
    return null;
  }
}

/// DateTime转换为字符串（序列化用）
String? _dateTimeToJson(DateTime? dateTime) {
  return dateTime?.toIso8601String();
}

/// 角色数组转换器：将后端返回的角色对象数组转换为角色名称字符串数组
/// 后端返回格式：[{"roleId": 1, "roleName": "超级管理员", "roleCode": "SUPER_ADMIN"}]
/// 转换后格式：["超级管理员"] 或 ["SUPER_ADMIN"]
List<String>? _rolesFromJson(dynamic rolesValue) {
  if (rolesValue == null) return null;
  
  try {
    // 如果已经是字符串数组，直接返回
    if (rolesValue is List<String>) {
      return rolesValue;
    }
    
    // 如果是对象数组，提取roleName或roleCode
    if (rolesValue is List) {
      return rolesValue.map((role) {
        if (role is String) return role;
        if (role is Map) {
          // 优先使用roleCode，其次是roleName
          return (role['roleCode'] ?? role['roleName'] ?? '').toString();
        }
        return role.toString();
      }).where((r) => r.isNotEmpty).toList();
    }
    
    return null;
  } catch (e) {
    print('⚠️ 解析角色字段失败: $rolesValue (${rolesValue.runtimeType}), 错误: $e');
    return null;
  }
}

/// 用户数据模型
/// 
/// 📌 对应后端实体：com.lynn.museum.system.model.entity.User (extends BaseEntity)
/// 📌 审计字段说明：
///    - createAt: 创建时间 (对应后端 create_at)
///    - updateAt: 更新时间 (对应后端 update_at)
///    - 后端使用 Date 类型，通过 @JsonFormat 返回格式化字符串
@JsonSerializable()
class User {
  @JsonKey(readValue: _readUserId) // 同时支持userId和id字段
  final int id;
  final String? username;
  final String? nickname;
  final String? avatar;
  final String? phone;
  final String? email;
  final int? gender; // 0=未知，1=男，2=女
  final String? birthday;
  final String? city;
  final String? province;
  final String? signature;
  final String? bio; // 用户简介，兼容性字段
  final int? points; // 积分
  final int? level; // 用户等级
  final int? checkinCount; // 打卡次数
  final int? visitedMuseumCount; // 参观博物馆数量
  final int? visitedCityCount; // 参观城市数量
  
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime? lastLoginTime;
  
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime? createAt;
  
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime? updateAt;
  
  @JsonKey(fromJson: _rolesFromJson)
  final List<String>? roles; // 用户角色列表（从后端角色对象数组转换）
  
  final List<String>? permissions; // 用户权限列表
  final int? status; // 状态：0=禁用，1=启用

  const User({
    required this.id,
    this.username,
    this.nickname,
    this.avatar,
    this.phone,
    this.email,
    this.gender,
    this.birthday,
    this.city,
    this.province,
    this.signature,
    this.bio,
    this.points,
    this.level,
    this.checkinCount,
    this.visitedMuseumCount,
    this.visitedCityCount,
    this.lastLoginTime,
    this.createAt,
    this.updateAt,
    this.roles,
    this.permissions,
    this.status,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  /// 获取显示名称（优先显示昵称，然后用户名，最后显示默认值）
  String get displayName => nickname ?? username ?? '用户$id';
  
  /// 获取性别文本
  String get genderText {
    switch (gender) {
      case 1:
        return '男';
      case 2:
        return '女';
      default:
        return '未知';
    }
  }
  
  /// 获取头像URL（如果没有则返回默认头像）
  String get avatarUrl => avatar ?? 'assets/images/default_avatar.jpg';
  
  /// 获取积分文本
  String get pointsText => points?.toString() ?? '0';
  
  /// 获取等级文本
  String get levelText {
    if (level == null || level! <= 0) return '新手';
    
    const levelNames = [
      '新手', '青铜', '白银', '黄金', '铂金', 
      '钻石', '大师', '宗师', '传奇'
    ];
    
    return level! < levelNames.length ? levelNames[level!] : '传奇${level! - levelNames.length + 1}';
  }

  /// 复制并更新字段
  User copyWith({
    int? id,
    String? username,
    String? nickname,
    String? avatar,
    String? phone,
    String? email,
    int? gender,
    String? birthday,
    String? city,
    String? province,
    String? signature,
    int? points,
    int? level,
    int? checkinCount,
    int? visitedMuseumCount,
    int? visitedCityCount,
    DateTime? lastLoginTime,
    DateTime? createAt,
    DateTime? updateAt,
    List<String>? roles,
    List<String>? permissions,
    int? status,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      nickname: nickname ?? this.nickname,
      avatar: avatar ?? this.avatar,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      birthday: birthday ?? this.birthday,
      city: city ?? this.city,
      province: province ?? this.province,
      signature: signature ?? this.signature,
      points: points ?? this.points,
      level: level ?? this.level,
      checkinCount: checkinCount ?? this.checkinCount,
      visitedMuseumCount: visitedMuseumCount ?? this.visitedMuseumCount,
      visitedCityCount: visitedCityCount ?? this.visitedCityCount,
      lastLoginTime: lastLoginTime ?? this.lastLoginTime,
      createAt: createAt ?? this.createAt,
      updateAt: updateAt ?? this.updateAt,
      roles: roles ?? this.roles,
      permissions: permissions ?? this.permissions,
      status: status ?? this.status,
    );
  }
}

