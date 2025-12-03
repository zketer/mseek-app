import 'dart:io';
import 'package:dio/dio.dart';

/// 统一错误处理工具类
/// 将技术性错误转换为用户友好的提示信息
class ErrorHandler {
  /// 将异常转换为用户友好的错误消息
  static String getUserFriendlyMessage(dynamic error) {
    // Dio 网络错误
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return '网络连接超时，请检查网络设置';
        
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          if (statusCode == 401) {
            return '登录已过期，请重新登录';
          } else if (statusCode == 403) {
            return '没有访问权限';
          } else if (statusCode == 404) {
            return '请求的资源不存在';
          } else if (statusCode == 500) {
            return '服务器错误，请稍后重试';
          } else {
            return '请求失败，请稍后重试';
          }
        
        case DioExceptionType.cancel:
          return '请求已取消';
        
        case DioExceptionType.connectionError:
          return '网络连接失败，请检查网络设置';
        
        case DioExceptionType.badCertificate:
          return '证书验证失败';
        
        case DioExceptionType.unknown:
          // 检查是否是连接被拒绝错误
          if (error.error is SocketException) {
            return '无法连接到服务器，请检查网络或稍后重试';
          }
          return '网络异常，请检查网络设置';
      }
    }
    
    // Socket 异常
    if (error is SocketException) {
      return '无法连接到服务器，请检查网络或稍后重试';
    }
    
    // 格式异常
    if (error is FormatException) {
      return '数据格式错误';
    }
    
    // 其他异常
    if (error is Exception) {
      final errorString = error.toString().toLowerCase();
      
      // 连接相关错误
      if (errorString.contains('connection') || 
          errorString.contains('refused') ||
          errorString.contains('failed host lookup')) {
        return '无法连接到服务器，请检查网络或稍后重试';
      }
      
      // 超时相关错误
      if (errorString.contains('timeout')) {
        return '网络连接超时，请稍后重试';
      }
      
      // 证书相关错误
      if (errorString.contains('certificate') || errorString.contains('handshake')) {
        return '网络连接异常';
      }
      
      // 默认提示
      return '操作失败，请稍后重试';
    }
    
    // 字符串类型错误（可能是服务器返回的错误消息）
    if (error is String) {
      // 如果包含技术性关键词，则返回通用提示
      final lowerError = error.toLowerCase();
      if (lowerError.contains('exception') || 
          lowerError.contains('error') ||
          lowerError.contains('stack trace') ||
          lowerError.contains('failed host')) {
        return '操作失败，请稍后重试';
      }
      // 否则可能是业务错误消息，直接返回
      return error;
    }
    
    // 未知错误
    return '操作失败，请稍后重试';
  }
  
  /// 判断错误是否为网络连接错误
  static bool isNetworkError(dynamic error) {
    if (error is DioException) {
      return error.type == DioExceptionType.connectionTimeout ||
             error.type == DioExceptionType.connectionError ||
             error.type == DioExceptionType.sendTimeout ||
             error.type == DioExceptionType.receiveTimeout;
    }
    
    if (error is SocketException) {
      return true;
    }
    
    if (error is Exception) {
      final errorString = error.toString().toLowerCase();
      return errorString.contains('connection') || 
             errorString.contains('network') ||
             errorString.contains('timeout');
    }
    
    return false;
  }
  
  /// 判断错误是否为认证错误
  static bool isAuthError(dynamic error) {
    if (error is DioException) {
      return error.response?.statusCode == 401;
    }
    return false;
  }
}

