// lib/src/flutter/widgets/callback_widgets.dart
//
// Flutter widget wrappers for throttle and debounce operations.

import 'package:flutter/material.dart';

import '../../core/async_debouncer.dart';
import '../../core/async_throttler.dart';
import '../../core/concurrent_async_throttler.dart';
import '../../core/concurrency_mode.dart';
import '../../core/debouncer.dart';
import '../../core/throttler.dart';

// Re-export VoidCallback from throttler for convenience
export '../../core/throttler.dart' show VoidCallback;

/// Throttled callback wrapper. Used by BaseButton. Prefer ThrottledInkWell for tap events.
class ThrottledCallback extends StatefulWidget {
  final VoidCallback? onPressed;
  final Duration? duration;
  final Widget Function(BuildContext context, VoidCallback? throttledCallback)
      builder;

  const ThrottledCallback({
    super.key,
    required this.onPressed,
    required this.builder,
    this.duration,
  });

  @override
  State<ThrottledCallback> createState() => _ThrottledCallbackState();
}

class _ThrottledCallbackState extends State<ThrottledCallback> {
  late final Throttler _throttler;

  @override
  void initState() {
    super.initState();
    _throttler = Throttler(duration: widget.duration);
  }

  @override
  void dispose() {
    _throttler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _throttler.wrap(widget.onPressed));
  }
}

/// Universal throttle builder that works with ANY widget.
///
/// **Usage:**
/// ```dart
/// ThrottledBuilder(
///   duration: Duration(milliseconds: 500),
///   builder: (context, throttle) {
///     return InkWell(
///       onTap: throttle(() => handleTap()),
///       onLongPress: throttle(() => handleLongPress()),
///       child: MyWidget(),
///     );
///   },
/// )
/// ```
class ThrottledBuilder extends StatefulWidget {
  final Duration? duration;
  final Widget Function(
    BuildContext context,
    VoidCallback? Function(VoidCallback? action) throttle,
  ) builder;

  const ThrottledBuilder({
    super.key,
    required this.builder,
    this.duration,
  });

  @override
  State<ThrottledBuilder> createState() => _ThrottledBuilderState();
}

class _ThrottledBuilderState extends State<ThrottledBuilder> {
  late Throttler _throttler;

  @override
  void initState() {
    super.initState();
    _throttler = Throttler(duration: widget.duration);
  }

  @override
  void didUpdateWidget(ThrottledBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _throttler.dispose();
      _throttler = Throttler(duration: widget.duration);
    }
  }

  @override
  void dispose() {
    _throttler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _throttler.wrap);
  }
}

/// Universal debounce builder that works with ANY widget.
///
/// **Usage:**
/// ```dart
/// DebouncedBuilder(
///   duration: Duration(milliseconds: 300),
///   builder: (context, debounce) {
///     return Slider(
///       onChanged: (value) => debounce(() => saveValue(value)),
///     );
///   },
/// )
/// ```
class DebouncedBuilder extends StatefulWidget {
  final Duration? duration;
  final Widget Function(
    BuildContext context,
    VoidCallback? Function(VoidCallback? action) debounce,
  ) builder;

  const DebouncedBuilder({
    super.key,
    required this.builder,
    this.duration,
  });

  @override
  State<DebouncedBuilder> createState() => _DebouncedBuilderState();
}

class _DebouncedBuilderState extends State<DebouncedBuilder> {
  late Debouncer _debouncer;

  @override
  void initState() {
    super.initState();
    _debouncer = Debouncer(duration: widget.duration);
  }

  @override
  void didUpdateWidget(DebouncedBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _debouncer.dispose();
      _debouncer = Debouncer(duration: widget.duration);
    }
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _debouncer.wrap);
  }
}

