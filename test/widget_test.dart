import 'package:flutter_test/flutter_test.dart';
import 'package:sema_mobile_app/main.dart';

void main() {
  testWidgets('App starts successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const SemaApp());

    
    expect(find.byType(SemaApp), findsOneWidget);
  });
}
