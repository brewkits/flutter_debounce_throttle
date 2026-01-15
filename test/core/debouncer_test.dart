import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_debounce_throttle/core.dart';

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
      FlutterDebounceThrottle.init(
        defaultDebounceDuration: const Duration(milliseconds: 50),
      );

      debouncer = Debouncer();
      int callCount = 0;

      debouncer.call(() => callCount++);
      expect(callCount, 0);

      await Future.delayed(const Duration(milliseconds: 60));
      expect(callCount, 1);

      // Reset global config
      FlutterDebounceThrottle.reset();
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
  });
}