/// Universal async throttle builder that works with ANY widget.
///
/// **⚠️ Always check `mounted` before using BuildContext after await!**
///
/// **Usage:**
/// ```dart
/// AsyncThrottledBuilder(
///   maxDuration: Duration(seconds: 15),
///   builder: (context, throttle) {
///     return ElevatedButton(
///       onPressed: throttle(() async {
///         await api.submit();
///         if (!mounted) return;
///         Navigator.pop(context);
///       }),
///       child: Text('Submit'),
///     );
///   },
/// )
/// ```
class AsyncThrottledBuilder extends StatefulWidget {
  final Duration? maxDuration;
  final Widget Function(
    BuildContext context,
    VoidCallback? Function(Future<void> Function()? action) throttle,
  ) builder;

  const AsyncThrottledBuilder({
    super.key,
    required this.builder,
    this.maxDuration,
  });

  @override
  State<AsyncThrottledBuilder> createState() => _AsyncThrottledBuilderState();
}

class _AsyncThrottledBuilderState extends State<AsyncThrottledBuilder> {
  late AsyncThrottler _throttler;

  @override
  void initState() {
    super.initState();
    _throttler = AsyncThrottler(maxDuration: widget.maxDuration);
  }

  @override
  void didUpdateWidget(AsyncThrottledBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.maxDuration != widget.maxDuration) {
      _throttler.dispose();
      _throttler = AsyncThrottler(maxDuration: widget.maxDuration);
    }
  }

  @override
  void dispose() {
    _throttler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _throttler.wrap);
  }
}

/// Universal async debounce builder that works with ANY widget.
///
/// **⚠️ Always check `mounted` before setState after await!**
///
/// **Usage:**
/// ```dart
/// AsyncDebouncedBuilder(
///   duration: Duration(milliseconds: 300),
///   builder: (context, debounce) {
///     return TextField(
///       onChanged: (text) => debounce(() async {
///         final results = await searchApi(text);
///         if (!mounted) return;
///         setState(() => _results = results);
///       }),
///     );
///   },
/// )
/// ```
class AsyncDebouncedBuilder extends StatefulWidget {
  final Duration? duration;
  final Widget Function(
    BuildContext context,
    void Function(Future<void> Function() action) debounce,
  ) builder;

  const AsyncDebouncedBuilder({
    super.key,
    required this.builder,
    this.duration,
  });

  @override
  State<AsyncDebouncedBuilder> createState() => _AsyncDebouncedBuilderState();
}

class _AsyncDebouncedBuilderState extends State<AsyncDebouncedBuilder> {
  late AsyncDebouncer _debouncer;

  @override
  void initState() {
    super.initState();
    _debouncer = AsyncDebouncer(duration: widget.duration);
  }

  @override
  void didUpdateWidget(AsyncDebouncedBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _debouncer.dispose();
      _debouncer = AsyncDebouncer(duration: widget.duration);
    }
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  void _wrapDebounce(Future<void> Function() action) {
    _debouncer.run(action);
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _wrapDebounce);
  }
}

/// Async debounced callback wrapper with auto-cancel for search/autocomplete.
class AsyncDebouncedCallback extends StatefulWidget {
  final void Function(String)? onChanged;
  final Duration? duration;
  final Widget Function(
      BuildContext context, void Function(String)? debouncedCallback) builder;

  const AsyncDebouncedCallback({
    super.key,
    required this.onChanged,
    required this.builder,
    this.duration,
  });

  @override
  State<AsyncDebouncedCallback> createState() => _AsyncDebouncedCallbackState();
}

class _AsyncDebouncedCallbackState extends State<AsyncDebouncedCallback> {
  late final AsyncDebouncer _debouncer;

  @override
  void initState() {
    super.initState();
    _debouncer = AsyncDebouncer(duration: widget.duration);
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onChanged == null) {
      return widget.builder(context, null);
    }

    return widget.builder(context, (text) {
      _debouncer.run(() async {
        widget.onChanged!(text);
      });
    });
  }
}

