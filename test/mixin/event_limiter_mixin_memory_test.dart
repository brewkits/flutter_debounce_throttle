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
      testDebouncers.length +
      testThrottlers.length +
      testAsyncDebouncers.length +
      testAsyncThrottlers.length;

  // Expose timestamp maps for testing
  int get timestampCount =>
      testDebouncersLastUsed.length +
      testThrottlersLastUsed.length +
      testAsyncDebouncersLastUsed.length +
      testAsyncThrottlersLastUsed.length;
}

void main() {
  group('EventLimiterMixin Memory Guard', () {
    test('should warn when limiter count exceeds 100', () {
      final controller = TestController();

      // Should not trigger warning with 100 limiters
      controller.simulateSpam(100);
      expect(controller.limiterCount, 100);

      // Should trigger warning with 101st limiter (in debug mode)
      expect(
        () => controller.debounce('trigger', () {}),
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

      // Create 100 limiters (at the threshold, won't trigger warning)
      for (var i = 0; i < 100; i++) {
        controller.debounce('item_$i', () {});
      }

      // Remove 50 limiters
      for (var i = 0; i < 50; i++) {
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

  group('TTL Auto-Cleanup', () {
    tearDown(() {
      DebounceThrottleConfig.reset();
    });

    test('auto-cleanup does not run when TTL is disabled (default)', () async {
      final controller = TestController();

      // Add 50 limiters
      for (var i = 0; i < 50; i++) {
        controller.debounce('item_$i', () {});
      }

      // Wait a bit (simulating that these are "old")
      await Future.delayed(const Duration(milliseconds: 50));

      // Add another limiter - TTL is disabled so no auto-cleanup should occur
      controller.debounce('new_item', () {});

      // All limiters should still be there (no auto-cleanup when TTL is disabled)
      expect(controller.limiterCount, 51);

      controller.cancelAll();
    });

    test('auto-cleanup removes limiters older than TTL', () async {
      DebounceThrottleConfig.init(
        limiterAutoCleanupTTL: const Duration(milliseconds: 100),
        limiterAutoCleanupThreshold: 50,
      );

      final controller = TestController();

      // Add 60 limiters (exceeds threshold)
      for (var i = 0; i < 60; i++) {
        controller.debounce('item_$i', () {});
      }

      expect(controller.limiterCount, 60);

      // Wait for TTL to expire
      await Future.delayed(const Duration(milliseconds: 150));

      // Trigger auto-cleanup by adding new limiter
      controller.debounce('new_item', () {});

      // Old limiters should be auto-removed, only new one remains
      expect(controller.limiterCount, 1);
      expect(controller.timestampCount, 1);

      controller.cancelAll();
    });

    test('auto-cleanup preserves recently-used limiters', () async {
      DebounceThrottleConfig.init(
        limiterAutoCleanupTTL: const Duration(milliseconds: 100),
        limiterAutoCleanupThreshold: 50,
      );

      final controller = TestController();

      // Add 60 limiters
      for (var i = 0; i < 60; i++) {
        controller.debounce('item_$i', () {});
      }

      // Wait a bit
      await Future.delayed(const Duration(milliseconds: 50));

      // Use some limiters again (refresh timestamps)
      for (var i = 0; i < 10; i++) {
        controller.debounce('item_$i', () {});
      }

      // Wait for initial TTL to expire (but refreshed ones are still valid)
      await Future.delayed(const Duration(milliseconds: 60));

      // Trigger auto-cleanup
      controller.debounce('trigger', () {});

      // Only recently-used limiters (10) + trigger (1) should remain
      expect(controller.limiterCount, 11);

      controller.cancelAll();
    });

    test('auto-cleanup only triggers when threshold is exceeded', () async {
      DebounceThrottleConfig.init(
        limiterAutoCleanupTTL: const Duration(milliseconds: 100),
        limiterAutoCleanupThreshold: 100,
      );

      final controller = TestController();

      // Add 50 limiters (below threshold)
      for (var i = 0; i < 50; i++) {
        controller.debounce('item_$i', () {});
      }

      // Wait for TTL to expire
      await Future.delayed(const Duration(milliseconds: 150));

      // Add new limiter (should not trigger cleanup)
      controller.debounce('new_item', () {});

      // All limiters should still be there (threshold not reached)
      expect(controller.limiterCount, 51);

      controller.cancelAll();
    });

    test('auto-cleanup works with all limiter types', () async {
      DebounceThrottleConfig.init(
        limiterAutoCleanupTTL: const Duration(milliseconds: 100),
        limiterAutoCleanupThreshold: 20,
      );

      final controller = TestController();

      // Add different types of limiters
      for (var i = 0; i < 10; i++) {
        controller.debounce('debounce_$i', () {});
        controller.throttle('throttle_$i', () {});
        controller.debounceAsync<void>('async_debounce_$i', () async {});
        controller.throttleAsync('async_throttle_$i', () async {});
      }

      expect(controller.limiterCount, 40);

      // Wait for TTL to expire
      await Future.delayed(const Duration(milliseconds: 150));

      // Trigger cleanup
      controller.debounce('trigger', () {});

      // Only trigger should remain
      expect(controller.limiterCount, 1);

      controller.cancelAll();
    });
  });

  group('Manual Cleanup Methods', () {
    test('cleanupInactive() removes only inactive limiters', () async {
      final controller = TestController();

      // Add some limiters
      for (var i = 0; i < 5; i++) {
        controller.debounce('item_$i', () {});
      }

      expect(controller.limiterCount, 5);

      // Wait for all to become inactive
      await Future.delayed(const Duration(milliseconds: 400));

      // Cleanup inactive
      final removed = controller.cleanupInactive();

      expect(removed, 5);
      expect(controller.limiterCount, 0);
    });

    test('cleanupInactive() preserves pending limiters', () async {
      final controller = TestController();

      // Add limiters
      controller.debounce('pending1', () {});
      controller.debounce('pending2', () {});
      controller.debounce('pending3', () {});

      // These are still pending (debounce not executed yet)
      expect(controller.limiterCount, 3);

      // Cleanup should not remove pending limiters
      final removed = controller.cleanupInactive();

      expect(removed, 0);
      expect(controller.limiterCount, 3);

      controller.cancelAll();
    });

    test('cleanupUnused() respects inactivity period', () async {
      final controller = TestController();

      // Add limiters
      for (var i = 0; i < 10; i++) {
        controller.debounce('item_$i', () {});
      }

      expect(controller.limiterCount, 10);

      // Wait 50ms
      await Future.delayed(const Duration(milliseconds: 50));

      // Use some limiters again
      for (var i = 0; i < 5; i++) {
        controller.debounce('item_$i', () {});
      }

      // Wait another 60ms
      await Future.delayed(const Duration(milliseconds: 60));

      // Cleanup limiters unused for 100ms
      // The first 5 are now 110ms old, the refreshed 5 are only 60ms old
      final removed =
          controller.cleanupUnused(const Duration(milliseconds: 100));

      expect(removed, 5);
      expect(controller.limiterCount, 5);

      controller.cancelAll();
    });

    test('cleanupUnused() returns correct count', () async {
      final controller = TestController();

      // Add limiters
      for (var i = 0; i < 20; i++) {
        controller.debounce('item_$i', () {});
      }

      // Wait for all to age
      await Future.delayed(const Duration(milliseconds: 150));

      // Cleanup all older than 100ms
      final removed =
          controller.cleanupUnused(const Duration(milliseconds: 100));

      expect(removed, 20);
      expect(controller.limiterCount, 0);
    });

    test('remove() also cleans up timestamps', () {
      final controller = TestController();

      controller.debounce('item1', () {});
      controller.throttle('item2', () {});

      expect(controller.limiterCount, 2);
      expect(controller.timestampCount, 2);

      controller.remove('item1');

      expect(controller.limiterCount, 1);
      expect(controller.timestampCount, 1);

      controller.cancelAll();
    });

    test('cancelAll() also cleans up all timestamps', () {
      final controller = TestController();

      for (var i = 0; i < 10; i++) {
        controller.debounce('item_$i', () {});
      }

      expect(controller.limiterCount, 10);
      expect(controller.timestampCount, 10);

      controller.cancelAll();

      expect(controller.limiterCount, 0);
      expect(controller.timestampCount, 0);
    });
  });
}
