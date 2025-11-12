// lib/core/errors/error_handler.dart
class ErrorHandler {
  static void handleError(dynamic error, BuildContext context) {
    String message;
    
    if (error is AppException) {
      message = error.message;
    } else if (error is DioException) {
      message = _handleDioError(error);
    } else {
      message = 'حدث خطأ غير متوقع';
      print('Unexpected error: $error');
    }
    
    _showErrorSnackbar(context, message);
  }
  
  static String _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'انتهى وقت الاتصال - تحقق من الإنترنت';
        
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 401) return 'جلسة منتهية - يرجى تسجيل الدخول مجدداً';
        if (statusCode == 403) return 'غير مصرح لك بهذا الإجراء';
        if (statusCode == 404) return 'العنصر المطلوب غير موجود';
        if (statusCode == 500) return 'خطأ في السيرفر';
        return error.response?.data['message'] ?? 'خطأ في الطلب';
        
      case DioExceptionType.cancel:
        return 'تم إلغاء الطلب';
        
      default:
        return 'خطأ في الاتصال بالشبكة';
    }
  }
  
  static void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 4),
        action: SnackBarAction(
          label: 'حسناً',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }
  
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }
}
