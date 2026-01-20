import 'package:flutter_debounce_throttle/flutter_debounce_throttle.dart';
import 'package:flutter_test/flutter_test.dart';

class TestController with EventLimiterMixin {
  void simulateSpam(int count) {
    for (var i = 0; i < count; i++) {
      debounce('dynamic_id_$i', () {
        // Simulate dynamic ID usage
      });
    }
  }

  int get limiterCount =>
      _debouncers.length +
      _throttlers.length +
      _asyncDebouncers.length +
      _asyncThrottlers.length;
}

void main() {
  group('EventLimiterMixin Memory Guard', () {
    test('should warn when limiter count exceeds 100', () {
      final controller = TestController();

      // Should not trigger warning with 50 limiters
      controller.simulateSpam(50);
      expect(controller.limiterCount, 50);

      // Should trigger warning with 101 limiters (in debug mode)
      expect(
        () => controller.simulateSpam(51),
        throwsA(
          isA<AssertionError>().having(
            (e) => e.message,
            'message',
            contains('over 100 limiter instances'),
          ),
        ),
      );

      controller.cancelAll();
    });

    test('should allow cleanup with remove() to prevent warnings', () {
      final controller = TestController();

      // Create 150 limiters
      for (var i = 0; i < 150; i++) {
        controller.debounce('item_$i', () {});
      }

      // Remove 100 limiters
      for (var i = 0; i < 100; i++) {
        controller.remove('item_$i');
      }

      // Should have only 50 left, no warning on next debounce
      expect(controller.limiterCount, 50);
      expect(
        () => controller.debounce('new_item', () {}),
        returnsNormally,
      );

      controller.cancelAll();
    });

    test('should track all limiter types in count', () {
      final controller = TestController();

      // Add different types of limiters
      controller.debounce('d1', () {});
      controller.throttle('t1', () {});
      controller.debounceAsync<void>('ad1', () async {});
      controller.throttleAsync('at1', () async {});

      expect(controller.limiterCount, 4);

      controller.cancelAll();
    });

    test('cancelAll should clear all limiters', () {
      final controller = TestController();

      controller.simulateSpam(50);
      expect(controller.limiterCount, 50);

      controller.cancelAll();
      expect(controller.limiterCount, 0);
    });
  });
}
