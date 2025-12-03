import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../models/user.dart';
import '../../core/utils/image_utils.dart';
import 'http_client.dart';

/// 用户服务 - 处理用户相关API请求
class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final HttpClient _httpClient = HttpClient();

  /// 根据用户ID获取用户信息
  Future<User> getUserById(int userId) async {
    debugPrint('📡 [UserService] 获取用户信息: userId=$userId');
    // 通过网关访问用户服务
    final response = await _httpClient.get('/api/v1/system/users/$userId');
    debugPrint('✅ [UserService] 获取用户信息成功');
    return User.fromJson(response.data['data']);
  }

  /// 更新用户信息
  Future<User> updateUserInfo({
    String? nickname,
    String? avatar,
    int? gender,
    String? birthday,
    String? bio,
  }) async {
    final data = <String, dynamic>{};
    if (nickname != null) data['nickname'] = nickname;
    if (avatar != null) data['avatar'] = avatar;
    if (gender != null) data['gender'] = gender;
    if (birthday != null) data['birthday'] = birthday;
    if (bio != null) data['bio'] = bio;

    // 注意：用户服务的context-path是/api/v1/system
    final response = await _httpClient.put(
      '/museum-system/api/v1/system/users/current',
      data: data,
    );
    return User.fromJson(response.data['data']);
  }

  /// 上传头像
  /// 返回头像URL（base64格式）
  Future<String> uploadAvatar(File imageFile, int userId) async {
    try {
      debugPrint('📤 [UserService] 开始上传头像: userId=$userId, file=${imageFile.path}');
      
      // 统一使用Base64接口：POST /api/v1/system/users/{userId}/avatar/base64
      final path = '/api/v1/system/users/$userId/avatar/base64';
      
      // 将图片文件转换为Base64
      final avatarBase64 = await ImageUtils.encodeImageToBase64(imageFile);
      if (avatarBase64 == null) {
        throw Exception('图片转Base64失败');
      }

      debugPrint('✅ [UserService] 图片转Base64成功，长度: ${avatarBase64.length}');

      // 发送Base64数据到后端
      final response = await _httpClient.post(
        path,
        data: {'avatar': avatarBase64},
      );

      debugPrint('✅ [UserService] 上传成功，响应: ${response.data}');
      
      // 返回头像URL（后端返回格式：{ code: 200, data: "data:image/png;base64,..." }）
      if (response.data is Map) {
        final data = response.data as Map;
        
        // 情况1: { data: "base64..." }
        if (data['data'] is String) {
          final avatarUrl = data['data'] as String;
          debugPrint('✅ [UserService] 获取到头像URL: ${avatarUrl.substring(0, 50)}...');
          return avatarUrl;
        }
      }
      
      throw Exception('响应格式不符合预期: ${response.data}');
    } catch (e) {
      debugPrint('❌ [UserService] 上传头像失败: $e');
      rethrow;
    }
  }

  /// 更新头像（选择图片 + 上传，后端会自动更新用户信息）
  /// 注意：需要传入userId
  Future<String> updateAvatar(File imageFile, int userId) async {
    // 上传图片，后端会自动更新用户的avatar字段并返回base64数据
    return await uploadAvatar(imageFile, userId);
  }
}

