// Pure Dart - no Flutter dependencies.
//
// Advanced async throttler with concurrency control strategies.

import 'dart:async';
import 'dart:collection';

import 'async_throttler.dart';
import 'concurrency_mode.dart';
import 'throttler.dart';

/// Advanced async throttler with concurrency control strategies.
///
/// Wraps [AsyncThrottler] with different concurrency modes:
/// - **drop** (default): Ignore new calls while busy (same as AsyncThrottler)
/// - **enqueue**: Queue calls and execute sequentially (FIFO)
/// - **replace**: Cancel current execution and start new one
/// - **keepLatest**: Keep latest call and execute after current finishes
///
/// **Use cases:**
/// - Chat app: `enqueue` mode to send messages in order
/// - Search: `replace` mode to cancel old queries
/// - Auto-save: `keepLatest` mode to save final version after edits
/// - Payment: `drop` mode to prevent duplicate charges (default)
///
/// **Example:**
/// ```dart
/// // Enqueue mode - execute all calls sequentially
/// final chatSender = ConcurrentAsyncThrottler(
///   mode: ConcurrencyMode.enqueue,
///   maxDuration: Duration(seconds: 30),
///   debugMode: true,
///   name: 'chat-sender',
/// );
///
/// // User sends 3 messages rapidly
/// chatSender.call(() async => await api.sendMessage('Hello'));
/// chatSender.call(() async => await api.sendMessage('World'));
/// chatSender.call(() async => await api.sendMessage('!'));
/// // All 3 execute in order, one after another
///
/// // Replace mode - cancel old, start new
/// final searchController = ConcurrentAsyncThrottler(
///   mode: ConcurrencyMode.replace,
///   maxDuration: Duration(seconds: 10),
/// );
///
/// // User types "abc" rapidly
/// searchController.call(() async => await api.search('a')); // Cancelled
/// searchController.call(() async => await api.search('ab')); // Cancelled
/// searchController.call(() async => await api.search('abc')); // Executes
///
/// // Keep Latest mode - execute current + latest
/// final autoSaver = ConcurrentAsyncThrottler(
///   mode: ConcurrencyMode.keepLatest,
///   maxDuration: Duration(seconds: 30),
/// );
///
/// // User edits 5 times rapidly
/// autoSaver.call(() async => await api.saveDraft(v1)); // Executes
/// autoSaver.call(() async => await api.saveDraft(v2)); // Replaced
/// autoSaver.call(() async => await api.saveDraft(v3)); // Replaced
/// autoSaver.call(() async => await api.saveDraft(v4)); // Replaced
/// autoSaver.call(() async => await api.saveDraft(v5)); // Kept, executes after v1
/// // Only v1 and v5 execute
/// ```
///
/// **Performance:**
/// - Drop mode: Zero overhead (wraps AsyncThrottler directly)
/// - Enqueue mode: ~60 bytes per queued operation
/// - Replace/KeepLatest mode: ~40 bytes overhead
class ConcurrentAsyncThrottler {
  final AsyncThrottler _throttler;
  final ConcurrencyMode mode;
  final Queue<Future<void> Function()> _queue = Queue();
  Future<void> Function()? _latestCall;
  bool _isProcessingQueue = false;
  int _latestCallId = 0;

  ConcurrentAsyncThrottler({
    this.mode = ConcurrencyMode.drop,
    Duration? maxDuration,
    bool debugMode = false,
    String? name,
    bool enabled = true,
    bool resetOnError = false,
    void Function(Duration executionTime, bool executed)? onMetrics,
  }) : _throttler = AsyncThrottler(
          maxDuration: maxDuration,
          debugMode: debugMode,
          name: name,
          enabled: enabled,
          resetOnError: resetOnError,
          onMetrics: onMetrics,
        );

  /// Execute async operation with selected concurrency mode.
  Future<void> call(Future<void> Function() callback) async {
    switch (mode) {
      case ConcurrencyMode.drop:
        return _throttler.call(callback);

      case ConcurrencyMode.enqueue:
        return _enqueueCall(callback);

      case ConcurrencyMode.replace:
        return _replaceCall(callback);

      case ConcurrencyMode.keepLatest:
        return _keepLatestCall(callback);
    }
  }

