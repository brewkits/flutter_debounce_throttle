import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_debounce_throttle/core.dart';

void main() {
  group('ConcurrentAsyncThrottler', () {
    group('drop mode', () {
      late ConcurrentAsyncThrottler throttler;

      tearDown(() {
        throttler.dispose();
      });

      test('executes first call', () async {
        throttler = ConcurrentAsyncThrottler(
          mode: ConcurrencyMode.drop,
          maxDuration: const Duration(seconds: 5),
        );
        int callCount = 0;

        await throttler.call(() async => callCount++);
        expect(callCount, 1);
      });

      test('drops calls while busy', () async {
        throttler = ConcurrentAsyncThrottler(
          mode: ConcurrencyMode.drop,
          maxDuration: const Duration(seconds: 5),
        );
        int callCount = 0;

        final future1 = throttler.call(() async {
          await Future.delayed(const Duration(milliseconds: 50));
          callCount++;
        });

        // These should be dropped
        throttler.call(() async => callCount++);
        throttler.call(() async => callCount++);

        await future1;
        expect(callCount, 1);
      });

      test('allows new calls after completion', () async {
        throttler = ConcurrentAsyncThrottler(
          mode: ConcurrencyMode.drop,
          maxDuration: const Duration(seconds: 5),
        );
        int callCount = 0;

        await throttler.call(() async {
          await Future.delayed(const Duration(milliseconds: 20));
          callCount++;
        });

        await throttler.call(() async => callCount++);

        expect(callCount, 2);
      });
    });

    group('enqueue mode', () {
      late ConcurrentAsyncThrottler throttler;

      tearDown(() {
        throttler.dispose();
      });

      test('queues and executes in order', () async {
        throttler = ConcurrentAsyncThrottler(
          mode: ConcurrencyMode.enqueue,
          maxDuration: const Duration(seconds: 5),
        );

        final results = <int>[];

        final future1 = throttler.call(() async {
          await Future.delayed(const Duration(milliseconds: 20));
          results.add(1);
        });

        final future2 = throttler.call(() async {
          results.add(2);
        });

        final future3 = throttler.call(() async {
          results.add(3);
        });

        await Future.wait([future1, future2, future3]);

        expect(results, [1, 2, 3]);
      });

      test('queueSize returns correct count', () {
        throttler = ConcurrentAsyncThrottler(
          mode: ConcurrencyMode.enqueue,
          maxDuration: const Duration(seconds: 5),
        );

        expect(throttler.queueSize, 0);

        throttler.call(() async {
          await Future.delayed(const Duration(milliseconds: 100));
        });

        throttler.call(() async {});
        throttler.call(() async {});

        expect(throttler.queueSize, 2);
      });
    });

    group('replace mode', () {
      late ConcurrentAsyncThrottler throttler;

      tearDown(() {
        throttler.dispose();
      });

      test('cancels current and starts new', () async {
        throttler = ConcurrentAsyncThrottler(
          mode: ConcurrencyMode.replace,
          maxDuration: const Duration(seconds: 5),
        );

        final results = <int>[];

        throttler.call(() async {
          await Future.delayed(const Duration(milliseconds: 100));
          results.add(1);
        });

        await Future.delayed(const Duration(milliseconds: 20));

        await throttler.call(() async {
          await Future.delayed(const Duration(milliseconds: 20));
          results.add(2);
        });

        // Wait for potential first execution
        await Future.delayed(const Duration(milliseconds: 100));

        // Second should complete, first should be cancelled
        expect(results.contains(2), true);
      });
    });

    group('keepLatest mode', () {
      late ConcurrentAsyncThrottler throttler;

      tearDown(() {
        throttler.dispose();
      });

      test('keeps only the latest pending call', () async {
        throttler = ConcurrentAsyncThrottler(
          mode: ConcurrencyMode.keepLatest,
          maxDuration: const Duration(seconds: 5),
        );

        final results = <int>[];

        throttler.call(() async {
          await Future.delayed(const Duration(milliseconds: 50));
          results.add(1);
        });

        // These should be replaced by latest
        throttler.call(() async => results.add(2));
        throttler.call(() async => results.add(3));

        await Future.delayed(const Duration(milliseconds: 100));

        // First executes, middle ones dropped, latest executes after
        expect(results.contains(1), true);
        expect(results.contains(3), true);
        expect(results.contains(2), false);
      });
    });

    group('common functionality', () {
      test('isLocked returns correct state', () async {
        final throttler = ConcurrentAsyncThrottler(
          mode: ConcurrencyMode.drop,
          maxDuration: const Duration(seconds: 5),
        );

        expect(throttler.isLocked, false);

        final future = throttler.call(() async {
          await Future.delayed(const Duration(milliseconds: 50));
        });

        expect(throttler.isLocked, true);

        await future;
        expect(throttler.isLocked, false);

        throttler.dispose();
      });

      test('reset clears state', () async {
        final throttler = ConcurrentAsyncThrottler(
          mode: ConcurrencyMode.enqueue,
          maxDuration: const Duration(seconds: 5),
        );

        throttler.call(() async {
          await Future.delayed(const Duration(milliseconds: 100));
        });

        throttler.call(() async {});
        throttler.call(() async {});

        expect(throttler.queueSize, 2);

        throttler.reset();
        expect(throttler.queueSize, 0);
        expect(throttler.isLocked, false);

        throttler.dispose();
      });

      test('debugMode works', () async {
        final throttler = ConcurrentAsyncThrottler(
          mode: ConcurrencyMode.drop,
          maxDuration: const Duration(seconds: 5),
          debugMode: true,
          name: 'TestConcurrent',
        );

        await throttler.call(() async {});

        throttler.dispose();
      });

      test('timeout unlocks stuck operations', () async {
        final throttler = ConcurrentAsyncThrottler(
          mode: ConcurrencyMode.drop,
          maxDuration: const Duration(milliseconds: 50),
        );

        throttler.call(() async {
          await Future.delayed(const Duration(milliseconds: 200));
        });

        await Future.delayed(const Duration(milliseconds: 70));

        // Should be unlocked due to timeout
        expect(throttler.isLocked, false);

        throttler.dispose();
      });
    });
  });
}
