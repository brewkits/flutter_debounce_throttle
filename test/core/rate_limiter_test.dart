import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_debounce_throttle/core.dart';

void main() {
  group('RateLimiter', () {
    group('Basic Token Bucket', () {
      test('starts with full tokens', () {
        final limiter = RateLimiter(maxTokens: 10);
        expect(limiter.availableTokens, 10);
        limiter.dispose();
      });

      test('tryAcquire consumes tokens', () {
        final limiter = RateLimiter(maxTokens: 5);

        expect(limiter.tryAcquire(), true);
        expect(limiter.availableTokens, 4);

        expect(limiter.tryAcquire(), true);
        expect(limiter.availableTokens, 3);

        limiter.dispose();
      });

      test('tryAcquire fails when no tokens available', () {
        final limiter = RateLimiter(maxTokens: 2);

        expect(limiter.tryAcquire(), true);
        expect(limiter.tryAcquire(), true);
        expect(limiter.tryAcquire(), false); // No tokens left

        limiter.dispose();
      });

      test('tryAcquire can consume multiple tokens', () {
        final limiter = RateLimiter(maxTokens: 10);

        expect(limiter.tryAcquire(5), true);
        expect(limiter.availableTokens, 5);

        expect(limiter.tryAcquire(6), false); // Not enough tokens
        expect(limiter.availableTokens, 5);

        expect(limiter.tryAcquire(5), true);
        expect(limiter.availableTokens, 0);

        limiter.dispose();
      });

      test('canAcquire returns correct state', () {
        final limiter = RateLimiter(maxTokens: 1);

        expect(limiter.canAcquire, true);
        limiter.tryAcquire();
        expect(limiter.canAcquire, false);

        limiter.dispose();
      });
    });

    group('Token Refill', () {
      test('refills tokens over time', () async {
        final limiter = RateLimiter(
          maxTokens: 5,
          refillRate: 10, // 10 tokens per 100ms
          refillInterval: const Duration(milliseconds: 100),
        );

        // Consume all tokens
        for (var i = 0; i < 5; i++) {
          limiter.tryAcquire();
        }
        expect(limiter.availableTokens, 0);

        // Wait for refill
        await Future.delayed(const Duration(milliseconds: 150));

        // Should have refilled (but capped at maxTokens)
        expect(limiter.availableTokens, greaterThan(0));
        expect(limiter.availableTokens, lessThanOrEqualTo(5));

        limiter.dispose();
      });

      test('does not exceed maxTokens on refill', () async {
        final limiter = RateLimiter(
          maxTokens: 5,
          refillRate: 100,
          refillInterval: const Duration(milliseconds: 10),
        );

        // Wait for many refills
        await Future.delayed(const Duration(milliseconds: 100));

        expect(limiter.availableTokens, 5); // Capped at max

        limiter.dispose();
      });

      test('timeUntilNextToken returns correct duration', () {
        final limiter = RateLimiter(
          maxTokens: 1,
          refillRate: 1,
          refillInterval: const Duration(seconds: 1),
        );

        // With tokens available
        expect(limiter.timeUntilNextToken, Duration.zero);

        // After consuming
        limiter.tryAcquire();
        expect(limiter.timeUntilNextToken.inMilliseconds, greaterThan(0));

        limiter.dispose();
      });
    });

    group('call() method', () {
      test('executes callback when token available', () {
        final limiter = RateLimiter(maxTokens: 5);
        var executed = false;

        final result = limiter.call(() => executed = true);

        expect(result, true);
        expect(executed, true);

        limiter.dispose();
      });

      test('does not execute callback when no token', () {
        final limiter = RateLimiter(maxTokens: 1);
        var executed = false;

        limiter.tryAcquire(); // Consume the only token

        final result = limiter.call(() => executed = true);

        expect(result, false);
        expect(executed, false);

        limiter.dispose();
      });

      test('executes callback with multiple tokens', () {
        final limiter = RateLimiter(maxTokens: 10);
        var executed = false;

        final result = limiter.call(() => executed = true, 5);

        expect(result, true);
        expect(executed, true);
        expect(limiter.availableTokens, 5);

        limiter.dispose();
      });
    });

    group('callAsync() method', () {
      test('executes async callback when token available', () async {
        final limiter = RateLimiter(maxTokens: 5);

        final result = await limiter.callAsync(() async {
          await Future.delayed(const Duration(milliseconds: 10));
          return 'success';
        });

        expect(result, 'success');

        limiter.dispose();
      });

      test('returns null when no token', () async {
        final limiter = RateLimiter(maxTokens: 1);
        limiter.tryAcquire();

        final result = await limiter.callAsync(() async => 'success');

        expect(result, null);

        limiter.dispose();
      });
    });

    group('enabled parameter', () {
      test('bypasses rate limiting when disabled', () {
        final limiter = RateLimiter(maxTokens: 1, enabled: false);

        // Should always succeed when disabled
        for (var i = 0; i < 100; i++) {
          expect(limiter.tryAcquire(), true);
        }

        limiter.dispose();
      });

      test('call() always executes when disabled', () {
        final limiter = RateLimiter(maxTokens: 1, enabled: false);
        var count = 0;

        for (var i = 0; i < 10; i++) {
          limiter.call(() => count++);
        }

        expect(count, 10);

        limiter.dispose();
      });
    });

    group('reset()', () {
      test('resets to full capacity', () {
        final limiter = RateLimiter(maxTokens: 10);

        // Consume all tokens
        for (var i = 0; i < 10; i++) {
          limiter.tryAcquire();
        }
        expect(limiter.availableTokens, 0);

        limiter.reset();
        expect(limiter.availableTokens, 10);

        limiter.dispose();
      });
    });

    group('onMetrics callback', () {
      test('calls onMetrics on acquire attempt', () {
        final metrics = <Map<String, dynamic>>[];

        final limiter = RateLimiter(
          maxTokens: 2,
          onMetrics: (remaining, acquired) {
            metrics.add({'remaining': remaining, 'acquired': acquired});
          },
        );

        limiter.tryAcquire();
        limiter.tryAcquire();
        limiter.tryAcquire(); // Should fail

        expect(metrics.length, 3);
        expect(metrics[0], {'remaining': 1, 'acquired': true});
        expect(metrics[1], {'remaining': 0, 'acquired': true});
        expect(metrics[2], {'remaining': 0, 'acquired': false});

        limiter.dispose();
      });
    });

    group('debugMode', () {
      test('logs when debugMode is true', () {
        final limiter = RateLimiter(
          maxTokens: 5,
          debugMode: true,
          name: 'TestLimiter',
        );

        limiter.tryAcquire();
        limiter.reset();
        limiter.dispose();
        // No assertion - just verify no errors
      });
    });

    group('Real-world scenarios', () {
      test('API rate limiting scenario', () async {
        // Simulate: 10 requests burst, then 2 per second
        final limiter = RateLimiter(
          maxTokens: 10,
          refillRate: 2,
          refillInterval: const Duration(seconds: 1),
        );

        // Burst of 10 requests
        var successCount = 0;
        for (var i = 0; i < 15; i++) {
          if (limiter.tryAcquire()) successCount++;
        }

        expect(successCount, 10); // Only 10 should succeed

        // Wait for partial refill
        await Future.delayed(const Duration(milliseconds: 600));

        // Should have ~1 token now
        expect(limiter.availableTokens, greaterThanOrEqualTo(1));

        limiter.dispose();
      });

      test('game input limiting scenario', () {
        // Simulate: Allow 3 rapid clicks, then cooldown
        final limiter = RateLimiter(
          maxTokens: 3,
          refillRate: 1,
          refillInterval: const Duration(milliseconds: 500),
        );

        var attackCount = 0;

        // Rapid fire attacks
        for (var i = 0; i < 5; i++) {
          limiter.call(() => attackCount++);
        }

        expect(attackCount, 3); // Only 3 attacks allowed

        limiter.dispose();
      });

      test('server protection scenario', () async {
        // Simulate: Protect against traffic spike
        final limiter = RateLimiter(
          maxTokens: 100,
          refillRate: 10,
          refillInterval: const Duration(seconds: 1),
        );

        var processedRequests = 0;
        var rejectedRequests = 0;

        // Traffic spike: 150 requests
        for (var i = 0; i < 150; i++) {
          if (limiter.tryAcquire()) {
            processedRequests++;
          } else {
            rejectedRequests++;
          }
        }

        expect(processedRequests, 100);
        expect(rejectedRequests, 50);

        limiter.dispose();
      });
    });
  });
}
