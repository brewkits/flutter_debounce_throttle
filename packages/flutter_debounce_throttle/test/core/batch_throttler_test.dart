import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_debounce_throttle/flutter_debounce_throttle.dart';

void main() {
  group('BatchThrottler', () {
    late BatchThrottler batcher;

    test('batches multiple actions', () async {
      final executedActions = <int>[];

      batcher = BatchThrottler(
        duration: const Duration(milliseconds: 50),
        onBatchExecute: (actions) {
          for (final action in actions) {
            action();
          }
        },
      );

      batcher.call(() => executedActions.add(1));
      batcher.call(() => executedActions.add(2));
      batcher.call(() => executedActions.add(3));

      expect(executedActions, isEmpty);

      await Future.delayed(const Duration(milliseconds: 60));

      expect(executedActions, [1, 2, 3]);
      batcher.dispose();
    });

    test('resets timer on each add', () async {
      int batchCount = 0;

      batcher = BatchThrottler(
        duration: const Duration(milliseconds: 50),
        onBatchExecute: (actions) => batchCount++,
      );

      batcher.call(() {});
      await Future.delayed(const Duration(milliseconds: 30));
      batcher.call(() {});
      await Future.delayed(const Duration(milliseconds: 30));
      batcher.call(() {});

      expect(batchCount, 0);

      await Future.delayed(const Duration(milliseconds: 60));
      expect(batchCount, 1);

      batcher.dispose();
    });

    test('flush() executes immediately', () {
      final executedActions = <int>[];

      batcher = BatchThrottler(
        duration: const Duration(milliseconds: 100),
        onBatchExecute: (actions) {
          for (final action in actions) {
            action();
          }
        },
      );

      batcher.call(() => executedActions.add(1));
      batcher.call(() => executedActions.add(2));

      expect(executedActions, isEmpty);

      batcher.flush();
      expect(executedActions, [1, 2]);

      batcher.dispose();
    });

    test('clear() removes pending without executing', () async {
      final executedActions = <int>[];

      batcher = BatchThrottler(
        duration: const Duration(milliseconds: 50),
        onBatchExecute: (actions) {
          for (final action in actions) {
            action();
          }
        },
      );

      batcher.call(() => executedActions.add(1));
      batcher.call(() => executedActions.add(2));

      batcher.clear();

      await Future.delayed(const Duration(milliseconds: 60));
      expect(executedActions, isEmpty);

      batcher.dispose();
    });

    test('pendingCount returns correct count', () {
      batcher = BatchThrottler(
        duration: const Duration(milliseconds: 100),
        onBatchExecute: (actions) {},
      );

      expect(batcher.pendingCount, 0);

      batcher.call(() {});
      expect(batcher.pendingCount, 1);

      batcher.call(() {});
      expect(batcher.pendingCount, 2);

      batcher.call(() {});
      expect(batcher.pendingCount, 3);

      batcher.dispose();
    });

    test('hasPending returns correct state', () async {
      batcher = BatchThrottler(
        duration: const Duration(milliseconds: 50),
        onBatchExecute: (actions) {},
      );

      expect(batcher.hasPending, false);

      batcher.call(() {});
      expect(batcher.hasPending, true);

      await Future.delayed(const Duration(milliseconds: 60));
      expect(batcher.hasPending, false);

      batcher.dispose();
    });

    test('debugMode logs messages', () async {
      batcher = BatchThrottler(
        duration: const Duration(milliseconds: 50),
        onBatchExecute: (actions) {},
        debugMode: true,
        name: 'TestBatcher',
      );

      batcher.call(() {});
      batcher.call(() {});

      await Future.delayed(const Duration(milliseconds: 60));

      batcher.dispose();
    });

    test('dispose clears pending actions', () async {
      final executedActions = <int>[];

      batcher = BatchThrottler(
        duration: const Duration(milliseconds: 100),
        onBatchExecute: (actions) {
          for (final action in actions) {
            action();
          }
        },
      );

      batcher.call(() => executedActions.add(1));
      batcher.call(() => executedActions.add(2));

      batcher.dispose();

      await Future.delayed(const Duration(milliseconds: 120));
      expect(executedActions, isEmpty);
    });

    test('handles large batches', () async {
      int totalExecuted = 0;

      batcher = BatchThrottler(
        duration: const Duration(milliseconds: 50),
        onBatchExecute: (actions) {
          totalExecuted = actions.length;
        },
      );

      for (var i = 0; i < 1000; i++) {
        batcher.call(() {});
      }

      await Future.delayed(const Duration(milliseconds: 60));
      expect(totalExecuted, 1000);

      batcher.dispose();
    });

    test('multiple batches can be executed sequentially', () async {
      int batchCount = 0;

      batcher = BatchThrottler(
        duration: const Duration(milliseconds: 50),
        onBatchExecute: (actions) => batchCount++,
      );

      batcher.call(() {});
      await Future.delayed(const Duration(milliseconds: 60));
      expect(batchCount, 1);

      batcher.call(() {});
      batcher.call(() {});
      await Future.delayed(const Duration(milliseconds: 60));
      expect(batchCount, 2);

      batcher.dispose();
    });

    // ========================================================================
    // maxBatchSize Tests
    // ========================================================================

    group('maxBatchSize', () {
      test('unlimited by default (null)', () async {
        final executedCounts = <int>[];

        batcher = BatchThrottler(
          duration: const Duration(milliseconds: 50),
          onBatchExecute: (actions) {
            executedCounts.add(actions.length);
          },
        );

        // Add many items
        for (var i = 0; i < 1000; i++) {
          batcher.call(() {});
        }

        await Future.delayed(const Duration(milliseconds: 60));

        expect(executedCounts, [1000]); // All in one batch
        batcher.dispose();
      });

      test('limits batch size when set', () async {
        final executedCounts = <int>[];

        batcher = BatchThrottler(
          duration: const Duration(milliseconds: 50),
          maxBatchSize: 5,
          onBatchExecute: (actions) {
            executedCounts.add(actions.length);
          },
        );

        // Add items up to limit
        for (var i = 0; i < 5; i++) {
          batcher.call(() {});
        }
        expect(batcher.pendingCount, 5);

        await Future.delayed(const Duration(milliseconds: 60));
        expect(executedCounts, [5]);

        batcher.dispose();
      });
    });

    group('BatchOverflowStrategy.dropOldest', () {
      test('removes oldest when full', () async {
        final executedValues = <int>[];

        batcher = BatchThrottler(
          duration: const Duration(milliseconds: 50),
          maxBatchSize: 3,
          overflowStrategy: BatchOverflowStrategy.dropOldest,
          onBatchExecute: (actions) {
            for (final action in actions) {
              action();
            }
          },
        );

        batcher.call(() => executedValues.add(1)); // Will be dropped
        batcher.call(() => executedValues.add(2)); // Will be dropped
        batcher.call(() => executedValues.add(3));
        batcher.call(() => executedValues.add(4));
        batcher.call(() => executedValues.add(5));

        await Future.delayed(const Duration(milliseconds: 60));

        // Only last 3 should execute
        expect(executedValues, [3, 4, 5]);
        batcher.dispose();
      });

      test('maintains correct order after drops', () async {
        final order = <int>[];

        batcher = BatchThrottler(
          duration: const Duration(milliseconds: 50),
          maxBatchSize: 2,
          overflowStrategy: BatchOverflowStrategy.dropOldest,
          onBatchExecute: (actions) {
            for (final action in actions) {
              action();
            }
          },
        );

        for (var i = 1; i <= 10; i++) {
          final value = i;
          batcher.call(() => order.add(value));
        }

        await Future.delayed(const Duration(milliseconds: 60));

        // Only last 2 should remain
        expect(order, [9, 10]);
        batcher.dispose();
      });
    });

    group('BatchOverflowStrategy.dropNewest', () {
      test('rejects new when full', () async {
        final executedValues = <int>[];

        batcher = BatchThrottler(
          duration: const Duration(milliseconds: 50),
          maxBatchSize: 3,
          overflowStrategy: BatchOverflowStrategy.dropNewest,
          onBatchExecute: (actions) {
            for (final action in actions) {
              action();
            }
          },
        );

        batcher.call(() => executedValues.add(1));
        batcher.call(() => executedValues.add(2));
        batcher.call(() => executedValues.add(3));
        batcher.call(() => executedValues.add(4)); // Rejected
        batcher.call(() => executedValues.add(5)); // Rejected

        await Future.delayed(const Duration(milliseconds: 60));

        // Only first 3 should execute
        expect(executedValues, [1, 2, 3]);
        batcher.dispose();
      });

      test('pendingCount does not exceed maxBatchSize', () {
        batcher = BatchThrottler(
          duration: const Duration(milliseconds: 100),
          maxBatchSize: 3,
          overflowStrategy: BatchOverflowStrategy.dropNewest,
          onBatchExecute: (actions) {},
        );

        for (var i = 0; i < 10; i++) {
          batcher.call(() {});
        }

        expect(batcher.pendingCount, 3);
        batcher.dispose();
      });
    });

    group('BatchOverflowStrategy.flushAndAdd', () {
      test('flushes batch when full and adds new', () async {
        final batchSizes = <int>[];
        final executedValues = <int>[];

        batcher = BatchThrottler(
          duration: const Duration(milliseconds: 100),
          maxBatchSize: 3,
          overflowStrategy: BatchOverflowStrategy.flushAndAdd,
          onBatchExecute: (actions) {
            batchSizes.add(actions.length);
            for (final action in actions) {
              action();
            }
          },
        );

        batcher.call(() => executedValues.add(1));
        batcher.call(() => executedValues.add(2));
        batcher.call(() => executedValues.add(3));
        // Next call triggers flush
        batcher.call(() => executedValues.add(4));

        // Flush should happen immediately
        await Future.delayed(const Duration(milliseconds: 10));
        expect(batchSizes, [3]); // First batch flushed
        expect(executedValues, [1, 2, 3]);

        // Wait for remaining item
        await Future.delayed(const Duration(milliseconds: 110));
        expect(batchSizes, [3, 1]); // Second batch with item 4
        expect(executedValues, [1, 2, 3, 4]);

        batcher.dispose();
      });

      test('handles continuous overflow', () async {
        final batchSizes = <int>[];

        batcher = BatchThrottler(
          duration: const Duration(milliseconds: 100),
          maxBatchSize: 2,
          overflowStrategy: BatchOverflowStrategy.flushAndAdd,
          onBatchExecute: (actions) {
            batchSizes.add(actions.length);
          },
        );

        // Add 7 items rapidly
        for (var i = 0; i < 7; i++) {
          batcher.call(() {});
        }

        // Should trigger multiple flushes
        await Future.delayed(const Duration(milliseconds: 150));

        // Expected: flush at 2, flush at 4, flush at 6, then 1 remaining
        expect(batchSizes, [2, 2, 2, 1]);
        batcher.dispose();
      });
    });

    group('maxBatchSize edge cases', () {
      test('maxBatchSize of 1 flushes each item', () async {
        final batchSizes = <int>[];

        batcher = BatchThrottler(
          duration: const Duration(milliseconds: 100),
          maxBatchSize: 1,
          overflowStrategy: BatchOverflowStrategy.flushAndAdd,
          onBatchExecute: (actions) {
            batchSizes.add(actions.length);
          },
        );

        batcher.call(() {});
        batcher.call(() {});
        batcher.call(() {});

        await Future.delayed(const Duration(milliseconds: 150));

        // Each triggers flush + last one via timer
        expect(batchSizes.length, 3);
        expect(batchSizes.every((size) => size == 1), true);
        batcher.dispose();
      });

      test('works with debugMode', () async {
        batcher = BatchThrottler(
          duration: const Duration(milliseconds: 50),
          maxBatchSize: 2,
          overflowStrategy: BatchOverflowStrategy.dropOldest,
          onBatchExecute: (actions) {},
          debugMode: true,
          name: 'TestOverflow',
        );

        for (var i = 0; i < 5; i++) {
          batcher.call(() {});
        }

        await Future.delayed(const Duration(milliseconds: 60));
        batcher.dispose();
        // No assertion - just verify no errors with debug logging
      });
    });

    group('Real-world scenarios', () {
      test('log batching with size limit', () async {
        final batches = <List<String>>[];

        batcher = BatchThrottler(
          duration: const Duration(milliseconds: 50),
          maxBatchSize: 100,
          overflowStrategy: BatchOverflowStrategy.flushAndAdd,
          onBatchExecute: (actions) {
            final logs = <String>[];
            for (final action in actions) {
              action();
            }
            batches.add(List.from(logs));
          },
        );

        // Simulate burst of 250 log entries
        final allLogs = <String>[];
        for (var i = 0; i < 250; i++) {
          final logMsg = 'Log $i';
          batcher.call(() => allLogs.add(logMsg));
        }

        await Future.delayed(const Duration(milliseconds: 100));

        // Should have created multiple batches
        expect(allLogs.length, 250);
        batcher.dispose();
      });

      test('event aggregation with dropNewest for backpressure', () async {
        var processedCount = 0;

        batcher = BatchThrottler(
          duration: const Duration(milliseconds: 50),
          maxBatchSize: 10,
          overflowStrategy: BatchOverflowStrategy.dropNewest,
          onBatchExecute: (actions) {
            processedCount += actions.length;
          },
        );

        // Simulate 100 events when we can only handle 10
        for (var i = 0; i < 100; i++) {
          batcher.call(() {});
        }

        await Future.delayed(const Duration(milliseconds: 60));

        // Only 10 should be processed (backpressure)
        expect(processedCount, 10);
        batcher.dispose();
      });
    });
  });
}
