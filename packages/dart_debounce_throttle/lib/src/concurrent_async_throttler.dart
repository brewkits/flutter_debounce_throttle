// Pure Dart - no Flutter dependencies.
//
// Advanced async throttler with concurrency control strategies.

import 'dart:async';
import 'dart:collection';

import 'async_throttler.dart';
import 'cancellation_token.dart';
import 'concurrency_mode.dart';
import 'throttler.dart';
import 'throttler_result.dart';

/// Strategy for handling queue overflow when [ConcurrentAsyncThrottler.maxQueueSize] is reached.
enum QueueOverflowStrategy {
  /// Reject new calls when queue is full (return immediately without execution).
  dropNewest,

  /// Remove oldest queued call to make room for new one.
  dropOldest,
}

/// Advanced async throttler with concurrency control strategies.
///
/// Wraps [AsyncThrottler] with different concurrency modes:
/// - **drop** (default): Ignore new calls while busy (same as AsyncThrottler)
/// - **enqueue**: Queue calls and execute sequentially (FIFO)
/// - **replace**: Cancel current execution and start new one
/// - **keepLatest**: Keep latest call and execute after current finishes
///
/// Every call returns a [ThrottlerResult] indicating whether the callback
/// actually ran. Always check [ThrottlerResult.isDropped] before treating
/// the operation as successful:
///
/// ```dart
/// final result = await throttler.call(() async {
///   await submitOrder(orderId);
/// });
/// if (result.isDropped) {
///   showError('Request dropped — try again.');
///   return;
/// }
/// showSuccessDialog();
/// ```
///
/// **Use cases:**
/// - Chat app: `enqueue` mode to send messages in order
/// - Search: `replace` mode to cancel old queries
/// - Auto-save: `keepLatest` mode to save final version after edits
/// - Payment: `drop` mode to prevent duplicate charges (default)
///
/// **Performance:**
/// - Drop mode: Zero overhead (wraps AsyncThrottler directly)
/// - Enqueue mode: ~60 bytes per queued operation
/// - Replace/KeepLatest mode: ~40 bytes overhead
class ConcurrentAsyncThrottler {
  final AsyncThrottler _throttler;
  final ConcurrencyMode mode;

  /// Maximum queue size for enqueue mode.
  ///
  /// Null means unlimited (default for backward compatibility).
  /// Only applies to [ConcurrencyMode.enqueue].
  ///
  /// **Warning:** For network requests or memory-intensive operations,
  /// always set a reasonable limit (e.g., 10-50) to prevent OOM (Out Of Memory)
  /// if operations timeout or network is slow.
  final int? maxQueueSize;

  /// Strategy to use when [maxQueueSize] is reached in enqueue mode.
  final QueueOverflowStrategy queueOverflowStrategy;

  final Queue<_QueuedCall> _queue = Queue();
  Future<void> Function()? _latestCall;
  Completer<ThrottlerResult>? _latestCallCompleter;
  bool _isProcessingQueue = false;
  int _latestCallId = 0;
  CancellationToken? _replaceToken;

  ConcurrentAsyncThrottler({
    this.mode = ConcurrencyMode.drop,
    Duration? maxDuration,
    bool debugMode = false,
    String? name,
    bool enabled = true,
    bool resetOnError = false,
    void Function(Duration executionTime, bool executed)? onMetrics,
    void Function(Object error, StackTrace stackTrace)? onError,
    this.maxQueueSize,
    this.queueOverflowStrategy = QueueOverflowStrategy.dropNewest,
  }) : _throttler = AsyncThrottler(
          maxDuration: maxDuration,
          debugMode: debugMode,
          name: name,
          enabled: enabled,
          resetOnError: resetOnError,
          onMetrics: onMetrics,
          onError: onError,
        );

