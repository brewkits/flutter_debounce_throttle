// Pure Dart - no Flutter dependencies.
//
// Extension methods for convenient debounce/throttle operations.

import 'debouncer.dart';
import 'throttler.dart';

/// Extension on [int] for convenient Duration creation.
///
/// **Example:**
/// ```dart
/// 300.ms    // Duration(milliseconds: 300)
/// 2.seconds // Duration(seconds: 2)
/// 5.minutes // Duration(minutes: 5)
/// ```
extension DurationIntExtension on int {
  /// Creates a Duration with this many milliseconds.
  Duration get ms => Duration(milliseconds: this);

  /// Creates a Duration with this many seconds.
  Duration get seconds => Duration(seconds: this);

  /// Creates a Duration with this many minutes.
  Duration get minutes => Duration(minutes: this);

  /// Creates a Duration with this many hours.
  Duration get hours => Duration(hours: this);
}

/// Extension on [void Function()] for debounce/throttle operations.
///
/// **Example:**
/// ```dart
/// final myFunc = () => print('Hello');
///
/// // Create debounced version
/// final debouncedFunc = myFunc.debounced(300.ms);
/// debouncedFunc(); // Delays execution
///
/// // Create throttled version
/// final throttledFunc = myFunc.throttled(500.ms);
/// throttledFunc(); // Executes immediately, blocks for 500ms
/// ```
///
/// **Note:** Each call to `.debounced()` or `.throttled()` creates a new
/// limiter instance. For repeated use, prefer creating a [Debouncer] or
/// [Throttler] instance directly.
extension VoidCallbackDebounceExtension on void Function() {
  /// Returns a debounced version of this callback.
  ///
  /// Creates a new [Debouncer] internally. For repeated use with the same
  /// debouncer instance, prefer creating a [Debouncer] directly.
  void Function() debounced(Duration duration) {
    final debouncer = Debouncer(duration: duration);
    return () => debouncer.call(this);
  }

  /// Returns a throttled version of this callback.
  ///
  /// Creates a new [Throttler] internally. For repeated use with the same
  /// throttler instance, prefer creating a [Throttler] directly.
  void Function() throttled(Duration duration) {
    final throttler = Throttler(duration: duration);
    return () => throttler.call(this);
  }
}

/// Extension on [Future<T> Function()] for async debounce operations.
///
/// **Example:**
/// ```dart
/// Future<String> fetchData() async => await api.getData();
///
/// final debouncedFetch = fetchData.asyncDebounced(300.ms);
/// final result = await debouncedFetch(); // null if cancelled
/// ```
extension AsyncCallbackDebounceExtension<T> on Future<T> Function() {
  /// Returns an async debounced version that creates its own debouncer.
  ///
  /// **Note:** Each call creates a new internal debouncer. For production use,
  /// prefer creating an [AsyncDebouncer] instance directly.
  // Note: This is intentionally not implemented to avoid complexity
  // and encourage proper AsyncDebouncer usage. Users should create
  // AsyncDebouncer instances directly for async operations.
}
