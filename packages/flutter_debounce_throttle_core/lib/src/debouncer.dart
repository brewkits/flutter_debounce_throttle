// Pure Dart - no Flutter dependencies.
//
// Debounce controller for delayed execution.

import 'dart:async';

import 'config.dart';
import 'throttler.dart';

/// Delays execution until user stops calling for [duration] (default 300ms).
///
/// **Behavior:** Resets timer on each call, executes only after pause.
///
/// **Features:**
/// - Debug mode: `Debouncer(debugMode: true, name: 'search-input')`
/// - Performance metrics: `onMetrics` callback tracks timing
/// - Conditional debouncing: `enabled` parameter to bypass debounce
/// - Reset on error: `resetOnError: true` auto-resets on exceptions
/// - Leading edge: `leading: true` executes immediately on first call
/// - Trailing edge: `trailing: true` executes after pause (default)
///
/// **Use cases:**
/// - Search input: Wait for user to stop typing
/// - Window resize: Recalculate after resize stops
/// - Form validation: Validate after user stops editing
/// - Button feedback: `leading: true` for immediate response + debounced follow-up
///
/// **Example:**
/// ```dart
/// final debouncer = Debouncer(
///   debugMode: true,
///   name: 'search',
///   onMetrics: (duration, cancelled) {
///     print('Took: $duration, cancelled: $cancelled');
///   },
/// );
///
/// void onTextChanged(String text) {
///   debouncer.call(() => searchApi(text));
/// }
///
/// // Leading + trailing edge (like lodash)
/// final buttonDebouncer = Debouncer(
///   duration: Duration(milliseconds: 300),
///   leading: true,   // Execute immediately on first call
///   trailing: true,  // Also execute after pause
/// );
///
/// // Don't forget to dispose
/// debouncer.dispose();
/// ```
class Debouncer extends CallbackController {
  /// Default debounce duration (300ms).
  static Duration get defaultDuration =>
      DebounceThrottleConfig.config.defaultDebounceDuration;

  /// Whether debouncing is enabled. Set to false to bypass debounce.
  final bool enabled;

  /// Whether to reset debounce state on error.
  final bool resetOnError;

  /// Callback for performance metrics.
  final void Function(Duration waitTime, bool cancelled)? onMetrics;

  /// Execute callback immediately on first call (leading edge).
  /// Default is false (trailing edge only).
  final bool leading;

  /// Execute callback after pause (trailing edge).
  /// Default is true (standard debounce behavior).
  final bool trailing;

  DateTime? _lastCallTime;
  DateTime? _leadingExecutedAt; // Track when leading edge was executed
  bool _isInDebounceWindow = false;
  VoidCallback? _pendingCallback;

  Debouncer({
    Duration? duration,
    super.debugMode = false,
    super.name,
    this.enabled = true,
    this.resetOnError = false,
    this.onMetrics,
    this.leading = false,
    this.trailing = true,
  })  : assert(
          leading || trailing,
          'At least one of leading or trailing must be true',
        ),
        super(duration: duration ?? defaultDuration);

  @override
  void call(VoidCallback callback) {
    _debounceWithDuration(callback, duration);
  }

  /// Execute with custom duration for this specific call.
  void callWithDuration(VoidCallback callback, Duration customDuration) {
    _debounceWithDuration(callback, customDuration);
  }

  void _debounceWithDuration(
    VoidCallback callback,
    Duration effectiveDuration,
  ) {
    final callTime = DateTime.now();

    // Skip debounce if disabled
    if (!enabled) {
      debugLog('Debounce bypassed (disabled)');
      _executeCallback(callback, callTime, cancelled: false);
      return;
    }

    // Cancel previous timer (if any)
    if (_lastCallTime != null && timer?.isActive == true) {
      final waitTime = callTime.difference(_lastCallTime!);
      debugLog(
        'Debounce cancelled (new call after ${waitTime.inMilliseconds}ms)',
      );
      onMetrics?.call(waitTime, true);
    }

    // Store the latest callback for trailing edge
    _pendingCallback = callback;
    _lastCallTime = callTime;

    // Leading edge: execute immediately if not already in a debounce window
    if (leading && !_isInDebounceWindow) {
      _isInDebounceWindow = true;
      _leadingExecutedAt = callTime;
      debugLog('Leading edge: executing immediately');
      _executeCallback(callback, callTime, cancelled: false);
    }

    // Reset the timer
    timer?.cancel();
    timer = Timer(effectiveDuration, () {
      final totalWaitTime = DateTime.now().difference(callTime);

      // Trailing edge: execute after pause
      if (trailing && _pendingCallback != null) {
        // Execute trailing if:
        // 1. Leading is disabled, OR
        // 2. There were additional calls after the leading execution
        final hasNewCallsAfterLeading =
            _leadingExecutedAt != null && _lastCallTime != _leadingExecutedAt;
        if (!leading || hasNewCallsAfterLeading) {
          debugLog(
              'Trailing edge: executed after ${totalWaitTime.inMilliseconds}ms');
          _executeCallback(_pendingCallback!, callTime, cancelled: false);
        } else {
          debugLog('Trailing edge: skipped (same as leading call)');
        }
      }

      // Reset debounce window
      _isInDebounceWindow = false;
      _leadingExecutedAt = null;
      _pendingCallback = null;
    });
  }

  void _executeCallback(
    VoidCallback callback,
    DateTime callTime, {
    required bool cancelled,
  }) {
    if (cancelled) return;

    try {
      callback();
      final totalTime = DateTime.now().difference(callTime);
      onMetrics?.call(totalTime, false);
    } catch (e) {
      if (resetOnError) {
        debugLog('Error occurred, cancelling pending debounce');
        cancel();
        _lastCallTime = null;
      }
      // Don't rethrow - errors in debounced callbacks are swallowed
      // This is consistent with how Timer callbacks work
      debugLog('Debounce callback error (swallowed): $e');
    }
  }

  /// Force immediate execution (e.g., form submit without waiting).
  void flush(VoidCallback callback) {
    cancel();
    _lastCallTime = null;
    debugLog('Debounce flushed (immediate execution)');
    callback();
    onMetrics?.call(Duration.zero, false);
  }

  @override
  void dispose() {
    super.dispose();
    _lastCallTime = null;
    _isInDebounceWindow = false;
    _pendingCallback = null;
  }
}