  /// Execute async operation with selected concurrency mode.
  ///
  /// Returns [ThrottlerResult.executed] if the callback ran, or
  /// [ThrottlerResult.dropped] if it was skipped due to throttle/queue limits.
  /// Always check [ThrottlerResult.isDropped] before treating the call as
  /// successful.
  Future<ThrottlerResult> call(Future<void> Function() callback) async {
    return callWithToken((_) => callback());
  }

  /// Execute async operation that provides a [CancellationToken].
  ///
  /// This is essential for [ConcurrencyMode.replace] to actually stop previous
  /// tasks from continuing their execution in the background. Check
  /// `token.isCancelled` periodically or pass it to APIs like Dio.
  ///
  /// Returns [ThrottlerResult] — check [ThrottlerResult.isDropped] before
  /// acting on any side-effects of the operation.
  ///
  /// **IMPORTANT — CancellationToken is cooperative, not preemptive.**
  ///
  /// The library signals cancellation via the token but cannot forcibly stop
  /// in-flight I/O (HTTP requests, file reads, etc.). If you do not check
  /// `token.isCancelled` inside your callback, or do not pass the token to
  /// your HTTP client (e.g. Dio's `cancelToken`), the underlying operation
  /// continues running until completion — consuming RAM and server resources.
  ///
  /// In the worst case, rapid-firing 100 calls in replace mode still sends
  /// 100 HTTP requests to the backend. Always propagate the token:
  ///
  /// ```dart
  /// searchController.callWithToken((token) async {
  ///   final result = await dio.get('/search',
  ///     cancelToken: token.asDioCancelToken(), // propagate!
  ///   );
  ///   if (token.isCancelled) return;
  ///   showResult(result.data);
  /// });
  /// ```
  Future<ThrottlerResult> callWithToken(
      Future<void> Function(CancellationToken token) callback) async {
    switch (mode) {
      case ConcurrencyMode.drop:
        // Capture lock state before the await — no other code can run between
        // this check and _throttler.call() in Dart's cooperative model.
        final wasLocked = _throttler.isLocked;
        await _throttler.call(() => callback(CancellationToken()));
        return wasLocked
            ? ThrottlerResult.dropped()
            : ThrottlerResult.executed();

      case ConcurrencyMode.enqueue:
        return _enqueueCall(() => callback(CancellationToken()));

      case ConcurrencyMode.replace:
        return _replaceCall(callback);

      case ConcurrencyMode.keepLatest:
        return _keepLatestCall(() => callback(CancellationToken()));
    }
  }

  /// Enqueue mode: Queue calls and execute sequentially (FIFO).
  Future<ThrottlerResult> _enqueueCall(Future<void> Function() callback) async {
    final completer = Completer<ThrottlerResult>();
    final queuedCall = _QueuedCall(callback, completer);

    if (maxQueueSize != null && _queue.length >= maxQueueSize!) {
      switch (queueOverflowStrategy) {
        case QueueOverflowStrategy.dropOldest:
          final dropped = _queue.removeFirst();
          dropped.completer.complete(ThrottlerResult.dropped());
          _throttler.debugLog(
            'Queue full ($maxQueueSize), dropped oldest (dropOldest strategy)',
          );
          break;
        case QueueOverflowStrategy.dropNewest:
          _throttler.debugLog(
            'Queue full ($maxQueueSize), rejecting new call (dropNewest strategy)',
          );
          completer.complete(ThrottlerResult.dropped());
          return completer.future;
      }
    }

    _queue.add(queuedCall);
    _throttler.debugLog(
      'Enqueued call (queue size: ${_queue.length}, processing: $_isProcessingQueue)',
    );

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
      final queuedCall = _queue.removeFirst();
      _throttler
          .debugLog('Processing queued item (${_queue.length} remaining)');

      try {
        await _throttler.call(queuedCall.callback);
        queuedCall.completer.complete(ThrottlerResult.executed());
      } catch (e, stack) {
        _throttler.debugLog('Queue processing error: $e');
        queuedCall.completer.completeError(e, stack);
        // Continue processing queue even if one item fails.
      }
    }

