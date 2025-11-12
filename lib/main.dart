// lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // تهيئة Hive
  await Hive.initFlutter();
  await Hive.openBox('app_data');
  
  // تهيئة الصلاحيات
  await Permission.camera.request();
  await Permission.microphone.request();
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        Provider(create: (_) => ApiService()),
        Provider(create: (_) => SocketService()),
        ProxyProvider2<ApiService, ConnectivityService, SyncService>(
          update: (_, api, connectivity, __) => SyncService(
            localDB: Hive.box('app_data'),
            api: api,
            connectivity: connectivity,
          )..initialize(),
        ),
      ],
      child: MaterialApp(
        title: 'المعهد الأول',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        locale: Locale('ar'),
        supportedLocales: [
          Locale('ar'),
          Locale('en'),
        ],
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        onGenerateRoute: AppRoutes.generateRoute,
        initialRoute: AppRoutes.splash,
        builder: (context, child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              children: [
                ConnectivityBanner(),
                Expanded(child: child!),
              ],
            ),
          );
        },
      ),
    );
  }
}
