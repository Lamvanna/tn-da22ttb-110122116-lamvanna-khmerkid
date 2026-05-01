import 'package:flutter_test/flutter_test.dart';
import 'package:khmerkid/main.dart';

void main() {
  testWidgets('App loads home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const KhmerKidApp());

    // Verify the home screen is displayed
    expect(find.text('Xin chào! 👋'), findsOneWidget);
    expect(find.text('Học chữ Khmer'), findsOneWidget);
  });
}
