// Pure Dart - no Flutter dependencies.
//
// Async throttle controller with lock-based execution.

import 'dart:async';

import 'config.dart';
import 'logger.dart';
import 'throttler.dart';

/// Prevents duplicate async operations by locking until Future completes.
///
/// **Behavior:** Locks during async execution, auto-unlocks after timeout.
///
/// **Difference from Throttler:** Process-based (waits for completion) vs time-based (fixed duration).
/// **Difference from AsyncDebouncer:** Locks immediately, while AsyncDebouncer delays execution.
///
/// **Features:**
/// - Debug mode: `AsyncThrottler(debugMode: true, name: 'form-submit')`
/// - Performance metrics: `onMetrics` callback tracks async execution time
/// - Conditional throttling: `enabled` parameter to bypass throttle
/// - Reset on error: `resetOnError: true` auto-resets on exceptions
/// - Custom timeout: `maxDuration` parameter (default 15s)
///
/// **Use cases:**
/// - Form submission: Prevent double-submit
/// - File upload: Lock during upload
/// - Payment: Prevent duplicate charges
///
/// **Example:**
/// ```dart
/// final throttler = AsyncThrottler(
///   debugMode: true,
///   name: 'submit',
///   maxDuration: Duration(seconds: 30),
///   onMetrics: (duration, executed) {
///     print('Submit took: $duration, executed: $executed');
///   },
/// );
///
/// void onSubmit() async {
///   await throttler.call(() async {
///     await api.submit();
///   });
/// }
///
/// // Don't forget to dispose
/// throttler.dispose();
/// ```
class AsyncThrottler with EventLimiterLogging {
  /// Default timeout duration.
  static Duration get defaultTimeout =>
      DebounceThrottleConfig.config.defaultAsyncTimeout;

  /// Maximum duration before auto-unlock (default 15s for APIs, 60s+ for uploads).
  final Duration? maxDuration;

  @override
  final bool debugMode;

  @override
  final String? name;

  /// Whether throttling is enabled. Set to false to bypass throttle.
  final bool enabled;

  /// Whether to reset state on error.
  final bool resetOnError;

  /// Callback for performance metrics.
  final void Function(Duration executionTime, bool executed)? onMetrics;

  bool _isLocked = false;
  Timer? _timeoutTimer;

  AsyncThrottler({
    Duration? maxDuration,
    this.debugMode = false,
    this.name,
    this.enabled = true,
    this.resetOnError = false,
    this.onMetrics,
  }) : maxDuration = maxDuration ?? defaultTimeout;

  /// Execute async operation with lock protection.
  Future<void> call(Future<void> Function() callback) async {
    final startTime = DateTime.now();

    // Skip throttle if disabled
    if (!enabled) {
      debugLog('AsyncThrottle bypassed (disabled)');
      try {
        await callback();
        final executionTime = DateTime.now().difference(startTime);
        onMetrics?.call(executionTime, true);
      } catch (e) {
        if (resetOnError) {
          debugLog('Error occurred, resetting lock state');
        }
        rethrow;
      }
      return;
    }

    if (_isLocked) {
      debugLog('AsyncThrottle blocked (locked)');
      onMetrics?.call(Duration.zero, false);
      return;
    }

    _isLocked = true;
    debugLog('AsyncThrottle locked');

    if (maxDuration != null) {
      _timeoutTimer?.cancel();
      _timeoutTimer = Timer(maxDuration!, () {
        debugLog('AsyncThrottle timeout reached, auto-unlocking');
        _timeoutTimer = null;
        _isLocked = false;
      });
    }

    try {
      await callback();
      final executionTime = DateTime.now().difference(startTime);
      debugLog('AsyncThrottle completed in ${executionTime.inMilliseconds}ms');
      onMetrics?.call(executionTime, true);
    } catch (e) {
      debugLog('AsyncThrottle error: $e');
      if (resetOnError) {
        debugLog('Resetting AsyncThrottler state due to error');
        reset();
      }
      rethrow;
    } finally {
      // Only unlock if timeout hasn't already unlocked
      if (_timeoutTimer != null) {
        _timeoutTimer!.cancel();
        _timeoutTimer = null;
        _isLocked = false;
        debugLog('AsyncThrottle unlocked');
      }
    }
  }

  /// Wraps callback for builders.
  VoidCallback? wrap(Future<void> Function()? callback) {
    if (callback == null) return null;
    return () => call(callback);
  }

  /// Whether the throttler is currently locked (busy).
  bool get isLocked => _isLocked;

  /// Reset throttler state, allowing immediate execution.
  void reset() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    _isLocked = false;
    debugLog('AsyncThrottle reset');
  }

  void dispose() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    _isLocked = false;
  }
}