  /// Enqueue mode: Queue calls and execute sequentially (FIFO).
  Future<void> _enqueueCall(Future<void> Function() callback) async {
    final completer = Completer<void>();

    // Add to queue
    _queue.add(() async {
      try {
        await callback();
        completer.complete();
      } catch (e, stack) {
        completer.completeError(e, stack);
      }
    });

    _throttler.debugLog(
      'Enqueued call (queue size: ${_queue.length}, processing: $_isProcessingQueue)',
    );

    // Start processing if not already processing
    if (!_isProcessingQueue) {
      _processQueue();
    }

    return completer.future;
  }

  /// Process queue sequentially using AsyncThrottler.
  Future<void> _processQueue() async {
    if (_isProcessingQueue || _queue.isEmpty) return;

    _isProcessingQueue = true;
    _throttler.debugLog('Started queue processing');

    while (_queue.isNotEmpty) {
      final action = _queue.removeFirst();
      _throttler
          .debugLog('Processing queued item (${_queue.length} remaining)');

      try {
        await _throttler.call(action);
      } catch (e) {
        _throttler.debugLog('Queue processing error: $e');
        // Continue processing queue even if one item fails
      }
    }

    _isProcessingQueue = false;
    _throttler.debugLog('Queue processing complete');
  }

  /// Replace mode: Cancel current execution and start new one.
  Future<void> _replaceCall(Future<void> Function() callback) async {
    final currentCallId = ++_latestCallId;
    _throttler.debugLog('Replace mode: new call ID $currentCallId');

    // Reset to allow new call immediately
    _throttler.reset();

    // Execute with ID check wrapper
    await _throttler.call(() async {
      // Check if still valid before executing callback
      if (currentCallId != _latestCallId) {
        _throttler.debugLog(
          'Replace mode: call $currentCallId cancelled before execution',
        );
        return;
      }

      await callback();

      // Check again after execution
      if (currentCallId != _latestCallId) {
        _throttler.debugLog(
          'Replace mode: call $currentCallId result ignored (replaced during execution)',
        );
      }
    });
  }

  /// Keep Latest mode: Keep latest call and execute after current finishes.
  Future<void> _keepLatestCall(Future<void> Function() callback) async {
    // If throttler is locked (busy), save this as latest call
    if (_throttler.isLocked) {
      _latestCall = callback;
      _throttler.debugLog('Kept latest call (will execute after current)');
      return;
    }

    // Execute immediately if not locked
    await _throttler.call(callback);

    // After execution, check if there's a pending latest call
    if (_latestCall != null) {
      final pendingCall = _latestCall!;
      _latestCall = null;
      _throttler.debugLog('Executing pending latest call');

      // Recursively call to handle any new latest that arrived during execution
      await _keepLatestCall(pendingCall);
    }
  }

  /// Wraps callback for builders.
  VoidCallback? wrap(Future<void> Function()? callback) {
    if (callback == null) return null;
    return () => call(callback);
  }

  /// Check if throttler is currently locked (busy).
  bool get isLocked => _throttler.isLocked;

  /// Check if there are pending operations.
  bool get hasPendingCalls {
    switch (mode) {
      case ConcurrencyMode.enqueue:
        return _queue.isNotEmpty || _isProcessingQueue;
      case ConcurrencyMode.keepLatest:
        return _latestCall != null || _throttler.isLocked;
      default:
        return _throttler.isLocked;
    }
  }

  /// Get current queue size (enqueue mode only).
  int get queueSize => mode == ConcurrencyMode.enqueue ? _queue.length : 0;

  /// Get pending call count (all modes).
  int get pendingCount {
    switch (mode) {
      case ConcurrencyMode.enqueue:
        return _queue.length + (_isProcessingQueue ? 1 : 0);
      case ConcurrencyMode.keepLatest:
        return (_throttler.isLocked ? 1 : 0) + (_latestCall != null ? 1 : 0);
      case ConcurrencyMode.drop:
      case ConcurrencyMode.replace:
        return _throttler.isLocked ? 1 : 0;
    }
  }

  /// Reset throttler state and clear pending operations.
  void reset() {
    _throttler.reset();
    _queue.clear();
    _latestCall = null;
    _isProcessingQueue = false;
    _latestCallId++;
    _throttler.debugLog('ConcurrentAsyncThrottler reset (mode: ${mode.name})');
  }

  /// Dispose and clean up resources.
  void dispose() {
    _throttler.dispose();
    _queue.clear();
    _latestCall = null;
    _isProcessingQueue = false;
  }
}
