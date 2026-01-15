import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_debounce_throttle/core.dart';

void main() {
  group('ThrottleDebouncer', () {
    late ThrottleDebouncer throttleDebouncer;

    tearDown(() {
      throttleDebouncer.dispose();
    });

    test('executes immediately on first call (leading edge)', () {
      throttleDebouncer = ThrottleDebouncer(
        duration: const Duration(milliseconds: 100),
      );
      int callCount = 0;

      throttleDebouncer.call(() => callCount++);

      expect(callCount, 1);
    });

    test('executes trailing edge after duration', () async {
      throttleDebouncer = ThrottleDebouncer(
        duration: const Duration(milliseconds: 50),
      );
      int callCount = 0;

      throttleDebouncer.call(() => callCount++);
      throttleDebouncer.call(() => callCount++);
      throttleDebouncer.call(() => callCount++);

      expect(callCount, 1); // Leading edge

      await Future.delayed(const Duration(milliseconds: 60));

      expect(callCount, 2); // Trailing edge
    });

    test('only executes last callback on trailing edge', () async {
      throttleDebouncer = ThrottleDebouncer(
        duration: const Duration(milliseconds: 50),
      );
      String lastValue = '';

      throttleDebouncer.call(() => lastValue = 'first');
      throttleDebouncer.call(() => lastValue = 'second');
      throttleDebouncer.call(() => lastValue = 'third');

      expect(lastValue, 'first'); // Leading edge

      await Future.delayed(const Duration(milliseconds: 60));

      expect(lastValue, 'third'); // Trailing edge with last callback
    });

    test('no trailing if only one call', () async {
      throttleDebouncer = ThrottleDebouncer(
        duration: const Duration(milliseconds: 50),
      );
      int callCount = 0;

      throttleDebouncer.call(() => callCount++);

      expect(callCount, 1);

      await Future.delayed(const Duration(milliseconds: 60));

      expect(callCount, 1); // No trailing edge since no pending
    });

    test('reset clears state', () async {
      throttleDebouncer = ThrottleDebouncer(
        duration: const Duration(milliseconds: 100),
      );
      int callCount = 0;

      throttleDebouncer.call(() => callCount++);
      throttleDebouncer.call(() => callCount++);

      expect(callCount, 1);

      throttleDebouncer.reset();

      throttleDebouncer.call(() => callCount++);
      expect(callCount, 2);
    });

    test('cancel prevents trailing execution', () async {
      throttleDebouncer = ThrottleDebouncer(
        duration: const Duration(milliseconds: 50),
      );
      int callCount = 0;

      throttleDebouncer.call(() => callCount++);
      throttleDebouncer.call(() => callCount++);

      expect(callCount, 1);

      throttleDebouncer.cancel();

      await Future.delayed(const Duration(milliseconds: 60));

      expect(callCount, 1); // No trailing edge
    });

    test('works with rapid calls', () async {
      throttleDebouncer = ThrottleDebouncer(
        duration: const Duration(milliseconds: 50),
      );
      int callCount = 0;

      for (var i = 0; i < 100; i++) {
        throttleDebouncer.call(() => callCount++);
      }

      expect(callCount, 1); // Only leading edge

      await Future.delayed(const Duration(milliseconds: 60));

      expect(callCount, 2); // Leading + trailing
    });

    test('isPending returns correct state', () async {
      throttleDebouncer = ThrottleDebouncer(
        duration: const Duration(milliseconds: 50),
      );

      throttleDebouncer.call(() {});
      expect(throttleDebouncer.isPending, true);

      await Future.delayed(const Duration(milliseconds: 60));
      expect(throttleDebouncer.isPending, false);
    });

    test('wrap returns VoidCallback', () {
      throttleDebouncer = ThrottleDebouncer(
        duration: const Duration(milliseconds: 100),
      );
      int callCount = 0;

      final wrapped = throttleDebouncer.wrap(() => callCount++);
      expect(wrapped, isNotNull);

      wrapped!();
      expect(callCount, 1);
    });

    test('dispose prevents trailing execution', () async {
      throttleDebouncer = ThrottleDebouncer(
        duration: const Duration(milliseconds: 50),
      );
      int callCount = 0;

      throttleDebouncer.call(() => callCount++);
      throttleDebouncer.call(() => callCount++);

      throttleDebouncer.dispose();

      await Future.delayed(const Duration(milliseconds: 60));

      expect(callCount, 1); // Only leading, no trailing
    });

    test('consecutive bursts work correctly', () async {
      throttleDebouncer = ThrottleDebouncer(
        duration: const Duration(milliseconds: 50),
      );
      int callCount = 0;

      // First burst
      throttleDebouncer.call(() => callCount++);
      throttleDebouncer.call(() => callCount++);
      await Future.delayed(const Duration(milliseconds: 100));
      expect(callCount, 2); // Leading + trailing

      // Second burst - need to wait for throttle to clear
      await Future.delayed(const Duration(milliseconds: 10));
      throttleDebouncer.call(() => callCount++);
      throttleDebouncer.call(() => callCount++);
      await Future.delayed(const Duration(milliseconds: 100));
      expect(callCount, 4); // Leading + trailing again
    });
  });
}
