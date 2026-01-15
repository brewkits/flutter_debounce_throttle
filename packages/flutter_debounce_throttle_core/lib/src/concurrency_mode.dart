// Pure Dart - no Flutter dependencies.
//
// Execution strategy for concurrent async operations.

/// Execution strategy for concurrent async operations.
///
/// Determines how [ConcurrentAsyncThrottler] handles multiple async calls
/// when the throttler is busy processing a previous operation.
///
/// **Example usage:**
/// ```dart
/// // Sequential execution - all calls execute in order
/// final throttler = ConcurrentAsyncThrottler(
///   mode: ConcurrencyMode.enqueue,
///   maxDuration: Duration(seconds: 30),
/// );
///
/// // User clicks button 3 times rapidly
/// throttler.call(() async => await submitOrder(1)); // Executes immediately
/// throttler.call(() async => await submitOrder(2)); // Queued
/// throttler.call(() async => await submitOrder(3)); // Queued
/// // All 3 orders will be submitted, one after another
/// ```
///
/// See also:
/// - [ConcurrentAsyncThrottler] - Controller that uses this mode
/// - [AsyncThrottler] - Simple async throttler (drop mode only)
enum ConcurrencyMode {
  /// **Drop Mode** (Default)
  ///
  /// Ignores new calls while a previous call is executing.
  ///
  /// **Behavior:**
  /// - First call executes immediately
  /// - Subsequent calls are dropped until first completes
  /// - Most memory efficient
  ///
  /// **Use cases:**
  /// - Button clicks where only first action matters
  /// - Operations that shouldn't be repeated
  /// - When duplicate actions are mistakes
  ///
  /// **Example:**
  /// ```dart
  /// User clicks: ▼     ▼   ▼▼▼
  /// Executes:    ✓     X   X X
  ///              |<-busy->|
  /// ```
  ///
  /// **Real-world scenario:**
  /// Payment submission button - only first click should charge customer.
  drop,

  /// **Enqueue Mode**
  ///
  /// Queues new calls and executes them sequentially.
  ///
  /// **Behavior:**
  /// - First call executes immediately
  /// - Subsequent calls are added to queue
  /// - Queue is processed one by one (FIFO)
  /// - All calls eventually execute
  ///
  /// **Use cases:**
  /// - Chat message sending (preserve order)
  /// - Sequential API calls (dependencies)
  /// - Operations that must all execute
  /// - Analytics events (no data loss)
  ///
  /// **Example:**
  /// ```dart
  /// User clicks: ▼     ▼     ▼
  /// Queue:       [1]   [1,2] [1,2,3]
  /// Executes:    1 → 2 → 3
  /// ```
  ///
  /// **Real-world scenario:**
  /// Chat app - user sends 3 messages rapidly, all must be sent in order.
  ///
  /// **Warning:** Queue can grow if calls are added faster than processed.
  enqueue,

  /// **Replace Mode**
  ///
  /// Cancels current execution and starts new one.
  ///
  /// **Behavior:**
  /// - First call starts executing
  /// - New call cancels first (if cancellable)
  /// - Latest call always executes
  /// - Previous calls never complete
  ///
  /// **Use cases:**
  /// - Search queries (only latest query matters)
  /// - Real-time preview updates
  /// - Operations where latest data wins
  ///
  /// **Example:**
  /// ```dart
  /// User clicks: ▼       ▼       ▼
  /// Executes:    1       X       3
  ///              (start) (cancel)(start)
  /// ```
  ///
  /// **Real-world scenario:**
  /// Product filter - user changes filter rapidly, only last filter applies.
  replace,

  /// **Keep Latest Mode**
  ///
  /// Keeps track of latest call and executes it after current finishes.
  ///
  /// **Behavior:**
  /// - First call executes fully
  /// - New calls replace pending call (only latest is kept)
  /// - After current completes, executes latest pending
  /// - Maximum of 2 executions (current + latest)
  ///
  /// **Use cases:**
  /// - Form auto-save (save latest after current save completes)
  /// - Settings updates (apply latest setting)
  /// - Data sync (sync latest data)
  ///
  /// **Example:**
  /// ```dart
  /// User clicks: ▼   ▼   ▼   ▼
  /// Pending:     1   1   1   1
  /// Latest:      -   2   3   4
  /// Executes:    1 completes → 4 executes
  /// ```
  ///
  /// **Real-world scenario:**
  /// Auto-save document - user types rapidly, save current draft, then save
  /// final version after typing stops (ignore intermediate saves).
  keepLatest,
}

/// Extension methods for [ConcurrencyMode] to provide readable descriptions.
extension ConcurrencyModeExtension on ConcurrencyMode {
  /// Human-readable name of the concurrency mode.
  String get displayName {
    switch (this) {
      case ConcurrencyMode.drop:
        return 'Drop';
      case ConcurrencyMode.enqueue:
        return 'Enqueue';
      case ConcurrencyMode.replace:
        return 'Replace';
      case ConcurrencyMode.keepLatest:
        return 'Keep Latest';
    }
  }

  /// Short description of the concurrency mode behavior.
  String get description {
    switch (this) {
      case ConcurrencyMode.drop:
        return 'Ignore new calls while busy';
      case ConcurrencyMode.enqueue:
        return 'Queue calls and execute sequentially';
      case ConcurrencyMode.replace:
        return 'Cancel current and start new';
      case ConcurrencyMode.keepLatest:
        return 'Keep latest call and execute after current';
    }
  }

  /// Whether this mode requires a queue to store pending calls.
  bool get requiresQueue => this == ConcurrencyMode.enqueue;

  /// Whether this mode can have pending calls.
  bool get supportsPending =>
      this == ConcurrencyMode.enqueue || this == ConcurrencyMode.keepLatest;
}
