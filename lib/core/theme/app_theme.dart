// lib/core/theme/app_theme.dart
class AppTheme {
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color secondaryColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFF44336);
  static const Color warningColor = Color(0xFFFF9800);
  
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
    ),
    
    // AppBar Theme
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        fontFamily: 'Cairo',
      ),
    ),
    
    // Card Theme
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: EdgeInsets.all(8),
    ),
    
    // Button Themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          fontFamily: 'Cairo',
        ),
      ),
    ),
    
    // Input Decoration
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      labelStyle: TextStyle(fontFamily: 'Cairo'),
      hintStyle: TextStyle(fontFamily: 'Cairo'),
    ),
    
    // Text Theme
    textTheme: TextTheme(
      displayLarge: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
      displayMedium: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
      displaySmall: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600),
      titleLarge: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(fontFamily: 'Cairo'),
      bodyMedium: TextStyle(fontFamily: 'Cairo'),
    ),
    
    fontFamily: 'Cairo',
  );
  
  // Dark Theme (اختياري)
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
    ),
    fontFamily: 'Cairo',
  );
}