    _isProcessingQueue = false;
    _throttler.debugLog('Queue processing complete');
  }

  /// Replace mode: Cancel current execution and start new one.
  Future<ThrottlerResult> _replaceCall(
      Future<void> Function(CancellationToken) callback) async {
    final currentCallId = ++_latestCallId;
    _throttler.debugLog('Replace mode: new call ID $currentCallId');

    _replaceToken?.cancel();
    _replaceToken = CancellationToken();
    final token = _replaceToken!;

    _throttler.reset();

    // Track whether the callback body actually ran.
    var ran = false;
    await _throttler.call(() async {
      if (currentCallId != _latestCallId || token.isCancelled) {
        _throttler.debugLog(
          'Replace mode: call $currentCallId cancelled before execution',
        );
        return;
      }

      try {
        ran = true;
        await callback(token);
      } on CancellationException {
        ran = false;
        _throttler.debugLog(
          'Replace mode: call $currentCallId aborted via CancellationException',
        );
      }

      if (currentCallId != _latestCallId || token.isCancelled) {
        _throttler.debugLog(
          'Replace mode: call $currentCallId result ignored (replaced during execution)',
        );
      }
    });

    return ran ? ThrottlerResult.executed() : ThrottlerResult.dropped();
  }

  /// Keep Latest mode: Keep latest call and execute after current finishes.
  ///
  /// When the throttler is busy, the new call is saved and its future is
  /// suspended until the current one finishes. If yet another call arrives
  /// before that, the saved call is dropped ([ThrottlerResult.dropped]).
  Future<ThrottlerResult> _keepLatestCall(
      Future<void> Function() callback) async {
    if (_throttler.isLocked) {
      // A new call supersedes the previously saved one — drop it.
      _latestCallCompleter?.complete(ThrottlerResult.dropped());
      _latestCall = callback;
      _latestCallCompleter = Completer<ThrottlerResult>();
      _throttler.debugLog('Kept latest call (will execute after current)');
      return _latestCallCompleter!.future;
    }

    try {
      await _throttler.call(callback);
      return ThrottlerResult.executed();
    } finally {
      if (_latestCall != null) {
        final pendingCall = _latestCall!;
        final pendingCompleter = _latestCallCompleter;
        _latestCall = null;
        _latestCallCompleter = null;
        _throttler.debugLog('Executing pending latest call');
        // Recursive call — handles any new "latest" that arrived during execution.
        final result = await _keepLatestCall(pendingCall);
        pendingCompleter?.complete(result);
      }
    }
  }

  /// Wraps callback for fire-and-forget builders (e.g. button `onTap`).
  ///
  /// The [ThrottlerResult] is intentionally discarded here. For use cases
  /// where you need to react to drops, call [call] directly and await it.
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

  /// Reset throttler state and complete all pending operations as dropped.
  void reset() {
    _throttler.reset();
    for (final item in _queue) {
      item.completer.complete(ThrottlerResult.dropped());
    }
    _queue.clear();
    _latestCallCompleter?.complete(ThrottlerResult.dropped());
    _latestCallCompleter = null;
    _latestCall = null;
    _isProcessingQueue = false;
    _latestCallId++;
    _replaceToken?.cancel();
    _replaceToken = null;
    _throttler.debugLog('ConcurrentAsyncThrottler reset (mode: ${mode.name})');
  }

  /// Dispose and complete all pending operations as dropped.
  void dispose() {
    _throttler.dispose();
    for (final item in _queue) {
      item.completer.complete(ThrottlerResult.dropped());
    }
    _queue.clear();
    _latestCallCompleter?.complete(ThrottlerResult.dropped());
    _latestCallCompleter = null;
    _latestCall = null;
    _isProcessingQueue = false;
    _replaceToken?.cancel();
    _replaceToken = null;
  }
}

/// Internal class to hold queued callback and its completer.
class _QueuedCall {
  final Future<void> Function() callback;
  final Completer<ThrottlerResult> completer;

  _QueuedCall(this.callback, this.completer);
}
