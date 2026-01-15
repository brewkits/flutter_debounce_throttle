import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_debounce_throttle/flutter_debounce_throttle.dart';

void main() {
  group('StreamSafeListener', () {
    testWidgets('listens to stream events', (tester) async {
      final controller = StreamController<int>();
      final received = <int>[];

      await tester.pumpWidget(
        MaterialApp(
          home: StreamSafeListener<int>(
            stream: controller.stream,
            onData: (data) => received.add(data),
            child: const Text('Test'),
          ),
        ),
      );

      controller.add(1);
      controller.add(2);
      controller.add(3);

      await tester.pump();

      expect(received, [1, 2, 3]);

      await controller.close();
    });

    testWidgets('handles errors', (tester) async {
      final controller = StreamController<int>();
      Object? receivedError;

      await tester.pumpWidget(
        MaterialApp(
          home: StreamSafeListener<int>(
            stream: controller.stream,
            onData: (data) {},
            onError: (error, stackTrace) => receivedError = error,
            child: const Text('Test'),
          ),
        ),
      );

      controller.addError('Test error');
      await tester.pump();

      expect(receivedError, 'Test error');

      await controller.close();
    });

    testWidgets('calls onDone when stream closes', (tester) async {
      final controller = StreamController<int>();
      bool doneCalledFlag = false;

      await tester.pumpWidget(
        MaterialApp(
          home: StreamSafeListener<int>(
            stream: controller.stream,
            onData: (data) {},
            onDone: () => doneCalledFlag = true,
            child: const Text('Test'),
          ),
        ),
      );

      await controller.close();
      await tester.pump();

      expect(doneCalledFlag, true);
    });

    testWidgets('cancels subscription on dispose', (tester) async {
      final controller = StreamController<int>.broadcast();
      final received = <int>[];

      await tester.pumpWidget(
        MaterialApp(
          home: StreamSafeListener<int>(
            stream: controller.stream,
            onData: (data) => received.add(data),
            child: const Text('Test'),
          ),
        ),
      );

      controller.add(1);
      await tester.pump();

      // Dispose widget
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));

      // These should not be received after dispose
      controller.add(2);
      await tester.pump();

      expect(received, [1]);

      await controller.close();
    });
  });

  group('StreamDebounceListener', () {
    testWidgets('debounces stream events', (tester) async {
      final controller = StreamController<int>();
      final received = <int>[];

      await tester.pumpWidget(
        MaterialApp(
          home: StreamDebounceListener<int>(
            stream: controller.stream,
            duration: const Duration(milliseconds: 100),
            onData: (data) => received.add(data),
            child: const Text('Test'),
          ),
        ),
      );

      controller.add(1);
      controller.add(2);
      controller.add(3);

      await tester.pump();
      expect(received, isEmpty);

      await tester.pump(const Duration(milliseconds: 150));

      // Only last value after debounce
      expect(received, [3]);

      await controller.close();
    });

    testWidgets('resets timer on new events', (tester) async {
      final controller = StreamController<int>();
      final received = <int>[];

      await tester.pumpWidget(
        MaterialApp(
          home: StreamDebounceListener<int>(
            stream: controller.stream,
            duration: const Duration(milliseconds: 100),
            onData: (data) => received.add(data),
            child: const Text('Test'),
          ),
        ),
      );

      controller.add(1);
      await tester.pump(const Duration(milliseconds: 50));

      controller.add(2);
      await tester.pump(const Duration(milliseconds: 50));

      controller.add(3);
      await tester.pump(const Duration(milliseconds: 50));

      expect(received, isEmpty);

      await tester.pump(const Duration(milliseconds: 100));

      expect(received, [3]);

      await controller.close();
    });
  });

  group('StreamThrottleListener', () {
    testWidgets('throttles stream events', (tester) async {
      final controller = StreamController<int>();
      final received = <int>[];

      await tester.pumpWidget(
        MaterialApp(
          home: StreamThrottleListener<int>(
            stream: controller.stream,
            duration: const Duration(milliseconds: 100),
            onData: (data) => received.add(data),
            child: const Text('Test'),
          ),
        ),
      );

      controller.add(1);
      controller.add(2);
      controller.add(3);

      await tester.pump();

      // First event passes immediately
      expect(received, [1]);

      await controller.close();
    });

    testWidgets('allows events after duration', (tester) async {
      final controller = StreamController<int>();
      final received = <int>[];

      await tester.pumpWidget(
        MaterialApp(
          home: StreamThrottleListener<int>(
            stream: controller.stream,
            duration: const Duration(milliseconds: 100),
            onData: (data) => received.add(data),
            child: const Text('Test'),
          ),
        ),
      );

      controller.add(1);
      await tester.pump();
      expect(received, [1]);

      await tester.pump(const Duration(milliseconds: 150));

      controller.add(2);
      await tester.pump();
      expect(received, [1, 2]);

      await controller.close();
    });
  });
}
