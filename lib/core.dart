// lib/core.dart
//
// Pure Dart core library for flutter_debounce_throttle.
// Use this entry point for Dart servers (Serverpod, Dart Frog) and CLI tools.
//
// **IMPORTANT:** This library has NO Flutter dependencies.
// It can be used in any Dart environment.
//
// Example (Dart Server):
// ```dart
// import 'package:flutter_debounce_throttle/core.dart';
//
// class RateLimitedApiClient {
//   final _throttler = Throttler(duration: Duration(seconds: 1));
//
//   void makeRequest() {
//     _throttler.call(() => http.get(url));
//   }
// }
// ```
//
// Example (Batching Database Writes):
// ```dart
// import 'package:flutter_debounce_throttle/core.dart';
//
// class LogService {
//   final _batcher = BatchThrottler(
//     duration: Duration(seconds: 1),
//     onBatchExecute: (actions) {
//       final logs = actions.map((a) => a()).toList();
//       database.insertAll(logs);
//     },
//   );
//
//   void log(String message) {
//     _batcher.add(() => message);
//   }
// }
// ```

// library flutter_debounce_throttle_core;

// Configuration
export 'src/core/config.dart';
export 'src/core/logger.dart';

// Concurrency modes
export 'src/core/concurrency_mode.dart';

// Core controllers
export 'src/core/throttler.dart';
export 'src/core/debouncer.dart';
export 'src/core/async_debouncer.dart';
export 'src/core/async_throttler.dart';
export 'src/core/high_frequency_throttler.dart';
export 'src/core/throttle_debouncer.dart';
export 'src/core/batch_throttler.dart';
export 'src/core/concurrent_async_throttler.dart';
