// Pure Dart - no Flutter dependencies.
//
// Async debounce controller with auto-cancel.

import 'dart:async';

import 'config.dart';
import 'logger.dart';

/// Result wrapper for async debounce operations.
///
/// Distinguishes between:
/// - Cancelled operation: `isCancelled = true`, `value = null`
/// - Successful null result: `isCancelled = false`, `value = null`
///
/// **Example:**
/// ```dart
/// final result = await debouncer.callWithResult(() async {
///   return await api.search(query); // May return null
/// });
///
/// if (result.isCancelled) {
///   print('Cancelled by newer call');
///   return;
/// }
///
/// // Safe to use result.value (may be null, but that's the actual result)
/// updateUI(result.value);
/// ```
class DebounceResult<T> {
  /// Whether this operation was cancelled by a newer call.
  final bool isCancelled;

  /// The result value. May be null even if not cancelled
  /// (if the async operation returned null).
  final T? value;

  const DebounceResult._({required this.isCancelled, this.value});

  /// Creates a cancelled result.
  const DebounceResult.cancelled() : this._(isCancelled: true, value: null);

  /// Creates a successful result with the given value.
  const DebounceResult.success(T? value)
      : this._(isCancelled: false, value: value);

  /// Whether the operation completed successfully (not cancelled).
  bool get isSuccess => !isCancelled;

