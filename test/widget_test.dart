import 'package:flutter_test/flutter_test.dart';

import 'package:visionmate_ai/main.dart';

void main() {
  testWidgets('app navigates from splash to home screen', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('VisionMate AI'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    expect(find.text('Start Navigation'), findsOneWidget);
    expect(find.text('Camera'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Help'), findsOneWidget);
  });
}
