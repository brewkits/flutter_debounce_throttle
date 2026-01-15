import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_debounce_throttle/core.dart';

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
  });
}
