// Pure Dart - no Flutter dependencies.

/// A token that can be checked for cancellation status.
///
/// Used to cooperatively cancel async operations in Dart, since
/// Dart Futures cannot be forcefully interrupted.
class CancellationToken {
  bool _isCancelled = false;

  /// Whether cancellation has been requested.
  bool get isCancelled => _isCancelled;

  /// Request cancellation.
  void cancel() {
    _isCancelled = true;
  }

  /// Throws a [CancellationException] if cancellation has been requested.
  void throwIfCancelled() {
    if (_isCancelled) {
      throw CancellationException();
    }
  }
}

/// Exception thrown when an operation is cancelled via [CancellationToken].
class CancellationException implements Exception {
  final String message;
  CancellationException([this.message = 'Operation was cancelled']);

  @override
  String toString() => 'CancellationException: $message';
}
