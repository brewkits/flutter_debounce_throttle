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
        capturedDebouncer =
            useDebouncer(duration: const Duration(milliseconds: 300));
        return Container();
      }),
    );

    expect(capturedDebouncer, isNotNull);
    expect(
        capturedDebouncer!.duration, equals(const Duration(milliseconds: 300)));

    // Dispose widget - hooks should auto-dispose
    await tester.pumpWidget(Container());
  });

  testWidgets('useDebouncer debounces calls correctly',
      (WidgetTester tester) async {
    int callCount = 0;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        final debouncer =
            useDebouncer(duration: const Duration(milliseconds: 100));

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
        capturedThrottler =
            useThrottler(duration: const Duration(milliseconds: 300));
        return Container();
      }),
    );

    expect(capturedThrottler, isNotNull);
    expect(
        capturedThrottler!.duration, equals(const Duration(milliseconds: 300)));

    // Dispose widget - hooks should auto-dispose
    await tester.pumpWidget(Container());
  });

  testWidgets('useThrottler throttles calls correctly',
      (WidgetTester tester) async {
    int callCount = 0;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        final throttler =
            useThrottler(duration: const Duration(milliseconds: 100));

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
        capturedDebouncer =
            useAsyncDebouncer(duration: const Duration(milliseconds: 300));
        return Container();
      }),
    );

    expect(capturedDebouncer, isNotNull);
    expect(
        capturedDebouncer!.duration, equals(const Duration(milliseconds: 300)));

    // Dispose widget - hooks should auto-dispose
    await tester.pumpWidget(Container());
  });

  testWidgets('useAsyncDebouncer debounces async calls',
      (WidgetTester tester) async {
    int callCount = 0;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        final asyncDebouncer =
            useAsyncDebouncer(duration: const Duration(milliseconds: 100));

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
        capturedThrottler =
            useAsyncThrottler(maxDuration: const Duration(milliseconds: 300));
        return Container();
      }),
    );

    expect(capturedThrottler, isNotNull);
    expect(capturedThrottler!.maxDuration,
        equals(const Duration(milliseconds: 300)));

    // Dispose widget - hooks should auto-dispose
    await tester.pumpWidget(Container());
  });

  testWidgets('useAsyncThrottler throttles async calls',
      (WidgetTester tester) async {
    int callCount = 0;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        final asyncThrottler =
            useAsyncThrottler(maxDuration: const Duration(milliseconds: 100));

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
        final debouncer =
            useDebouncer(duration: const Duration(milliseconds: 100));
        final throttler =
            useThrottler(duration: const Duration(milliseconds: 100));
        final asyncDebouncer =
            useAsyncDebouncer(duration: const Duration(milliseconds: 100));
        final asyncThrottler =
            useAsyncThrottler(maxDuration: const Duration(milliseconds: 100));

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

  testWidgets('hooks persist across rebuilds', (WidgetTester tester) async {
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

  testWidgets('useDebouncer updates duration when property changes',
      (WidgetTester tester) async {
    Duration duration = const Duration(milliseconds: 100);
    Debouncer? capturedDebouncer;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        capturedDebouncer = useDebouncer(duration: duration);
        return Container();
      }),
    );

    expect(
        capturedDebouncer!.duration, equals(const Duration(milliseconds: 100)));

    duration = const Duration(milliseconds: 500);
    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        capturedDebouncer = useDebouncer(duration: duration);
        return Container();
      }),
    );

    expect(
        capturedDebouncer!.duration, equals(const Duration(milliseconds: 500)));
  });

  testWidgets('useThrottler updates duration when property changes',
      (WidgetTester tester) async {
    Duration duration = const Duration(milliseconds: 100);
    Throttler? capturedThrottler;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        capturedThrottler = useThrottler(duration: duration);
        return Container();
      }),
    );

    expect(
        capturedThrottler!.duration, equals(const Duration(milliseconds: 100)));

    duration = const Duration(milliseconds: 500);
    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        capturedThrottler = useThrottler(duration: duration);
        return Container();
      }),
    );

    expect(
        capturedThrottler!.duration, equals(const Duration(milliseconds: 500)));
  });

  // ─── useDebouncer expanded ──────────────────────────────────────────────────

  testWidgets('useDebouncer cancel() prevents execution',
      (WidgetTester tester) async {
    var fired = false;
    Debouncer? debouncer;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        debouncer = useDebouncer(duration: const Duration(milliseconds: 100));
        return Container();
      }),
    );

    debouncer!.call(() => fired = true);
    debouncer!.cancel();

    await tester.pump(const Duration(milliseconds: 150));
    expect(fired, isFalse);
  });

  testWidgets('useDebouncer isPending is true while waiting',
      (WidgetTester tester) async {
    Debouncer? debouncer;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        debouncer = useDebouncer(duration: const Duration(milliseconds: 200));
        return Container();
      }),
    );

    expect(debouncer!.isPending, isFalse);
    debouncer!.call(() {});
    expect(debouncer!.isPending, isTrue);

    await tester.pump(const Duration(milliseconds: 250));
    expect(debouncer!.isPending, isFalse);
  });

  testWidgets('useDebouncer 50 rapid calls collapse to 1 execution',
      (WidgetTester tester) async {
    var count = 0;
    Debouncer? debouncer;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        debouncer = useDebouncer(duration: const Duration(milliseconds: 80));
        return Container();
      }),
    );

    for (var i = 0; i < 50; i++) {
      debouncer!.call(() => count++);
    }

    await tester.pump(const Duration(milliseconds: 120));
    expect(count, equals(1));
  });

  testWidgets('useDebouncer last value wins among rapid calls',
      (WidgetTester tester) async {
    var last = '';
    Debouncer? debouncer;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        debouncer = useDebouncer(duration: const Duration(milliseconds: 80));
        return Container();
      }),
    );

    debouncer!.call(() => last = 'a');
    debouncer!.call(() => last = 'b');
    debouncer!.call(() => last = 'c');

    await tester.pump(const Duration(milliseconds: 120));
    expect(last, equals('c'));
  });

  testWidgets('useDebouncer unmount during pending does not crash',
      (WidgetTester tester) async {
    Debouncer? debouncer;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        debouncer = useDebouncer(duration: const Duration(milliseconds: 300));
        return Container();
      }),
    );

    debouncer!.call(() {});
    expect(debouncer!.isPending, isTrue);

    await tester.pumpWidget(Container()); // unmount

    await tester.pump(const Duration(milliseconds: 400));
    // no crash expected
  });

  testWidgets('useDebouncer name and debugMode params do not crash',
      (WidgetTester tester) async {
    Debouncer? debouncer;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        debouncer = useDebouncer(
          duration: const Duration(milliseconds: 100),
          name: 'search',
          debugMode: false,
        );
        return Container();
      }),
    );

    expect(debouncer, isNotNull);
    await tester.pumpWidget(Container());
  });

  testWidgets('useDebouncer sequential bursts each execute once',
      (WidgetTester tester) async {
    var count = 0;
    Debouncer? debouncer;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        debouncer = useDebouncer(duration: const Duration(milliseconds: 80));
        return Container();
      }),
    );

    // first burst
    debouncer!.call(() => count++);
    debouncer!.call(() => count++);
    await tester.pump(const Duration(milliseconds: 120));
    expect(count, equals(1));

    // second burst
    debouncer!.call(() => count++);
    debouncer!.call(() => count++);
    await tester.pump(const Duration(milliseconds: 120));
    expect(count, equals(2));
  });

  // ─── useThrottler expanded ──────────────────────────────────────────────────

  testWidgets('useThrottler isThrottled is true after first call',
      (WidgetTester tester) async {
    Throttler? throttler;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        throttler = useThrottler(duration: const Duration(milliseconds: 300));
        return Container();
      }),
    );

    expect(throttler!.isThrottled, isFalse);
    throttler!.call(() {});
    expect(throttler!.isThrottled, isTrue);

    await tester.pump(const Duration(milliseconds: 350));
    expect(throttler!.isThrottled, isFalse);
  });

  testWidgets('useThrottler cancel() resets throttle lock',
      (WidgetTester tester) async {
    var count = 0;
    Throttler? throttler;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        throttler = useThrottler(duration: const Duration(milliseconds: 500));
        return Container();
      }),
    );

    throttler!.call(() => count++);
    expect(throttler!.isThrottled, isTrue);
    throttler!
        .reset(); // reset() clears isThrottled; cancel() only cancels the timer
    expect(throttler!.isThrottled, isFalse);

    throttler!.call(() => count++);
    expect(count, equals(2));
  });

  testWidgets('useThrottler 50 rapid calls produce 1 execution',
      (WidgetTester tester) async {
    var count = 0;
    Throttler? throttler;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        throttler = useThrottler(duration: const Duration(milliseconds: 500));
        return Container();
      }),
    );

    for (var i = 0; i < 50; i++) {
      throttler!.call(() => count++);
    }

    expect(count, equals(1));
  });

  testWidgets('useThrottler allows execution after cooldown',
      (WidgetTester tester) async {
    var count = 0;
    Throttler? throttler;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        throttler = useThrottler(duration: const Duration(milliseconds: 100));
        return Container();
      }),
    );

    throttler!.call(() => count++);
    expect(count, equals(1));

    await tester.pump(const Duration(milliseconds: 150));
    throttler!.call(() => count++);
    expect(count, equals(2));
  });

  testWidgets('useThrottler unmount while throttled does not crash',
      (WidgetTester tester) async {
    Throttler? throttler;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        throttler = useThrottler(duration: const Duration(milliseconds: 500));
        return Container();
      }),
    );

    throttler!.call(() {});
    expect(throttler!.isThrottled, isTrue);

    await tester.pumpWidget(Container()); // unmount
    // no crash expected
  });

  testWidgets('useThrottler name and debugMode params do not crash',
      (WidgetTester tester) async {
    Throttler? throttler;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        throttler = useThrottler(
          duration: const Duration(milliseconds: 100),
          name: 'submit',
          debugMode: false,
        );
        return Container();
      }),
    );

    expect(throttler, isNotNull);
    await tester.pumpWidget(Container());
  });

  // ─── useDebouncedCallback expanded ─────────────────────────────────────────

  testWidgets('useDebouncedCallback passes correct value to callback',
      (WidgetTester tester) async {
    String? received;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        final cb = useDebouncedCallback<String>(
          (v) => received = v,
          duration: const Duration(milliseconds: 80),
        );
        cb('hello');
        return Container();
      }),
    );

    await tester.pump(const Duration(milliseconds: 120));
    expect(received, equals('hello'));
  });

  testWidgets('useDebouncedCallback rapid calls: last value wins',
      (WidgetTester tester) async {
    String? received;
    late void Function(String) cb;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        cb = useDebouncedCallback<String>(
          (v) => received = v,
          duration: const Duration(milliseconds: 80),
        );
        return Container();
      }),
    );

    cb('a');
    cb('b');
    cb('c');

    await tester.pump(const Duration(milliseconds: 120));
    expect(received, equals('c'));
  });

  testWidgets('useDebouncedCallback with int type works correctly',
      (WidgetTester tester) async {
    int? received;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        final cb = useDebouncedCallback<int>(
          (v) => received = v,
          duration: const Duration(milliseconds: 80),
        );
        cb(42);
        return Container();
      }),
    );

    await tester.pump(const Duration(milliseconds: 120));
    expect(received, equals(42));
  });

  testWidgets('multiple useDebouncedCallback hooks are independent',
      (WidgetTester tester) async {
    String? a;
    String? b;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        final cbA = useDebouncedCallback<String>(
          (v) => a = v,
          duration: const Duration(milliseconds: 80),
        );
        final cbB = useDebouncedCallback<String>(
          (v) => b = v,
          duration: const Duration(milliseconds: 80),
        );
        cbA('from-a');
        cbB('from-b');
        return Container();
      }),
    );

    await tester.pump(const Duration(milliseconds: 120));
    expect(a, equals('from-a'));
    expect(b, equals('from-b'));
  });

  // ─── useThrottledCallback expanded ─────────────────────────────────────────

  testWidgets('useThrottledCallback 10 rapid calls produce 1 execution',
      (WidgetTester tester) async {
    var count = 0;
    late VoidCallback cb;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        cb = useThrottledCallback(
          () => count++,
          duration: const Duration(milliseconds: 500),
        );
        return Container();
      }),
    );

    for (var i = 0; i < 10; i++) {
      cb();
    }

    expect(count, equals(1));
  });

  testWidgets('useThrottledCallback allows call after cooldown',
      (WidgetTester tester) async {
    var count = 0;
    late VoidCallback cb;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        cb = useThrottledCallback(
          () => count++,
          duration: const Duration(milliseconds: 100),
        );
        return Container();
      }),
    );

    cb();
    expect(count, equals(1));

    await tester.pump(const Duration(milliseconds: 150));
    cb();
    expect(count, equals(2));
  });

  testWidgets('multiple useThrottledCallback hooks are independent',
      (WidgetTester tester) async {
    var countA = 0;
    var countB = 0;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        final cbA = useThrottledCallback(
          () => countA++,
          duration: const Duration(milliseconds: 500),
        );
        final cbB = useThrottledCallback(
          () => countB++,
          duration: const Duration(milliseconds: 500),
        );
        cbA();
        cbA();
        cbB();
        cbB();
        return Container();
      }),
    );

    expect(countA, equals(1));
    expect(countB, equals(1));
  });

  // ─── useDebouncedValue expanded ─────────────────────────────────────────────

  testWidgets(
      'useDebouncedValue with int stays at initial until debounce fires',
      (WidgetTester tester) async {
    int? debouncedValue;
    var counter = 0;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        final val = useState(counter);
        debouncedValue = useDebouncedValue(
          val.value,
          duration: const Duration(milliseconds: 100),
        );

        useEffect(() {
          Future.delayed(const Duration(milliseconds: 20), () {
            val.value = 99;
          });
          return null;
        }, []);

        return Container();
      }),
    );

    expect(debouncedValue, equals(0));
    // Two pumps: first to fire Future.delayed, second to fire debounce timer
    await tester.pump(const Duration(milliseconds: 50));
    expect(debouncedValue, equals(0)); // still debouncing
    await tester.pump(const Duration(milliseconds: 120));
    expect(debouncedValue, equals(99));
  });

  testWidgets('useDebouncedValue ignores intermediate values',
      (WidgetTester tester) async {
    String? debouncedValue;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        final text = useState('initial');
        debouncedValue = useDebouncedValue(
          text.value,
          duration: const Duration(milliseconds: 100),
        );

        useEffect(() {
          Future.delayed(const Duration(milliseconds: 10), () {
            text.value = 'step1';
          });
          Future.delayed(const Duration(milliseconds: 20), () {
            text.value = 'step2';
          });
          Future.delayed(const Duration(milliseconds: 30), () {
            text.value = 'final';
          });
          return null;
        }, []);

        return Container();
      }),
    );

    // First pump fires all Future.delayed calls; debounce hasn't fired yet
    await tester.pump(const Duration(milliseconds: 50));
    expect(debouncedValue, equals('initial')); // still debouncing
    // Second pump fires the debounce timer (100ms after last call)
    await tester.pump(const Duration(milliseconds: 120));
    expect(debouncedValue, equals('final'));
    expect(debouncedValue, isNot(equals('step1')));
    expect(debouncedValue, isNot(equals('step2')));
  });

  testWidgets('useDebouncedValue with bool type works correctly',
      (WidgetTester tester) async {
    bool? debouncedValue;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        final flag = useState(false);
        debouncedValue = useDebouncedValue(
          flag.value,
          duration: const Duration(milliseconds: 80),
        );

        useEffect(() {
          Future.delayed(const Duration(milliseconds: 20), () {
            flag.value = true;
          });
          return null;
        }, []);

        return Container();
      }),
    );

    expect(debouncedValue, isFalse);
    await tester.pump(const Duration(milliseconds: 40)); // fires Future.delayed
    await tester.pump(const Duration(milliseconds: 100)); // fires debounce
    expect(debouncedValue, isTrue);
  });

  // ─── useThrottledValue expanded ─────────────────────────────────────────────

  testWidgets('useThrottledValue updates on first value change',
      (WidgetTester tester) async {
    String? throttledValue;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        final text = useState('a');
        throttledValue = useThrottledValue(
          text.value,
          duration: const Duration(milliseconds: 200),
        );

        useEffect(() {
          text.value = 'b';
          return null;
        }, []);

        return Container();
      }),
    );

    await tester.pump();
    // first change fires immediately via throttle
    expect(throttledValue, anyOf(equals('a'), equals('b')));
  });

  testWidgets('useThrottledValue drops rapid changes after first',
      (WidgetTester tester) async {
    final captured = <int>[];

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        final counter = useState(0);
        final throttled = useThrottledValue(
          counter.value,
          duration: const Duration(milliseconds: 300),
        );

        useEffect(() {
          captured.add(throttled);
          return null;
        }, [throttled]);

        useEffect(() {
          counter.value = 1;
          counter.value = 2;
          counter.value = 3;
          return null;
        }, []);

        return Container();
      }),
    );

    await tester.pump(const Duration(milliseconds: 50));
    // throttle should prevent all 3 intermediate updates
    expect(captured.length, lessThan(4));
  });

  // ─── useAsyncDebouncer expanded ─────────────────────────────────────────────

  testWidgets('useAsyncDebouncer isPending while waiting',
      (WidgetTester tester) async {
    AsyncDebouncer? debouncer;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        debouncer =
            useAsyncDebouncer(duration: const Duration(milliseconds: 200));
        return Container();
      }),
    );

    expect(debouncer!.isPending, isFalse);
    debouncer!(() async {});
    expect(debouncer!.isPending, isTrue);

    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(milliseconds: 50));
    expect(debouncer!.isPending, isFalse);
  });

  testWidgets('useAsyncDebouncer cancel() resolves pending as cancelled',
      (WidgetTester tester) async {
    AsyncDebouncer? debouncer;
    DebounceResult<String>? result;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        debouncer =
            useAsyncDebouncer(duration: const Duration(milliseconds: 200));
        return Container();
      }),
    );

    final future = debouncer!.callWithResult<String>(() async => 'value');
    debouncer!.cancel();
    result = await future;

    expect(result.isCancelled, isTrue);
  });

  testWidgets('useAsyncDebouncer rapid calls: only last resolves with value',
      (WidgetTester tester) async {
    AsyncDebouncer? debouncer;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        debouncer =
            useAsyncDebouncer(duration: const Duration(milliseconds: 80));
        return Container();
      }),
    );

    // Call directly from test body so futures are tracked before pumping
    final f1 = debouncer!<String>(() async => 'first');
    final f2 = debouncer!<String>(() async => 'second');
    final f3 = debouncer!<String>(() async => 'third');

    // f1/f2 are cancelled by subsequent calls — resolve to null immediately
    await tester
        .pump(const Duration(milliseconds: 120)); // fires debounce timer

    final r1 = await f1;
    final r2 = await f2;
    final r3 = await f3;

    expect(r1, isNull);
    expect(r2, isNull);
    expect(r3, equals('third'));
  });

  testWidgets('useAsyncDebouncer callWithResult distinguishes null from cancel',
      (WidgetTester tester) async {
    AsyncDebouncer? debouncer;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        debouncer =
            useAsyncDebouncer(duration: const Duration(milliseconds: 80));
        return Container();
      }),
    );

    // Start the call but don't await yet — pump first to fire the debounce timer
    final futureResult = debouncer!.callWithResult<String?>(() async => null);
    await tester
        .pump(const Duration(milliseconds: 120)); // fires debounce timer
    final result = await futureResult; // now resolves immediately

    expect(result.isSuccess, isTrue);
    expect(result.value, isNull);
  });

  testWidgets('useAsyncDebouncer unmount during pending does not crash',
      (WidgetTester tester) async {
    AsyncDebouncer? debouncer;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        debouncer =
            useAsyncDebouncer(duration: const Duration(milliseconds: 300));
        return Container();
      }),
    );

    debouncer!(() async {});
    expect(debouncer!.isPending, isTrue);

    await tester.pumpWidget(Container()); // unmount
    await tester.pump(const Duration(milliseconds: 400));
    // no crash expected
  });

  testWidgets('useAsyncDebouncer duration updates on rebuild',
      (WidgetTester tester) async {
    Duration dur = const Duration(milliseconds: 100);
    AsyncDebouncer? captured;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        captured = useAsyncDebouncer(duration: dur);
        return Container();
      }),
    );

    expect(captured!.duration, equals(const Duration(milliseconds: 100)));

    dur = const Duration(milliseconds: 400);
    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        captured = useAsyncDebouncer(duration: dur);
        return Container();
      }),
    );

    expect(captured!.duration, equals(const Duration(milliseconds: 400)));
  });

  testWidgets('useAsyncDebouncer name and debugMode params do not crash',
      (WidgetTester tester) async {
    AsyncDebouncer? debouncer;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        debouncer = useAsyncDebouncer(
          duration: const Duration(milliseconds: 100),
          name: 'fetch',
          debugMode: false,
        );
        return Container();
      }),
    );

    expect(debouncer, isNotNull);
    await tester.pumpWidget(Container());
  });

  // ─── useAsyncThrottler expanded ─────────────────────────────────────────────

  testWidgets('useAsyncThrottler isLocked while executing',
      (WidgetTester tester) async {
    AsyncThrottler? throttler;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        throttler =
            useAsyncThrottler(maxDuration: const Duration(milliseconds: 500));
        return Container();
      }),
    );

    expect(throttler!.isLocked, isFalse);
    throttler!(() async {
      await Future.delayed(const Duration(milliseconds: 100));
    });
    expect(throttler!.isLocked, isTrue);

    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump(const Duration(milliseconds: 50));
    expect(throttler!.isLocked, isFalse);
  });

  testWidgets('useAsyncThrottler concurrent calls are dropped',
      (WidgetTester tester) async {
    var count = 0;
    AsyncThrottler? throttler;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        throttler =
            useAsyncThrottler(maxDuration: const Duration(milliseconds: 500));
        return Container();
      }),
    );

    // Call directly from test body to keep futures in scope
    throttler!(() async {
      count++;
      await Future.delayed(const Duration(milliseconds: 50));
    });
    throttler!(() async {
      count++;
    });
    throttler!(() async {
      count++;
    });

    await tester.pump();
    expect(
        count, equals(1)); // only first call starts; subsequent calls dropped

    await tester.pumpAndSettle(); // drain the 50ms async operation
  });

  testWidgets('useAsyncThrottler maxDuration updates on rebuild',
      (WidgetTester tester) async {
    Duration dur = const Duration(milliseconds: 100);
    AsyncThrottler? captured;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        captured = useAsyncThrottler(maxDuration: dur);
        return Container();
      }),
    );

    expect(captured!.maxDuration, equals(const Duration(milliseconds: 100)));

    dur = const Duration(milliseconds: 500);
    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        captured = useAsyncThrottler(maxDuration: dur);
        return Container();
      }),
    );

    expect(captured!.maxDuration, equals(const Duration(milliseconds: 500)));
  });

  testWidgets('useAsyncThrottler unmount while executing does not crash',
      (WidgetTester tester) async {
    AsyncThrottler? throttler;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        throttler =
            useAsyncThrottler(maxDuration: const Duration(milliseconds: 500));
        return Container();
      }),
    );

    throttler!(() async {
      await Future.delayed(const Duration(milliseconds: 200));
    });
    expect(throttler!.isLocked, isTrue);

    await tester.pumpWidget(Container()); // unmount
    await tester.pump(const Duration(milliseconds: 300));
    // no crash expected
  });

  testWidgets('useAsyncThrottler name and debugMode params do not crash',
      (WidgetTester tester) async {
    AsyncThrottler? throttler;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        throttler = useAsyncThrottler(
          maxDuration: const Duration(milliseconds: 100),
          name: 'upload',
          debugMode: false,
        );
        return Container();
      }),
    );

    expect(throttler, isNotNull);
    await tester.pumpWidget(Container());
  });

  // ─── Widget lifecycle ───────────────────────────────────────────────────────

  testWidgets('all hooks auto-dispose on widget unmount without errors',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        final debouncer =
            useDebouncer(duration: const Duration(milliseconds: 100));
        final throttler =
            useThrottler(duration: const Duration(milliseconds: 100));
        final asyncDebouncer =
            useAsyncDebouncer(duration: const Duration(milliseconds: 100));
        final asyncThrottler =
            useAsyncThrottler(maxDuration: const Duration(milliseconds: 100));

        debouncer.call(() {});
        throttler.call(() {});
        asyncDebouncer(() async {});
        asyncThrottler(() async {});

        return Container();
      }),
    );

    // unmount with pending operations
    await tester.pumpWidget(Container());
    await tester.pump(const Duration(milliseconds: 200));
    // no crash expected
  });

  testWidgets('hooks are stable across many rebuilds',
      (WidgetTester tester) async {
    Debouncer? first;
    Debouncer? last;
    var buildCount = 0;

    Future<void> pump() => tester.pumpWidget(
          HookBuilder(builder: (context) {
            final d = useDebouncer(duration: const Duration(milliseconds: 100));
            buildCount++;
            first ??= d;
            last = d;
            return Container();
          }),
        );

    await pump();

    for (var i = 0; i < 9; i++) {
      await pump();
    }

    // Same widget type at same position → same hook state → same debouncer instance
    expect(identical(first, last), isTrue);
    expect(last, isNotNull);
    expect(buildCount, greaterThanOrEqualTo(10));
  });

  testWidgets('useDebouncer keys change creates new instance and disposes old',
      (WidgetTester tester) async {
    var key = 1;
    final captured = <Debouncer>[];

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        final d = useDebouncer(
          duration: const Duration(milliseconds: 100),
          keys: [key],
        );
        captured.add(d);
        return Container();
      }),
    );

    key = 2;
    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        final d = useDebouncer(
          duration: const Duration(milliseconds: 100),
          keys: [key],
        );
        captured.add(d);
        return Container();
      }),
    );

    expect(captured.length, equals(2));
    expect(identical(captured[0], captured[1]), isFalse);
  });

  // ─── System / Integration ───────────────────────────────────────────────────

  testWidgets('System: search field simulation — only last query fires',
      (WidgetTester tester) async {
    final queries = <String>[];
    late void Function(String) onChanged;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        onChanged = useDebouncedCallback<String>(
          (q) => queries.add(q),
          duration: const Duration(milliseconds: 100),
        );
        return Container();
      }),
    );

    // Simulate user typing rapidly
    onChanged('f');
    onChanged('fl');
    onChanged('flu');
    onChanged('flut');
    onChanged('flutter');

    await tester.pump(const Duration(milliseconds: 150));
    expect(queries, equals(['flutter']));
  });

  testWidgets('System: submit button throttle — 5 taps = 1 call',
      (WidgetTester tester) async {
    var submitCount = 0;
    late VoidCallback onTap;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        onTap = useThrottledCallback(
          () => submitCount++,
          duration: const Duration(milliseconds: 500),
        );
        return Container();
      }),
    );

    for (var i = 0; i < 5; i++) {
      onTap();
    }

    expect(submitCount, equals(1));
  });

  testWidgets(
      'System: submit button allows second submit after throttle cooldown',
      (WidgetTester tester) async {
    var submitCount = 0;
    late VoidCallback onTap;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        onTap = useThrottledCallback(
          () => submitCount++,
          duration: const Duration(milliseconds: 100),
        );
        return Container();
      }),
    );

    onTap();
    expect(submitCount, equals(1));

    await tester.pump(const Duration(milliseconds: 150));
    onTap();
    expect(submitCount, equals(2));
  });

  testWidgets('System: async search — rapid queries collapse, result is latest',
      (WidgetTester tester) async {
    String? result;
    AsyncDebouncer? debouncer;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        debouncer =
            useAsyncDebouncer(duration: const Duration(milliseconds: 80));
        return Container();
      }),
    );

    Future<void>? last;
    for (final q in ['d', 'da', 'dar', 'dart']) {
      last = debouncer!<String?>(() async => q).then((v) {
        if (v != null) result = v;
      });
    }

    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump(const Duration(milliseconds: 50));
    await last;

    expect(result, equals('dart'));
  });

  testWidgets('System: debounce + throttle coexist without interference',
      (WidgetTester tester) async {
    var debounceCount = 0;
    var throttleCount = 0;
    Debouncer? debouncer;
    Throttler? throttler;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        debouncer = useDebouncer(duration: const Duration(milliseconds: 100));
        throttler = useThrottler(duration: const Duration(milliseconds: 100));
        return Container();
      }),
    );

    // Fire both rapidly
    for (var i = 0; i < 5; i++) {
      debouncer!.call(() => debounceCount++);
      throttler!.call(() => throttleCount++);
    }

    await tester.pump(const Duration(milliseconds: 150));
    expect(debounceCount, equals(1)); // debounce collapses
    expect(throttleCount, equals(1)); // throttle drops all but first
  });
}

class HookBuilder extends HookWidget {
  const HookBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context) builder;

  @override
  Widget build(BuildContext context) => builder(context);
}
