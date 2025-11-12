// lib/core/errors/app_exception.dart
abstract class AppException implements Exception {
  final String message;
  final String? code;
  
  AppException(this.message, [this.code]);
  
  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException([String? message]) 
    : super(message ?? 'خطأ في الاتصال بالشبكة', 'NETWORK_ERROR');
}

class AuthException extends AppException {
  AuthException([String? message]) 
    : super(message ?? 'خطأ في المصادقة', 'AUTH_ERROR');
}

class ValidationException extends AppException {
  ValidationException([String? message]) 
    : super(message ?? 'بيانات غير صحيحة', 'VALIDATION_ERROR');
}

class ServerException extends AppException {
  ServerException([String? message]) 
    : super(message ?? 'خطأ في السيرفر', 'SERVER_ERROR');
}

class NotFoundException extends AppException {
  NotFoundException([String? message]) 
    : super(message ?? 'العنصر غير موجود', 'NOT_FOUND');
}
