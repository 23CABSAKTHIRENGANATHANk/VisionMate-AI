// Widget test for VisionMate AI — verifies the app starts on the Splash screen.
// Note: Deep navigation testing (Splash → Home) is deferred to integration
// tests in Module 3, as it requires real async timers and image loading.
import 'package:flutter_test/flutter_test.dart';

import 'package:visionmate_ai/main.dart';

void main() {
  testWidgets('App launches and displays the VisionMate AI name', (
    WidgetTester tester,
  ) async {
    // Pump the root app widget.
    await tester.pumpWidget(const VisionMateApp());

    // The splash screen should display the app name immediately.
    expect(find.text('VisionMate AI'), findsOneWidget);
  });
}
