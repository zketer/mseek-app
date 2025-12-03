import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../auth/auth_service.dart';

/// HTTP客户端服务
class HttpClient {
  static final HttpClient _instance = HttpClient._internal();
  factory HttpClient() => _instance;
  HttpClient._internal();

  late Dio _dio;
  
  /// 初始化HTTP客户端
  void init() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: AppConstants.connectTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // 添加请求拦截器
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: _onRequest,
      onResponse: _onResponse,
      onError: _onError,
    ));

    // 添加日志拦截器（仅在调试模式下）
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => print('HTTP: $obj'),
    ));
  }

  /// 请求拦截器
  void _onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // 添加认证token和userId
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.keyToken);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    
    // 添加userId到请求头（后端小程序接口需要）
    final userId = prefs.getInt(AppConstants.keyUserId);
    if (userId != null) {
      options.headers['userId'] = userId.toString();
    }
    
    handler.next(options);
  }

  /// 响应拦截器
  void _onResponse(Response response, ResponseInterceptorHandler handler) {
    // 处理业务逻辑错误
    if (response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      final code = data['code'] as int?;
      
      if (code != null && code != 200) {
        final message = data['message'] as String? ?? AppConstants.errorUnknown;
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message: message,
        );
      }
    }
    
    handler.next(response);
  }

  /// 错误拦截器
  void _onError(DioException error, ErrorInterceptorHandler handler) async {
    // 处理token过期
    if (error.response?.statusCode == 401) {
      await _handleTokenExpired();
    }
    
    handler.next(error);
  }

  /// 处理token过期
  Future<void> _handleTokenExpired() async {
    print('⚠️ 收到 401 错误，Token 可能已过期');
    
    // 尝试刷新 Token
    try {
      final authService = AuthService();
      final hasValidToken = await authService.ensureValidToken();
      
      if (hasValidToken) {
        print('✅ Token 刷新成功，可以继续使用');
        return;
      }
    } catch (e) {
      print('❌ Token 刷新失败: $e');
    }
    
    // 刷新失败，清除所有认证信息
    print('🚪 清除认证信息，需要重新登录');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyToken);
    await prefs.remove(AppConstants.keyUserId);
    await prefs.remove(AppConstants.keyUserInfo);
    // TODO: 跳转到登录页面
  }

  /// GET请求
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// POST请求
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// PUT请求
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// DELETE请求
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 上传文件
  Future<Response<T>> upload<T>(
    String path,
    String filePath,
    String name, {
    Map<String, dynamic>? data,
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      final formData = FormData.fromMap({
        name: await MultipartFile.fromFile(filePath),
        ...?data,
      });

      return await _dio.post<T>(
        path,
        data: formData,
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 处理错误
  Exception _handleError(DioException error) {
    String message;
    
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = AppConstants.errorNetworkConnection;
        break;
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode != null && statusCode >= 500) {
          message = AppConstants.errorServerError;
        } else {
          message = error.message ?? AppConstants.errorUnknown;
        }
        break;
      case DioExceptionType.cancel:
        message = '请求已取消';
        break;
      default:
        message = error.message ?? AppConstants.errorUnknown;
    }
    
    return Exception(message);
  }

  /// 获取Dio实例（用于特殊情况）
  Dio get dio => _dio;
}
