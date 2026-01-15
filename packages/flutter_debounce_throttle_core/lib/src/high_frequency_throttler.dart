// Pure Dart - no Flutter dependencies.
//
// Optimized throttler for high-frequency events.

import 'throttler.dart';

/// Throttle for high-frequency events (scroll, resize) using DateTime check.
///
/// **Behavior:** Executes immediately if enough time passed, otherwise ignores.
///
/// **Difference from Throttler:** Uses DateTime.now() instead of Timer (less overhead).
///
/// **Why DateTime.now() instead of Timer:**
/// - High frequency (16-32ms): Timer overhead becomes significant
/// - No timer cleanup needed: Simpler, more efficient
/// - More accurate: Timer can drift, DateTime is precise
///
/// **Use cases:**
/// - Scroll listener: Update sticky header every 16ms (~60fps)
/// - Window resize: Recalculate layout every 32ms
/// - Mouse move: Track position every 50ms
/// - Sensor data: Process readings at controlled rate
///
/// **Example:**
/// ```dart
/// final throttler = HighFrequencyThrottler(
///   duration: Duration(milliseconds: 16), // ~60fps
/// );
///
/// void onScroll(double offset) {
///   throttler.call(() {
///     updateStickyHeader(offset);
///   });
/// }
///
/// // Don't forget to dispose
/// throttler.dispose();
/// ```
class HighFrequencyThrottler {
  /// Default duration (16ms for ~60fps).
  static const Duration defaultDuration = Duration(milliseconds: 16);

  final Duration duration;
  DateTime? _lastExecutionTime;

  HighFrequencyThrottler({this.duration = defaultDuration});

  /// Execute callback if enough time has passed.
  void call(VoidCallback callback) {
    final now = DateTime.now();

    if (_lastExecutionTime == null ||
        now.difference(_lastExecutionTime!) >= duration) {
      callback();
      _lastExecutionTime = now;
    }
  }

  /// Wraps callback for listeners.
  VoidCallback? wrap(VoidCallback? callback) {
    if (callback == null) return null;
    return () => call(callback);
  }

  /// Reset throttle state, allowing immediate execution.
  void reset() {
    _lastExecutionTime = null;
  }

  void dispose() {
    _lastExecutionTime = null;
  }

  /// Whether the throttle is currently active (blocking calls).
  bool get isThrottled {
    if (_lastExecutionTime == null) return false;
    return DateTime.now().difference(_lastExecutionTime!) < duration;
  }
}
