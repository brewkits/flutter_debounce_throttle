import 'package:flutter/material.dart';
import 'package:flutter_debounce_throttle/flutter_debounce_throttle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Security & Robustness Tests for Flutter Widgets', () {
    testWidgets(
        'ThrottledGestureDetector handles rapid taps safely (DoS protection)',
        (WidgetTester tester) async {
      int tapCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ThrottledGestureDetector(
              discreteDuration: const Duration(milliseconds: 500),
              onTap: () {
                tapCount++;
              },
              child: const Text('Tap Me'),
            ),
          ),
        ),
      );

      final finder = find.text('Tap Me');
      expect(finder, findsOneWidget);

      // Simulate a flood of rapid taps
      for (int i = 0; i < 50; i++) {
        await tester.tap(finder);
      }

      // Despite 50 taps instantly, it should only fire once initially
      expect(tapCount, 1);
    });
  });
}
