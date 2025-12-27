import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_debounce_throttle/flutter_debounce_throttle.dart';

void main() {
  group('Throttler', () {
    test('executes immediately on first call', () {
      final throttler = Throttler(duration: const Duration(milliseconds: 100));
      int callCount = 0;

      throttler.call(() => callCount++);

      expect(callCount, 1);
      throttler.dispose();
    });

    test('blocks subsequent calls within duration', () {
      final throttler = Throttler(duration: const Duration(milliseconds: 100));
      int callCount = 0;

      throttler.call(() => callCount++);
      throttler.call(() => callCount++);
      throttler.call(() => callCount++);

      expect(callCount, 1);
      throttler.dispose();
    });

    test('allows calls after duration expires', () async {
      final throttler = Throttler(duration: const Duration(milliseconds: 50));
      int callCount = 0;

      throttler.call(() => callCount++);
      expect(callCount, 1);

      await Future.delayed(const Duration(milliseconds: 60));
      throttler.call(() => callCount++);
      expect(callCount, 2);

      throttler.dispose();
    });
  });

  group('Debouncer', () {
    test('delays execution until pause', () async {
      final debouncer = Debouncer(duration: const Duration(milliseconds: 50));
      int callCount = 0;

      debouncer.call(() => callCount++);
      expect(callCount, 0);

      await Future.delayed(const Duration(milliseconds: 60));
      expect(callCount, 1);

      debouncer.dispose();
    });

    test('resets timer on each call', () async {
      final debouncer = Debouncer(duration: const Duration(milliseconds: 50));
      int callCount = 0;

      debouncer.call(() => callCount++);
      await Future.delayed(const Duration(milliseconds: 30));
      debouncer.call(() => callCount++);
      await Future.delayed(const Duration(milliseconds: 30));
      debouncer.call(() => callCount++);
      await Future.delayed(const Duration(milliseconds: 60));

      expect(callCount, 1);
      debouncer.dispose();
    });
  });

  group('AsyncDebouncer', () {
    test('cancels previous calls', () async {
      final debouncer = AsyncDebouncer(duration: const Duration(milliseconds: 50));
      final results = <int>[];

      debouncer.run(() async {
        await Future.delayed(const Duration(milliseconds: 10));
        return 1;
      }).then((r) {
        if (r != null) results.add(r);
      });

      debouncer.run(() async {
        await Future.delayed(const Duration(milliseconds: 10));
        return 2;
      }).then((r) {
        if (r != null) results.add(r);
      });

      debouncer.run(() async {
        await Future.delayed(const Duration(milliseconds: 10));
        return 3;
      }).then((r) {
        if (r != null) results.add(r);
      });

      await Future.delayed(const Duration(milliseconds: 100));
      expect(results, [3]);

      debouncer.dispose();
    });
  });

  group('HighFrequencyThrottler', () {
    test('allows first call immediately', () {
      final throttler = HighFrequencyThrottler(
        duration: const Duration(milliseconds: 16),
      );
      int callCount = 0;

      throttler.call(() => callCount++);
      expect(callCount, 1);

      throttler.dispose();
    });

    test('blocks calls within duration', () {
      final throttler = HighFrequencyThrottler(
        duration: const Duration(milliseconds: 100),
      );
      int callCount = 0;

      throttler.call(() => callCount++);
      throttler.call(() => callCount++);
      throttler.call(() => callCount++);

      expect(callCount, 1);
      throttler.dispose();
    });
  });

  group('ConcurrentAsyncThrottler', () {
    test('drop mode ignores calls while busy', () async {
      final throttler = ConcurrentAsyncThrottler(
        mode: ConcurrencyMode.drop,
        maxDuration: const Duration(seconds: 5),
      );
      final results = <int>[];

      throttler.call(() async {
        await Future.delayed(const Duration(milliseconds: 50));
        results.add(1);
      });
      throttler.call(() async {
        results.add(2);
      });

      await Future.delayed(const Duration(milliseconds: 100));
      expect(results, [1]);

      throttler.dispose();
    });
  });

  group('EventLimiterMixin', () {
    test('debounce works with ID', () async {
      final controller = TestController();

      controller.debounce('test', () => controller.value++);
      controller.debounce('test', () => controller.value++);
      controller.debounce('test', () => controller.value++);

      await Future.delayed(const Duration(milliseconds: 400));
      expect(controller.value, 1);

      controller.cancelAllLimiters();
    });

    test('throttle works with ID', () {
      final controller = TestController();

      controller.throttle('test', () => controller.value++);
      controller.throttle('test', () => controller.value++);
      controller.throttle('test', () => controller.value++);

      expect(controller.value, 1);

      controller.cancelAllLimiters();
    });
  });
}

class TestController with EventLimiterMixin {
  int value = 0;
}
