import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khmerkid/main.dart';
import 'package:khmerkid/screens/auth/login_screen.dart';
import 'package:khmerkid/l10n/language_manager.dart';

void main() {
  testWidgets('App loads login screen initially', (WidgetTester tester) async {
    // Initialize LanguageManager to populate supportedLanguages and avoid assertion errors
    await LanguageManager.instance.init();

    // Configure ultra-wide mobile/tablet emulation to prevent Ahem font layout overflows in tests
    tester.view.physicalSize = const Size(3000, 3000);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(const KhmerKidApp(isLoggedIn: false, isAdmin: false));

    // Verify the login screen widget is rendered initially
    expect(find.byType(LoginScreen), findsOneWidget);

    await tester.pumpAndSettle();

    // Reset views physical size after test
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
