// dart_debounce_throttle
//
// Pure Dart library for debounce and throttle operations.
// Zero external dependencies - works on Mobile, Web, Desktop, Server, and CLI.
//
// ============================================================================
// QUICK START
// ============================================================================
//
// **Basic Throttle (prevent spam clicks):**
// ```dart
// final throttler = Throttler(duration: Duration(milliseconds: 500));
// throttler.call(() => submitForm());
// ```
//
// **Basic Debounce (wait for user to stop):**
// ```dart
// final debouncer = Debouncer(duration: Duration(milliseconds: 300));
// debouncer.call(() => search(query));
// ```
//
// **Async Throttle (API calls):**
// ```dart
// final asyncThrottler = AsyncThrottler(maxDuration: Duration(seconds: 15));
// await asyncThrottler.call(() async => await api.submit());
// ```
//
// **Async Debounce (search autocomplete):**
// ```dart
// final asyncDebouncer = AsyncDebouncer(duration: Duration(milliseconds: 300));
// final result = await asyncDebouncer.run(() async => await searchApi(query));
// if (result == null) return; // Cancelled by newer call
// updateResults(result);
// ```
//
// **Server-side batching:**
// ```dart
// final batcher = BatchThrottler(
//   duration: Duration(seconds: 1),
//   onBatchExecute: (actions) async {
//     final logs = actions.map((a) => a()).toList();
//     await database.insertAll(logs);
//   },
// );
// batcher.add(() => 'User logged in');
// ```
//
// ============================================================================
// AVAILABLE CLASSES
// ============================================================================
//
// **Sync Controllers:**
// - Throttler: Immediate execution, blocks for duration
// - Debouncer: Delayed execution after pause
// - HighFrequencyThrottler: Optimized for scroll/resize (no Timer)
// - ThrottleDebouncer: Leading + trailing edge execution
//
// **Async Controllers:**
// - AsyncThrottler: Lock-based async throttle
// - AsyncDebouncer: Debounce with auto-cancel for async operations
// - ConcurrentAsyncThrottler: Advanced async with drop/enqueue/replace/keepLatest modes
//
// **Utilities:**
// - BatchThrottler: Batch multiple actions for bulk execution
// - DebounceThrottleConfig: Global configuration
// - EventLimiterLogger: Centralized logging

// Configuration
export 'src/config.dart';
export 'src/logger.dart';

// Concurrency modes
export 'src/concurrency_mode.dart';

// Core sync controllers
export 'src/throttler.dart';
export 'src/debouncer.dart';
export 'src/high_frequency_throttler.dart';
export 'src/throttle_debouncer.dart';

// Core async controllers
export 'src/async_debouncer.dart';
export 'src/async_throttler.dart';
export 'src/concurrent_async_throttler.dart';

// Utilities
export 'src/batch_throttler.dart';
export 'src/rate_limiter.dart';

// Extensions
export 'src/extensions.dart';
