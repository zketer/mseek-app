// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exhibition.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Exhibition _$ExhibitionFromJson(Map<String, dynamic> json) => Exhibition(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      subtitle: json['subtitle'] as String?,
      description: json['description'] as String?,
      coverImage: json['coverImage'] as String?,
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
      isPermanent: (json['isPermanent'] as num?)?.toInt(),
      museumId: (json['museumId'] as num?)?.toInt(),
      museumName: json['museumName'] as String?,
      location: json['location'] as String?,
      ticketPrice: (json['ticketPrice'] as num?)?.toDouble(),
      freeAdmission: (json['freeAdmission'] as num?)?.toInt(),
      enabled: (json['enabled'] as num?)?.toInt(),
      images: (json['imageUrls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      viewCount: (json['viewCount'] as num?)?.toInt(),
      createAt: json['createAt'] == null
          ? null
          : DateTime.parse(json['createAt'] as String),
      updateAt: json['updateAt'] == null
          ? null
          : DateTime.parse(json['updateAt'] as String),
    );

Map<String, dynamic> _$ExhibitionToJson(Exhibition instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'subtitle': instance.subtitle,
      'description': instance.description,
      'coverImage': instance.coverImage,
      'startDate': instance.startDate,
      'endDate': instance.endDate,
      'isPermanent': instance.isPermanent,
      'museumId': instance.museumId,
      'museumName': instance.museumName,
      'location': instance.location,
      'ticketPrice': instance.ticketPrice,
      'freeAdmission': instance.freeAdmission,
      'enabled': instance.enabled,
      'imageUrls': instance.images,
      'viewCount': instance.viewCount,
      'createAt': instance.createAt?.toIso8601String(),
      'updateAt': instance.updateAt?.toIso8601String(),
    };
