// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'museum.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Museum _$MuseumFromJson(Map<String, dynamic> json) => Museum(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      address: json['address'] as String?,
      longitude: (json['longitude'] as num?)?.toDouble(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      openTime: json['openTime'] as String?,
      ticketPrice: (json['ticketPrice'] as num?)?.toDouble(),
      ticketDescription: json['ticketDescription'] as String?,
      freeAdmission: (json['freeAdmission'] as num?)?.toInt(),
      level: (json['level'] as num?)?.toInt(),
      phone: json['phone'] as String?,
      website: json['website'] as String?,
      description: json['description'] as String?,
      capacity: (json['capacity'] as num?)?.toInt(),
      collectionCount: (json['collectionCount'] as num?)?.toInt(),
      preciousItems: (json['preciousItems'] as num?)?.toInt(),
      exhibitions: (json['exhibitions'] as num?)?.toInt(),
      coverImage: json['coverImage'] as String?,
      imageUrl: json['imageUrl'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      visitCount: (json['visitCount'] as num?)?.toInt(),
      status: (json['status'] as num?)?.toInt(),
      categories: (json['categories'] as List<dynamic>?)
          ?.map((e) => MuseumCategory.fromJson(e as Map<String, dynamic>))
          .toList(),
      tags: (json['tags'] as List<dynamic>?)
          ?.map((e) => TagInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      cityCode: json['cityCode'] as String?,
      cityName: json['cityName'] as String?,
      districtCode: json['districtCode'] as String?,
      districtName: json['districtName'] as String?,
      provinceCode: json['provinceCode'] as String?,
      provinceName: json['provinceName'] as String?,
      type: json['type'] as String?,
      educationActivities: (json['educationActivities'] as num?)?.toInt(),
      annualVisitors: (json['annualVisitors'] as num?)?.toInt(),
      imageUrls: (json['imageUrls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      distance: json['distance'] as String?,
      isFavorite: json['isFavorite'] as bool?,
      isCheckedIn: json['isCheckedIn'] as bool?,
    );

Map<String, dynamic> _$MuseumToJson(Museum instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'address': instance.address,
      'longitude': instance.longitude,
      'latitude': instance.latitude,
      'openTime': instance.openTime,
      'ticketPrice': instance.ticketPrice,
      'ticketDescription': instance.ticketDescription,
      'freeAdmission': instance.freeAdmission,
      'level': instance.level,
      'phone': instance.phone,
      'website': instance.website,
      'description': instance.description,
      'capacity': instance.capacity,
      'collectionCount': instance.collectionCount,
      'preciousItems': instance.preciousItems,
      'exhibitions': instance.exhibitions,
      'coverImage': instance.coverImage,
      'imageUrl': instance.imageUrl,
      'rating': instance.rating,
      'visitCount': instance.visitCount,
      'status': instance.status,
      'categories': instance.categories,
      'tags': instance.tags,
      'cityCode': instance.cityCode,
      'cityName': instance.cityName,
      'districtCode': instance.districtCode,
      'districtName': instance.districtName,
      'provinceCode': instance.provinceCode,
      'provinceName': instance.provinceName,
      'type': instance.type,
      'educationActivities': instance.educationActivities,
      'annualVisitors': instance.annualVisitors,
      'imageUrls': instance.imageUrls,
      'distance': instance.distance,
      'isFavorite': instance.isFavorite,
      'isCheckedIn': instance.isCheckedIn,
    };

MuseumCategory _$MuseumCategoryFromJson(Map<String, dynamic> json) =>
    MuseumCategory(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      code: json['code'] as String,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$MuseumCategoryToJson(MuseumCategory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'code': instance.code,
      'description': instance.description,
    };

TagInfo _$TagInfoFromJson(Map<String, dynamic> json) => TagInfo(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      code: json['code'] as String,
      color: json['color'] as String?,
    );

Map<String, dynamic> _$TagInfoToJson(TagInfo instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'code': instance.code,
      'color': instance.color,
    };
