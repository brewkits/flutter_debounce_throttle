//import 'dart:async';

/// Extension methods for Stream debouncing and throttling.
///
/// Provides rxdart-style extensions for applying debounce and throttle
/// operations directly to streams.
///
/// **Example:**
/// ```dart
/// final searchStream = searchController.stream
///   .debounce(Duration(milliseconds: 300))
///   .listen((query) => performSearch(query));
///
/// final clickStream = buttonController.stream
///   .throttle(Duration(milliseconds: 500))
///   .listen((event) => handleClick(event));
/// ```
extension StreamDebounceThrottleExtension<T> on Stream<T> {
  /// Debounces the stream events.
  ///
  /// Only emits an event when [duration] has passed without another event.
  /// Useful for search inputs, form validation, etc.
  ///
  /// **Example:**
  /// ```dart
  /// searchController.stream
  ///   .debounce(Duration(milliseconds: 300))
  ///   .listen((query) {
  ///     print('Searching for: $query');
  ///     performSearch(query);
  ///   });
  /// ```
  Stream<T> debounce(Duration duration) {
    StreamController<T>? controller;
    StreamSubscription<T>? subscription;
    Timer? debounceTimer;

    void onListen() {
      subscription = listen(
        (data) {
          debounceTimer?.cancel();
          debounceTimer = Timer(duration, () {
            controller?.add(data);
          });
        },
        onError: controller?.addError,
        onDone: () {
          debounceTimer?.cancel();
          controller?.close();
        },
        cancelOnError: false,
      );
    }

    void onCancel() {
      debounceTimer?.cancel();
      subscription?.cancel();
      debounceTimer = null;
      subscription = null;
    }

    if (isBroadcast) {
      controller = StreamController<T>.broadcast(
        onListen: onListen,
        onCancel: onCancel,
        sync: true,
      );
    } else {
      controller = StreamController<T>(
        onListen: onListen,
        onPause: ([Future<void>? resumeSignal]) =>
            subscription?.pause(resumeSignal),
        onResume: () => subscription?.resume(),
        onCancel: onCancel,
        sync: true,
      );
    }

    return controller.stream;
  }

  /// Throttles the stream events.
  ///
  /// Emits the first event immediately, then ignores subsequent events for
  /// [duration]. Useful for button clicks, scroll events, etc.
  ///
  /// **Example:**
  /// ```dart
  /// buttonController.stream
  ///   .throttle(Duration(milliseconds: 500))
  ///   .listen((event) {
  ///     print('Button clicked');
  ///     handleClick(event);
  ///   });
  /// ```
  Stream<T> throttle(Duration duration) {
    StreamController<T>? controller;
    StreamSubscription<T>? subscription;
    Timer? throttleTimer;
    var isThrottled = false;

    void onListen() {
      subscription = listen(
        (data) {
          if (!isThrottled) {
            controller?.add(data);
            isThrottled = true;
            throttleTimer = Timer(duration, () {
              isThrottled = false;
            });
          }
        },
        onError: controller?.addError,
        onDone: () {
          throttleTimer?.cancel();
          controller?.close();
        },
        cancelOnError: false,
      );
    }

    void onCancel() {
      throttleTimer?.cancel();
      subscription?.cancel();
      throttleTimer = null;
      subscription = null;
    }

    if (isBroadcast) {
      controller = StreamController<T>.broadcast(
        onListen: onListen,
        onCancel: onCancel,
        sync: true,
      );
    } else {
      controller = StreamController<T>(
        onListen: onListen,
        onPause: ([Future<void>? resumeSignal]) =>
            subscription?.pause(resumeSignal),
        onResume: () => subscription?.resume(),
        onCancel: onCancel,
        sync: true,
      );
    }

    return controller.stream;
  }
}
