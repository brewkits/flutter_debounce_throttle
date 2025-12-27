// lib/src/core/throttle_debouncer.dart
//
// Combined leading + trailing edge execution.
// Pure Dart - no Flutter dependencies.

import 'dart:async';

import 'throttler.dart';

/// Combines leading (immediate) + trailing (after pause) execution.
///
/// **Rare use case.** Most apps should use Throttler, Debouncer, or AsyncThrottler instead.
///
/// **Behavior:** Execute immediately (leading), then again after pause (trailing).
///
/// **Use cases:**
/// - Scroll position: Update on start + end of scroll
/// - Resize events: Handle first + final resize
/// - Drag gestures: Process start + end position
///
/// **Example:**
/// ```dart
/// final limiter = ThrottleDebouncer();
///
/// void onScroll(double offset) {
///   limiter.call(() => updatePosition(offset));
///   // Fires on first call AND after scroll stops
/// }
///
/// // Don't forget to dispose
/// limiter.dispose();
/// ```
class ThrottleDebouncer {
  /// Default duration (500ms).
  static const Duration defaultDuration = Duration(milliseconds: 500);

  final Duration duration;
  Timer? _timer;
  bool _isThrottled = false;
  VoidCallback? _pendingCallback;

  ThrottleDebouncer({this.duration = defaultDuration});

  /// Execute callback with leading + trailing edge behavior.
  void call(VoidCallback callback) {
    if (!_isThrottled) {
      // First call - execute immediately (leading edge)
      callback();
      _isThrottled = true;
      _startThrottleWindow();
    } else {
      // Within throttle window - save for trailing edge
      _pendingCallback = callback;
    }
  }

  // Async recursion (safe): Each call runs in new event loop, no stack buildup.
  // Self-terminating: Stops when _pendingCallback == null.
  void _startThrottleWindow() {
    _timer = Timer(duration, () {
      if (_pendingCallback != null) {
        final callback = _pendingCallback!;
        _pendingCallback = null;
        callback();
        _startThrottleWindow(); // New timer, not stack recursion
      } else {
        _isThrottled = false;
      }
    });
  }

  /// Wraps callback for listeners.
  VoidCallback? wrap(VoidCallback? callback) {
    if (callback == null) return null;
    return () => call(callback);
  }

  /// Reset state, allowing immediate execution.
  void reset() {
    cancel();
    _isThrottled = false;
    _pendingCallback = null;
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    cancel();
    _isThrottled = false;
    _pendingCallback = null;
  }

  bool get isPending => _timer?.isActive ?? false;
}
