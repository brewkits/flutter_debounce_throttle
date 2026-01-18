// Pure Dart - no Flutter dependencies.
//
// Debug logging system for flutter_debounce_throttle.

/// Log levels for event limiter debugging.
enum LogLevel {
  /// No logging
  none,

  /// Only errors
  error,

  /// Warnings and errors
  warning,

  /// Info, warnings, and errors
  info,

  /// All messages including debug
  debug,
}

/// Custom log handler function type.
typedef LogHandler = void Function(
  LogLevel level,
  String message,
  String? name,
  DateTime timestamp,
);

/// Global logger for flutter_debounce_throttle.
///
/// Provides centralized logging control for all event limiters.
///
/// **Usage:**
/// ```dart
/// // Enable debug logging globally
/// EventLimiterLogger.level = LogLevel.debug;
///
/// // Custom log handler (e.g., for crash reporting)
/// EventLimiterLogger.handler = (level, message, name, timestamp) {
///   myLogger.log(level.name, '$name: $message');
/// };
///
/// // Disable logging
/// EventLimiterLogger.level = LogLevel.none;
/// ```
class EventLimiterLogger {
  EventLimiterLogger._();

  /// Current log level. Default is [LogLevel.none] (disabled).
  static LogLevel level = LogLevel.none;

  /// Custom log handler. If null, uses default print behavior.
  static LogHandler? handler;

  /// Whether logging is enabled.
  static bool get isEnabled => level != LogLevel.none;

  /// Log a debug message.
  static void debug(String message, {String? name}) {
    _log(LogLevel.debug, message, name);
  }

  /// Log an info message.
  static void info(String message, {String? name}) {
    _log(LogLevel.info, message, name);
  }

  /// Log a warning message.
  static void warning(String message, {String? name}) {
    _log(LogLevel.warning, message, name);
  }

  /// Log an error message.
  static void error(String message, {String? name}) {
    _log(LogLevel.error, message, name);
  }

  static void _log(LogLevel messageLevel, String message, String? name) {
    // Check if this message level should be logged
    if (level == LogLevel.none) return;
    if (messageLevel.index > level.index) return;

    final timestamp = DateTime.now();

    // Use custom handler if provided
    if (handler != null) {
      handler!(messageLevel, message, name, timestamp);
      return;
    }

    // Default print behavior
    final prefix = name != null ? '[$name] ' : '';
    final levelTag = '[${messageLevel.name.toUpperCase()}]';
    final timeStr = timestamp.toIso8601String();

    // ignore: avoid_print
    print('$levelTag $prefix$message at $timeStr');
  }
}

/// Mixin to add logging capability to event limiters.
///
/// Provides a convenient way to add debug logging to any class.
mixin EventLimiterLogging {
  /// Whether debug mode is enabled for this instance.
  bool get debugMode;

  /// Optional name for this instance (used in log messages).
  String? get name;

  /// Log a debug message if debug mode is enabled.
  void debugLog(String message) {
    if (!debugMode) return;

    // Use global logger if enabled, otherwise use local print
    if (EventLimiterLogger.isEnabled) {
      EventLimiterLogger.debug(message, name: name);
    } else {
      final prefix = name != null ? '[$name] ' : '';
      final timestamp = DateTime.now().toIso8601String();
      // ignore: avoid_print
      print('$prefix$message at $timestamp');
    }
  }

  /// Log an info message.
  void infoLog(String message) {
    if (EventLimiterLogger.isEnabled) {
      EventLimiterLogger.info(message, name: name);
    }
  }

  /// Log a warning message.
  void warnLog(String message) {
    if (EventLimiterLogger.isEnabled) {
      EventLimiterLogger.warning(message, name: name);
    }
  }

  /// Log an error message.
  void errorLog(String message) {
    if (EventLimiterLogger.isEnabled) {
      EventLimiterLogger.error(message, name: name);
    }
  }
}
