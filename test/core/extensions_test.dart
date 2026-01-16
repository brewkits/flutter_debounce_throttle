import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_debounce_throttle/core.dart';

void main() {
  group('DurationIntExtension', () {
    group('ms (milliseconds)', () {
      test('creates correct Duration', () {
        expect(100.ms, const Duration(milliseconds: 100));
        expect(300.ms, const Duration(milliseconds: 300));
        expect(1000.ms, const Duration(milliseconds: 1000));
      });

      test('handles zero', () {
        expect(0.ms, Duration.zero);
      });

      test('handles large values', () {
        expect(60000.ms, const Duration(minutes: 1));
      });
    });

    group('seconds', () {
      test('creates correct Duration', () {
        expect(1.seconds, const Duration(seconds: 1));
        expect(5.seconds, const Duration(seconds: 5));
        expect(60.seconds, const Duration(minutes: 1));
      });

      test('handles zero', () {
        expect(0.seconds, Duration.zero);
      });
    });

    group('minutes', () {
      test('creates correct Duration', () {
        expect(1.minutes, const Duration(minutes: 1));
        expect(5.minutes, const Duration(minutes: 5));
        expect(60.minutes, const Duration(hours: 1));
      });

      test('handles zero', () {
        expect(0.minutes, Duration.zero);
      });
    });

    group('hours', () {
      test('creates correct Duration', () {
        expect(1.hours, const Duration(hours: 1));
        expect(24.hours, const Duration(days: 1));
      });

      test('handles zero', () {
        expect(0.hours, Duration.zero);
      });
    });

    group('Combination with controllers', () {
      test('works with Debouncer', () async {
        var callCount = 0;
        final debouncer = Debouncer(duration: 50.ms);

        debouncer.call(() => callCount++);
        debouncer.call(() => callCount++);
        debouncer.call(() => callCount++);

        await Future.delayed(100.ms);

        expect(callCount, 1);
        debouncer.dispose();
      });

      test('works with Throttler', () async {
        var callCount = 0;
        final throttler = Throttler(duration: 50.ms);

        throttler.call(() => callCount++);
        throttler.call(() => callCount++);
        throttler.call(() => callCount++);

        expect(callCount, 1);

        await Future.delayed(60.ms);

        throttler.call(() => callCount++);
        expect(callCount, 2);

        throttler.dispose();
      });

      test('works with RateLimiter', () {
        final limiter = RateLimiter(
          maxTokens: 5,
          refillInterval: 1.seconds,
        );

        expect(limiter.availableTokens, 5);
        limiter.dispose();
      });
    });
  });

  group('VoidCallbackDebounceExtension', () {
    group('debounced()', () {
      test('returns debounced function', () async {
        var callCount = 0;
        final original = () => callCount++;
        final debounced = original.debounced(50.ms);

        // Call multiple times rapidly
        debounced();
        debounced();
        debounced();

        // Not called yet (debouncing)
        expect(callCount, 0);

        // Wait for debounce
        await Future.delayed(100.ms);

        // Called once after debounce
        expect(callCount, 1);
      });

      test('resets timer on each call', () async {
        var callCount = 0;
        final debounced = (() => callCount++).debounced(50.ms);

        debounced();
        await Future.delayed(30.ms);
        debounced(); // Reset timer
        await Future.delayed(30.ms);
        debounced(); // Reset timer again

        expect(callCount, 0); // Still debouncing

        await Future.delayed(60.ms);
        expect(callCount, 1);
      });

      test('each debounced() call creates new debouncer', () async {
        var count1 = 0;
        var count2 = 0;

        final original = () {
          count1++;
          count2++;
        };

        final debounced1 = original.debounced(50.ms);
        final debounced2 = original.debounced(50.ms);

        debounced1();
        debounced2();

        await Future.delayed(100.ms);

        // Both should execute (separate debouncers)
        expect(count1, 2);
        expect(count2, 2);
      });
    });

    group('throttled()', () {
      test('returns throttled function', () async {
        var callCount = 0;
        final original = () => callCount++;
        final throttled = original.throttled(50.ms);

        // Call multiple times rapidly
        throttled();
        throttled();
        throttled();

        // First call executes immediately
        expect(callCount, 1);

        // Wait for throttle to reset
        await Future.delayed(60.ms);

        throttled();
        expect(callCount, 2);
      });

      test('blocks subsequent calls during throttle period', () async {
        var callCount = 0;
        final throttled = (() => callCount++).throttled(100.ms);

        throttled();
        expect(callCount, 1);

        await Future.delayed(30.ms);
        throttled();
        expect(callCount, 1); // Still blocked

        await Future.delayed(30.ms);
        throttled();
        expect(callCount, 1); // Still blocked

        await Future.delayed(50.ms);
        throttled();
        expect(callCount, 2); // Throttle expired
      });

      test('each throttled() call creates new throttler', () async {
        var count1 = 0;
        var count2 = 0;

        final fn1 = () => count1++;
        final fn2 = () => count2++;

        final throttled1 = fn1.throttled(100.ms);
        final throttled2 = fn2.throttled(100.ms);

        throttled1();
        throttled2();

        // Both should execute (separate throttlers)
        expect(count1, 1);
        expect(count2, 1);
      });
    });
  });

  group('Real-world usage patterns', () {
    test('search input debouncing', () async {
      final searchQueries = <String>[];
      void search(String query) => searchQueries.add(query);

      // Simulate rapid typing
      final debouncedSearch = search.debounced(50.ms);

      // This doesn't work directly because debounced returns void Function()
      // The extension is for simple callbacks, not parameterized ones
      // For parameterized callbacks, use Debouncer directly

      var lastQuery = '';
      final debouncedCallback = () => search(lastQuery);
      final debounced = debouncedCallback.debounced(50.ms);

      lastQuery = 'a';
      debounced();
      lastQuery = 'ab';
      debounced();
      lastQuery = 'abc';
      debounced();

      await Future.delayed(100.ms);

      // Only last query should be searched
      expect(searchQueries, ['abc']);
    });

    test('button click throttling', () async {
      var submitCount = 0;
      final throttledSubmit = (() => submitCount++).throttled(100.ms);

      // Rapid clicks
      for (var i = 0; i < 10; i++) {
        throttledSubmit();
      }

      // Only first click should register
      expect(submitCount, 1);

      // After throttle period
      await Future.delayed(110.ms);
      throttledSubmit();
      expect(submitCount, 2);
    });

    test('scroll event throttling', () async {
      final scrollPositions = <int>[];
      var currentPosition = 0;

      final throttledScroll = (() {
        scrollPositions.add(currentPosition);
      }).throttled(50.ms);

      // Simulate rapid scroll events
      for (var i = 0; i < 20; i++) {
        currentPosition = i * 10;
        throttledScroll();
        await Future.delayed(10.ms);
      }

      // Should have limited number of recorded positions
      expect(scrollPositions.length, lessThan(10));
      expect(scrollPositions.first, 0); // First position recorded
    });
  });
}
