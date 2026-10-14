import 'package:flutter_test/flutter_test.dart';
import 'package:sema_mobile_app/screens/login_screen.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('SAITRING login screen displays its fields', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const TestApp());

    expect(find.text('SAITRING'), findsOneWidget);
    expect(find.text('Employee Manager'), findsOneWidget);
    expect(find.text('Email or mobile number'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: LoginScreen());
  }
}
