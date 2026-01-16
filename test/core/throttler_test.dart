import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_debounce_throttle/flutter_debounce_throttle.dart';

void main() {
  group('Throttler', () {
    late Throttler throttler;

    tearDown(() {
      throttler.dispose();
    });

    test('executes immediately on first call', () {
      throttler = Throttler(duration: const Duration(milliseconds: 100));
      int callCount = 0;

      throttler.call(() => callCount++);

      expect(callCount, 1);
    });

    test('blocks subsequent calls within duration', () {
      throttler = Throttler(duration: const Duration(milliseconds: 100));
      int callCount = 0;

      throttler.call(() => callCount++);
      throttler.call(() => callCount++);
      throttler.call(() => callCount++);

      expect(callCount, 1);
    });

    test('allows calls after duration expires', () async {
      throttler = Throttler(duration: const Duration(milliseconds: 50));
      int callCount = 0;

      throttler.call(() => callCount++);
      expect(callCount, 1);

      await Future.delayed(const Duration(milliseconds: 60));
      throttler.call(() => callCount++);
      expect(callCount, 2);
    });

    test('wrap() returns a VoidCallback', () {
      throttler = Throttler(duration: const Duration(milliseconds: 100));
      int callCount = 0;

      final wrapped = throttler.wrap(() => callCount++);
      expect(wrapped, isNotNull);

      wrapped!();
      wrapped();
      wrapped();

      expect(callCount, 1);
    });

    test('reset() clears throttle state', () {
      throttler = Throttler(duration: const Duration(milliseconds: 100));
      int callCount = 0;

      throttler.call(() => callCount++);
      expect(callCount, 1);

      throttler.reset();
      throttler.call(() => callCount++);
      expect(callCount, 2);
    });

    test('isThrottled returns correct state', () async {
      throttler = Throttler(duration: const Duration(milliseconds: 50));

      expect(throttler.isThrottled, false);

      throttler.call(() {});
      expect(throttler.isThrottled, true);

      await Future.delayed(const Duration(milliseconds: 60));
      expect(throttler.isThrottled, false);
    });

    test('uses global config duration when not specified', () {
      DebounceThrottleConfig.init(
        defaultThrottleDuration: const Duration(milliseconds: 200),
      );

      throttler = Throttler();
      int callCount = 0;

      throttler.call(() => callCount++);
      throttler.call(() => callCount++);

      expect(callCount, 1);

      // Reset global config
      DebounceThrottleConfig.reset();
    });

    test('debugMode logs messages', () {
      throttler = Throttler(
        duration: const Duration(milliseconds: 100),
        debugMode: true,
        name: 'TestThrottler',
      );

      // Should not throw
      throttler.call(() {});
    });

    test('enabled=false bypasses throttle', () {
      throttler = Throttler(
        duration: const Duration(milliseconds: 100),
        enabled: false,
      );
      int callCount = 0;

      throttler.call(() => callCount++);
      throttler.call(() => callCount++);
      throttler.call(() => callCount++);

      expect(callCount, 3);
    });

    test('callWithDuration uses custom duration', () async {
      throttler = Throttler(duration: const Duration(milliseconds: 200));
      int callCount = 0;

      throttler.callWithDuration(
        () => callCount++,
        const Duration(milliseconds: 50),
      );
      expect(callCount, 1);

      await Future.delayed(const Duration(milliseconds: 60));
      throttler.call(() => callCount++);
      expect(callCount, 2);
    });

    test('onMetrics callback is called', () {
      Duration? metricsDuration;
      bool? metricsExecuted;

      throttler = Throttler(
        duration: const Duration(milliseconds: 100),
        onMetrics: (duration, executed) {
          metricsDuration = duration;
          metricsExecuted = executed;
        },
      );

      throttler.call(() {});

      expect(metricsDuration, isNotNull);
      expect(metricsExecuted, true);

      throttler.call(() {});
      expect(metricsExecuted, false); // Blocked call
    });

    test('multiple throttlers work independently', () {
      final throttler1 = Throttler(duration: const Duration(milliseconds: 100));
      final throttler2 = Throttler(duration: const Duration(milliseconds: 100));
      int count1 = 0;
      int count2 = 0;

      throttler1.call(() => count1++);
      throttler2.call(() => count2++);

      throttler1.call(() => count1++);
      throttler2.call(() => count2++);

      expect(count1, 1);
      expect(count2, 1);

      throttler1.dispose();
      throttler2.dispose();
    });
  });
}
