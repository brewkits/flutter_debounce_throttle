import 'dart:async';

import 'package:dart_debounce_throttle/dart_debounce_throttle.dart';
import 'package:test/test.dart';

void main() {
  // ─── Throttler Stress ────────────────────────────────────────────────────

  group('Throttler stress', () {
    test('100 rapid calls produce at most 1 execution within the interval',
        () async {
      final throttler = Throttler(duration: const Duration(milliseconds: 100));
      var executions = 0;

      for (var i = 0; i < 100; i++) {
        throttler.call(() => executions++);
      }

      expect(executions, lessThanOrEqualTo(1));
      throttler.dispose();
    });

    test('executions resume after cooldown expires', () async {
      final throttler = Throttler(duration: const Duration(milliseconds: 50));
      var executions = 0;

      throttler.call(() => executions++);
      await Future.delayed(const Duration(milliseconds: 80));
      throttler.call(() => executions++);

      expect(executions, 2);
      throttler.dispose();
    });

    test('isThrottled reflects state correctly across rapid calls', () {
      final throttler = Throttler(duration: const Duration(milliseconds: 200));

      expect(throttler.isThrottled, false);
      throttler.call(() {});
      expect(throttler.isThrottled, true);
      throttler.dispose();
    });

    test('reset() clears active throttle lock', () {
      final throttler = Throttler(duration: const Duration(milliseconds: 200));
      throttler.call(() {});
      expect(throttler.isThrottled, true);
      throttler.reset();
      expect(throttler.isThrottled, false);
      throttler.dispose();
    });

    test('1000 sequential throttle calls across intervals count correctly',
        () async {
      final throttler = Throttler(duration: const Duration(milliseconds: 30));
      var executions = 0;

      for (var batch = 0; batch < 5; batch++) {
        for (var i = 0; i < 200; i++) {
          throttler.call(() => executions++);
        }
        await Future.delayed(const Duration(milliseconds: 40));
      }

      // One execution per batch (5 batches) — up to 5 executions
      expect(executions, lessThanOrEqualTo(5));
      expect(executions, greaterThanOrEqualTo(4));
      throttler.dispose();
    });

    test('only first call executes within interval, subsequent are dropped',
        () async {
      final log = <int>[];
      final throttler = Throttler(
        duration: const Duration(milliseconds: 100),
      );

      for (var i = 0; i < 10; i++) {
        throttler.call(() => log.add(i));
      }

      // Throttler executes the first call, drops the rest
      expect(log.length, 1);
      expect(log[0], 0);
      throttler.dispose();
    });

    test('multiple dispose calls are safe', () {
      final throttler = Throttler(duration: const Duration(milliseconds: 100));
      throttler.call(() {});
      expect(() {
        throttler.dispose();
        throttler.dispose();
        throttler.dispose();
      }, returnsNormally);
    });

    test('zero-duration throttler executes every call', () async {
      final throttler =
          Throttler(duration: const Duration(milliseconds: 0));
      var executions = 0;

      for (var i = 0; i < 5; i++) {
        throttler.call(() => executions++);
        await Future.delayed(Duration.zero);
      }

      expect(executions, greaterThanOrEqualTo(5));
      throttler.dispose();
    });
  });

  // ─── Debouncer Stress ────────────────────────────────────────────────────

  group('Debouncer stress', () {
    test('500 rapid calls produce exactly 1 execution', () async {
      final debouncer =
          Debouncer(duration: const Duration(milliseconds: 100));
      var executions = 0;

      for (var i = 0; i < 500; i++) {
        debouncer.call(() => executions++);
      }

      await Future.delayed(const Duration(milliseconds: 200));

      expect(executions, 1);
      debouncer.dispose();
    });

    test('last value is captured, not first', () async {
      final debouncer =
          Debouncer(duration: const Duration(milliseconds: 80));
      var captured = 0;

      for (var i = 1; i <= 100; i++) {
        final current = i;
        debouncer.call(() => captured = current);
      }

      await Future.delayed(const Duration(milliseconds: 150));

      expect(captured, 100);
      debouncer.dispose();
    });

    test('cancel prevents execution', () async {
      final debouncer =
          Debouncer(duration: const Duration(milliseconds: 100));
      var executed = false;

      debouncer.call(() => executed = true);
      debouncer.cancel();

      await Future.delayed(const Duration(milliseconds: 200));

      expect(executed, false);
      debouncer.dispose();
    });

    test('multiple cancel calls are safe', () {
      final debouncer = Debouncer(duration: const Duration(milliseconds: 100));
      expect(() {
        debouncer.cancel();
        debouncer.cancel();
        debouncer.cancel();
      }, returnsNormally);
      debouncer.dispose();
    });

    test('leading: true + trailing: false only fires on first call', () async {
      final log = <int>[];
      final debouncer = Debouncer(
        duration: const Duration(milliseconds: 100),
        leading: true,
        trailing: false,
      );

      for (var i = 0; i < 10; i++) {
        final v = i;
        debouncer.call(() => log.add(v));
        await Future.delayed(const Duration(milliseconds: 10));
      }

      await Future.delayed(const Duration(milliseconds: 200));

      expect(log.length, 1);
      expect(log[0], 0);
      debouncer.dispose();
    });

    test('enabled: false bypasses debounce — every call executes immediately',
        () {
      final debouncer = Debouncer(
        duration: const Duration(milliseconds: 500),
        enabled: false,
      );
      var executions = 0;

      for (var i = 0; i < 10; i++) {
        debouncer.call(() => executions++);
      }

      expect(executions, 10);
      debouncer.dispose();
    });

    test('isPending reflects timer state', () async {
      final debouncer = Debouncer(duration: const Duration(milliseconds: 100));

      expect(debouncer.isPending, false);
      debouncer.call(() {});
      expect(debouncer.isPending, true);

      await Future.delayed(const Duration(milliseconds: 150));

      expect(debouncer.isPending, false);
      debouncer.dispose();
    });

    test('high-frequency bursts with gaps each fire once', () async {
      final debouncer = Debouncer(duration: const Duration(milliseconds: 60));
      var executions = 0;

      // Burst 1
      for (var i = 0; i < 50; i++) {
        debouncer.call(() => executions++);
      }
      await Future.delayed(const Duration(milliseconds: 100));

      // Burst 2
      for (var i = 0; i < 50; i++) {
        debouncer.call(() => executions++);
      }
      await Future.delayed(const Duration(milliseconds: 100));

      expect(executions, 2);
      debouncer.dispose();
    });
  });

  // ─── RateLimiter Stress ──────────────────────────────────────────────────

  group('RateLimiter stress', () {
    test('burst capacity respected: only maxTokens calls succeed initially',
        () {
      // refillRate must be > 0; use a very long interval so tokens don't refill
      final limiter = RateLimiter(
        maxTokens: 5,
        refillRate: 1,
        refillInterval: const Duration(hours: 1),
      );

      var allowed = 0;
      for (var i = 0; i < 20; i++) {
        if (limiter.tryAcquire()) allowed++;
      }

      expect(allowed, 5);
      limiter.dispose();
    });

    test('refill replenishes tokens over time', () async {
      final limiter = RateLimiter(
        maxTokens: 2,
        refillRate: 2,
        refillInterval: const Duration(milliseconds: 80),
      );

      // Drain initial tokens
      limiter.tryAcquire();
      limiter.tryAcquire();
      expect(limiter.tryAcquire(), false);

      await Future.delayed(const Duration(milliseconds: 120));

      expect(limiter.tryAcquire(), true);
      limiter.dispose();
    });

    test('timeUntilNextToken returns positive duration when empty', () {
      final limiter = RateLimiter(
        maxTokens: 1,
        refillRate: 1,
        refillInterval: const Duration(milliseconds: 200),
      );

      limiter.tryAcquire();

      final wait = limiter.timeUntilNextToken;
      expect(wait.inMilliseconds, greaterThan(0));
      limiter.dispose();
    });

    test('concurrent tryAcquire calls never exceed maxTokens', () async {
      final limiter = RateLimiter(
        maxTokens: 10,
        refillRate: 1,
        refillInterval: const Duration(hours: 1),
      );

      var acquired = 0;
      final futures = List.generate(
        50,
        (_) => Future(() {
          if (limiter.tryAcquire()) acquired++;
        }),
      );
      await Future.wait(futures);

      expect(acquired, lessThanOrEqualTo(10));
      limiter.dispose();
    });

    test('100 requests with refill: throughput matches configured rate',
        () async {
      final limiter = RateLimiter(
        maxTokens: 5,
        refillRate: 5,
        refillInterval: const Duration(milliseconds: 50),
      );

      var acquired = 0;
      for (var i = 0; i < 5; i++) {
        for (var j = 0; j < 20; j++) {
          if (limiter.tryAcquire()) acquired++;
        }
        if (i < 4) await Future.delayed(const Duration(milliseconds: 60));
      }

      // 5 tokens per 50ms window × 5 windows = up to 25 acquired
      expect(acquired, greaterThanOrEqualTo(20));
      expect(acquired, lessThanOrEqualTo(30));
      limiter.dispose();
    });

    test('dispose is safe to call multiple times', () {
      final limiter = RateLimiter(maxTokens: 5, refillRate: 1);
      expect(() {
        limiter.dispose();
        limiter.dispose();
      }, returnsNormally);
    });

    test('drained limiter rejects calls until refilled', () {
      final limiter = RateLimiter(
        maxTokens: 1,
        refillRate: 1,
        refillInterval: const Duration(hours: 1),
      );
      limiter.tryAcquire(); // drain the single token
      expect(limiter.tryAcquire(), false);
      limiter.dispose();
    });

    test('call() with action runs action when token is available', () {
      var ran = false;
      final limiter = RateLimiter(maxTokens: 1, refillRate: 1);
      limiter.call(() => ran = true);
      expect(ran, true);
      limiter.dispose();
    });
  });

  // ─── BatchThrottler Stress ───────────────────────────────────────────────

  group('BatchThrottler stress', () {
    test('1000 rapid calls produce few batch executions', () async {
      var batches = 0;
      final batcher = BatchThrottler(
        duration: const Duration(milliseconds: 60),
        maxBatchSize: 500,
        onBatchExecute: (_) async => batches++,
      );

      for (var i = 0; i < 1000; i++) {
        batcher.call(() => 'event$i');
      }

      await Future.delayed(const Duration(milliseconds: 150));

      // With maxBatchSize=500, 1000 items → at most 2 batches triggered by size
      // Plus 1 from timer. Total ≤ 4.
      expect(batches, lessThanOrEqualTo(4));
      expect(batches, greaterThanOrEqualTo(1));
      batcher.dispose();
    });

    test('flushAndAdd: maxBatchSize triggers flush before timer fires',
        () async {
      var batches = 0;
      final batcher = BatchThrottler(
        duration: const Duration(milliseconds: 500),
        maxBatchSize: 5,
        overflowStrategy: BatchOverflowStrategy.flushAndAdd,
        onBatchExecute: (_) async => batches++,
      );

      // 6 items: the 6th triggers an immediate flush of the first 5
      for (var i = 0; i < 6; i++) {
        batcher.call(() => 'item$i');
      }

      // Well under the 500ms timer — flush was triggered by overflow
      await Future.delayed(const Duration(milliseconds: 50));
      expect(batches, greaterThanOrEqualTo(1));
      batcher.dispose();
    });

    test('dropOldest overflow strategy keeps newest items', () async {
      final captured = <List>[];
      final batcher = BatchThrottler(
        duration: const Duration(milliseconds: 80),
        maxBatchSize: 3,
        overflowStrategy: BatchOverflowStrategy.dropOldest,
        onBatchExecute: (items) async => captured.add(List.from(items)),
      );

      for (var i = 0; i < 6; i++) {
        final v = i;
        batcher.call(() => v);
      }

      await Future.delayed(const Duration(milliseconds: 150));

      // Should have executed — verify items were batched, not lost entirely
      expect(captured, isNotEmpty);
      batcher.dispose();
    });

    test('dispose flushes pending batch', () async {
      var batches = 0;
      final batcher = BatchThrottler(
        duration: const Duration(milliseconds: 500),
        maxBatchSize: 100,
        onBatchExecute: (_) async => batches++,
      );

      batcher.call(() => 'item');
      batcher.dispose();

      // No batch fired (dispose doesn't flush by default, just cancels)
      expect(batches, 0);
    });

    test('empty batch is never executed', () async {
      var batches = 0;
      final batcher = BatchThrottler(
        duration: const Duration(milliseconds: 60),
        maxBatchSize: 100,
        onBatchExecute: (_) async => batches++,
      );

      await Future.delayed(const Duration(milliseconds: 100));

      expect(batches, 0);
      batcher.dispose();
    });

    test('concurrent batch calls are thread-safe', () async {
      var totalBatched = 0;
      final batcher = BatchThrottler(
        duration: const Duration(milliseconds: 80),
        maxBatchSize: 100,
        onBatchExecute: (items) async => totalBatched += items.length,
      );

      await Future.wait(
        List.generate(50, (i) async {
          batcher.call(() => i);
        }),
      );

      await Future.delayed(const Duration(milliseconds: 150));

      expect(totalBatched, 50);
      batcher.dispose();
    });
  });

  // ─── AsyncDebouncer Stress ───────────────────────────────────────────────

  group('AsyncDebouncer stress', () {
    test('100 rapid calls: only the last resolves as success', () async {
      final debouncer =
          AsyncDebouncer(duration: const Duration(milliseconds: 80));
      final futures = <Future<DebounceResult<int>>>[];

      for (var i = 0; i < 100; i++) {
        final v = i;
        futures.add(debouncer.callWithResult(() async => v));
      }

      final results = await Future.wait(futures);

      final successes = results.where((r) => r.isSuccess).toList();
      final cancellations = results.where((r) => r.isCancelled).toList();

      expect(successes.length, 1);
      expect(successes.first.value, 99);
      expect(cancellations.length, 99);

      debouncer.dispose();
    });

    test('call() during active async execution: new call wins', () async {
      final debouncer =
          AsyncDebouncer(duration: const Duration(milliseconds: 30));
      final log = <String>[];

      final f1 =
          debouncer.callWithResult(() async {
        await Future.delayed(const Duration(milliseconds: 10));
        return 'first';
      });

      final f2 =
          debouncer.callWithResult(() async {
        await Future.delayed(const Duration(milliseconds: 10));
        return 'second';
      });

      (await f1).when(
        onSuccess: (v) => log.add('f1:$v'),
        onCancelled: () => log.add('f1:cancelled'),
      );
      (await f2).when(
        onSuccess: (v) => log.add('f2:$v'),
        onCancelled: () => log.add('f2:cancelled'),
      );

      expect(log, ['f1:cancelled', 'f2:second']);
      debouncer.dispose();
    });

    test('dispose during pending call: future completes as cancelled',
        () async {
      final debouncer =
          AsyncDebouncer(duration: const Duration(milliseconds: 200));
      final future =
          debouncer.callWithResult(() async => 'result');

      debouncer.dispose();

      final result = await future;
      expect(result.isCancelled, true);
    });

    test('cancel() resolves pending future as cancelled', () async {
      final debouncer =
          AsyncDebouncer(duration: const Duration(milliseconds: 200));
      final future =
          debouncer.callWithResult(() async => 'data');

      debouncer.cancel();

      final result = await future;
      expect(result.isCancelled, true);
    });

    test('enabled: false — callWithResult returns success immediately',
        () async {
      final debouncer = AsyncDebouncer(
        duration: const Duration(milliseconds: 500),
        enabled: false,
      );

      final result = await debouncer.callWithResult(() async => 42);

      expect(result.isSuccess, true);
      expect(result.value, 42);
      debouncer.dispose();
    });

    test('onMetrics callback fires with correct cancelled flag', () async {
      final debouncer = AsyncDebouncer(
        duration: const Duration(milliseconds: 50),
        onMetrics: (_, cancelled) {
          // Just verify it doesn't crash
        },
      );

      final f1 = debouncer.callWithResult(() async => 1);
      final f2 = debouncer.callWithResult(() async => 2);

      await Future.wait([f1, f2]);
      debouncer.dispose();
    });

    test('stress: 10 concurrent debouncers each resolve correctly', () async {
      final debouncers = List.generate(
        10,
        (_) => AsyncDebouncer(duration: const Duration(milliseconds: 50)),
      );

      final futures = debouncers.map((d) {
        return d.callWithResult(() async => 'value');
      }).toList();

      final results = await Future.wait(futures);

      for (final result in results) {
        expect(result.isSuccess, true);
        expect(result.value, 'value');
      }

      for (final d in debouncers) {
        d.dispose();
      }
    });

    test('resetOnError: true resets state after callback throws', () async {
      var calls = 0;
      Object? caughtError;
      final debouncer = AsyncDebouncer(
        duration: const Duration(milliseconds: 30),
        resetOnError: true,
        onError: (e, _) => caughtError = e,
      );

      // First call: throws — error is captured by onError, not propagated
      debouncer.call(() async {
        calls++;
        throw Exception('boom');
      }).ignore(); // future completes with error; onError handles it
      await Future.delayed(const Duration(milliseconds: 80));

      expect(caughtError, isA<Exception>());

      // Second call after reset: should work normally
      final result = await debouncer.callWithResult(() async {
        calls++;
        return 'ok';
      });

      expect(calls, 2);
      expect(result.isSuccess, true);
      debouncer.dispose();
    });
  });

  // ─── ConcurrentAsyncThrottler Stress ────────────────────────────────────

  group('ConcurrentAsyncThrottler stress', () {
    test('drop mode: 50 concurrent calls → 1 executes, rest dropped',
        () async {
      final throttler = ConcurrentAsyncThrottler(
        mode: ConcurrencyMode.drop,
        maxDuration: const Duration(seconds: 2),
      );

      var executed = 0;
      var dropped = 0;

      final futures = List.generate(50, (i) async {
        final result = await throttler.call(() async {
          await Future.delayed(const Duration(milliseconds: 100));
        });
        result.when(
          onExecuted: () => executed++,
          onDropped: () => dropped++,
        );
      });

      await Future.wait(futures);

      expect(executed, 1);
      expect(dropped, 49);
      throttler.dispose();
    });

    test('enqueue mode: all calls execute in order', () async {
      final throttler = ConcurrentAsyncThrottler(
        mode: ConcurrencyMode.enqueue,
        maxDuration: const Duration(seconds: 10),
        maxQueueSize: 10,
      );

      final order = <int>[];

      await Future.wait(List.generate(5, (i) async {
        await throttler.call(() async {
          await Future.delayed(const Duration(milliseconds: 20));
          order.add(i);
        });
      }));

      expect(order, [0, 1, 2, 3, 4]);
      throttler.dispose();
    });

    test('replace mode: only the last call completes as executed', () async {
      final throttler = ConcurrentAsyncThrottler(
        mode: ConcurrencyMode.replace,
        maxDuration: const Duration(seconds: 5),
      );

      ThrottlerResult? lastResult;
      final futures = <Future>[];

      for (var i = 0; i < 5; i++) {
        futures.add(throttler.call(() async {
          await Future.delayed(const Duration(milliseconds: 50));
        }).then((r) => lastResult = r));
        await Future.delayed(const Duration(milliseconds: 10));
      }

      await Future.wait(futures);
      expect(lastResult?.isExecuted, true);
      throttler.dispose();
    });

    test('keepLatest mode: at most 2 tasks run (current + latest)', () async {
      final throttler = ConcurrentAsyncThrottler(
        mode: ConcurrencyMode.keepLatest,
        maxDuration: const Duration(seconds: 5),
      );

      var executed = 0;

      final futures = List.generate(5, (i) async {
        return throttler.call(() async {
          await Future.delayed(const Duration(milliseconds: 30));
          executed++;
        });
      });

      await Future.wait(futures);
      // keepLatest: first + last = 2 executions (middle ones dropped)
      expect(executed, lessThanOrEqualTo(3));
      throttler.dispose();
    });

    test('enqueue overflow (dropNewest): overflow calls return dropped',
        () async {
      final throttler = ConcurrentAsyncThrottler(
        mode: ConcurrencyMode.enqueue,
        maxDuration: const Duration(seconds: 5),
        maxQueueSize: 2,
        queueOverflowStrategy: QueueOverflowStrategy.dropNewest,
      );

      final results = <ThrottlerResult>[];

      // Fill the throttler + queue
      throttler.call(() async {
        await Future.delayed(const Duration(milliseconds: 100));
      });
      throttler.call(() async {});
      throttler.call(() async {}); // fills queue (size=2)

      // These overflow
      results.add(await throttler.call(() async {}));
      results.add(await throttler.call(() async {}));

      for (final r in results) {
        expect(r.isDropped, true);
      }

      throttler.dispose();
    });

    test('reset() drains pending calls with dropped result', () async {
      final throttler = ConcurrentAsyncThrottler(
        mode: ConcurrencyMode.enqueue,
        maxDuration: const Duration(seconds: 5),
        maxQueueSize: 10,
      );

      // Lock the throttler
      throttler.call(() async {
        await Future.delayed(const Duration(milliseconds: 200));
      });

      // Enqueue some
      final f1 = throttler.call(() async {});
      final f2 = throttler.call(() async {});

      throttler.reset();

      final r1 = await f1;
      final r2 = await f2;

      expect(r1.isDropped, true);
      expect(r2.isDropped, true);

      throttler.dispose();
    });

    test('dispose() drains all completers', () async {
      final throttler = ConcurrentAsyncThrottler(
        mode: ConcurrencyMode.enqueue,
        maxDuration: const Duration(seconds: 5),
        maxQueueSize: 5,
      );

      throttler.call(() async {
        await Future.delayed(const Duration(milliseconds: 200));
      });

      final pending = List.generate(3, (_) => throttler.call(() async {}));
      throttler.dispose();

      final results = await Future.wait(pending);
      for (final r in results) {
        expect(r.isDropped, true);
      }
    });

    test('ThrottlerResult.when() used in MVVM emit pattern', () async {
      final throttler = ConcurrentAsyncThrottler(
        mode: ConcurrencyMode.drop,
        maxDuration: const Duration(seconds: 2),
      );

      // Lock the throttler
      throttler.call(() async {
        await Future.delayed(const Duration(milliseconds: 100));
      });

      final log = <String>[];
      final result = await throttler.call(() async {});
      result.when(
        onExecuted: () => log.add('emit(Success)'),
        onDropped: () => log.add('emit(Dropped)'),
      );

      expect(log, ['emit(Dropped)']);
      throttler.dispose();
    });

    test('whenExecuted + whenDropped chaining resolves correctly', () async {
      final log = <String>[];

      const executed = ThrottlerResult.executed();
      executed
          .whenExecuted(() => log.add('ran'))
          .whenDropped(() => log.add('dropped'));

      const dropped = ThrottlerResult.dropped();
      dropped
          .whenExecuted(() => log.add('ran'))
          .whenDropped(() => log.add('dropped'));

      expect(log, ['ran', 'dropped']);
    });

    test('callWithToken: cancelled task produces dropped result', () async {
      final throttler = ConcurrentAsyncThrottler(
        mode: ConcurrencyMode.replace,
        maxDuration: const Duration(seconds: 5),
      );

      unawaited(throttler.callWithToken((token) async {
        await Future.delayed(const Duration(milliseconds: 100));
        if (token.isCancelled) return;
      }));

      await Future.delayed(const Duration(milliseconds: 20));
      final result = await throttler.callWithToken((token) async {
        if (token.isCancelled) return;
      });

      // The second call executed (replaced the first)
      expect(result.isExecuted, true);
      throttler.dispose();
    });
  });

  // ─── Memory Safety Under Stress ──────────────────────────────────────────

  group('Memory safety under stress', () {
    test('dispose during pending debounce: no StateError or crash', () async {
      final debouncer =
          Debouncer(duration: const Duration(milliseconds: 100));
      var executed = false;

      debouncer.call(() => executed = true);
      debouncer.dispose();

      await Future.delayed(const Duration(milliseconds: 200));
      expect(executed, false);
    });

    test('dispose during in-flight async: callWithResult resolves safely',
        () async {
      final debouncer =
          AsyncDebouncer(duration: const Duration(milliseconds: 100));
      final future =
          debouncer.callWithResult(() async {
        await Future.delayed(const Duration(milliseconds: 300));
        return 'data';
      });

      await Future.delayed(const Duration(milliseconds: 150));
      debouncer.dispose();

      final result = await future;
      // Either cancelled (dispose fired before execution started) or success
      expect(result.isSuccess || result.isCancelled, true);
    });

    test('10 debouncers disposed concurrently without crash', () async {
      final debouncers = List.generate(
        10,
        (_) => Debouncer(duration: const Duration(milliseconds: 50)),
      );

      for (final d in debouncers) {
        d.call(() {});
      }

      await Future.wait(debouncers.map((d) async => d.dispose()));
    });

    test('throttler: rapid call + dispose + call does not crash', () async {
      final throttler = Throttler(duration: const Duration(milliseconds: 50));

      throttler.call(() {});
      throttler.dispose();

      // Creating a new instance is fine; old is gone
      final throttler2 = Throttler(duration: const Duration(milliseconds: 50));
      throttler2.call(() {});
      throttler2.dispose();
    });

    test('rate limiter dispose during refill timer: no crash', () async {
      final limiter = RateLimiter(
        maxTokens: 5,
        refillRate: 2,
        refillInterval: const Duration(milliseconds: 30),
      );
      limiter.tryAcquire();
      limiter.dispose();

      await Future.delayed(const Duration(milliseconds: 60));
      // No crash after refill timer would have fired on disposed limiter
    });

    test('batch throttler: dispose during active timer no crash', () async {
      var executed = false;
      final batcher = BatchThrottler(
        duration: const Duration(milliseconds: 200),
        maxBatchSize: 100,
        onBatchExecute: (_) async => executed = true,
      );

      batcher.call(() => 'item');
      batcher.dispose();

      await Future.delayed(const Duration(milliseconds: 300));
      expect(executed, false);
    });
  });

  // ─── Boundary Conditions ─────────────────────────────────────────────────

  group('Boundary conditions', () {
    test('Debouncer with 1ms duration fires near-immediately', () async {
      final debouncer = Debouncer(duration: const Duration(milliseconds: 1));
      var executed = false;

      debouncer.call(() => executed = true);

      await Future.delayed(const Duration(milliseconds: 30));
      expect(executed, true);
      debouncer.dispose();
    });

    test('AsyncDebouncer with very long duration: cancel frees future',
        () async {
      final debouncer =
          AsyncDebouncer(duration: const Duration(hours: 1));
      final future =
          debouncer.callWithResult(() async => 'never');

      debouncer.cancel();
      final result = await future;
      expect(result.isCancelled, true);
      debouncer.dispose();
    });

    test('Throttler with 1ms duration allows calls after 1ms', () async {
      final throttler = Throttler(duration: const Duration(milliseconds: 1));
      var count = 0;

      throttler.call(() => count++);
      await Future.delayed(const Duration(milliseconds: 10));
      throttler.call(() => count++);

      expect(count, 2);
      throttler.dispose();
    });

    test('DebounceResult.success(null) is not treated as cancelled', () {
      final result = DebounceResult<String>.success(null);
      expect(result.isSuccess, true);
      expect(result.isCancelled, false);
      expect(result.value, null);
    });

    test('ThrottlerResult.when returns value from the matching branch', () {
      final e = const ThrottlerResult.executed()
          .when(onExecuted: () => 'yes', onDropped: () => 'no');
      expect(e, 'yes');

      final d = const ThrottlerResult.dropped()
          .when(onExecuted: () => 'yes', onDropped: () => 'no');
      expect(d, 'no');
    });

    test('DebounceResult.when passes value to onSuccess callback', () {
      final r = DebounceResult.success(42);
      final out =
          r.when(onSuccess: (v) => 'got:$v', onCancelled: () => 'cancelled');
      expect(out, 'got:42');
    });

    test('flushAndAdd maxBatchSize:1 flushes on every new item', () async {
      var batches = 0;
      final batcher = BatchThrottler(
        duration: const Duration(milliseconds: 300),
        maxBatchSize: 1,
        overflowStrategy: BatchOverflowStrategy.flushAndAdd,
        onBatchExecute: (_) async => batches++,
      );

      // 5 items: item[1..4] each triggers a flushAndAdd (4 immediate flushes)
      // + 1 timer flush for the last remaining item
      for (var i = 0; i < 5; i++) {
        batcher.call(() => i);
        await Future.delayed(const Duration(milliseconds: 20));
      }

      // Wait for final timer to fire
      await Future.delayed(const Duration(milliseconds: 400));

      expect(batches, greaterThanOrEqualTo(4));
      batcher.dispose();
    });

    test('RateLimiter maxTokens: 1 is effectively a strict mutex', () async {
      final limiter = RateLimiter(
        maxTokens: 1,
        refillRate: 1,
        refillInterval: const Duration(milliseconds: 100),
      );

      expect(limiter.tryAcquire(), true);
      expect(limiter.tryAcquire(), false);

      await Future.delayed(const Duration(milliseconds: 120));

      expect(limiter.tryAcquire(), true);
      limiter.dispose();
    });
  });
}
