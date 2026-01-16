import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_debounce_throttle/flutter_debounce_throttle.dart';

void main() {
  group('AsyncThrottler', () {
    late AsyncThrottler throttler;

    tearDown(() {
      throttler.dispose();
    });

    test('executes first call immediately', () async {
      throttler = AsyncThrottler(maxDuration: const Duration(seconds: 5));
      int callCount = 0;

      await throttler.call(() async {
        await Future.delayed(const Duration(milliseconds: 10));
        callCount++;
      });

      expect(callCount, 1);
    });

    test('blocks subsequent calls while locked', () async {
      throttler = AsyncThrottler(maxDuration: const Duration(seconds: 5));
      int callCount = 0;

      // First call starts
      final future1 = throttler.call(() async {
        await Future.delayed(const Duration(milliseconds: 100));
        callCount++;
      });

      // Second call should be blocked
      final future2 = throttler.call(() async {
        callCount++;
      });

      await Future.wait([future1, future2]);

      expect(callCount, 1); // Only first executed
    });

    test('isLocked returns correct state', () async {
      throttler = AsyncThrottler(maxDuration: const Duration(seconds: 5));

      expect(throttler.isLocked, false);

      final future = throttler.call(() async {
        await Future.delayed(const Duration(milliseconds: 50));
      });

      expect(throttler.isLocked, true);

      await future;
      expect(throttler.isLocked, false);
    });

    test('unlocks after async operation completes', () async {
      throttler = AsyncThrottler(maxDuration: const Duration(seconds: 5));
      int callCount = 0;

      await throttler.call(() async {
        await Future.delayed(const Duration(milliseconds: 50));
        callCount++;
      });

      // After first completes, second should work
      await throttler.call(() async {
        callCount++;
      });

      expect(callCount, 2);
    });

    test('timeout unlocks after maxDuration', () async {
      throttler = AsyncThrottler(maxDuration: const Duration(milliseconds: 50));

      // Start a long-running operation
      throttler.call(() async {
        await Future.delayed(const Duration(milliseconds: 200));
      });

      // Wait for timeout
      await Future.delayed(const Duration(milliseconds: 70));

      // Should be unlocked now due to timeout
      expect(throttler.isLocked, false);
    });

    test('reset() unlocks immediately', () async {
      throttler = AsyncThrottler(maxDuration: const Duration(seconds: 5));

      throttler.call(() async {
        await Future.delayed(const Duration(milliseconds: 100));
      });

      expect(throttler.isLocked, true);

      throttler.reset();
      expect(throttler.isLocked, false);
    });

    test('handles errors and still unlocks', () async {
      throttler = AsyncThrottler(maxDuration: const Duration(seconds: 5));

      try {
        await throttler.call(() async {
          throw Exception('Test error');
        });
      } catch (e) {
        // Expected
      }

      // Should be unlocked after error
      expect(throttler.isLocked, false);
    });

    test('enabled=false bypasses throttle', () async {
      throttler = AsyncThrottler(
        maxDuration: const Duration(seconds: 5),
        enabled: false,
      );
      int callCount = 0;

      await throttler.call(() async => callCount++);
      await throttler.call(() async => callCount++);
      await throttler.call(() async => callCount++);

      expect(callCount, 3);
    });

    test('debugMode logs messages', () async {
      throttler = AsyncThrottler(
        maxDuration: const Duration(seconds: 5),
        debugMode: true,
        name: 'TestAsyncThrottler',
      );

      await throttler.call(() async {});
    });

    test('wrap returns VoidCallback', () async {
      throttler = AsyncThrottler(maxDuration: const Duration(seconds: 5));
      int callCount = 0;

      final wrapped = throttler.wrap(() async {
        await Future.delayed(const Duration(milliseconds: 10));
        callCount++;
      });

      expect(wrapped, isNotNull);

      wrapped!();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(callCount, 1);
    });

    test('onMetrics callback is called', () async {
      Duration? metricsDuration;
      bool? metricsExecuted;

      throttler = AsyncThrottler(
        maxDuration: const Duration(seconds: 5),
        onMetrics: (duration, executed) {
          metricsDuration = duration;
          metricsExecuted = executed;
        },
      );

      await throttler.call(() async {
        await Future.delayed(const Duration(milliseconds: 10));
      });

      expect(metricsDuration, isNotNull);
      expect(metricsExecuted, true);

      // Blocked call
      throttler.call(() async {
        await Future.delayed(const Duration(milliseconds: 100));
      });
      throttler.call(() async {});

      expect(metricsExecuted, false);
    });
  });
}
