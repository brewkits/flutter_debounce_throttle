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
    Duration? limiterAutoCleanupTTL,
    int? limiterAutoCleanupThreshold,
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
    if (limiterAutoCleanupTTL != null) {
      _config._limiterAutoCleanupTTL = limiterAutoCleanupTTL;
    }
    if (limiterAutoCleanupThreshold != null) {
      _config._limiterAutoCleanupThreshold = limiterAutoCleanupThreshold;
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
  Duration? _limiterAutoCleanupTTL = const Duration(minutes: 10);
  int _limiterAutoCleanupThreshold = 100;

  /// Default duration for debounce operations.
  Duration get defaultDebounceDuration => _defaultDebounceDuration;

  /// Default duration for throttle operations.
  Duration get defaultThrottleDuration => _defaultThrottleDuration;

  /// Default timeout for async operations.
  Duration get defaultAsyncTimeout => _defaultAsyncTimeout;

  /// Time-to-live for auto-cleanup of inactive limiters in EventLimiterMixin.
  ///
  /// When set, limiters that haven't been used for this duration will be
  /// automatically disposed when the limiter count exceeds [limiterAutoCleanupThreshold].
  ///
  /// Default is 10 minutes (auto-cleanup enabled for production safety).
  /// Set to null via DebounceThrottleConfig.init() to disable auto-cleanup.
  Duration? get limiterAutoCleanupTTL => _limiterAutoCleanupTTL;

  /// Threshold for triggering auto-cleanup in EventLimiterMixin.
  ///
  /// When the total number of limiters exceeds this threshold, auto-cleanup
  /// will be triggered (if [limiterAutoCleanupTTL] is set).
  ///
  /// Default is 100.
  int get limiterAutoCleanupThreshold => _limiterAutoCleanupThreshold;

  void _reset() {
    _defaultDebounceDuration = const Duration(milliseconds: 300);
    _defaultThrottleDuration = const Duration(milliseconds: 500);
    _defaultAsyncTimeout = const Duration(seconds: 15);
    _limiterAutoCleanupTTL = const Duration(minutes: 10);
    _limiterAutoCleanupThreshold = 100;
  }
}
