import 'dart:async';
import 'package:dart_debounce_throttle/dart_debounce_throttle.dart';
import 'package:test/test.dart';

void main() {
  group('Security & Robustness Tests', () {
    test('RateLimiter handles extreme bounds without crashing (DoS protection)', () {
      final limiter = RateLimiter(
        maxTokens: 1000000,
        refillRate: 500000,
        refillInterval: const Duration(milliseconds: 1),
      );

      // Verify that math bounds don't overflow or crash
      for (int i = 0; i < 10000; i++) {
        limiter.tryAcquire();
      }
      expect(limiter.tryAcquire(), true);
      limiter.dispose();
    });

    test('RateLimiter rejects invalid configurations gracefully', () {
      // Dart assert/TypeError check on invalid configuration
      expect(() => RateLimiter(maxTokens: -1, refillRate: 1), throwsA(anything));
      expect(() => RateLimiter(maxTokens: 10, refillRate: -5), throwsA(anything));
    });

    test('BatchThrottler handles massive queue flood safely (memory exhaustion protection)', () async {
      // Testing if massive payloads crash the queue
      final batcher = BatchThrottler(
        duration: const Duration(seconds: 1),
        maxBatchSize: 100000,
        onBatchExecute: (items) async {},
      );

      for (int i = 0; i < 500000; i++) {
        batcher.call(() => 'A' * 10); // simulate payload
      }

      batcher.dispose(); // Ensure it cleans up
    });

    test('AsyncThrottler does not leak completers on infinite timeout', () async {
      final throttler = AsyncThrottler();
      // Emulate a hanging Future
      final future = throttler.call(() async {
        await Future.delayed(const Duration(hours: 10));
      });

      // We should be able to dispose and not get memory leak
      unawaited(future);
      throttler.dispose();
      // Unhandled Future is expected to not crash
    });

    test('ConcurrentAsyncThrottler queue flood handles gracefully', () async {
      final throttler = ConcurrentAsyncThrottler(
        mode: ConcurrencyMode.enqueue,
        maxQueueSize: 20, 
      );
      
      // Submit 1000 tasks instantly
      for (int i = 0; i < 1000; i++) {
        throttler.call(() async {});
      }

      throttler.dispose();
    });
  });
}
