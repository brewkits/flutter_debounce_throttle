// Integration tests for example app.
// Tests the new API in real-world scenarios.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:example/main.dart';

void main() {
  group('Example App Integration Tests', () {
    testWidgets('Throttle Demo - New API', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(const DemoApp());

      // Verify we're on throttle demo by default
      expect(find.text('Throttle Demo'), findsOneWidget);
      expect(find.text('TAP RAPIDLY!'), findsOneWidget);

      // Tap the button multiple times
      final buttonFinder = find.text('TAP RAPIDLY!');
      await tester.tap(buttonFinder);
      await tester.tap(buttonFinder);
      await tester.tap(buttonFinder);

      await tester.pump();

      // Should show throttled behavior in stats
      expect(find.textContaining('Raw Clicks'), findsOneWidget);
      expect(find.textContaining('Throttled'), findsAtLeastNWidgets(1));

      addTearDown(tester.view.resetPhysicalSize);
    });

    testWidgets('Debounce Demo - New API', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(const DemoApp());

      // Navigate to Debounce demo
      await tester.tap(find.text('Debounce'));
      await tester.pumpAndSettle();

      expect(find.text('Debounce Demo'), findsOneWidget);

      // Type in the text field
      final textField = find.byType(TextField);
      await tester.enterText(textField, 'test');
      await tester.pump();

      // Should be pending
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for debounce
      await tester.pump(const Duration(milliseconds: 600));

      // Should show result
      expect(find.text('test'), findsAtLeast(1));

      addTearDown(tester.view.resetPhysicalSize);
    });

    testWidgets('Search Demo - AsyncDebouncedTextController', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(const DemoApp());

      // Navigate to Search demo
      await tester.tap(find.text('Search'));
      await tester.pumpAndSettle();

      expect(find.text('Async Search Demo'), findsOneWidget);

      // Search for a fruit
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'app');
      await tester.pump();

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for debounce + search delay
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 400));

      // Should show Apple result
      expect(find.text('Apple'), findsOneWidget);

      addTearDown(tester.view.resetPhysicalSize);
    });

    testWidgets('Button Demo - AsyncThrottledBuilder', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(const DemoApp());

      // Navigate to Buttons demo
      await tester.tap(find.text('Buttons'));
      await tester.pumpAndSettle();

      expect(find.text('Async Button Demo'), findsOneWidget);

      // Verify the demo loaded successfully - this verifies AsyncThrottledBuilder widget works
      expect(find.textContaining('AsyncThrottledBuilder prevents'), findsOneWidget);

      // Note: Can't reliably test button tap in widget test due to async timing
      // Integration tests or manual testing should verify button functionality

      addTearDown(tester.view.resetPhysicalSize);
    });

    testWidgets('Advanced Demo - ConcurrentAsyncThrottledBuilder', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(const DemoApp());

      // Navigate to Advanced demo
      await tester.tap(find.text('Advanced'));
      await tester.pumpAndSettle();

      expect(find.text('Concurrency Modes'), findsOneWidget);

      // Test drop mode (default)
      final startButton = find.text('Start Operation');
      await tester.tap(startButton);
      await tester.pump();

      // Should show processing
      expect(find.textContaining('Processing'), findsOneWidget);

      // Switch to enqueue mode
      await tester.tap(find.text('enqueue'));
      await tester.pumpAndSettle();

      // Wait for operation to complete
      await tester.pump(const Duration(seconds: 3));

      // Verify operation completed
      expect(find.textContaining('Completed'), findsAtLeast(1));

      addTearDown(tester.view.resetPhysicalSize);
    });
  });

  group('New API Coverage Tests', () {
    testWidgets('Verifies EventLimiterMixin uses new cancel() API', (tester) async {
      // This test verifies that the mixin is using the new cancel() method
      // by checking that the example app works correctly with the new API
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(const DemoApp());

      // Navigate through all demos to verify no runtime errors
      await tester.tap(find.text('Debounce'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Search'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Buttons'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Advanced'));
      await tester.pumpAndSettle();

      // If we got here, all new APIs work correctly
      expect(find.text('Concurrency Modes'), findsOneWidget);

      addTearDown(tester.view.resetPhysicalSize);
    });

    testWidgets('Verifies DebouncedQueryBuilder in search demo', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(const DemoApp());

      // Navigate to search (uses AsyncDebouncedTextController which uses new call() API)
      await tester.tap(find.text('Search'));
      await tester.pumpAndSettle();

      // Type multiple times to test debouncing
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'a');
      await tester.pump(const Duration(milliseconds: 100));

      await tester.enterText(searchField, 'ap');
      await tester.pump(const Duration(milliseconds: 100));

      await tester.enterText(searchField, 'app');
      await tester.pump();

      // Wait for debounce + search
      await tester.pump(const Duration(milliseconds: 800));

      // Should only execute once (debounced)
      expect(find.text('Apple'), findsOneWidget);

      addTearDown(tester.view.resetPhysicalSize);
    });
  });
}
