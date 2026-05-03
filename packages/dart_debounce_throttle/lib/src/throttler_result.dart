// Pure Dart - no Flutter dependencies.

/// Result of a [ConcurrentAsyncThrottler] call.
///
/// Distinguishes between a callback that actually ran and one that was dropped
/// (queue overflow, throttle lock, or cancellation via [CancellationException]).
///
/// **Why this matters:** Without an explicit result, `await throttler.call(...)`
/// resolves with `void` even when the callback was never invoked — causing
/// silent data corruption where the app behaves as if the operation succeeded.
///
/// Use [when] for exhaustive handling (both branches required at compile time):
/// ```dart
/// final result = await throttler.call(() async {
///   await submitOrder(orderId);
/// });
///
/// result.when(
///   onExecuted: () => showSuccessDialog(),
///   onDropped: () => showError('Server busy — please try again.'),
/// );
/// ```
///
/// Use [whenExecuted] / [whenDropped] for fluent side-effects:
/// ```dart
/// (await throttler.call(() async => submitOrder(orderId)))
///   .whenExecuted(() => emit(OrderSuccess()))
///   .whenDropped(() => emit(OrderDropped()));
/// ```
class ThrottlerResult {
  /// Whether the callback ran to completion.
  final bool isExecuted;

  const ThrottlerResult._({required this.isExecuted});

  /// The callback ran to completion.
  const ThrottlerResult.executed() : this._(isExecuted: true);

  /// The callback was not invoked.
  ///
  /// Causes:
  /// - Queue full (`enqueue` mode with [ConcurrentAsyncThrottler.maxQueueSize])
  /// - Throttler locked (`drop` mode)
  /// - Call cancelled before or during execution (`replace` mode)
  /// - Call superseded by a newer call (`keepLatest` mode)
  const ThrottlerResult.dropped() : this._(isExecuted: false);

  /// Whether the callback did NOT run. Inverse of [isExecuted].
  bool get isDropped => !isExecuted;

  /// Exhaustive pattern match — both branches are required by the compiler.
  ///
  /// Preferred over `if (result.isDropped)` because the compiler rejects
  /// code that silently ignores the dropped branch.
  ///
  /// ```dart
  /// result.when(
  ///   onExecuted: () => emit(SubmitSuccess()),
  ///   onDropped:  () => emit(SubmitDropped('Try again')),
  /// );
  /// ```
  R when<R>({
    required R Function() onExecuted,
    required R Function() onDropped,
  }) =>
      isExecuted ? onExecuted() : onDropped();

  /// Run [action] only if the callback was executed. Returns `this` for chaining.
  ///
  /// ```dart
  /// (await throttler.call(() async => save()))
  ///   .whenExecuted(() => showToast('Saved'))
  ///   .whenDropped(() => showToast('Busy — not saved'));
  /// ```
  ThrottlerResult whenExecuted(void Function() action) {
    if (isExecuted) action();
    return this;
  }

  /// Run [action] only if the callback was dropped. Returns `this` for chaining.
  ThrottlerResult whenDropped(void Function() action) {
    if (isDropped) action();
    return this;
  }

  @override
  String toString() =>
      isExecuted ? 'ThrottlerResult.executed' : 'ThrottlerResult.dropped';
}
