// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
      id: (_readUserId(json, 'id') as num).toInt(),
      username: json['username'] as String?,
      nickname: json['nickname'] as String?,
      avatar: json['avatar'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      gender: (json['gender'] as num?)?.toInt(),
      birthday: json['birthday'] as String?,
      city: json['city'] as String?,
      province: json['province'] as String?,
      signature: json['signature'] as String?,
      bio: json['bio'] as String?,
      points: (json['points'] as num?)?.toInt(),
      level: (json['level'] as num?)?.toInt(),
      checkinCount: (json['checkinCount'] as num?)?.toInt(),
      visitedMuseumCount: (json['visitedMuseumCount'] as num?)?.toInt(),
      visitedCityCount: (json['visitedCityCount'] as num?)?.toInt(),
      lastLoginTime: _dateTimeFromJson(json['lastLoginTime']),
      createAt: _dateTimeFromJson(json['createAt']),
      updateAt: _dateTimeFromJson(json['updateAt']),
      roles: _rolesFromJson(json['roles']),
      permissions: (json['permissions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      status: (json['status'] as num?)?.toInt(),
    );

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'nickname': instance.nickname,
      'avatar': instance.avatar,
      'phone': instance.phone,
      'email': instance.email,
      'gender': instance.gender,
      'birthday': instance.birthday,
      'city': instance.city,
      'province': instance.province,
      'signature': instance.signature,
      'bio': instance.bio,
      'points': instance.points,
      'level': instance.level,
      'checkinCount': instance.checkinCount,
      'visitedMuseumCount': instance.visitedMuseumCount,
      'visitedCityCount': instance.visitedCityCount,
      'lastLoginTime': _dateTimeToJson(instance.lastLoginTime),
      'createAt': _dateTimeToJson(instance.createAt),
      'updateAt': _dateTimeToJson(instance.updateAt),
      'roles': instance.roles,
      'permissions': instance.permissions,
      'status': instance.status,
    };
