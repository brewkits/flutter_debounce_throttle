// Pure Dart - no Flutter dependencies.
//
// Global configuration for flutter_debounce_throttle.

import 'logger.dart';

/// Global configuration for flutter_debounce_throttle.
///
/// Allows setting default durations and logging behavior across all event limiters.
///
/// **Usage in Flutter app:**
/// ```dart
/// void main() {
///   // Configure before runApp
///   DebounceThrottleConfig.init(
///     defaultDebounceDuration: Duration(milliseconds: 300),
///     defaultThrottleDuration: Duration(milliseconds: 500),
///     enableDebugLog: kDebugMode,
///   );
///
///   runApp(MyApp());
/// }
/// ```
///
/// **Usage in Dart Server:**
/// ```dart
/// void main() {
///   DebounceThrottleConfig.init(
///     defaultDebounceDuration: Duration(seconds: 1),
///     defaultThrottleDuration: Duration(seconds: 2),
///     enableDebugLog: true,
///     logHandler: (level, message, name, timestamp) {
///       // Send to server logging system
///       logger.log(level.name, message);
///     },
///   );
///
///   startServer();
/// }
/// ```
class DebounceThrottleConfig {
  DebounceThrottleConfig._();

  static final _config = EventLimiterConfig._();

  /// Initialize global configuration.
  ///
  /// Call this once at app startup, before creating any event limiters.
  static void init({
    Duration? defaultDebounceDuration,
    Duration? defaultThrottleDuration,
    Duration? defaultAsyncTimeout,
    bool enableDebugLog = false,
    LogLevel logLevel = LogLevel.none,
    LogHandler? logHandler,
  }) {
    if (defaultDebounceDuration != null) {
      _config._defaultDebounceDuration = defaultDebounceDuration;
    }
    if (defaultThrottleDuration != null) {
      _config._defaultThrottleDuration = defaultThrottleDuration;
    }
    if (defaultAsyncTimeout != null) {
      _config._defaultAsyncTimeout = defaultAsyncTimeout;
    }

    // Configure logging
    if (enableDebugLog) {
      EventLimiterLogger.level = LogLevel.debug;
    } else if (logLevel != LogLevel.none) {
      EventLimiterLogger.level = logLevel;
    }

    if (logHandler != null) {
      EventLimiterLogger.handler = logHandler;
    }
  }

  /// Get current configuration (read-only).
  static EventLimiterConfig get config => _config;

  /// Reset configuration to defaults.
  static void reset() {
    _config._reset();
    EventLimiterLogger.level = LogLevel.none;
    EventLimiterLogger.handler = null;
  }
}

/// Read-only configuration values.
///
/// Access via [DebounceThrottleConfig.config].
class EventLimiterConfig {
  EventLimiterConfig._();

  Duration _defaultDebounceDuration = const Duration(milliseconds: 300);
  Duration _defaultThrottleDuration = const Duration(milliseconds: 500);
  Duration _defaultAsyncTimeout = const Duration(seconds: 15);

  /// Default duration for debounce operations.
  Duration get defaultDebounceDuration => _defaultDebounceDuration;

  /// Default duration for throttle operations.
  Duration get defaultThrottleDuration => _defaultThrottleDuration;

  /// Default timeout for async operations.
  Duration get defaultAsyncTimeout => _defaultAsyncTimeout;

  void _reset() {
    _defaultDebounceDuration = const Duration(milliseconds: 300);
    _defaultThrottleDuration = const Duration(milliseconds: 500);
    _defaultAsyncTimeout = const Duration(seconds: 15);
  }
}
