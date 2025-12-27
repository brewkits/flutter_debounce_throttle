// Pure Dart server example - no Flutter dependency
// Run with: dart run example/server_demo/server_example.dart

// ignore_for_file: avoid_print

import 'package:flutter_debounce_throttle/core.dart';

void main() async {
  print('=== flutter_debounce_throttle Server Demo ===\n');

  // Example 1: Rate Limiting API Calls
  await rateLimitingExample();

  // Example 2: Debouncing Database Writes
  await debouncingExample();

  // Example 3: Batch Processing
  await batchProcessingExample();

  // Example 4: Concurrent Request Handling
  await concurrentExample();

  print('\n=== Demo Complete ===');
}

/// Rate limiting example - limit API calls to once per second
Future<void> rateLimitingExample() async {
  print('1. Rate Limiting Example:');

  final rateLimiter = Throttler(
    duration: const Duration(seconds: 1),
    name: 'API RateLimiter',
  );

  // Simulate multiple API requests
  for (var i = 0; i < 5; i++) {
    rateLimiter.call(() {
      print('   API call $i executed');
    });
    await Future.delayed(const Duration(milliseconds: 300));
  }

  rateLimiter.dispose();
  print('');
}

/// Debouncing example - batch database writes
Future<void> debouncingExample() async {
  print('2. Debouncing Example:');

  final dbWriter = Debouncer(
    duration: const Duration(milliseconds: 500),
    name: 'DB Writer',
  );

  // Simulate rapid updates
  print('   Sending 5 rapid updates...');
  for (var i = 0; i < 5; i++) {
    dbWriter.call(() {
      print('   Database write executed (only once!)');
    });
    await Future.delayed(const Duration(milliseconds: 100));
  }

  // Wait for debounce to complete
  await Future.delayed(const Duration(milliseconds: 600));

  dbWriter.dispose();
  print('');
}

/// Batch processing example
Future<void> batchProcessingExample() async {
  print('3. Batch Processing Example:');

  final items = <String>[];

  final batcher = BatchThrottler(
    duration: const Duration(milliseconds: 300),
    onBatchExecute: (actions) {
      // Execute all batched actions
      for (final action in actions) {
        action();
      }
      print('   Batch processed: ${items.join(", ")}');
    },
  );

  // Add items rapidly as callbacks
  batcher.add(() => items.add('item1'));
  batcher.add(() => items.add('item2'));
  batcher.add(() => items.add('item3'));

  // Wait for batch to complete
  await Future.delayed(const Duration(milliseconds: 400));

  batcher.dispose();
  print('');
}

/// Concurrent request handling example
Future<void> concurrentExample() async {
  print('4. Concurrent Request Handling (drop mode):');

  final handler = ConcurrentAsyncThrottler(
    mode: ConcurrencyMode.drop,
    maxDuration: const Duration(seconds: 5),
  );

  // Simulate concurrent requests
  handler.call(() async {
    print('   Request 1 started');
    await Future.delayed(const Duration(milliseconds: 500));
    print('   Request 1 completed');
  });

  // This will be dropped because first request is still running
  handler.call(() async {
    print('   Request 2 started (should not appear)');
  });

  await Future.delayed(const Duration(milliseconds: 600));

  handler.dispose();
}
