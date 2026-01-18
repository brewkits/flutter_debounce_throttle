import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_debounce_throttle/flutter_debounce_throttle.dart';

/// Integration tests for dart_debounce_throttle
///
/// These tests verify that multiple components work together correctly
/// in real-world scenarios.
void main() {
  group('Integration Tests', () {
    group('RateLimiter + Debouncer combination', () {
      test('rate limit API calls with debounced search', () async {
        // Scenario: Search input with rate limiting
        // - Debounce user input (300ms)
        // - Rate limit actual API calls (max 5 per second)

        final searchQueries = <String>[];
        final rateLimitedQueries = <String>[];

        final debouncer = Debouncer(duration: 50.ms);
        final rateLimiter = RateLimiter(
          maxTokens: 3,
          refillRate: 1,
          refillInterval: 100.ms,
        );

        var currentQuery = '';

        void onUserType(String query) {
          currentQuery = query;
          debouncer.call(() {
            searchQueries.add(currentQuery);
            // After debounce, apply rate limiting
            rateLimiter.call(() {
              rateLimitedQueries.add(currentQuery);
            });
          });
        }

        // Simulate rapid typing
        onUserType('a');
        await Future.delayed(20.ms);
        onUserType('ab');
        await Future.delayed(20.ms);
        onUserType('abc');

        // Wait for debounce
        await Future.delayed(100.ms);

        expect(searchQueries, ['abc']); // Only final query (debounced)
        expect(rateLimitedQueries, ['abc']); // Rate limited

        // Type more rapidly
        onUserType('abcd');
        await Future.delayed(60.ms);

        onUserType('abcde');
        await Future.delayed(60.ms);

        onUserType('abcdef');
        await Future.delayed(60.ms);

        // Rate limiter should allow some but not all
        expect(searchQueries.length, greaterThanOrEqualTo(2));

        debouncer.dispose();
        rateLimiter.dispose();
      });
    });

    group('Leading Debouncer + BatchThrottler combination', () {
      test('immediate feedback with batched API calls', () async {
        // Scenario: Button with immediate visual feedback, batched analytics
        // - Leading edge debounce for immediate UI feedback
        // - Batch analytics events

        final uiFeedback = <String>[];
        final batchedAnalytics = <List<String>>[];

        final debouncer = Debouncer(
          duration: 50.ms,
          leading: true,
          trailing: false,
        );

        var clickCount = 0;
        final batcher = BatchThrottler(
          duration: 100.ms,
          maxBatchSize: 5,
          onBatchExecute: (actions) {
            // Record the batch execution with count
            batchedAnalytics.add(['batch_${actions.length}_clicks']);
          },
        );

        void onButtonClick(String action) {
          debouncer.call(() {
            uiFeedback.add(action);
          });
          clickCount++;
          batcher.call(() {}); // Track click for analytics batch
        }

        // Rapid clicks
        onButtonClick('click1');
        onButtonClick('click2');
        onButtonClick('click3');

        expect(uiFeedback, ['click1']); // Immediate feedback for first (leading edge)

        await Future.delayed(150.ms);

        // Analytics should be batched (3 clicks batched together)
        expect(batchedAnalytics.length, 1);
        expect(clickCount, 3);

        debouncer.dispose();
        batcher.dispose();
      });
    });

    group('ConcurrentAsyncThrottler + RateLimiter combination', () {
      test('queued async operations with rate limiting', () async {
        // Scenario: File upload queue with rate limiting
        // - Queue uploads (max 3 pending)
        // - Rate limit to prevent server overload

        final uploadedFiles = <String>[];
        var rateLimitedCount = 0;

        final rateLimiter = RateLimiter(
          maxTokens: 5,
          refillRate: 2,
          refillInterval: 100.ms,
        );

        final uploadQueue = ConcurrentAsyncThrottler(
          mode: ConcurrencyMode.enqueue,
          maxDuration: const Duration(seconds: 5),
          maxQueueSize: 3,
          queueOverflowStrategy: QueueOverflowStrategy.dropNewest,
        );

        Future<void> uploadFile(String filename) async {
          await uploadQueue.call(() async {
            if (rateLimiter.tryAcquire()) {
              await Future.delayed(20.ms); // Simulate upload
              uploadedFiles.add(filename);
            } else {
              rateLimitedCount++;
            }
          }).catchError((_) {
            // Queue overflow - file rejected
          });
        }

        // Queue many files
        for (var i = 0; i < 10; i++) {
          uploadFile('file$i.txt');
        }

        await Future.delayed(500.ms);

        // Some files should be uploaded
        expect(uploadedFiles.length, greaterThan(0));
        // Queue overflow should have rejected some
        expect(uploadedFiles.length, lessThan(10));

        rateLimiter.dispose();
        uploadQueue.dispose();
      });
    });

    group('Extension methods integration', () {
      test('extensions work with Duration extensions', () async {
        var callCount = 0;
        final debounced = (() => callCount++).debounced(50.ms);

        debounced();
        debounced();
        debounced();

        expect(callCount, 0);

        await Future.delayed(100.ms);

        expect(callCount, 1);
      });

      test('multiple throttled functions maintain isolation', () async {
        var count1 = 0;
        var count2 = 0;

        final throttled1 = (() => count1++).throttled(100.ms);
        final throttled2 = (() => count2++).throttled(100.ms);

        throttled1();
        throttled2();
        throttled1();
        throttled2();

        // Each should execute once (first call)
        expect(count1, 1);
        expect(count2, 1);
      });
    });

    group('Error handling integration', () {
      test('errors in one component dont affect others', () async {
        final results = <String>[];

        final debouncer = Debouncer(
          duration: 50.ms,
          resetOnError: true,
        );

        final batcher = BatchThrottler(
          duration: 50.ms,
          onBatchExecute: (actions) {
            for (final action in actions) {
              try {
                action();
              } catch (_) {
                results.add('error');
              }
            }
          },
        );

        // Debouncer with error
        debouncer.call(() {
          results.add('debounced');
          throw Exception('Test error');
        });

        // Batcher should work independently
        batcher.call(() => results.add('batched1'));
        batcher.call(() => results.add('batched2'));

        await Future.delayed(100.ms);

        expect(results.contains('debounced'), true);
        expect(results.contains('batched1'), true);
        expect(results.contains('batched2'), true);

        debouncer.dispose();
        batcher.dispose();
      });
    });

    group('Memory and lifecycle integration', () {
      test('disposing all components cleans up properly', () async {
        final components = <dynamic>[];

        // Create many components
        for (var i = 0; i < 10; i++) {
          components.add(Debouncer(duration: 100.ms));
          components.add(Throttler(duration: 100.ms));
          components.add(RateLimiter(maxTokens: 10));
          components.add(BatchThrottler(
            duration: 100.ms,
            onBatchExecute: (_) {},
          ));
        }

        // Use them
        for (final component in components) {
          if (component is Debouncer) {
            component.call(() {});
          } else if (component is Throttler) {
            component.call(() {});
          } else if (component is RateLimiter) {
            component.tryAcquire();
          } else if (component is BatchThrottler) {
            component.call(() {});
          }
        }

        // Dispose all
        for (final component in components) {
          component.dispose();
        }

        // No assertions - just verify no memory leaks or errors
        await Future.delayed(200.ms);
      });
    });

    group('Real-world system test', () {
      test('e-commerce checkout flow', () async {
        // Simulate complete checkout flow with multiple limiters
        final events = <String>[];

        // 1. Debounce cart quantity changes
        final quantityDebouncer = Debouncer(
          duration: 100.ms,
          leading: true, // Show immediate feedback
          trailing: true, // Update server after pause
        );

        // 2. Throttle "Add to Cart" button
        final addToCartThrottler = Throttler(duration: 500.ms);

        // 3. Rate limit API calls
        final apiLimiter = RateLimiter(
            maxTokens: 10, refillRate: 2, refillInterval: 1.seconds);

        // 4. Queue checkout steps
        final checkoutQueue = ConcurrentAsyncThrottler(
          mode: ConcurrencyMode.enqueue,
          maxDuration: 30.seconds,
        );

        // Simulate user actions
        void updateQuantity(int qty) {
          quantityDebouncer.call(() => events.add('qty_update_$qty'));
        }

        void addToCart(String item) {
          addToCartThrottler.call(() {
            if (apiLimiter.tryAcquire()) {
              events.add('add_$item');
            }
          });
        }

        Future<void> checkout(String step) async {
          await checkoutQueue.call(() async {
            await Future.delayed(50.ms);
            events.add('checkout_$step');
          });
        }

        // User rapidly changes quantity
        updateQuantity(1);
        updateQuantity(2);
        updateQuantity(3);
        await Future.delayed(150.ms);

        // User rapidly clicks "Add to Cart"
        addToCart('item1');
        addToCart('item1'); // Should be throttled
        addToCart('item1'); // Should be throttled

        // User proceeds through checkout
        checkout('address');
        checkout('payment');
        checkout('confirm');

        await Future.delayed(500.ms);

        // Verify flow
        expect(events.where((e) => e.startsWith('qty_update')).length,
            2); // Leading + trailing
        expect(
            events.where((e) => e.startsWith('add_')).length, 1); // Throttled
        expect(events.where((e) => e.startsWith('checkout_')).length,
            3); // All queued

        quantityDebouncer.dispose();
        addToCartThrottler.dispose();
        apiLimiter.dispose();
        checkoutQueue.dispose();
      });

      test('real-time collaboration scenario', () async {
        // Simulate collaborative editing with multiple users
        final serverUpdates = <String>[];
        final localUpdates = <String>[];

        // Debounce local edits before sending to server
        final editDebouncer = Debouncer(duration: 50.ms);

        // Batch server updates
        final updateBatcher = BatchThrottler(
          duration: 100.ms,
          maxBatchSize: 10,
          overflowStrategy: BatchOverflowStrategy.flushAndAdd,
          onBatchExecute: (actions) {
            serverUpdates.add('batch_${actions.length}');
            for (final action in actions) {
              action();
            }
          },
        );

        void onLocalEdit(String content) {
          localUpdates.add(content);
          editDebouncer.call(() {
            updateBatcher.call(() {});
          });
        }

        // Simulate rapid typing
        for (var i = 0; i < 20; i++) {
          onLocalEdit('char_$i');
          await Future.delayed(10.ms);
        }

        await Future.delayed(200.ms);

        // Local updates should be all 20
        expect(localUpdates.length, 20);

        // Server updates should be batched
        expect(serverUpdates.length, greaterThan(0));
        expect(serverUpdates.length, lessThan(20));

        editDebouncer.dispose();
        updateBatcher.dispose();
      });
    });
  });
}
