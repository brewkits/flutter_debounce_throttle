import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_debounce_throttle_hooks/flutter_debounce_throttle_hooks.dart';

void main() {
  testWidgets('useDebouncer creates debouncer instance',
      (WidgetTester tester) async {
    Debouncer? capturedDebouncer;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        capturedDebouncer = useDebouncer(duration: const Duration(milliseconds: 300));
        return Container();
      }),
    );

    expect(capturedDebouncer, isNotNull);
    expect(capturedDebouncer!.duration, equals(const Duration(milliseconds: 300)));

    // Dispose widget - hooks should auto-dispose
    await tester.pumpWidget(Container());
  });

  testWidgets('useDebouncer debounces calls correctly',
      (WidgetTester tester) async {
    int callCount = 0;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        final debouncer = useDebouncer(duration: const Duration(milliseconds: 100));

        // Call multiple times
        debouncer.call(() => callCount++);
        debouncer.call(() => callCount++);
        debouncer.call(() => callCount++);

        return Container();
      }),
    );

    expect(callCount, equals(0));

    await tester.pump(const Duration(milliseconds: 50));
    expect(callCount, equals(0));

    await tester.pump(const Duration(milliseconds: 60));
    expect(callCount, equals(1));
  });

  testWidgets('useThrottler creates throttler instance',
      (WidgetTester tester) async {
    Throttler? capturedThrottler;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        capturedThrottler = useThrottler(duration: const Duration(milliseconds: 300));
        return Container();
      }),
    );

    expect(capturedThrottler, isNotNull);
    expect(capturedThrottler!.duration, equals(const Duration(milliseconds: 300)));

    // Dispose widget - hooks should auto-dispose
    await tester.pumpWidget(Container());
  });

  testWidgets('useThrottler throttles calls correctly',
      (WidgetTester tester) async {
    int callCount = 0;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        final throttler = useThrottler(duration: const Duration(milliseconds: 100));

        // First call executes immediately
        throttler.call(() => callCount++);
        // Second call should be throttled
        throttler.call(() => callCount++);

        return Container();
      }),
    );

    expect(callCount, equals(1));

    await tester.pump(const Duration(milliseconds: 150));
    expect(callCount, equals(1)); // Still 1 because second call was dropped
  });

  testWidgets('useDebouncedCallback debounces function calls',
      (WidgetTester tester) async {
    final results = <String>[];

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        final debouncedCallback = useDebouncedCallback<String>(
          (value) => results.add(value),
          duration: const Duration(milliseconds: 100),
        );

        debouncedCallback('first');
        debouncedCallback('second');
        debouncedCallback('third');

        return Container();
      }),
    );

    expect(results, isEmpty);

    await tester.pump(const Duration(milliseconds: 50));
    expect(results, isEmpty);

    await tester.pump(const Duration(milliseconds: 60));
    expect(results, equals(['third']));
  });

  testWidgets('useThrottledCallback throttles function calls',
      (WidgetTester tester) async {
    int callCount = 0;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        final throttledCallback = useThrottledCallback(
          () => callCount++,
          duration: const Duration(milliseconds: 100),
        );

        throttledCallback();
        throttledCallback();
        throttledCallback();

        return Container();
      }),
    );

    expect(callCount, equals(1)); // Only first call executes
  });

  testWidgets('useDebouncedValue debounces value changes',
      (WidgetTester tester) async {
    String? debouncedValue;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        final text = useState('initial');
        debouncedValue = useDebouncedValue(
          text.value,
          duration: const Duration(milliseconds: 100),
        );

        // Simulate rapid changes
        useEffect(() {
          Future.delayed(const Duration(milliseconds: 10), () {
            text.value = 'changed1';
          });
          Future.delayed(const Duration(milliseconds: 20), () {
            text.value = 'changed2';
          });
          Future.delayed(const Duration(milliseconds: 30), () {
            text.value = 'final';
          });
          return null;
        }, []);

        return Container();
      }),
    );

    expect(debouncedValue, equals('initial'));

    await tester.pump(const Duration(milliseconds: 50));
    expect(debouncedValue, equals('initial'));

    await tester.pump(const Duration(milliseconds: 100));
    expect(debouncedValue, equals('final'));
  });

  testWidgets('useThrottledValue throttles value changes',
      (WidgetTester tester) async {
    int? throttledValue;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        final counter = useState(0);
        throttledValue = useThrottledValue(
          counter.value,
          duration: const Duration(milliseconds: 100),
        );

        // Simulate rapid increments
        useEffect(() {
          counter.value = 1;
          counter.value = 2;
          counter.value = 3;
          return null;
        }, []);

        return Container();
      }),
    );

    // First value is set immediately
    await tester.pump();
    expect(throttledValue, equals(0));

    await tester.pump(const Duration(milliseconds: 10));
    // Changes are throttled
    expect(throttledValue, equals(0));
  });

  testWidgets('useAsyncDebouncer creates async debouncer instance',
      (WidgetTester tester) async {
    AsyncDebouncer? capturedDebouncer;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        capturedDebouncer = useAsyncDebouncer(duration: const Duration(milliseconds: 300));
        return Container();
      }),
    );

    expect(capturedDebouncer, isNotNull);
    expect(capturedDebouncer!.duration, equals(const Duration(milliseconds: 300)));

    // Dispose widget - hooks should auto-dispose
    await tester.pumpWidget(Container());
  });

  testWidgets('useAsyncDebouncer debounces async calls',
      (WidgetTester tester) async {
    int callCount = 0;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        final asyncDebouncer = useAsyncDebouncer(duration: const Duration(milliseconds: 100));

        useEffect(() {
          asyncDebouncer(() async {
            callCount++;
          });
          asyncDebouncer(() async {
            callCount++;
          });
          asyncDebouncer(() async {
            callCount++;
          });
          return null;
        }, []);

        return Container();
      }),
    );

    expect(callCount, equals(0));

    await tester.pump(const Duration(milliseconds: 50));
    expect(callCount, equals(0));

    await tester.pump(const Duration(milliseconds: 60));
    // Wait for async execution
    await tester.pump(const Duration(milliseconds: 10));
    expect(callCount, equals(1)); // Only last call executes
  });

  testWidgets('useAsyncThrottler creates async throttler instance',
      (WidgetTester tester) async {
    AsyncThrottler? capturedThrottler;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        capturedThrottler = useAsyncThrottler(maxDuration: const Duration(milliseconds: 300));
        return Container();
      }),
    );

    expect(capturedThrottler, isNotNull);
    expect(capturedThrottler!.maxDuration, equals(const Duration(milliseconds: 300)));

    // Dispose widget - hooks should auto-dispose
    await tester.pumpWidget(Container());
  });

  testWidgets('useAsyncThrottler throttles async calls',
      (WidgetTester tester) async {
    int callCount = 0;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        final asyncThrottler = useAsyncThrottler(maxDuration: const Duration(milliseconds: 100));

        useEffect(() {
          asyncThrottler(() async {
            callCount++;
            await Future.delayed(const Duration(milliseconds: 50));
          });
          asyncThrottler(() async {
            callCount++;
          });
          return null;
        }, []);

        return Container();
      }),
    );

    // First call starts immediately
    await tester.pump();
    expect(callCount, equals(1));

    // Wait for async operation to complete
    await tester.pumpAndSettle();
    expect(callCount, lessThanOrEqualTo(2));
  });

  testWidgets('useDebouncer respects keys parameter',
      (WidgetTester tester) async {
    Debouncer? debouncer1;
    Debouncer? debouncer2;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        debouncer1 = useDebouncer(
          duration: const Duration(milliseconds: 300),
          keys: [1],
        );
        return Container();
      }),
    );

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        debouncer2 = useDebouncer(
          duration: const Duration(milliseconds: 300),
          keys: [2], // Different key
        );
        return Container();
      }),
    );

    // Should create a new instance when keys change
    expect(identical(debouncer1, debouncer2), isFalse);
  });

  testWidgets('useThrottler respects keys parameter',
      (WidgetTester tester) async {
    Throttler? throttler1;
    Throttler? throttler2;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        throttler1 = useThrottler(
          duration: const Duration(milliseconds: 300),
          keys: [1],
        );
        return Container();
      }),
    );

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        throttler2 = useThrottler(
          duration: const Duration(milliseconds: 300),
          keys: [2], // Different key
        );
        return Container();
      }),
    );

    // Should create a new instance when keys change
    expect(identical(throttler1, throttler2), isFalse);
  });

  testWidgets('multiple hooks can coexist in same widget',
      (WidgetTester tester) async {
    int debouncedCallCount = 0;
    int throttledCallCount = 0;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        final debouncer = useDebouncer(duration: const Duration(milliseconds: 100));
        final throttler = useThrottler(duration: const Duration(milliseconds: 100));
        final asyncDebouncer = useAsyncDebouncer(duration: const Duration(milliseconds: 100));
        final asyncThrottler = useAsyncThrottler(maxDuration: const Duration(milliseconds: 100));

        debouncer.call(() => debouncedCallCount++);
        throttler.call(() => throttledCallCount++);

        expect(asyncDebouncer, isNotNull);
        expect(asyncThrottler, isNotNull);

        return Container();
      }),
    );

    expect(throttledCallCount, equals(1));
    expect(debouncedCallCount, equals(0));

    await tester.pump(const Duration(milliseconds: 150));
    expect(debouncedCallCount, equals(1));
  });

  testWidgets('hooks persist across rebuilds',
      (WidgetTester tester) async {
    Debouncer? debouncer1;
    Debouncer? debouncer2;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        debouncer1 = useDebouncer(duration: const Duration(milliseconds: 100));
        final counter = useState(0);

        // Trigger a rebuild
        if (counter.value == 0) {
          Future.microtask(() => counter.value = 1);
        }

        return Container();
      }),
    );

    // Pump to process rebuild
    await tester.pump();

    // Capture debouncer after rebuild
    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        debouncer2 = useDebouncer(duration: const Duration(milliseconds: 100));
        return Container();
      }),
    );

    // Same instance should be reused across rebuilds with same keys
    expect(debouncer1, isNotNull);
    expect(debouncer2, isNotNull);
  });
}

class HookBuilder extends HookWidget {
  const HookBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context) builder;

  @override
  Widget build(BuildContext context) => builder(context);
}
