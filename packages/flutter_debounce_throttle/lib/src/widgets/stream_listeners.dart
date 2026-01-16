// Stream listener widgets with auto-cancel and lifecycle safety.

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_debounce_throttle_core/flutter_debounce_throttle_core.dart';

/// Safe stream listener with auto-cancel on dispose.
///
/// Automatically cancels subscription when widget unmounts.
/// Checks `mounted` before calling callbacks.
///
/// **Example:**
/// ```dart
/// StreamSafeListener<int>(
///   stream: myStream,
///   onData: (data) => setState(() => _value = data),
///   onError: (error) => showError(error),
///   child: Text('Value: $_value'),
/// )
/// ```
class StreamSafeListener<T> extends StatefulWidget {
  final Stream<T> stream;
  final void Function(T data) onData;
  final void Function(Object error, StackTrace stackTrace)? onError;
  final VoidCallback? onDone;
  final Widget child;

  const StreamSafeListener({
    super.key,
    required this.stream,
    required this.onData,
    this.onError,
    this.onDone,
    required this.child,
  });

  @override
  State<StreamSafeListener<T>> createState() => _StreamSafeListenerState<T>();
}

class _StreamSafeListenerState<T> extends State<StreamSafeListener<T>> {
  StreamSubscription<T>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void didUpdateWidget(StreamSafeListener<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stream != widget.stream) {
      _unsubscribe();
      _subscribe();
    }
  }

  void _subscribe() {
    _subscription = widget.stream.listen(
      (data) {
        if (mounted) {
          widget.onData(data);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (mounted) {
          widget.onError?.call(error, stackTrace);
        }
      },
      onDone: () {
        if (mounted) {
          widget.onDone?.call();
        }
      },
    );
  }

  void _unsubscribe() {
    _subscription?.cancel();
    _subscription = null;
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Stream listener with debounce for high-frequency events.
///
/// Debounces stream events before calling onData.
/// Useful for search input streams, sensor data, etc.
///
/// **Example:**
/// ```dart
/// StreamDebounceListener<String>(
///   stream: searchQueryStream,
///   duration: Duration(milliseconds: 300),
///   onData: (query) async {
///     final results = await searchApi(query);
///     if (mounted) setState(() => _results = results);
///   },
///   child: SearchResults(_results),
/// )
/// ```
class StreamDebounceListener<T> extends StatefulWidget {
  final Stream<T> stream;
  final void Function(T data) onData;
  final void Function(Object error, StackTrace stackTrace)? onError;
  final VoidCallback? onDone;
  final Duration? duration;
  final Widget child;

  const StreamDebounceListener({
    super.key,
    required this.stream,
    required this.onData,
    this.onError,
    this.onDone,
    this.duration,
    required this.child,
  });

  @override
  State<StreamDebounceListener<T>> createState() =>
      _StreamDebounceListenerState<T>();
}

class _StreamDebounceListenerState<T> extends State<StreamDebounceListener<T>> {
  StreamSubscription<T>? _subscription;
  late final Debouncer _debouncer;
  T? _latestData;

  @override
  void initState() {
    super.initState();
    _debouncer = Debouncer(duration: widget.duration);
    _subscribe();
  }

  @override
  void didUpdateWidget(StreamDebounceListener<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stream != widget.stream) {
      _unsubscribe();
      _subscribe();
    }
  }

  void _subscribe() {
    _subscription = widget.stream.listen(
      (data) {
        _latestData = data;
        _debouncer.call(() {
          if (mounted && _latestData != null) {
            widget.onData(_latestData as T);
          }
        });
      },
      onError: (Object error, StackTrace stackTrace) {
        if (mounted) {
          widget.onError?.call(error, stackTrace);
        }
      },
      onDone: () {
        if (mounted) {
          widget.onDone?.call();
        }
      },
    );
  }

  void _unsubscribe() {
    _subscription?.cancel();
    _subscription = null;
  }

  @override
  void dispose() {
    _unsubscribe();
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Stream listener with throttle for high-frequency events.
///
/// Throttles stream events before calling onData.
/// Useful for scroll events, mouse move, etc.
///
/// **Example:**
/// ```dart
/// StreamThrottleListener<ScrollNotification>(
///   stream: scrollStream,
///   duration: Duration(milliseconds: 16), // ~60fps
///   onData: (notification) {
///     updateStickyHeader(notification.metrics.pixels);
///   },
///   child: ListView(...),
/// )
/// ```
class StreamThrottleListener<T> extends StatefulWidget {
  final Stream<T> stream;
  final void Function(T data) onData;
  final void Function(Object error, StackTrace stackTrace)? onError;
  final VoidCallback? onDone;
  final Duration? duration;
  final Widget child;

  const StreamThrottleListener({
    super.key,
    required this.stream,
    required this.onData,
    this.onError,
    this.onDone,
    this.duration,
    required this.child,
  });

  @override
  State<StreamThrottleListener<T>> createState() =>
      _StreamThrottleListenerState<T>();
}

class _StreamThrottleListenerState<T> extends State<StreamThrottleListener<T>> {
  StreamSubscription<T>? _subscription;
  late final Throttler _throttler;

  @override
  void initState() {
    super.initState();
    _throttler = Throttler(duration: widget.duration);
    _subscribe();
  }

  @override
  void didUpdateWidget(StreamThrottleListener<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stream != widget.stream) {
      _unsubscribe();
      _subscribe();
    }
  }

  void _subscribe() {
    _subscription = widget.stream.listen(
      (data) {
        _throttler.call(() {
          if (mounted) {
            widget.onData(data);
          }
        });
      },
      onError: (Object error, StackTrace stackTrace) {
        if (mounted) {
          widget.onError?.call(error, stackTrace);
        }
      },
      onDone: () {
        if (mounted) {
          widget.onDone?.call();
        }
      },
    );
  }

  void _unsubscribe() {
    _subscription?.cancel();
    _subscription = null;
  }

  @override
  void dispose() {
    _unsubscribe();
    _throttler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
