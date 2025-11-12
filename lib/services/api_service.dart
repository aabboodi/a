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
    if (e.response?.statusCode == 500) {
      return Exception('خطأ في السيرفر');
    }
    
    return Exception(e.response?.data['message'] ?? 'خطأ غير متوقع');
  }
  
  Future<String?> _getToken() async {
    final storage = FlutterSecureStorage();
    return await storage.read(key: 'auth_token');
  }
  
  void _handleUnauthorized() {
    // إعادة توجيه لصفحة تسجيل الدخول
    // يتم التعامل معها عبر الـ Provider
  }
}

// Retry Interceptor مخصص
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final void Function(String) logPrint;
  final int retries;
  final List<Duration> retryDelays;
  
  RetryInterceptor({
    required this.dio,
    required this.logPrint,
    this.retries = 3,
    required this.retryDelays,
  });
  
  @override
  Future onError(DioException err, ErrorInterceptorHandler handler) async {
    var extra = RetryOptions.fromExtra(err.requestOptions) ?? RetryOptions();
    
    if (extra.retries > 0 && _shouldRetry(err)) {
      logPrint('Retrying request... (${extra.retries} attempts left)');
      
      extra = extra.copyWith(retries: extra.retries - 1);
      err.requestOptions.extra = err.requestOptions.extra..addAll(extra.toExtra());
      
      // الانتظار قبل المحاولة التالية
      final delayIndex = retries - extra.retries - 1;
      final delay = delayIndex < retryDelays.length 
        ? retryDelays[delayIndex] 
        : retryDelays.last;
      
      await Future.delayed(delay);
      
      try {
        final response = await dio.fetch(err.requestOptions);
        return handler.resolve(response);
      } catch (e) {
        return super.onError(err, handler);
      }
    }
    
    return super.onError(err, handler);
  }
  
  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
           err.type == DioExceptionType.receiveTimeout ||
           err.type == DioExceptionType.connectionError ||
           (err.response?.statusCode ?? 0) >= 500;
  }
}

class RetryOptions {
  final int retries;
  
  const RetryOptions({this.retries = 3});
  
  factory RetryOptions.fromExtra(RequestOptions request) {
    return request.extra['retryOptions'] as RetryOptions?;
  }
  
  RetryOptions copyWith({int? retries}) {
    return RetryOptions(retries: retries ?? this.retries);
  }
  
  Map<String, dynamic> toExtra() {
    return {'retryOptions': this};
  }
}