/// Enhanced async debounced callback with loading state and error handling.
///
/// **Features:**
/// - Auto loading state management
/// - Built-in error handling
/// - Safe setState (auto-checks mounted)
/// - Auto-cancels old API calls
/// - Generic type support
///
/// **Example:**
/// ```dart
/// AsyncDebouncedCallbackBuilder<List<User>>(
///   onChanged: (text) async => await searchApi(text),
///   onSuccess: (results) => setState(() => _searchResults = results),
///   onError: (error, stack) => showSnackbar('Error: $error'),
///   builder: (context, callback, isLoading) => TextField(
///     onChanged: callback,
///     decoration: InputDecoration(
///       suffixIcon: isLoading ? CircularProgressIndicator() : Icon(Icons.search),
///     ),
///   ),
/// )
/// ```
class AsyncDebouncedCallbackBuilder<T> extends StatefulWidget {
  final Future<T> Function(String value)? onChanged;
  final void Function(T result)? onSuccess;
  final void Function(Object error, StackTrace stackTrace)? onError;
  final Duration? duration;
  final Widget Function(
    BuildContext context,
    void Function(String)? callback,
    bool isLoading,
  ) builder;

  const AsyncDebouncedCallbackBuilder({
    super.key,
    required this.onChanged,
    required this.builder,
    this.onSuccess,
    this.onError,
    this.duration,
  });

  @override
  State<AsyncDebouncedCallbackBuilder<T>> createState() =>
      _AsyncDebouncedCallbackBuilderState<T>();
}

class _AsyncDebouncedCallbackBuilderState<T>
    extends State<AsyncDebouncedCallbackBuilder<T>> {
  late final AsyncDebouncer _debouncer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _debouncer = AsyncDebouncer(duration: widget.duration);
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  Future<void> _handleChanged(String text) async {
    if (widget.onChanged == null) return;

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final result = await _debouncer.run(() async {
        return await widget.onChanged!(text);
      });

      if (result != null) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        if (mounted && widget.onSuccess != null) {
          widget.onSuccess!(result);
        }
      }
    } catch (error, stackTrace) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      widget.onError?.call(error, stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(
      context,
      widget.onChanged == null ? null : _handleChanged,
      _isLoading,
    );
  }
}

/// Async callback wrapper. Locks until Future completes (for form submit).
class AsyncThrottledCallback extends StatefulWidget {
  final Future<void> Function()? onPressed;
  final Duration? maxDuration;
  final Widget Function(
      BuildContext context, VoidCallback? asyncThrottledCallback) builder;

  const AsyncThrottledCallback({
    super.key,
    required this.onPressed,
    required this.builder,
    this.maxDuration,
  });

  @override
  State<AsyncThrottledCallback> createState() => _AsyncThrottledCallbackState();
}

class _AsyncThrottledCallbackState extends State<AsyncThrottledCallback> {
  late final AsyncThrottler _throttler;

  @override
  void initState() {
    super.initState();
    _throttler = AsyncThrottler(maxDuration: widget.maxDuration);
  }

  @override
  void dispose() {
    _throttler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _throttler.wrap(widget.onPressed));
  }
}

/// Enhanced async callback wrapper with loading state and error handling.
///
/// **Features:**
/// - Auto loading state management
/// - Built-in error handling
/// - Safe setState (auto-checks mounted)
/// - Prevents duplicate submissions
///
/// **Example:**
/// ```dart
/// AsyncThrottledCallbackBuilder(
///   onPressed: () async {
///     await api.submitForm();
///     Navigator.pop(context);
///   },
///   onError: (error, stack) => showSnackbar('Error: $error'),
///   builder: (context, callback, isLoading) => ElevatedButton(
///     onPressed: isLoading ? null : callback,
///     child: isLoading ? CircularProgressIndicator() : Text('Submit'),
///   ),
/// )
/// ```
class AsyncThrottledCallbackBuilder extends StatefulWidget {
  final Future<void> Function()? onPressed;
  final void Function(Object error, StackTrace stackTrace)? onError;
  final VoidCallback? onSuccess;
  final Duration? maxDuration;
  final Widget Function(
    BuildContext context,
    VoidCallback? callback,
    bool isLoading,
  ) builder;

