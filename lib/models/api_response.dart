import 'package:json_annotation/json_annotation.dart';

part 'api_response.g.dart';

/// API统一响应格式
@JsonSerializable(genericArgumentFactories: true)
class ApiResponse<T> {
  final int code;
  final String message;
  final T? data;
  final int timestamp;

  const ApiResponse({
    required this.code,
    required this.message,
    this.data,
    required this.timestamp,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) =>
      _$ApiResponseFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) =>
      _$ApiResponseToJson(this, toJsonT);

  /// 是否成功
  bool get isSuccess => code == 200;
  
  /// 是否失败
  bool get isFailed => !isSuccess;
}

/// 分页响应数据
@JsonSerializable(genericArgumentFactories: true)
class PageResponse<T> {
  final List<T> records;
  final int total;
  final int current;
  final int size;
  final int pages;

  const PageResponse({
    required this.records,
    required this.total,
    required this.current,
    required this.size,
    required this.pages,
  });

  factory PageResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) =>
      _$PageResponseFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) =>
      _$PageResponseToJson(this, toJsonT);

  /// 是否还有更多数据
  bool get hasMore => current < pages;
  
  /// 是否为空
  bool get isEmpty => records.isEmpty;
  
  /// 是否不为空
  bool get isNotEmpty => records.isNotEmpty;
}
