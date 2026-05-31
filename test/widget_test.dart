import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khmerkid/main.dart';

void main() {
  testWidgets('App loads splash screen initially', (WidgetTester tester) async {
    // Configure ultra-wide mobile/tablet emulation to prevent Ahem font layout overflows in tests
    tester.view.physicalSize = const Size(3000, 3000);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(const KhmerKidApp());

    // Verify the splash screen is displayed initially with "Đang tải..."
    expect(find.text('Đang tải...'), findsOneWidget);

    // Pump with duration to trigger and clean up the 2.5 second delayed timer
    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pumpAndSettle();

    // Reset views physical size after test
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
