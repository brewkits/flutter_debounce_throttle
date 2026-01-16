import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_debounce_throttle/flutter_debounce_throttle.dart';

void main() {
  group('HighFrequencyThrottler', () {
    late HighFrequencyThrottler throttler;

    tearDown(() {
      throttler.dispose();
    });

    test('executes first call immediately', () {
      throttler = HighFrequencyThrottler(
        duration: const Duration(milliseconds: 16),
      );
      int callCount = 0;

      throttler.call(() => callCount++);

      expect(callCount, 1);
    });

    test('blocks calls within duration', () {
      throttler = HighFrequencyThrottler(
        duration: const Duration(milliseconds: 100),
      );
      int callCount = 0;

      throttler.call(() => callCount++);
      throttler.call(() => callCount++);
      throttler.call(() => callCount++);

      expect(callCount, 1);
    });

    test('allows calls after duration expires', () async {
      throttler = HighFrequencyThrottler(
        duration: const Duration(milliseconds: 50),
      );
      int callCount = 0;

      throttler.call(() => callCount++);
      expect(callCount, 1);

      await Future.delayed(const Duration(milliseconds: 60));

      throttler.call(() => callCount++);
      expect(callCount, 2);
    });

    test('uses DateTime for high precision', () async {
      throttler = HighFrequencyThrottler(
        duration: const Duration(milliseconds: 16), // ~60fps
      );
      int callCount = 0;

      // Simulate rapid calls like scroll events
      for (var i = 0; i < 10; i++) {
        throttler.call(() => callCount++);
      }

      expect(callCount, 1);

      // Wait and try again
      await Future.delayed(const Duration(milliseconds: 20));

      throttler.call(() => callCount++);
      expect(callCount, 2);
    });

    test('reset clears last execution time', () {
      throttler = HighFrequencyThrottler(
        duration: const Duration(milliseconds: 100),
      );
      int callCount = 0;

      throttler.call(() => callCount++);
      expect(callCount, 1);

      throttler.reset();

      throttler.call(() => callCount++);
      expect(callCount, 2);
    });

    test('wrap returns VoidCallback', () {
      throttler = HighFrequencyThrottler(
        duration: const Duration(milliseconds: 100),
      );
      int callCount = 0;

      final wrapped = throttler.wrap(() => callCount++);
      expect(wrapped, isNotNull);

      wrapped!();
      wrapped();
      wrapped();

      expect(callCount, 1);
    });

    test('isThrottled returns correct state', () async {
      throttler = HighFrequencyThrottler(
        duration: const Duration(milliseconds: 50),
      );

      expect(throttler.isThrottled, false);

      throttler.call(() {});
      expect(throttler.isThrottled, true);

      await Future.delayed(const Duration(milliseconds: 60));
      expect(throttler.isThrottled, false);
    });

    test('handles very short durations', () async {
      throttler = HighFrequencyThrottler(
        duration: const Duration(microseconds: 100),
      );
      int callCount = 0;

      throttler.call(() => callCount++);
      await Future.delayed(const Duration(milliseconds: 1));
      throttler.call(() => callCount++);

      expect(callCount, 2);
    });

    test('dispose is safe to call multiple times', () {
      throttler = HighFrequencyThrottler(
        duration: const Duration(milliseconds: 16),
      );

      throttler.dispose();
      throttler.dispose();
      throttler.dispose();
    });

    test('works correctly for 60fps simulation', () async {
      throttler = HighFrequencyThrottler(
        duration: const Duration(milliseconds: 16),
      );
      int callCount = 0;

      // Simulate 60fps for 100ms (should allow ~6 calls)
      final stopwatch = Stopwatch()..start();
      while (stopwatch.elapsedMilliseconds < 100) {
        throttler.call(() => callCount++);
        await Future.delayed(const Duration(milliseconds: 1));
      }

      // Should have multiple executions due to throttle releasing
      expect(callCount, greaterThan(1));
      expect(callCount, lessThanOrEqualTo(10));
    });

    test('multiple throttlers work independently', () {
      final throttler1 = HighFrequencyThrottler(
        duration: const Duration(milliseconds: 100),
      );
      final throttler2 = HighFrequencyThrottler(
        duration: const Duration(milliseconds: 100),
      );

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
