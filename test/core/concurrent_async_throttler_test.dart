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

    // ========================================================================
    // maxQueueSize Tests (Enqueue Mode)
    // ========================================================================

    group('maxQueueSize', () {
      test('unlimited by default (null)', () async {
        final throttler = ConcurrentAsyncThrottler(
          mode: ConcurrencyMode.enqueue,
          maxDuration: const Duration(seconds: 5),
        );

        // Start a long-running task to hold the lock
        throttler.call(() async {
          await Future.delayed(const Duration(milliseconds: 100));
        });

        // Queue many calls
        for (var i = 0; i < 100; i++) {
          throttler.call(() async {});
        }

        expect(throttler.queueSize, 100);

        throttler.dispose();
      });

      test('limits queue when maxQueueSize is set', () {
        final throttler = ConcurrentAsyncThrottler(
          mode: ConcurrencyMode.enqueue,
          maxDuration: const Duration(seconds: 5),
          maxQueueSize: 5,
        );

        // Start task to lock
        throttler.call(() async {
          await Future.delayed(const Duration(milliseconds: 200));
        });

        // Try to queue more than limit
        for (var i = 0; i < 10; i++) {
          throttler.call(() async {});
        }

        // Queue should be capped at maxQueueSize
        expect(throttler.queueSize, lessThanOrEqualTo(5));

        throttler.dispose();
      });
    });

    group('QueueOverflowStrategy.dropNewest', () {
      test('rejects new calls when queue is full', () async {
        final results = <int>[];
        var rejectedCount = 0;

        final throttler = ConcurrentAsyncThrottler(
          mode: ConcurrencyMode.enqueue,
          maxDuration: const Duration(seconds: 5),
          maxQueueSize: 3,
          queueOverflowStrategy: QueueOverflowStrategy.dropNewest,
        );

        // Start long task to hold lock
        throttler.call(() async {
          await Future.delayed(const Duration(milliseconds: 100));
          results.add(0);
        });

        // Queue 3 items (max)
        throttler
            .call(() async => results.add(1))
            .catchError((_) => rejectedCount++);
        throttler
            .call(() async => results.add(2))
            .catchError((_) => rejectedCount++);
        throttler
            .call(() async => results.add(3))
            .catchError((_) => rejectedCount++);

        // These should be rejected
        throttler
            .call(() async => results.add(4))
            .catchError((_) => rejectedCount++);
        throttler
            .call(() async => results.add(5))
            .catchError((_) => rejectedCount++);

        await Future.delayed(const Duration(milliseconds: 200));

        expect(results, [0, 1, 2, 3]); // Only first 4 (including initial)
        expect(rejectedCount, 2); // 2 were rejected

        throttler.dispose();
      });

      test('maintains FIFO order for queued items', () async {
        final results = <int>[];

        final throttler = ConcurrentAsyncThrottler(
          mode: ConcurrencyMode.enqueue,
          maxDuration: const Duration(seconds: 5),
          maxQueueSize: 3,
          queueOverflowStrategy: QueueOverflowStrategy.dropNewest,
        );

        // Start task
        throttler.call(() async {
          await Future.delayed(const Duration(milliseconds: 50));
          results.add(0);
        });

        // Queue items
        throttler.call(() async => results.add(1));
        throttler.call(() async => results.add(2));
        throttler.call(() async => results.add(3));
        throttler
            .call(() async => results.add(4))
            .catchError((_) {}); // Rejected

        await Future.delayed(const Duration(milliseconds: 200));

        expect(results, [0, 1, 2, 3]); // FIFO order preserved

        throttler.dispose();
      });

      test('queueSize respects limit with dropNewest', () {
        final throttler = ConcurrentAsyncThrottler(
          mode: ConcurrencyMode.enqueue,
          maxDuration: const Duration(seconds: 5),
          maxQueueSize: 5,
          queueOverflowStrategy: QueueOverflowStrategy.dropNewest,
        );

        // Lock
        throttler.call(() async {
          await Future.delayed(const Duration(milliseconds: 500));
        });

        // Spam calls
        for (var i = 0; i < 100; i++) {
          throttler.call(() async {}).catchError((_) {});
        }

        expect(throttler.queueSize, 5);

        throttler.dispose();
      });
    });

    group('QueueOverflowStrategy.dropOldest', () {
      test('removes oldest when queue is full', () async {
        final results = <int>[];

        final throttler = ConcurrentAsyncThrottler(
          mode: ConcurrencyMode.enqueue,
          maxDuration: const Duration(seconds: 5),
          maxQueueSize: 3,
          queueOverflowStrategy: QueueOverflowStrategy.dropOldest,
        );

        // Start task
        throttler.call(() async {
          await Future.delayed(const Duration(milliseconds: 50));
          results.add(0);
        });

        // Queue more than limit
        throttler
            .call(() async => results.add(1))
            .catchError((_) {}); // Dropped
        throttler
            .call(() async => results.add(2))
            .catchError((_) {}); // Dropped
        throttler.call(() async => results.add(3));
        throttler.call(() async => results.add(4));
        throttler.call(() async => results.add(5));

        await Future.delayed(const Duration(milliseconds: 200));

        // Should have: initial (0) + last 3 queued (3, 4, 5)
        expect(results, [0, 3, 4, 5]);

        throttler.dispose();
      });

      test('dropped items receive error', () async {
        var droppedCount = 0;

        final throttler = ConcurrentAsyncThrottler(
          mode: ConcurrencyMode.enqueue,
          maxDuration: const Duration(seconds: 5),
          maxQueueSize: 2,
          queueOverflowStrategy: QueueOverflowStrategy.dropOldest,
        );

        // Lock
        throttler.call(() async {
          await Future.delayed(const Duration(milliseconds: 100));
        });

        // Queue items
        throttler.call(() async {}).catchError((_) => droppedCount++);
        throttler.call(() async {}).catchError((_) => droppedCount++);
        throttler
            .call(() async {})
            .catchError((_) => droppedCount++); // Causes drop
        throttler
            .call(() async {})
            .catchError((_) => droppedCount++); // Causes drop

        await Future.delayed(const Duration(milliseconds: 200));

        expect(droppedCount, 2); // First 2 were dropped

        throttler.dispose();
      });

      test('always keeps latest items', () async {
        final results = <int>[];

        final throttler = ConcurrentAsyncThrottler(
          mode: ConcurrencyMode.enqueue,
          maxDuration: const Duration(seconds: 5),
          maxQueueSize: 2,
          queueOverflowStrategy: QueueOverflowStrategy.dropOldest,
        );

        // Lock
        throttler.call(() async {
          await Future.delayed(const Duration(milliseconds: 50));
          results.add(0);
        });

        // Rapidly add 10 items
        for (var i = 1; i <= 10; i++) {
          final value = i;
          throttler.call(() async => results.add(value)).catchError((_) {});
        }

        await Future.delayed(const Duration(milliseconds: 200));

        // Should have initial + last 2
        expect(results, [0, 9, 10]);

        throttler.dispose();
      });
    });

    group('maxQueueSize edge cases', () {
      test('maxQueueSize of 1 works correctly', () async {
        final results = <int>[];

        final throttler = ConcurrentAsyncThrottler(
          mode: ConcurrencyMode.enqueue,
          maxDuration: const Duration(seconds: 5),
          maxQueueSize: 1,
          queueOverflowStrategy: QueueOverflowStrategy.dropOldest,
        );

        // Lock
        throttler.call(() async {
          await Future.delayed(const Duration(milliseconds: 50));
          results.add(0);
        });

        // Add multiple - only last should be kept
        for (var i = 1; i <= 5; i++) {
          final value = i;
          throttler.call(() async => results.add(value)).catchError((_) {});
        }

        await Future.delayed(const Duration(milliseconds: 150));

        expect(results, [0, 5]); // Initial + only last

        throttler.dispose();
      });

      test('works with debugMode', () async {
        final throttler = ConcurrentAsyncThrottler(
          mode: ConcurrencyMode.enqueue,
          maxDuration: const Duration(seconds: 5),
          maxQueueSize: 2,
          queueOverflowStrategy: QueueOverflowStrategy.dropOldest,
          debugMode: true,
          name: 'TestQueue',
        );

        // Lock
        throttler.call(() async {
          await Future.delayed(const Duration(milliseconds: 50));
        });

        // Trigger overflow
        throttler.call(() async {}).catchError((_) {});
        throttler.call(() async {}).catchError((_) {});
        throttler.call(() async {}).catchError((_) {}); // Triggers drop

        await Future.delayed(const Duration(milliseconds: 100));

        throttler.dispose();
        // No assertion - just verify debug logging doesn't crash
      });

      test('reset clears queue and overflow state', () async {
        final throttler = ConcurrentAsyncThrottler(
          mode: ConcurrencyMode.enqueue,
          maxDuration: const Duration(seconds: 5),
          maxQueueSize: 3,
        );

        // Fill queue
        throttler.call(() async {
          await Future.delayed(const Duration(milliseconds: 200));
        });

        throttler.call(() async {}).catchError((_) {});
        throttler.call(() async {}).catchError((_) {});
        throttler.call(() async {}).catchError((_) {});

        expect(throttler.queueSize, 3);

        throttler.reset();

        expect(throttler.queueSize, 0);
        expect(throttler.isLocked, false);

        throttler.dispose();
      });

      test('pendingCount includes active + queued', () {
        final throttler = ConcurrentAsyncThrottler(
          mode: ConcurrencyMode.enqueue,
          maxDuration: const Duration(seconds: 5),
          maxQueueSize: 5,
        );

        // Lock with active task
        throttler.call(() async {
          await Future.delayed(const Duration(milliseconds: 500));
        });

        // Add to queue
        throttler.call(() async {});
        throttler.call(() async {});

        expect(throttler.queueSize, 2);
        expect(throttler.pendingCount, 3); // 1 active + 2 queued

        throttler.dispose();
      });
    });

    group('Real-world scenarios', () {
      test('chat message queue with limit', () async {
        final sentMessages = <String>[];

        final chatSender = ConcurrentAsyncThrottler(
          mode: ConcurrencyMode.enqueue,
          maxDuration: const Duration(seconds: 30),
          maxQueueSize: 10,
          queueOverflowStrategy: QueueOverflowStrategy.dropOldest,
        );

        var messageId = 0;

        // Simulate rapid message sending
        Future<void> sendMessage(String msg) async {
          final id = ++messageId;
          await chatSender.call(() async {
            await Future.delayed(const Duration(milliseconds: 10));
            sentMessages.add('$msg-$id');
          }).catchError((_) {}); // Ignore dropped messages
        }

        // User spams 20 messages
        for (var i = 0; i < 20; i++) {
          sendMessage('msg$i');
        }

        await Future.delayed(const Duration(milliseconds: 500));

        // Should have sent ~11 messages (1 active + 10 queued max)
        expect(sentMessages.length, lessThanOrEqualTo(11));
        // Last messages should be most recent
        expect(
            sentMessages.last.contains('19') ||
                sentMessages.last.contains('20'),
            true);

        chatSender.dispose();
      });

      test('API request queue with backpressure', () async {
        var processedRequests = 0;
        var rejectedRequests = 0;

        final apiQueue = ConcurrentAsyncThrottler(
          mode: ConcurrencyMode.enqueue,
          maxDuration: const Duration(seconds: 10),
          maxQueueSize: 5,
          queueOverflowStrategy: QueueOverflowStrategy.dropNewest,
        );

        // Simulate burst of 50 requests
        final futures = <Future>[];
        for (var i = 0; i < 50; i++) {
          futures.add(
            apiQueue.call(() async {
              await Future.delayed(const Duration(milliseconds: 5));
              processedRequests++;
            }).catchError((_) {
              rejectedRequests++;
            }),
          );
        }

        await Future.wait(futures);

        // Should process max 6 (1 active + 5 queued initially)
        expect(processedRequests, lessThanOrEqualTo(10));
        expect(rejectedRequests, greaterThan(40));

        apiQueue.dispose();
      });
    });
  });
}