  const AsyncThrottledCallbackBuilder({
    super.key,
    required this.onPressed,
    required this.builder,
    this.onError,
    this.onSuccess,
    this.maxDuration,
  });

  @override
  State<AsyncThrottledCallbackBuilder> createState() =>
      _AsyncThrottledCallbackBuilderState();
}

class _AsyncThrottledCallbackBuilderState
    extends State<AsyncThrottledCallbackBuilder> {
  late final AsyncThrottler _throttler;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _throttler = AsyncThrottler(maxDuration: widget.maxDuration);
  }

  @override
  void dispose() {
    _throttler.dispose();
    super.dispose();
  }

  Future<void> _handlePress() async {
    if (_isLoading || widget.onPressed == null) return;

    setState(() => _isLoading = true);

    try {
      await _throttler.call(() async {
        await widget.onPressed!();
      });

      if (mounted) {
        setState(() => _isLoading = false);
      }
      widget.onSuccess?.call();
    } catch (error, stackTrace) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      widget.onError?.call(error, stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(
      context,
      widget.onPressed == null ? null : _handlePress,
      _isLoading,
    );
  }
}

/// Advanced async throttled callback builder with concurrency control.
///
/// **Concurrency modes:**
/// - `drop`: Ignore new calls while busy (default)
/// - `enqueue`: Queue calls and execute sequentially
/// - `replace`: Cancel current and start new
/// - `keepLatest`: Execute current + latest only
///
/// **Example:**
/// ```dart
/// ConcurrentAsyncThrottledBuilder(
///   mode: ConcurrencyMode.enqueue,
///   onPressed: () async => await api.sendMessage(text),
///   builder: (context, callback, isLoading, pendingCount) {
///     return ElevatedButton(
///       onPressed: callback,
///       child: Text('Send ($pendingCount pending)'),
///     );
///   },
/// )
/// ```
class ConcurrentAsyncThrottledBuilder extends StatefulWidget {
  final ConcurrencyMode mode;
  final Future<void> Function()? onPressed;
  final void Function(Object error, StackTrace stackTrace)? onError;
  final VoidCallback? onSuccess;
  final Duration? maxDuration;
  final bool debugMode;
  final String? name;
  final Widget Function(
    BuildContext context,
    VoidCallback? callback,
    bool isLoading,
    int pendingCount,
  ) builder;

  const ConcurrentAsyncThrottledBuilder({
    super.key,
    this.mode = ConcurrencyMode.drop,
    required this.onPressed,
    required this.builder,
    this.onError,
    this.onSuccess,
    this.maxDuration,
    this.debugMode = false,
    this.name,
  });

  @override
  State<ConcurrentAsyncThrottledBuilder> createState() =>
      _ConcurrentAsyncThrottledBuilderState();
}

class _ConcurrentAsyncThrottledBuilderState
    extends State<ConcurrentAsyncThrottledBuilder> {
  late final ConcurrentAsyncThrottler _throttler;
  bool _isLoading = false;
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _throttler = ConcurrentAsyncThrottler(
      mode: widget.mode,
      maxDuration: widget.maxDuration,
      debugMode: widget.debugMode,
      name: widget.name,
    );
  }

  @override
  void dispose() {
    _throttler.dispose();
    super.dispose();
  }

  Future<void> _handlePress() async {
    if (widget.onPressed == null) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
        _pendingCount = _throttler.pendingCount;
      });
    }

    try {
      await _throttler.call(() async {
        await widget.onPressed!();
      });

      if (mounted) {
        setState(() {
          _isLoading = _throttler.isLocked;
          _pendingCount = _throttler.pendingCount;
        });
      }
      widget.onSuccess?.call();
    } catch (error, stackTrace) {
      if (mounted) {
        setState(() {
          _isLoading = _throttler.isLocked;
          _pendingCount = _throttler.pendingCount;
        });
      }
      widget.onError?.call(error, stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(
      context,
      widget.onPressed == null ? null : _handlePress,
      _isLoading,
      _pendingCount,
    );
  }
}

