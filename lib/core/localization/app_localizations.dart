// lib/core/localization/app_localizations.dart
class AppLocalizations {
  final Locale locale;
  
  AppLocalizations(this.locale);
  
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }
  
  static const LocalizationsDelegate<AppLocalizations> delegate = 
    _AppLocalizationsDelegate();
  
  static Map<String, Map<String, String>> _localizedValues = {
    'ar': {
      'app_title': 'المعهد الأول',
      'login': 'تسجيل الدخول',
      'enter_code': 'أدخل الكود',
      'submit': 'دخول',
      'teacher': 'مدرس',
      'student': 'طالب',
      'admin': 'مدير',
      'classes': 'الصفوف',
      'students': 'الطلاب',
      'recordings': 'التسجيلات',
      'chat': 'المحادثة',
      'start_class': 'بدء المحاضرة',
      'end_class': 'إنهاء المحاضرة',
      'camera': 'الكاميرا',
      'microphone': 'الميكروفون',
      'screen_share': 'مشاركة الشاشة',
      'recording': 'التسجيل',
      'no_connection': 'لا يوجد اتصال بالإنترنت',
      'offline_mode': 'وضع عدم الاتصال',
      'syncing': 'جاري المزامنة...',
      'sync_complete': 'تمت المزامنة بنجاح',
      'error': 'خطأ',
      'success': 'نجح',
      'loading': 'جاري التحميل...',
      'save': 'حفظ',
      'cancel': 'إلغاء',
      'delete': 'حذف',
      'edit': 'تعديل',
      'add': 'إضافة',
      'search': 'بحث',
      'filter': 'تصفية',
      'download': 'تنزيل',
      'upload': 'رفع',
      'send': 'إرسال',
      'receive': 'استقبال',
    },
    'en': {
      'app_title': 'Al-Mahad Al-Awwal',
      'login': 'Login',
      'enter_code': 'Enter Code',
      'submit': 'Submit',
      // ... الترجمات الإنجليزية
    },
  };
  
  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
  
  // Getters للوصول السريع
  String get appTitle => translate('app_title');
  String get login => translate('login');
  String get enterCode => translate('enter_code');
  // ... بقية الـ getters
}

class _AppLocalizationsDelegate 
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();
  
  @override
  bool isSupported(Locale locale) => ['ar', 'en'].contains(locale.languageCode);
  
  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }
  
  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
