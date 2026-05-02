import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_debounce_throttle/flutter_debounce_throttle.dart';

void main() {
  group('Debouncer', () {
    late Debouncer debouncer;

    tearDown(() {
      debouncer.dispose();
    });

    test('delays execution until pause', () async {
      debouncer = Debouncer(duration: const Duration(milliseconds: 50));
      int callCount = 0;

      debouncer.call(() => callCount++);
      expect(callCount, 0);

      await Future.delayed(const Duration(milliseconds: 60));
      expect(callCount, 1);
    });

    test('resets timer on each call', () async {
      debouncer = Debouncer(duration: const Duration(milliseconds: 50));
      int callCount = 0;

      debouncer.call(() => callCount++);
      await Future.delayed(const Duration(milliseconds: 30));
      debouncer.call(() => callCount++);
      await Future.delayed(const Duration(milliseconds: 30));
      debouncer.call(() => callCount++);

      expect(callCount, 0);

      await Future.delayed(const Duration(milliseconds: 60));
      expect(callCount, 1);
    });

    test('only executes last callback', () async {
      debouncer = Debouncer(duration: const Duration(milliseconds: 50));
      String lastValue = '';

      debouncer.call(() => lastValue = 'first');
      debouncer.call(() => lastValue = 'second');
      debouncer.call(() => lastValue = 'third');

      await Future.delayed(const Duration(milliseconds: 60));
      expect(lastValue, 'third');
    });

    test('flush() executes callback immediately', () {
      debouncer = Debouncer(duration: const Duration(milliseconds: 100));
      int callCount = 0;

      debouncer.flush(() => callCount++);
      expect(callCount, 1);
    });

    test('cancel() prevents execution', () async {
      debouncer = Debouncer(duration: const Duration(milliseconds: 50));
      int callCount = 0;

      debouncer.call(() => callCount++);
      debouncer.cancel();

      await Future.delayed(const Duration(milliseconds: 60));
      expect(callCount, 0);
    });

    test('isPending returns correct state', () async {
      debouncer = Debouncer(duration: const Duration(milliseconds: 50));

      expect(debouncer.isPending, false);

      debouncer.call(() {});
      expect(debouncer.isPending, true);

      await Future.delayed(const Duration(milliseconds: 60));
      expect(debouncer.isPending, false);
    });

    test('uses global config duration when not specified', () async {
      DebounceThrottleConfig.init(
        defaultDebounceDuration: const Duration(milliseconds: 50),
      );

      debouncer = Debouncer();
      int callCount = 0;

      debouncer.call(() => callCount++);
      expect(callCount, 0);

      await Future.delayed(const Duration(milliseconds: 60));
      expect(callCount, 1);

      // Reset global config
      DebounceThrottleConfig.reset();
    });

    test('enabled=false bypasses debounce', () {
      debouncer = Debouncer(
        duration: const Duration(milliseconds: 100),
        enabled: false,
      );
      int callCount = 0;

      debouncer.call(() => callCount++);
      expect(callCount, 1); // Immediate execution
    });

    test('callWithDuration uses custom duration', () async {
      debouncer = Debouncer(duration: const Duration(milliseconds: 200));
      int callCount = 0;

      debouncer.callWithDuration(
        () => callCount++,
        const Duration(milliseconds: 50),
      );

      await Future.delayed(const Duration(milliseconds: 60));
      expect(callCount, 1);
    });

    test('onMetrics callback is called', () async {
      Duration? metricsDuration;
      bool? metricsCancelled;

      debouncer = Debouncer(
        duration: const Duration(milliseconds: 50),
        onMetrics: (duration, cancelled) {
          metricsDuration = duration;
          metricsCancelled = cancelled;
        },
      );

      debouncer.call(() {});
      debouncer.call(() {}); // Cancels first

      expect(metricsCancelled, true); // First call was cancelled

      await Future.delayed(const Duration(milliseconds: 60));

      expect(metricsDuration, isNotNull);
      expect(metricsCancelled, false); // Second call completed
    });

    test('debugMode logs messages', () async {
      debouncer = Debouncer(
        duration: const Duration(milliseconds: 50),
        debugMode: true,
        name: 'TestDebouncer',
      );

      // Should not throw
      debouncer.call(() {});
      await Future.delayed(const Duration(milliseconds: 60));
    });

    test('dispose prevents further executions', () async {
      debouncer = Debouncer(duration: const Duration(milliseconds: 50));
      int callCount = 0;

      debouncer.call(() => callCount++);
      debouncer.dispose();

      await Future.delayed(const Duration(milliseconds: 60));
      expect(callCount, 0);
    });

    test('can be reused after execution', () async {
      debouncer = Debouncer(duration: const Duration(milliseconds: 50));
      int callCount = 0;

      debouncer.call(() => callCount++);
      await Future.delayed(const Duration(milliseconds: 60));
      expect(callCount, 1);

      debouncer.call(() => callCount++);
      await Future.delayed(const Duration(milliseconds: 60));
      expect(callCount, 2);
    });

    test('handles rapid successive calls', () async {
      debouncer = Debouncer(duration: const Duration(milliseconds: 50));
      int callCount = 0;

      for (var i = 0; i < 100; i++) {
        debouncer.call(() => callCount++);
      }

      await Future.delayed(const Duration(milliseconds: 60));
      expect(callCount, 1);
    });

    // ========================================================================
    // Leading/Trailing Edge Tests
    // ========================================================================

    group('Leading Edge (leading: true)', () {
      test('executes immediately on first call', () async {
        debouncer = Debouncer(
          duration: const Duration(milliseconds: 50),
          leading: true,
          trailing: false,
        );
        int callCount = 0;

        debouncer.call(() => callCount++);

        // Should execute immediately
        expect(callCount, 1);

        // No more executions after waiting
        await Future.delayed(const Duration(milliseconds: 60));
        expect(callCount, 1);
      });

      test('blocks subsequent calls during debounce window', () async {
        debouncer = Debouncer(
          duration: const Duration(milliseconds: 50),
          leading: true,
          trailing: false,
        );
        int callCount = 0;

        debouncer.call(() => callCount++); // Executes
        debouncer.call(() => callCount++); // Blocked
        debouncer.call(() => callCount++); // Blocked

        expect(callCount, 1);

        await Future.delayed(const Duration(milliseconds: 60));
        expect(callCount, 1);
      });

      test('allows new leading call after debounce window', () async {
        debouncer = Debouncer(
          duration: const Duration(milliseconds: 50),
          leading: true,
          trailing: false,
        );
        int callCount = 0;

        debouncer.call(() => callCount++);
        expect(callCount, 1);

        await Future.delayed(const Duration(milliseconds: 60));

        debouncer.call(() => callCount++);
        expect(callCount, 2);
      });

      test('captures latest callback value', () async {
        debouncer = Debouncer(
          duration: const Duration(milliseconds: 50),
          leading: true,
          trailing: false,
        );
        String value = '';

        debouncer.call(() => value = 'first');
        expect(value, 'first');

        debouncer.call(() => value = 'second'); // Blocked
        expect(value, 'first');
      });
    });

    group('Trailing Edge (trailing: true, default)', () {
      test('default behavior is trailing only', () async {
        debouncer = Debouncer(duration: const Duration(milliseconds: 50));
        int callCount = 0;

        debouncer.call(() => callCount++);
        expect(callCount, 0); // Not immediate

        await Future.delayed(const Duration(milliseconds: 60));
        expect(callCount, 1);
      });

      test('executes after pause in calls', () async {
        debouncer = Debouncer(
          duration: const Duration(milliseconds: 50),
          leading: false,
          trailing: true,
        );
        int callCount = 0;

        debouncer.call(() => callCount++);
        debouncer.call(() => callCount++);
        debouncer.call(() => callCount++);

        expect(callCount, 0);

        await Future.delayed(const Duration(milliseconds: 60));
        expect(callCount, 1);
      });
    });

    group('Both Edges (leading: true, trailing: true)', () {
      test('executes on first call AND after pause', () async {
        debouncer = Debouncer(
          duration: const Duration(milliseconds: 50),
          leading: true,
          trailing: true,
        );
        int callCount = 0;

        debouncer.call(() => callCount++); // Leading
        expect(callCount, 1);

        debouncer.call(() => callCount++); // Sets up trailing
        debouncer.call(() => callCount++); // Updates trailing

        await Future.delayed(const Duration(milliseconds: 60));
        expect(callCount, 2); // Trailing executed
      });

      test('skips trailing if no new calls after leading', () async {
        debouncer = Debouncer(
          duration: const Duration(milliseconds: 50),
          leading: true,
          trailing: true,
        );
        int callCount = 0;

        debouncer.call(() => callCount++); // Leading only

        await Future.delayed(const Duration(milliseconds: 60));
        expect(callCount, 1); // No trailing (same call)
      });

      test('executes trailing with latest callback', () async {
        debouncer = Debouncer(
          duration: const Duration(milliseconds: 50),
          leading: true,
          trailing: true,
        );
        final values = <String>[];

        debouncer.call(() => values.add('first')); // Leading
        debouncer.call(() => values.add('second'));
        debouncer.call(() => values.add('third'));

        expect(values, ['first']);

        await Future.delayed(const Duration(milliseconds: 60));
        expect(values, ['first', 'third']); // Leading + latest trailing
      });

      test('lodash-style debounce behavior', () async {
        debouncer = Debouncer(
          duration: const Duration(milliseconds: 50),
          leading: true,
          trailing: true,
        );
        final timestamps = <int>[];
        final stopwatch = Stopwatch()..start();

        debouncer.call(() => timestamps.add(stopwatch.elapsedMilliseconds));

        await Future.delayed(const Duration(milliseconds: 20));
        debouncer.call(() => timestamps.add(stopwatch.elapsedMilliseconds));

        await Future.delayed(const Duration(milliseconds: 20));
        debouncer.call(() => timestamps.add(stopwatch.elapsedMilliseconds));

        await Future.delayed(const Duration(milliseconds: 70));

        expect(timestamps.length, 2); // Leading + trailing
        expect(timestamps[0], lessThan(10)); // First was immediate
        expect(timestamps[1],
            greaterThan(80)); // Trailing after last call + duration
      });
    });

    group('Edge cases', () {
      test('assertion fails if both leading and trailing are false', () {
        expect(
          () => Debouncer(
            duration: const Duration(milliseconds: 50),
            leading: false,
            trailing: false,
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('leading works with enabled=false', () {
        debouncer = Debouncer(
          duration: const Duration(milliseconds: 50),
          leading: true,
          trailing: true,
          enabled: false,
        );
        int callCount = 0;

        debouncer.call(() => callCount++);
        expect(callCount, 1); // Immediate (bypassed)

        debouncer.call(() => callCount++);
        expect(callCount, 2); // Also immediate
      });

      test('leading/trailing works with onMetrics', () async {
        final metrics = <bool>[];

        debouncer = Debouncer(
          duration: const Duration(milliseconds: 50),
          leading: true,
          trailing: true,
          onMetrics: (duration, cancelled) {
            metrics.add(cancelled);
          },
        );

        debouncer.call(() {}); // Leading
        debouncer.call(() {}); // Will be trailing

        await Future.delayed(const Duration(milliseconds: 60));

        // Leading should have metrics called, middle cancelled
        expect(metrics.contains(true), true); // Cancelled metric
        expect(metrics.contains(false), true); // Completed metric
      });

      test('dispose clears leading state', () async {
        debouncer = Debouncer(
          duration: const Duration(milliseconds: 50),
          leading: true,
          trailing: true,
        );
        int callCount = 0;

        debouncer.call(() => callCount++);
        expect(callCount, 1);

        debouncer.dispose();

        // Create new instance
        debouncer = Debouncer(
          duration: const Duration(milliseconds: 50),
          leading: true,
          trailing: true,
        );

        debouncer.call(() => callCount++);
        expect(callCount, 2); // New leading should execute
      });
    });

    group('Real-world scenarios', () {
      test('button feedback with leading edge', () async {
        debouncer = Debouncer(
          duration: const Duration(milliseconds: 300),
          leading: true,
          trailing: false,
        );
        var buttonPressed = false;
        var feedbackShown = false;

        // First tap - immediate feedback
        debouncer.call(() {
          buttonPressed = true;
          feedbackShown = true;
        });
        expect(feedbackShown, true);

        // Rapid taps - blocked
        for (var i = 0; i < 5; i++) {
          debouncer.call(() {
            buttonPressed = true;
          });
        }

        // Only one press registered
        expect(buttonPressed, true);
      });

      test('search with leading (show results) + trailing (final search)',
          () async {
        debouncer = Debouncer(
          duration: const Duration(milliseconds: 50),
          leading: true,
          trailing: true,
        );
        final searches = <String>[];
        var currentQuery = '';

        void search() => searches.add(currentQuery);

        currentQuery = 'a';
        debouncer.call(search); // Leading: search 'a'
        expect(searches, ['a']);

        currentQuery = 'ab';
        debouncer.call(search);

        currentQuery = 'abc';
        debouncer.call(search);

        await Future.delayed(const Duration(milliseconds: 60));

        // Trailing: search 'abc'
        expect(searches, ['a', 'abc']);
      });

      test('resize handler with trailing only', () async {
        debouncer = Debouncer(
          duration: const Duration(milliseconds: 50),
          leading: false,
          trailing: true,
        );
        var recalculations = 0;

        // Simulate many resize events
        for (var i = 0; i < 20; i++) {
          debouncer.call(() => recalculations++);
          await Future.delayed(const Duration(milliseconds: 10));
        }

        await Future.delayed(const Duration(milliseconds: 60));

        // Should only recalculate once at the end
        expect(recalculations, 1);
      });
    });
  });
}
