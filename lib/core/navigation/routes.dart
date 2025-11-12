// lib/core/navigation/routes.dart
class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String adminDashboard = '/admin';
  static const String adminTeachers = '/admin/teachers';
  static const String adminClasses = '/admin/classes';
  static const String adminStudents = '/admin/students';
  static const String adminArchive = '/admin/archive';
  static const String adminMessaging = '/admin/messaging';
  static const String teacherDashboard = '/teacher';
  static const String teacherClass = '/teacher/class';
  static const String studentDashboard = '/student';
  static const String studentClass = '/student/class';
  
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => SplashScreen());
        
      case login:
        return MaterialPageRoute(builder: (_) => LoginScreen());
        
      case adminDashboard:
        return MaterialPageRoute(
          builder: (_) => AdminDashboardScreen(),
        );
        
      case adminStudents:
        return MaterialPageRoute(
          builder: (_) => StudentsManagementScreen(),
        );
        
      case teacherClass:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => LiveClassScreen(
            classData: args['classData'],
          ),
        );
        
      case studentClass:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => StudentClassScreen(
            classData: args['classData'],
          ),
        );
        
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('الصفحة غير موجودة'),
            ),
          ),
        );
    }
  }
}