/// Debounced callback wrapper.
class DebouncedCallback extends StatefulWidget {
  final VoidCallback? onChanged;
  final Duration? duration;
  final Widget Function(BuildContext context, VoidCallback? debouncedCallback)
      builder;

  const DebouncedCallback({
    super.key,
    required this.onChanged,
    required this.builder,
    this.duration,
  });

  @override
  State<DebouncedCallback> createState() => _DebouncedCallbackState();
}

class _DebouncedCallbackState extends State<DebouncedCallback> {
  late final Debouncer _debouncer;

  @override
  void initState() {
    super.initState();
    _debouncer = Debouncer(duration: widget.duration);
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _debouncer.wrap(widget.onChanged));
  }
}

/// Throttled tap with ripple effect.
///
/// **Example:**
/// ```dart
/// ThrottledInkWell(
///   onTap: () => handleTap(),
///   onLongPress: () => showMenu(),
///   child: MyButton(),
/// )
/// ```
class ThrottledInkWell extends StatefulWidget {
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onLongPress;
  final Widget child;
  final Duration? duration;
  final BorderRadius? borderRadius;
  final Color? splashColor;
  final Color? highlightColor;
  final InteractiveInkFeatureFactory? splashFactory;

  const ThrottledInkWell({
    super.key,
    required this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    required this.child,
    this.duration,
    this.borderRadius,
    this.splashColor,
    this.highlightColor,
    this.splashFactory,
  });

  @override
  State<ThrottledInkWell> createState() => _ThrottledInkWellState();
}

class _ThrottledInkWellState extends State<ThrottledInkWell> {
  late final Throttler _throttler;

  @override
  void initState() {
    super.initState();
    _throttler = Throttler(duration: widget.duration);
  }

  @override
  void dispose() {
    _throttler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _throttler.wrap(widget.onTap),
      onDoubleTap: _throttler.wrap(widget.onDoubleTap),
      onLongPress: _throttler.wrap(widget.onLongPress),
      borderRadius: widget.borderRadius,
      splashColor: widget.splashColor,
      highlightColor: widget.highlightColor,
      splashFactory: widget.splashFactory,
      child: widget.child,
    );
  }
}

/// Throttled tap without ripple.
class ThrottledTapWidget extends StatefulWidget {
  final VoidCallback? onTap;
  final Widget child;
  final Duration? duration;
  final HitTestBehavior behavior;

  const ThrottledTapWidget({
    super.key,
    required this.onTap,
    required this.child,
    this.duration,
    this.behavior = HitTestBehavior.opaque,
  });

  @override
  State<ThrottledTapWidget> createState() => _ThrottledTapWidgetState();
}

class _ThrottledTapWidgetState extends State<ThrottledTapWidget> {
  late final Throttler _throttler;

  @override
  void initState() {
    super.initState();
    _throttler = Throttler(duration: widget.duration);
  }

  @override
  void dispose() {
    _throttler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior,
      onTap: _throttler.wrap(widget.onTap),
      child: widget.child,
    );
  }
}

/// Debounced tap (waits until user stops).
class DebouncedTapWidget extends StatefulWidget {
  final VoidCallback? onTap;
  final Widget child;
  final Duration? duration;
  final HitTestBehavior behavior;

  const DebouncedTapWidget({
    super.key,
    required this.onTap,
    required this.child,
    this.duration,
    this.behavior = HitTestBehavior.opaque,
  });

  @override
  State<DebouncedTapWidget> createState() => _DebouncedTapWidgetState();
}

class _DebouncedTapWidgetState extends State<DebouncedTapWidget> {
  late final Debouncer _debouncer;

  @override
  void initState() {
    super.initState();
    _debouncer = Debouncer(duration: widget.duration);
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior,
      onTap: _debouncer.wrap(widget.onTap),
      child: widget.child,
    );
  }
}
