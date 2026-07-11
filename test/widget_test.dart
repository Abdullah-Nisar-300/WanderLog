// widget_test.dart
// Basic smoke test to verify the application loads and renders correctly.

import 'package:flutter_test/flutter_test.dart';
import 'package:wander_log/main.dart';

void main() {
  testWidgets('App smoke test - starts on Splash Screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const WanderLogApp());

    // Verify that the splash screen shows the title and description.
    expect(find.text('WanderLog'), findsOneWidget);
    expect(find.text('Smart Travel & Expense Journal'), findsOneWidget);

    // Let the splash screen auto-navigation timer fire and complete
    await tester.pumpAndSettle(const Duration(milliseconds: 2500));
  });
}
