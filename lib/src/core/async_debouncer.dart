// lib/src/core/async_debouncer.dart
//
// Async debounce controller with auto-cancel.
// Pure Dart - no Flutter dependencies.

import 'dart:async';

import 'config.dart';
import 'logger.dart';

/// Debounce with auto-cancel for async operations (search API, autocomplete).
///
/// **Behavior:** Waits for duration before execution, cancels previous pending calls.
///
/// **Difference from Debouncer:** Handles async operations and cancels old results.
/// **Difference from AsyncThrottler:** Debounces (delays), while AsyncThrottler locks immediately.
///
/// **Features:**
/// - Debug mode: `AsyncDebouncer(debugMode: true, name: 'search-api')`
/// - Performance metrics: `onMetrics` callback tracks async execution time
/// - Conditional debouncing: `enabled` parameter to bypass debounce
/// - Reset on error: `resetOnError: true` auto-resets on exceptions
///
/// **Use cases:**
/// - Search API: User types "abc" → only last call executes
/// - Autocomplete: Cancels stale API responses
/// - Real-time validation: Debounce + async server check
///
/// **IMPORTANT:**
/// - `run()` returns `Future<T?>`. If cancelled, it returns `null`.
/// - Always check for null if you need to handle cancellation.
/// - Call `dispose()` to prevent memory leaks.
///
/// **Example:**
/// ```dart
/// final debouncer = AsyncDebouncer(
///   debugMode: true,
///   name: 'search',
///   onMetrics: (duration, cancelled) {
///     print('API call took: $duration, cancelled: $cancelled');
///   },
/// );
///
/// void onSearch(String text) async {
///   final result = await debouncer.run(() async {
///     return await searchApi(text);
///   });
///
///   if (result == null) return; // Cancelled by newer call
///   updateResults(result);
/// }
///
/// // Don't forget to dispose
/// debouncer.dispose();
/// ```
class AsyncDebouncer with EventLimiterLogging {
  /// Default debounce duration (300ms).
  static Duration get defaultDuration =>
      FlutterDebounceThrottle.config.defaultDebounceDuration;

  final Duration duration;
  @override
  final bool debugMode;
  @override
  final String? name;

  /// Whether debouncing is enabled. Set to false to bypass debounce.
  final bool enabled;

  /// Whether to reset state on error.
  final bool resetOnError;

  /// Callback for performance metrics.
  final void Function(Duration executionTime, bool cancelled)? onMetrics;

  Timer? _timer;
  int _latestCallId = 0;
  Completer<dynamic>? _pendingCompleter;

  AsyncDebouncer({
    Duration? duration,
    this.debugMode = false,
    this.name,
    this.enabled = true,
    this.resetOnError = false,
    this.onMetrics,
  }) : duration = duration ?? defaultDuration;

  /// Executes async action after debounce delay, auto-cancels previous calls.
  ///
  /// Returns `Future<T?>` where null means the call was cancelled by a newer call.
  Future<T?> run<T>(Future<T> Function() action) async {
    final startTime = DateTime.now();

    // Skip debounce if disabled
    if (!enabled) {
      debugLog('AsyncDebounce bypassed (disabled)');
      try {
        final result = await action();
        final executionTime = DateTime.now().difference(startTime);
        onMetrics?.call(executionTime, false);
        return result;
      } catch (e) {
        if (resetOnError) {
          debugLog('Error occurred, state reset');
        }
        rethrow;
      }
    }

    // Cancel old timer
    _timer?.cancel();

    // Complete old completer to prevent hanging futures
    if (_pendingCompleter != null && !_pendingCompleter!.isCompleted) {
      _pendingCompleter!.complete(null);
      debugLog('AsyncDebounce cancelled previous call');
      final cancelTime = DateTime.now().difference(startTime);
      onMetrics?.call(cancelTime, true);
    }

    final currentCallId = ++_latestCallId;
    final completer = Completer<T?>();
    _pendingCompleter = completer;

    _timer = Timer(duration, () async {
      try {
        // Check if this is still the latest call
        if (currentCallId != _latestCallId) {
          if (!completer.isCompleted) {
            completer.complete(null);
            debugLog('AsyncDebounce cancelled during wait');
          }
          return;
        }

        debugLog('AsyncDebounce executing async action');
        try {
          final result = await action();
          // Double-check after await
          if (currentCallId == _latestCallId && !completer.isCompleted) {
            final executionTime = DateTime.now().difference(startTime);
            debugLog(
              'AsyncDebounce completed in ${executionTime.inMilliseconds}ms',
            );
            onMetrics?.call(executionTime, false);
            completer.complete(result);
          } else if (!completer.isCompleted) {
            debugLog('AsyncDebounce cancelled after execution');
            completer.complete(null);
          }
        } catch (e, stackTrace) {
          debugLog('AsyncDebounce error: $e');
          if (resetOnError) {
            debugLog('Resetting AsyncDebouncer state due to error');
            cancel();
          }
          if (!completer.isCompleted) {
            completer.completeError(e, stackTrace);
          }
        }
      } catch (e, stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(e, stackTrace);
        }
      } finally {
        if (_pendingCompleter == completer) {
          _pendingCompleter = null;
        }
      }
    });

    return completer.future;
  }

  /// Cancels all pending and in-flight operations.
  void cancel() {
    _timer?.cancel();
    _timer = null;

    if (_pendingCompleter != null && !_pendingCompleter!.isCompleted) {
      _pendingCompleter!.complete(null);
      _pendingCompleter = null;
    }

    _latestCallId++;
  }

  void dispose() {
    cancel();
  }

  bool get isPending => _timer?.isActive ?? false;
}
