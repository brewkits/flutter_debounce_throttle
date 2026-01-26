// Tests for RateLimiterStore, DistributedRateLimiter, and storage implementations.

import 'package:dart_debounce_throttle/dart_debounce_throttle.dart';
import 'package:test/test.dart';

void main() {
  group('RateLimiterState', () {
    test('creates state with correct values', () {
      const state = RateLimiterState(
        tokens: 10.5,
        lastRefillMicroseconds: 123456,
      );

      expect(state.tokens, 10.5);
      expect(state.lastRefillMicroseconds, 123456);
    });

    test('converts to/from list correctly', () {
      const original = RateLimiterState(
        tokens: 7.3,
        lastRefillMicroseconds: 999999,
      );

      final list = original.toList();
      expect(list, [7.3, 999999]);

      final restored = RateLimiterState.fromList(list);
      expect(restored.tokens, 7.3);
      expect(restored.lastRefillMicroseconds, 999999);
    });

    test('fromList handles empty list', () {
      final state = RateLimiterState.fromList([]);
      expect(state.tokens, 0);
      expect(state.lastRefillMicroseconds, 0);
    });

    test('fromList handles partial list', () {
      final state = RateLimiterState.fromList([5.5]);
      expect(state.tokens, 5.5);
      expect(state.lastRefillMicroseconds, 0);
    });

    test('toString works correctly', () {
      const state = RateLimiterState(
        tokens: 8.2,
        lastRefillMicroseconds: 111222,
      );

      expect(state.toString(), contains('8.2'));
      expect(state.toString(), contains('111222'));
    });
  });

  group('InMemoryRateLimiterStore', () {
    late InMemoryRateLimiterStore store;

    setUp(() {
      store = InMemoryRateLimiterStore();
    });

    test('fetchState returns initial state for new key', () {
      final state = store.fetchState('user-123');
      expect(state.tokens, 0);
      expect(state.lastRefillMicroseconds, 0);
    });

    test('saveState and fetchState work correctly', () {
      const state = RateLimiterState(
        tokens: 15.5,
        lastRefillMicroseconds: 555555,
      );

      store.saveState('user-123', state);
      final fetched = store.fetchState('user-123');

      expect(fetched.tokens, 15.5);
      expect(fetched.lastRefillMicroseconds, 555555);
    });

    test('clearState removes key', () {
      const state = RateLimiterState(tokens: 10, lastRefillMicroseconds: 123);
      store.saveState('user-123', state);
      expect(store.containsKey('user-123'), true);

      store.clearState('user-123');
      expect(store.containsKey('user-123'), false);

      final fetched = store.fetchState('user-123');
      expect(fetched.tokens, 0);
      expect(fetched.lastRefillMicroseconds, 0);
    });

    test('clearAll removes all keys', () {
      store.saveState('user-1',
          const RateLimiterState(tokens: 10, lastRefillMicroseconds: 123));
      store.saveState('user-2',
          const RateLimiterState(tokens: 20, lastRefillMicroseconds: 456));
      store.saveState('user-3',
          const RateLimiterState(tokens: 30, lastRefillMicroseconds: 789));

      expect(store.keyCount, 3);

      store.clearAll();
      expect(store.keyCount, 0);
    });

    test('keyCount tracks number of keys', () {
      expect(store.keyCount, 0);

      store.saveState('key1',
          const RateLimiterState(tokens: 1, lastRefillMicroseconds: 1));
      expect(store.keyCount, 1);

      store.saveState('key2',
          const RateLimiterState(tokens: 2, lastRefillMicroseconds: 2));
      expect(store.keyCount, 2);

      store.clearState('key1');
      expect(store.keyCount, 1);
    });

    test('containsKey checks key existence', () {
      expect(store.containsKey('user-123'), false);

      store.saveState('user-123',
          const RateLimiterState(tokens: 10, lastRefillMicroseconds: 123));
      expect(store.containsKey('user-123'), true);
    });

    test('multiple keys are independent', () {
      store.saveState('user-1',
          const RateLimiterState(tokens: 10, lastRefillMicroseconds: 100));
      store.saveState('user-2',
          const RateLimiterState(tokens: 20, lastRefillMicroseconds: 200));

      final state1 = store.fetchState('user-1');
      final state2 = store.fetchState('user-2');

      expect(state1.tokens, 10);
      expect(state1.lastRefillMicroseconds, 100);
      expect(state2.tokens, 20);
      expect(state2.lastRefillMicroseconds, 200);
    });
  });

  group('AsyncInMemoryRateLimiterStore', () {
    late AsyncInMemoryRateLimiterStore store;

    setUp(() {
      store = AsyncInMemoryRateLimiterStore();
    });

    test('fetchState returns initial state for new key', () async {
      final state = await store.fetchState('user-123');
      expect(state.tokens, 0);
      expect(state.lastRefillMicroseconds, 0);
    });

    test('saveState and fetchState work correctly', () async {
      const state = RateLimiterState(
        tokens: 25.7,
        lastRefillMicroseconds: 777777,
      );

      await store.saveState('user-123', state);
      final fetched = await store.fetchState('user-123');

      expect(fetched.tokens, 25.7);
      expect(fetched.lastRefillMicroseconds, 777777);
    });

    test('clearState removes key', () async {
      const state = RateLimiterState(tokens: 10, lastRefillMicroseconds: 123);
      await store.saveState('user-123', state);
      expect(store.containsKey('user-123'), true);

      await store.clearState('user-123');
      expect(store.containsKey('user-123'), false);

      final fetched = await store.fetchState('user-123');
      expect(fetched.tokens, 0);
      expect(fetched.lastRefillMicroseconds, 0);
    });

    test('clearAll removes all keys', () async {
      await store.saveState('user-1',
          const RateLimiterState(tokens: 10, lastRefillMicroseconds: 123));
      await store.saveState('user-2',
          const RateLimiterState(tokens: 20, lastRefillMicroseconds: 456));

      expect(store.keyCount, 2);

      await store.clearAll();
      expect(store.keyCount, 0);
    });
  });

  group('DistributedRateLimiter', () {
    late AsyncInMemoryRateLimiterStore store;

    setUp(() {
      store = AsyncInMemoryRateLimiterStore();
    });

    test('creates limiter with valid parameters', () {
      final limiter = DistributedRateLimiter(
        key: 'user-123',
        store: store,
        maxTokens: 10,
        refillRate: 1,
        refillInterval: const Duration(seconds: 1),
      );

      expect(limiter.key, 'user-123');
      expect(limiter.maxTokens, 10);
      expect(limiter.refillRate, 1);
    });

    test('throws on empty key', () {
      expect(
        () => DistributedRateLimiter(
          key: '',
          store: store,
          maxTokens: 10,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('throws on invalid maxTokens', () {
      expect(
        () => DistributedRateLimiter(
          key: 'user-123',
          store: store,
          maxTokens: 0,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('throws on invalid refillRate', () {
      expect(
        () => DistributedRateLimiter(
          key: 'user-123',
          store: store,
          maxTokens: 10,
          refillRate: 0,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('tryAcquire succeeds on first call', () async {
      final limiter = DistributedRateLimiter(
        key: 'user-123',
        store: store,
        maxTokens: 10,
        refillRate: 1,
        refillInterval: const Duration(seconds: 1),
      );

      final result = await limiter.tryAcquire();
      expect(result, true);
    });

    test('tryAcquire respects maxTokens', () async {
      final limiter = DistributedRateLimiter(
        key: 'user-123',
        store: store,
        maxTokens: 3,
        refillRate: 1,
        refillInterval: const Duration(hours: 1), // No refill during test
      );

      // Should succeed 3 times
      expect(await limiter.tryAcquire(), true);
      expect(await limiter.tryAcquire(), true);
      expect(await limiter.tryAcquire(), true);

      // Should fail on 4th
      expect(await limiter.tryAcquire(), false);
    });

    test('tryAcquire with multiple tokens', () async {
      final limiter = DistributedRateLimiter(
        key: 'user-123',
        store: store,
        maxTokens: 10,
        refillRate: 1,
        refillInterval: const Duration(hours: 1),
      );

      // Acquire 5 tokens
      expect(await limiter.tryAcquire(5), true);

      // Acquire 3 more (total 8, should work)
      expect(await limiter.tryAcquire(3), true);

      // Try to acquire 3 more (would be 11 total, should fail)
      expect(await limiter.tryAcquire(3), false);

      // But 2 should work (total 10)
      expect(await limiter.tryAcquire(2), true);
    });

    test('callAsync returns result when token available', () async {
      final limiter = DistributedRateLimiter(
        key: 'user-123',
        store: store,
        maxTokens: 10,
        refillRate: 1,
        refillInterval: const Duration(seconds: 1),
      );

      final result = await limiter.callAsync(() async => 'success');
      expect(result, 'success');
    });

    test('callAsync returns null when rate limited', () async {
      final limiter = DistributedRateLimiter(
        key: 'user-123',
        store: store,
        maxTokens: 1,
        refillRate: 1,
        refillInterval: const Duration(hours: 1),
      );

      // First call succeeds
      final result1 = await limiter.callAsync(() async => 'success');
      expect(result1, 'success');

      // Second call is rate limited
      final result2 = await limiter.callAsync(() async => 'should-fail');
      expect(result2, null);
    });

    test('availableTokens reflects current state', () async {
      final limiter = DistributedRateLimiter(
        key: 'user-123',
        store: store,
        maxTokens: 10,
        refillRate: 1,
        refillInterval: const Duration(hours: 1),
      );

      expect(await limiter.availableTokens, 10);

      await limiter.tryAcquire(3);
      expect(await limiter.availableTokens, 7);

      await limiter.tryAcquire(5);
      expect(await limiter.availableTokens, 2);
    });

    test('canAcquire checks token availability', () async {
      final limiter = DistributedRateLimiter(
        key: 'user-123',
        store: store,
        maxTokens: 1,
        refillRate: 1,
        refillInterval: const Duration(hours: 1),
      );

      expect(await limiter.canAcquire, true);

      await limiter.tryAcquire();
      expect(await limiter.canAcquire, false);
    });

    test('timeUntilNextToken returns zero when tokens available', () async {
      final limiter = DistributedRateLimiter(
        key: 'user-123',
        store: store,
        maxTokens: 10,
        refillRate: 1,
        refillInterval: const Duration(seconds: 1),
      );

      final timeUntil = await limiter.timeUntilNextToken;
      expect(timeUntil, Duration.zero);
    });

    test('timeUntilNextToken calculates correctly when no tokens', () async {
      final limiter = DistributedRateLimiter(
        key: 'user-123',
        store: store,
        maxTokens: 1,
        refillRate: 2, // 2 tokens per second
        refillInterval: const Duration(seconds: 1),
      );

      await limiter.tryAcquire(); // Use the 1 token

      final timeUntil = await limiter.timeUntilNextToken;
      // Should take 0.5 seconds to get 1 token (2 tokens per second = 0.5s per token)
      expect(timeUntil.inMilliseconds, greaterThan(400));
      expect(timeUntil.inMilliseconds, lessThan(600));
    });

    test('reset restores to full capacity', () async {
      final limiter = DistributedRateLimiter(
        key: 'user-123',
        store: store,
        maxTokens: 10,
        refillRate: 1,
        refillInterval: const Duration(hours: 1),
      );

      // Use some tokens
      await limiter.tryAcquire(7);
      expect(await limiter.availableTokens, 3);

      // Reset
      await limiter.reset();
      expect(await limiter.availableTokens, 10);
    });

    test('dispose clears state from store', () async {
      final limiter = DistributedRateLimiter(
        key: 'user-123',
        store: store,
        maxTokens: 10,
        refillRate: 1,
        refillInterval: const Duration(seconds: 1),
      );

      await limiter.tryAcquire();
      expect(store.containsKey('user-123'), true);

      await limiter.dispose();
      expect(store.containsKey('user-123'), false);
    });

    test('enabled=false allows all calls', () async {
      final limiter = DistributedRateLimiter(
        key: 'user-123',
        store: store,
        maxTokens: 1,
        refillRate: 1,
        refillInterval: const Duration(hours: 1),
        enabled: false,
      );

      // Should succeed unlimited times
      for (int i = 0; i < 100; i++) {
        expect(await limiter.tryAcquire(), true);
      }
    });

    test('onMetrics callback is called', () async {
      int callCount = 0;
      int? lastTokensRemaining;
      bool? lastAcquired;

      final limiter = DistributedRateLimiter(
        key: 'user-123',
        store: store,
        maxTokens: 10,
        refillRate: 1,
        refillInterval: const Duration(hours: 1),
        onMetrics: (tokensRemaining, acquired) {
          callCount++;
          lastTokensRemaining = tokensRemaining;
          lastAcquired = acquired;
        },
      );

      await limiter.tryAcquire();
      expect(callCount, 1);
      expect(lastTokensRemaining, 9);
      expect(lastAcquired, true);

      // Use all remaining tokens
      for (int i = 0; i < 9; i++) {
        await limiter.tryAcquire();
      }

      // This should fail
      await limiter.tryAcquire();
      expect(lastTokensRemaining, 0);
      expect(lastAcquired, false);
    });

    test('multiple limiters with different keys are independent', () async {
      final limiter1 = DistributedRateLimiter(
        key: 'user-1',
        store: store,
        maxTokens: 5,
        refillRate: 1,
        refillInterval: const Duration(hours: 1),
      );

      final limiter2 = DistributedRateLimiter(
        key: 'user-2',
        store: store,
        maxTokens: 3,
        refillRate: 1,
        refillInterval: const Duration(hours: 1),
      );

      // Use all tokens for user-1
      for (int i = 0; i < 5; i++) {
        expect(await limiter1.tryAcquire(), true);
      }
      expect(await limiter1.tryAcquire(), false);

      // User-2 should still have tokens
      expect(await limiter2.tryAcquire(), true);
      expect(await limiter2.tryAcquire(), true);
      expect(await limiter2.tryAcquire(), true);
      expect(await limiter2.tryAcquire(), false);
    });

    test('state persists across limiter instances', () async {
      // Create first limiter and use some tokens
      final limiter1 = DistributedRateLimiter(
        key: 'user-shared',
        store: store,
        maxTokens: 10,
        refillRate: 1,
        refillInterval: const Duration(hours: 1),
      );

      await limiter1.tryAcquire(7);
      expect(await limiter1.availableTokens, 3);

      // Create second limiter with same key
      final limiter2 = DistributedRateLimiter(
        key: 'user-shared',
        store: store,
        maxTokens: 10,
        refillRate: 1,
        refillInterval: const Duration(hours: 1),
      );

      // Should see the same state (3 tokens remaining)
      expect(await limiter2.availableTokens, 3);

      // Use 2 more tokens
      await limiter2.tryAcquire(2);

      // First limiter should also see only 1 token
      expect(await limiter1.availableTokens, 1);
    });
  });
}
