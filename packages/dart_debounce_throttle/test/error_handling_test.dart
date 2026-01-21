import 'package:dart_debounce_throttle/dart_debounce_throttle.dart';
import 'package:test/test.dart';

void main() {
  group('Debouncer Error Handling', () {
    test('onError callback is called when callback throws', () async {
      Object? caughtError;
      StackTrace? caughtStack;

      final debouncer = Debouncer(
        duration: const Duration(milliseconds: 50),
        onError: (error, stackTrace) {
          caughtError = error;
          caughtStack = stackTrace;
        },
      );

      // Trigger error
      debouncer.call(() {
        throw Exception('Test error');
      });

      // Wait for debounce to execute
      await Future.delayed(const Duration(milliseconds: 100));

      expect(caughtError, isA<Exception>());
      expect(caughtError.toString(), contains('Test error'));
      expect(caughtStack, isNotNull);

      debouncer.dispose();
    });

    test('error is logged when onError is not provided', () async {
      final debouncer = Debouncer(
        duration: const Duration(milliseconds: 50),
        // No onError callback
      );

      // Should not throw, error is swallowed
      expect(() {
        debouncer.call(() {
          throw Exception('Test error');
        });
      }, returnsNormally);

      await Future.delayed(const Duration(milliseconds: 100));
      debouncer.dispose();
    });

    test('onError handler errors are caught and logged', () async {
      final debouncer = Debouncer(
        duration: const Duration(milliseconds: 50),
        onError: (error, stackTrace) {
          throw Exception('Error in error handler');
        },
      );

      // Should not crash even if error handler throws
      expect(() {
        debouncer.call(() {
          throw Exception('Original error');
        });
      }, returnsNormally);

      await Future.delayed(const Duration(milliseconds: 100));
      debouncer.dispose();
    });

    test('resetOnError works with onError callback', () async {
      var errorCount = 0;
      var executeCount = 0;

      final debouncer = Debouncer(
        duration: const Duration(milliseconds: 50),
        resetOnError: true,
        onError: (error, stackTrace) {
          errorCount++;
        },
      );

      // First call - will error
      debouncer.call(() {
        executeCount++;
        throw Exception('Error');
      });

      await Future.delayed(const Duration(milliseconds: 100));
      expect(errorCount, 1);
      expect(executeCount, 1);

      // Second call - should work normally (debouncer was reset)
      debouncer.call(() {
        executeCount++;
      });

      await Future.delayed(const Duration(milliseconds: 100));
      expect(executeCount, 2);
      expect(errorCount, 1); // No new errors

      debouncer.dispose();
    });
  });

  group('Throttler Error Handling', () {
    test('onError callback is called when callback throws', () async {
      Object? caughtError;
      StackTrace? caughtStack;

      final throttler = Throttler(
        duration: const Duration(milliseconds: 100),
        onError: (error, stackTrace) {
          caughtError = error;
          caughtStack = stackTrace;
        },
      );

      // Trigger error (executes immediately)
      throttler.call(() {
        throw Exception('Test error');
      });

      // Give it a moment
      await Future.delayed(const Duration(milliseconds: 10));

      expect(caughtError, isA<Exception>());
      expect(caughtError.toString(), contains('Test error'));
      expect(caughtStack, isNotNull);

      throttler.dispose();
    });

    test('error is rethrown when onError is not provided', () {
      final throttler = Throttler(
        duration: const Duration(milliseconds: 100),
        // No onError callback
      );

      // Should rethrow (original behavior)
      expect(() {
        throttler.call(() {
          throw Exception('Test error');
        });
      }, throwsException);

      throttler.dispose();
    });

    test('onError prevents rethrow', () {
      final throttler = Throttler(
        duration: const Duration(milliseconds: 100),
        onError: (error, stackTrace) {
          // Handle error
        },
      );

      // Should NOT rethrow when onError is provided
      expect(() {
        throttler.call(() {
          throw Exception('Test error');
        });
      }, returnsNormally);

      throttler.dispose();
    });

    test('resetOnError flag is respected with onError callback', () async {
      var errorCount = 0;

      final throttlerWithReset = Throttler(
        duration: const Duration(milliseconds: 100),
        resetOnError: true,
        onError: (error, stackTrace) {
          errorCount++;
        },
      );

      final throttlerNoReset = Throttler(
        duration: const Duration(milliseconds: 100),
        resetOnError: false,
        onError: (error, stackTrace) {
          errorCount++;
        },
      );

      // Both should call onError
      throttlerWithReset.call(() => throw Exception('Error 1'));
      throttlerNoReset.call(() => throw Exception('Error 2'));

      expect(errorCount, 2);

      throttlerWithReset.dispose();
      throttlerNoReset.dispose();
    });
  });

  group('AsyncDebouncer Error Handling', () {
    test('onError callback is called when async action throws', () async {
      Object? caughtError;
      StackTrace? caughtStack;

      final debouncer = AsyncDebouncer(
        duration: const Duration(milliseconds: 50),
        onError: (error, stackTrace) {
          caughtError = error;
          caughtStack = stackTrace;
        },
      );

      // Trigger error
      try {
        await debouncer.call(() async {
          throw Exception('Async test error');
        });
      } catch (e) {
        // Expected - error is still thrown after calling onError
      }

      expect(caughtError, isA<Exception>());
      expect(caughtError.toString(), contains('Async test error'));
      expect(caughtStack, isNotNull);

      debouncer.dispose();
    });

    test('onError is called before completeError', () async {
      var onErrorCalled = false;
      var errorFromFuture = false;

      final debouncer = AsyncDebouncer(
        duration: const Duration(milliseconds: 50),
        onError: (error, stackTrace) {
          onErrorCalled = true;
          expect(errorFromFuture, false,
              reason: 'onError should be called first');
        },
      );

      try {
        await debouncer.call(() async {
          throw Exception('Test error');
        });
      } catch (e) {
        errorFromFuture = true;
        expect(onErrorCalled, true,
            reason: 'onError should be called before future completes');
      }

      debouncer.dispose();
    });

    test('onError handler errors are caught', () async {
      final debouncer = AsyncDebouncer(
        duration: const Duration(milliseconds: 50),
        onError: (error, stackTrace) {
          throw Exception('Error in error handler');
        },
      );

      // Should still complete with original error
      try {
        await debouncer.call(() async {
          throw Exception('Original error');
        });
        fail('Should have thrown');
      } catch (e) {
        expect(e.toString(), contains('Original error'));
      }

      debouncer.dispose();
    });
  });

  group('AsyncThrottler Error Handling', () {
    test('onError callback is called when async action throws', () async {
      Object? caughtError;
      StackTrace? caughtStack;

      final throttler = AsyncThrottler(
        onError: (error, stackTrace) {
          caughtError = error;
          caughtStack = stackTrace;
        },
      );

      // Trigger error (executes immediately)
      try {
        await throttler.call(() async {
          throw Exception('Async test error');
        });
      } catch (e) {
        // Expected
      }

      expect(caughtError, isA<Exception>());
      expect(caughtError.toString(), contains('Async test error'));
      expect(caughtStack, isNotNull);

      throttler.dispose();
    });

    test('onError is called before rethrow', () async {
      var onErrorCalled = false;
      var errorFromFuture = false;

      final throttler = AsyncThrottler(
        onError: (error, stackTrace) {
          onErrorCalled = true;
          expect(errorFromFuture, false,
              reason: 'onError should be called first');
        },
      );

      try {
        await throttler.call(() async {
          throw Exception('Test error');
        });
      } catch (e) {
        errorFromFuture = true;
        expect(onErrorCalled, true,
            reason: 'onError should be called before rethrow');
      }

      throttler.dispose();
    });

    test('resetOnError unlocks throttler on error', () async {
      var errorCount = 0;
      var executeCount = 0;

      final throttler = AsyncThrottler(
        maxDuration: const Duration(seconds: 10),
        resetOnError: true,
        onError: (error, stackTrace) {
          errorCount++;
        },
      );

      // First call - will error and unlock
      try {
        await throttler.call(() async {
          executeCount++;
          throw Exception('Error');
        });
      } catch (e) {
        // Expected
      }

      expect(errorCount, 1);
      expect(executeCount, 1);
      expect(throttler.isLocked, false,
          reason: 'Should be unlocked after error');

      // Should be able to call immediately (was unlocked)
      await throttler.call(() async {
        executeCount++;
      });

      expect(executeCount, 2);
      expect(errorCount, 1);

      throttler.dispose();
    });
  });

  group('Integration Tests', () {
    test('multiple limiters with error handlers work independently', () async {
      var debounceErrors = 0;
      var throttleErrors = 0;

      final debouncer = Debouncer(
        duration: const Duration(milliseconds: 50),
        onError: (error, stackTrace) {
          debounceErrors++;
        },
      );

      final throttler = Throttler(
        duration: const Duration(milliseconds: 50),
        onError: (error, stackTrace) {
          throttleErrors++;
        },
      );

      // Trigger both errors
      debouncer.call(() => throw Exception('Debounce error'));
      throttler.call(() => throw Exception('Throttle error'));

      await Future.delayed(const Duration(milliseconds: 100));

      expect(debounceErrors, 1);
      expect(throttleErrors, 1);

      debouncer.dispose();
      throttler.dispose();
    });
  });
}
