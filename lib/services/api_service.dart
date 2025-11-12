// lib/services/api_service.dart
class ApiService {
  final Dio _dio;
  
  ApiService() : _dio = Dio() {
    _dio.options.baseUrl = AppConfig.apiUrl;
    _dio.options.connectTimeout = Duration(seconds: 30);
    _dio.options.receiveTimeout = Duration(seconds: 30);
    
    // إضافة Interceptor لإعادة المحاولة
    _dio.interceptors.add(RetryInterceptor(
      dio: _dio,
      logPrint: print,
      retries: 3,
      retryDelays: [
        Duration(seconds: 1),
        Duration(seconds: 3),
        Duration(seconds: 5),
      ],
    ));
    
    // إضافة Interceptor للتوكن
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          // توكن منتهي - إعادة تسجيل الدخول
          _handleUnauthorized();
        }
        return handler.next(error);
      },
    ));
  }
  
  Future<Map<String, dynamic>> get(String path) async {
    try {
      final response = await _dio.get(path);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(path, data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Exception _handleError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return Exception('انتهى وقت الاتصال - تحقق من الإنترنت');
    }
    
    if (e.type == DioExceptionType.connectionError) {
      return Exception('لا يوجد اتصال بالإنترنت');
    }
