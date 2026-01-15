// Pure Dart - no Flutter dependencies.
//
// Batch execution utility for throttling/debouncing multiple actions.

import 'dart:async';

import 'logger.dart';
import 'throttler.dart';

/// Batch execution utility for throttling/debouncing multiple actions as one.
///
/// Collects multiple throttled calls and executes them as a single batch.
///
/// **Use cases:**
/// - Analytics tracking: Batch multiple tracking events
/// - API calls: Combine multiple small requests into one
/// - State updates: Batch multiple setState calls
/// - Database writes: Batch log entries for efficiency
/// - Server-side batching: Combine writes to reduce DB load
///
/// **Example:**
/// ```dart
/// final batcher = BatchThrottler(
///   duration: Duration(milliseconds: 500),
///   onBatchExecute: (actions) {
///     // Execute all actions as one batch
///     for (final action in actions) {
///       action();
///     }
///   },
///   debugMode: true,
///   name: 'analytics-batch',
/// );
///
/// // Multiple rapid calls - callable class syntax
/// batcher(() => trackEvent('click1'));
/// batcher(() => trackEvent('click2'));
/// batcher(() => trackEvent('click3'));
/// // After 500ms, all 3 events execute as one batch
///
/// // Don't forget to dispose
/// batcher.dispose();
/// ```
///
/// **Server-side example:**
/// ```dart
/// final logBatcher = BatchThrottler(
///   duration: Duration(seconds: 1),
///   onBatchExecute: (actions) async {
///     final logs = <String>[];
///     for (final action in actions) {
///       logs.add(action());
///     }
///     await database.insertLogs(logs); // Single DB write
///   },
///   debugMode: true,
///   name: 'log-batcher',
/// );
///
/// // 100 log calls → 1 database write
/// logBatcher(() => 'User logged in');
/// logBatcher(() => 'Page viewed');
/// // ...
/// ```
class BatchThrottler with EventLimiterLogging {
  final Duration duration;
  final void Function(List<VoidCallback> actions) onBatchExecute;

  @override
  final bool debugMode;

  @override
  final String? name;

  Timer? _timer;
  final List<VoidCallback> _pendingActions = [];

  BatchThrottler({
    required this.duration,
    required this.onBatchExecute,
    this.debugMode = false,
    this.name,
  });

  /// Add an action to the batch.
  ///
  /// Can be called directly as a function: `batcher(() => ...)`
  void call(VoidCallback action) {
    _pendingActions.add(action);
    debugLog('Action added to batch (${_pendingActions.length} total)');

    // Reset timer
    _timer?.cancel();
    _timer = Timer(duration, _executeBatch);
  }

  /// Alias for [call]. Prefer using `call()` or callable syntax.
  @Deprecated('Use call() instead. Will be removed in v2.0.0')
  void add(VoidCallback action) => call(action);

  void _executeBatch() {
    if (_pendingActions.isEmpty) return;

    debugLog('Executing batch of ${_pendingActions.length} actions');
    final actionsToExecute = List<VoidCallback>.from(_pendingActions);
    _pendingActions.clear();

    try {
      onBatchExecute(actionsToExecute);
    } catch (e) {
      debugLog('Batch execution error: $e');
      rethrow;
    }
  }

  /// Force immediate batch execution.
  void flush() {
    _timer?.cancel();
    _timer = null;
    _executeBatch();
  }

  /// Clear pending actions without executing.
  void clear() {
    debugLog('Clearing ${_pendingActions.length} pending actions');
    _timer?.cancel();
    _timer = null;
    _pendingActions.clear();
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    _pendingActions.clear();
  }

  /// Number of pending actions in the batch.
  int get pendingCount => _pendingActions.length;

  /// Whether there are pending actions.
  bool get hasPending => _pendingActions.isNotEmpty;
}
