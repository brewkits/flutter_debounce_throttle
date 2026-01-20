// Pure Dart - no Flutter dependencies.
//
// Throttle controller for preventing spam actions.

import 'dart:async';

import 'package:meta/meta.dart';

import 'config.dart';
import 'logger.dart';

/// Void callback type for Pure Dart compatibility.
typedef VoidCallback = void Function();

/// Base class for time-controlled callbacks (Throttler, Debouncer).
///
/// Pure Dart implementation - can be used in Flutter apps, Dart servers, and CLI tools.
abstract class CallbackController with EventLimiterLogging {
  final Duration duration;
  @override
  final bool debugMode;
  @override
  final String? name;
  Timer? _timer;

  CallbackController({
    required this.duration,
    this.debugMode = false,
    this.name,
  });

  /// Subclasses implement: Throttler (immediate), Debouncer (delayed), etc.
  void call(VoidCallback callback);

  /// Wraps callback for builders: `throttler.wrap(() => handleTap(index, item))`
  VoidCallback? wrap(VoidCallback? callback) {
    if (callback == null) return null;
    return () => call(callback);
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() => cancel();

  bool get isPending => _timer?.isActive ?? false;

  @protected
  set timer(Timer? value) {
    _timer?.cancel();
    _timer = value;
  }

  @protected
  Timer? get timer => _timer;
}

/// Prevents spam clicks by blocking calls for [duration] after first execution.
///
/// **Behavior:** First call executes immediately, subsequent calls blocked for duration.
///
/// **Features:**
/// - Debug mode: `Throttler(debugMode: true, name: 'submit-button')`
/// - Performance metrics: `onMetrics` callback tracks execution time
/// - Conditional throttling: `enabled` parameter to bypass throttle
/// - Reset on error: `resetOnError: true` auto-resets on exceptions
///
/// **Use cases:**
/// - Button clicks: Prevent double-click charges
/// - API calls: Rate limit outgoing requests
/// - UI updates: Limit refresh frequency
///
/// **Example:**
/// ```dart
/// final throttler = Throttler(
///   debugMode: true,
///   name: 'submit',
///   onMetrics: (duration, executed) {
///     print('Took: $duration, executed: $executed');
///   },
/// );
///
/// void onButtonTap() {
///   throttler.call(() => submitForm());
/// }
///
/// // Don't forget to dispose
/// throttler.dispose();
/// ```
class Throttler extends CallbackController {
  /// Default throttle duration (500ms).
  static Duration get defaultDuration =>
      DebounceThrottleConfig.config.defaultThrottleDuration;

  bool _isThrottled = false;

  /// Whether throttling is enabled. Set to false to bypass throttle.
  final bool enabled;

  /// Whether to reset throttle state on error.
  final bool resetOnError;

  /// Callback for performance metrics.
  final void Function(Duration executionTime, bool executed)? onMetrics;

  /// Error handler for exceptions thrown in throttled callbacks.
  ///
  /// When provided, errors from callbacks will be caught and passed to this handler.
  /// If not provided, errors will be rethrown (default behavior).
  ///
  /// Example:
  /// ```dart
  /// final throttler = Throttler(
  ///   onError: (error, stackTrace) {
  ///     FirebaseCrashlytics.instance.recordError(error, stackTrace);
  ///     logger.error('Throttle error: $error');
  ///   },
  /// );
  /// ```
  final void Function(Object error, StackTrace stackTrace)? onError;

  Throttler({
    Duration? duration,
    super.debugMode = false,
    super.name,
    this.enabled = true,
    this.resetOnError = false,
    this.onMetrics,
    this.onError,
  }) : super(duration: duration ?? defaultDuration);

  @override
  void call(VoidCallback callback) {
    _throttleWithDuration(callback, duration);
  }

  /// Execute with custom duration for this specific call.
  void callWithDuration(VoidCallback callback, Duration customDuration) {
    _throttleWithDuration(callback, customDuration);
  }

  void _throttleWithDuration(
    VoidCallback callback,
    Duration effectiveDuration,
  ) {
    final startTime = DateTime.now();

    // Skip throttle if disabled
    if (!enabled) {
      debugLog('Throttle bypassed (disabled)');
      _executeCallback(callback, startTime, executed: true);
      return;
    }

    if (_isThrottled) {
      debugLog('Throttle blocked');
      onMetrics?.call(Duration.zero, false);
      return;
    }

    debugLog('Throttle executed');
    _executeCallback(callback, startTime, executed: true);
    _isThrottled = true;
    timer = Timer(effectiveDuration, () {
      _isThrottled = false;
      debugLog('Throttle cooldown ended');
    });
  }

  void _executeCallback(
    VoidCallback callback,
    DateTime startTime, {
    required bool executed,
  }) {
    try {
      callback();
      final executionTime = DateTime.now().difference(startTime);
      onMetrics?.call(executionTime, executed);
    } catch (e, stackTrace) {
      if (resetOnError) {
        debugLog('Error occurred, resetting throttle state');
        reset();
      }

      // Call error handler if provided
      if (onError != null) {
        try {
          onError!(e, stackTrace);
        } catch (handlerError) {
          // Error in error handler - log but don't crash
          debugLog('Error in onError handler: $handlerError');
        }
        // Don't rethrow when onError is provided
      } else {
        // No error handler - rethrow (original behavior)
        rethrow;
      }
    }
  }

  /// Reset throttle state, allowing immediate execution.
  void reset() {
    cancel();
    _isThrottled = false;
    debugLog('Throttle reset');
  }

  /// Whether throttle is currently active (blocking calls).
  bool get isThrottled => _isThrottled;

  @override
  void dispose() {
    super.dispose();
    _isThrottled = false;
  }
}
