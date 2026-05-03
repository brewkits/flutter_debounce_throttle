import 'package:test/test.dart';
import 'package:dart_debounce_throttle/dart_debounce_throttle.dart';
import 'dart:async';

void main() {
  group('ConcurrentAsyncThrottler - True Cancellation', () {
    test('replace mode with CancellationToken prevents side effects', () async {
      final throttler = ConcurrentAsyncThrottler(
        mode: ConcurrencyMode.replace,
        maxDuration: const Duration(seconds: 5),
      );

      final sideEffectResults = <int>[];

      // First call
      unawaited(throttler.callWithToken((token) async {
        await Future.delayed(const Duration(milliseconds: 100));
        if (token.isCancelled) return; // Prevent side effect
        sideEffectResults.add(1);
      }));

      // Wait a bit
      await Future.delayed(const Duration(milliseconds: 20));

      // Second call (replaces first)
      await throttler.callWithToken((token) async {
        await Future.delayed(const Duration(milliseconds: 20));
        if (token.isCancelled) return;
        sideEffectResults.add(2);
      });

      // Wait for the first task to potentially finish
      await Future.delayed(const Duration(milliseconds: 150));

      expect(sideEffectResults.length, 1);
      expect(sideEffectResults, [2],
          reason: 'First task was successfully cancelled');

      throttler.dispose();
    });

    test('CancellationException aborts task silently', () async {
      final throttler = ConcurrentAsyncThrottler(
        mode: ConcurrencyMode.replace,
        maxDuration: const Duration(seconds: 5),
      );

      final sideEffectResults = <int>[];

      // First call
      unawaited(throttler.callWithToken((token) async {
        await Future.delayed(const Duration(milliseconds: 100));
        token.throwIfCancelled(); // Will throw CancellationException
        sideEffectResults.add(1);
      }));

      await Future.delayed(const Duration(milliseconds: 20));

      // Second call
      await throttler.callWithToken((token) async {
        sideEffectResults.add(2);
      });

      await Future.delayed(const Duration(milliseconds: 150));

      expect(sideEffectResults, [2]);

      throttler.dispose();
    });
  });
}