  @override
  String toString() => isCancelled
      ? 'DebounceResult.cancelled'
      : 'DebounceResult.success($value)';
}

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
/// - Returns `Future<T?>`. If cancelled, it returns `null`.
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
///   // Callable class - use like a function
///   final result = await debouncer(() async {
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
      DebounceThrottleConfig.config.defaultDebounceDuration;

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

  /// Error handler for exceptions thrown in async debounced callbacks.
  ///
  /// When provided, errors from callbacks will be caught and passed to this handler.
  /// The future will still complete with an error if not handled.
  ///
  /// Example:
  /// ```dart
  /// final debouncer = AsyncDebouncer(
  ///   onError: (error, stackTrace) {
  ///     FirebaseCrashlytics.instance.recordError(error, stackTrace);
  ///   },
  /// );
  /// ```
  final void Function(Object error, StackTrace stackTrace)? onError;

  Timer? _timer;
  int _latestCallId = 0;
  void Function()? _cancelPendingCompleter;

  AsyncDebouncer({
    Duration? duration,
    this.debugMode = false,
    this.name,
    this.enabled = true,
    this.resetOnError = false,
    this.onMetrics,
    this.onError,
  }) : duration = duration ?? defaultDuration;

  /// Executes async action after debounce delay, auto-cancels previous calls.
  ///
  /// ⚠️ **WARNING: Null Ambiguity Issue**
  ///
  /// Returns `Future<T?>` where null can mean:
  /// 1. The call was cancelled by a newer call, OR
  /// 2. Your async function legitimately returned null
  ///
  /// This ambiguity can cause bugs. **Consider using [callWithResult] instead**,
  /// which returns a `DebounceResult` to distinguish between these cases.
  ///
  /// Example:
  /// ```dart
  /// // ❌ Ambiguous - is null from cancellation or actual result?
  /// final result = await debouncer.call(() async => fetchData());
  /// if (result == null) {
  ///   // Was it cancelled? Or did fetchData() return null?
  /// }
  ///
  /// // ✅ Clear - use callWithResult instead
  /// final result = await debouncer.callWithResult(() async => fetchData());
  /// if (result.isCancelled) {
  ///   print('Debounce was cancelled');
  /// } else {
  ///   print('Got result: ${result.value}');
  /// }
  /// ```
  ///
  /// Can be called directly as a function: `debouncer(() async => ...)`
  Future<T?> call<T>(Future<T> Function() action) async {
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

    // Cancel old timer and complete old completer
    _timer?.cancel();
    if (_cancelPendingCompleter != null) {
      _cancelPendingCompleter!();
      debugLog('AsyncDebounce cancelled previous call');
      final cancelTime = DateTime.now().difference(startTime);
      onMetrics?.call(cancelTime, true);
    }

    final currentCallId = ++_latestCallId;
    final completer = Completer<T?>();

    // Store cancel callback for this completer
    _cancelPendingCompleter = () {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    };

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

          // Call error handler if provided
          if (onError != null) {
            try {
              onError!(e, stackTrace);
            } catch (handlerError) {
              debugLog('Error in onError handler: $handlerError');
            }
          }

          if (resetOnError) {
            debugLog('Resetting AsyncDebouncer state due to error');
            _cancelInternal();
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
        if (_cancelPendingCompleter != null) {
          _cancelPendingCompleter = null;
        }
      }
    });

    return completer.future;
  }

  /// Alias for [call]. Prefer using `call()` or callable syntax.
  @Deprecated('Use call() instead. Will be removed in v2.0.0')
  Future<T?> run<T>(Future<T> Function() action) => call(action);

  /// Executes async action with result wrapper to distinguish cancellation from null.
  ///
  /// Unlike [call] which returns `T?` (where null could mean cancelled OR actual null result),
  /// this returns [DebounceResult] which clearly indicates whether the operation was cancelled.
  ///
  /// **Use this when your async operation can legitimately return null.**
  ///
  /// ```dart
  /// final result = await debouncer.callWithResult(() async {
  ///   return await api.findUser(id); // May return null if not found
  /// });
  ///
  /// if (result.isCancelled) {
  ///   return; // Cancelled by newer call
  /// }
  ///
  /// final user = result.value; // May be null (user not found), but not cancelled
  /// showUser(user);
  /// ```
  Future<DebounceResult<T>> callWithResult<T>(
      Future<T> Function() action) async {
    final startTime = DateTime.now();

    // Skip debounce if disabled
    if (!enabled) {
      debugLog('AsyncDebounce bypassed (disabled)');
      try {
        final result = await action();
        final executionTime = DateTime.now().difference(startTime);
        onMetrics?.call(executionTime, false);
        return DebounceResult.success(result);
      } catch (e) {
        if (resetOnError) {
          debugLog('Error occurred, state reset');
        }
        rethrow;
      }
    }

    // Cancel old timer and complete old completer
    _timer?.cancel();
    if (_cancelPendingCompleter != null) {
      _cancelPendingCompleter!();
      debugLog('AsyncDebounce cancelled previous call');
      final cancelTime = DateTime.now().difference(startTime);
      onMetrics?.call(cancelTime, true);
    }

    final currentCallId = ++_latestCallId;
    final completer = Completer<DebounceResult<T>>();

    // Store cancel callback for this completer
    _cancelPendingCompleter = () {
      if (!completer.isCompleted) {
        completer.complete(DebounceResult<T>.cancelled());
      }
    };

    _timer = Timer(duration, () async {
      try {
        // Check if this is still the latest call
        if (currentCallId != _latestCallId) {
          if (!completer.isCompleted) {
            completer.complete(DebounceResult<T>.cancelled());
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
            completer.complete(DebounceResult.success(result));
          } else if (!completer.isCompleted) {
            debugLog('AsyncDebounce cancelled after execution');
            completer.complete(DebounceResult<T>.cancelled());
          }
        } catch (e, stackTrace) {
          debugLog('AsyncDebounce error: $e');

          // Call error handler if provided
          if (onError != null) {
            try {
              onError!(e, stackTrace);
            } catch (handlerError) {
              debugLog('Error in onError handler: $handlerError');
            }
          }

          if (resetOnError) {
            debugLog('Resetting AsyncDebouncer state due to error');
            _cancelInternal();
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
        _cancelPendingCompleter = null;
      }
    });

    return completer.future;
  }

  /// Internal cancel without completing the completer (for error handling).
  void _cancelInternal() {
    _timer?.cancel();
    _timer = null;
    _latestCallId++;
  }

  /// Cancels all pending and in-flight operations.
  void cancel() {
    _timer?.cancel();
    _timer = null;

    if (_cancelPendingCompleter != null) {
      _cancelPendingCompleter!();
      _cancelPendingCompleter = null;
    }

    _latestCallId++;
  }

  void dispose() {
    cancel();
  }

  bool get isPending => _timer?.isActive ?? false;
}
