import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/main.dart';

void main() {
  testWidgets('App smoke test - verifies initial build and MaterialApp', (WidgetTester tester) async {
    // Set a larger surface size to prevent overflow in test environment
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    // Verify that MaterialApp is present
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
