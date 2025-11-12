// integration_test/app_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('App Integration Tests', () {
    testWidgets('complete login flow', (WidgetTester tester) async {
      await tester.pumpWidget(MyApp());
      
      // انتظار شاشة تسجيل الدخول
      await tester.pumpAndSettle();
      
      // إدخال الكود
      final codeField = find.byType(TextField);
      await tester.enterText(codeField, '1234');
      
      // الضغط على زر الدخول
      final loginButton = find.text('دخول');
      await tester.tap(loginButton);
      
      // انتظار الانتقال للصفحة الرئيسية
      await tester.pumpAndSettle();
      
      // التحقق من الوصول للصفحة الصحيحة
      expect(find.text('لوحة التحكم'), findsOneWidget);
    });
    
    testWidgets('send message in class', (WidgetTester tester) async {
      // إعداد التطبيق والدخول للصف
      // ...
      
      // كتابة رسالة
      final messageField = find.byType(TextField).last;
      await tester.enterText(messageField, 'مرحباً');
      
      // إرسال
      final sendButton = find.byIcon(Icons.send);
      await tester.tap(sendButton);
      
      await tester.pumpAndSettle();
      
      // التحقق من ظهور الرسالة
      expect(find.text('مرحباً'), findsWidgets);
    });
  });
}
