// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example/main.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    // Set a larger surface size to avoid layout issues
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;

    // Build our app and trigger a frame.
    await tester.pumpWidget(const DemoApp());

    // Verify that the app title is shown
    expect(find.text('Flutter Debounce Throttle'), findsOneWidget);

    // Reset the test surface size
    addTearDown(tester.view.resetPhysicalSize);
  });
}
