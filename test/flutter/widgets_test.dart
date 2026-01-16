import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_debounce_throttle/flutter_debounce_throttle.dart';

void main() {
  group('ThrottledBuilder', () {
    testWidgets('provides throttle function to builder', (tester) async {
      int callCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: ThrottledBuilder(
            duration: const Duration(milliseconds: 500),
            builder: (context, throttle) => ElevatedButton(
              onPressed: throttle(() => callCount++),
              child: const Text('Tap'),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.tap(find.byType(ElevatedButton));
      await tester.tap(find.byType(ElevatedButton));

      expect(callCount, 1);
    });

    testWidgets('disposes throttler on widget dispose', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ThrottledBuilder(
            duration: const Duration(milliseconds: 500),
            builder: (context, throttle) => const Text('Test'),
          ),
        ),
      );

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));

      // No errors should occur
    });
  });

  group('ThrottledInkWell', () {
    testWidgets('executes onTap immediately', (tester) async {
      int callCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ThrottledInkWell(
              duration: const Duration(milliseconds: 500),
              onTap: () => callCount++,
              child: const Text('Tap me'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap me'));
      expect(callCount, 1);
    });

    testWidgets('blocks rapid taps', (tester) async {
      int callCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ThrottledInkWell(
              duration: const Duration(milliseconds: 500),
              onTap: () => callCount++,
              child: const Text('Tap me'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap me'));
      await tester.tap(find.text('Tap me'));
      await tester.tap(find.text('Tap me'));

      expect(callCount, 1);
    });

    testWidgets('allows tap after duration', (tester) async {
      int callCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ThrottledInkWell(
              duration: const Duration(milliseconds: 100),
              onTap: () => callCount++,
              child: const Text('Tap me'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap me'));
      expect(callCount, 1);

      await tester.pump(const Duration(milliseconds: 150));

      await tester.tap(find.text('Tap me'));
      expect(callCount, 2);
    });

    testWidgets('passes InkWell properties', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ThrottledInkWell(
              onTap: () {},
              splashColor: Colors.red,
              highlightColor: Colors.blue,
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Styled'),
              ),
            ),
          ),
        ),
      );

      final inkWell = tester.widget<InkWell>(find.byType(InkWell));
      expect(inkWell.splashColor, Colors.red);
      expect(inkWell.highlightColor, Colors.blue);
    });
  });

  group('DebouncedBuilder', () {
    testWidgets('provides debounce function to builder', (tester) async {
      int callCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DebouncedBuilder(
              duration: const Duration(milliseconds: 100),
              builder: (context, debounce) => TextField(
                // debounce returns a wrapped callback, call it immediately
                onChanged: (text) => debounce(() => callCount++)?.call(),
              ),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'a');
      await tester.enterText(find.byType(TextField), 'ab');
      await tester.enterText(find.byType(TextField), 'abc');

      expect(callCount, 0);

      await tester.pump(const Duration(milliseconds: 150));

      expect(callCount, 1);
    });
  });

  group('AsyncThrottledBuilder', () {
    testWidgets('provides throttle function to builder', (tester) async {
      int callCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: AsyncThrottledBuilder(
            maxDuration: const Duration(seconds: 5),
            builder: (context, throttle) {
              return ElevatedButton(
                onPressed: throttle(() async {
                  await Future.delayed(const Duration(milliseconds: 50));
                  callCount++;
                }),
                child: const Text('Submit'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Second tap should be blocked
      await tester.tap(find.byType(ElevatedButton));

      await tester.pump(const Duration(milliseconds: 100));

      expect(callCount, 1);
    });
  });

  group('DebouncedQueryBuilder', () {
    testWidgets('debounces query', (tester) async {
      String? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DebouncedQueryBuilder<String>(
              duration: const Duration(milliseconds: 50),
              onQuery: (text) async {
                return 'Result: $text';
              },
              onResult: (r) => result = r,
              builder: (context, search, isLoading) => TextField(
                onChanged: search,
              ),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'test');
      expect(result, isNull); // Still debouncing

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 50));

      expect(result, 'Result: test');
    });

    testWidgets('backward compatibility - AsyncDebouncedCallbackBuilder',
        (tester) async {
      String? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            // ignore: deprecated_member_use
            body: AsyncDebouncedCallbackBuilder<String>(
              duration: const Duration(milliseconds: 50),
              onQuery: (text) async {
                return 'Result: $text';
              },
              onResult: (r) => result = r,
              builder: (context, callback, isLoading) => TextField(
                onChanged: callback,
              ),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'test');
      expect(result, isNull);

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 50));

      expect(result, 'Result: test');
    });
  });

  group('ConcurrentAsyncThrottledBuilder', () {
    testWidgets('provides mode-based throttling', (tester) async {
      int callCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: ConcurrentAsyncThrottledBuilder(
            mode: ConcurrencyMode.drop,
            maxDuration: const Duration(seconds: 5),
            onPressed: () async {
              await Future.delayed(const Duration(milliseconds: 100));
              callCount++;
            },
            builder: (context, callback, isLoading, pendingCount) =>
                ElevatedButton(
              onPressed: callback,
              child: const Text('Call'),
            ),
          ),
        ),
      );

      // First tap
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Second tap (should be dropped)
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      await tester.pump(const Duration(milliseconds: 150));

      expect(callCount, 1);
    });
  });
}
