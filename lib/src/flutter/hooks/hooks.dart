// lib/src/flutter/hooks/hooks.dart
//
// Flutter Hooks support for debounce/throttle.
// Requires flutter_hooks package.

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../core/async_debouncer.dart';
import '../../core/async_throttler.dart';
import '../../core/debouncer.dart';
import '../../core/throttler.dart';

/// Hook to get a Debouncer instance.
///
/// Auto-disposes when widget unmounts.
///
/// **Example:**
/// ```dart
/// Widget build(BuildContext context) {
///   final debouncer = useDebouncer(duration: Duration(milliseconds: 300));
///
///   return TextField(
///     onChanged: (text) => debouncer.call(() => search(text)),
///   );
/// }
/// ```
Debouncer useDebouncer({
  Duration? duration,
  bool debugMode = false,
  String? name,
  List<Object?>? keys,
}) {
  return use(_DebouncerHook(
    duration: duration,
    debugMode: debugMode,
    name: name,
    keys: keys,
  ));
}

class _DebouncerHook extends Hook<Debouncer> {
  final Duration? duration;
  final bool debugMode;
  final String? name;

  const _DebouncerHook({
    this.duration,
    this.debugMode = false,
    this.name,
    super.keys,
  });

  @override
  _DebouncerHookState createState() => _DebouncerHookState();
}

class _DebouncerHookState extends HookState<Debouncer, _DebouncerHook> {
  late Debouncer _debouncer;

  @override
  void initHook() {
    super.initHook();
    _debouncer = Debouncer(
      duration: hook.duration,
      debugMode: hook.debugMode,
      name: hook.name,
    );
  }

  @override
  Debouncer build(BuildContext context) => _debouncer;

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }
}

/// Hook to get a Throttler instance.
///
/// Auto-disposes when widget unmounts.
///
/// **Example:**
/// ```dart
/// Widget build(BuildContext context) {
///   final throttler = useThrottler(duration: Duration(milliseconds: 500));
///
///   return ElevatedButton(
///     onPressed: throttler.wrap(() => submit()),
///     child: Text('Submit'),
///   );
/// }
/// ```
Throttler useThrottler({
  Duration? duration,
  bool debugMode = false,
  String? name,
  List<Object?>? keys,
}) {
  return use(_ThrottlerHook(
    duration: duration,
    debugMode: debugMode,
    name: name,
    keys: keys,
  ));
}

class _ThrottlerHook extends Hook<Throttler> {
  final Duration? duration;
  final bool debugMode;
  final String? name;

  const _ThrottlerHook({
    this.duration,
    this.debugMode = false,
    this.name,
    super.keys,
  });

  @override
  _ThrottlerHookState createState() => _ThrottlerHookState();
}

class _ThrottlerHookState extends HookState<Throttler, _ThrottlerHook> {
  late Throttler _throttler;

  @override
  void initHook() {
    super.initHook();
    _throttler = Throttler(
      duration: hook.duration,
      debugMode: hook.debugMode,
      name: hook.name,
    );
  }

  @override
  Throttler build(BuildContext context) => _throttler;

  @override
  void dispose() {
    _throttler.dispose();
    super.dispose();
  }
}

/// Hook for debounced callback.
///
/// Returns a function that debounces the provided callback.
///
/// **Example:**
/// ```dart
/// Widget build(BuildContext context) {
///   final debouncedSearch = useDebouncedCallback<String>(
///     (text) => searchApi(text),
///     duration: Duration(milliseconds: 300),
///   );
///
///   return TextField(
///     onChanged: debouncedSearch,
///   );
/// }
/// ```
void Function(T) useDebouncedCallback<T>(
  void Function(T) callback, {
  Duration? duration,
  List<Object?>? keys,
}) {
  final debouncer = useDebouncer(duration: duration, keys: keys);

  return useCallback(
    (T value) => debouncer.call(() => callback(value)),
    [debouncer, callback],
  );
}

/// Hook for throttled callback.
///
/// Returns a function that throttles the provided callback.
///
/// **Example:**
/// ```dart
/// Widget build(BuildContext context) {
///   final throttledSubmit = useThrottledCallback(
///     () => submitForm(),
///     duration: Duration(milliseconds: 500),
///   );
///
///   return ElevatedButton(
///     onPressed: throttledSubmit,
///     child: Text('Submit'),
///   );
/// }
/// ```
VoidCallback useThrottledCallback(
  VoidCallback callback, {
  Duration? duration,
  List<Object?>? keys,
}) {
  final throttler = useThrottler(duration: duration, keys: keys);

  return useCallback(
    () => throttler.call(callback),
    [throttler, callback],
  );
}

/// Hook for debounced value.
///
/// Returns the debounced version of a value.
///
/// **Example:**
/// ```dart
/// Widget build(BuildContext context) {
///   final [searchText, setSearchText] = useState('');
///   final debouncedText = useDebouncedValue(searchText);
///
///   useEffect(() {
///     if (debouncedText.isNotEmpty) {
///       searchApi(debouncedText);
///     }
///     return null;
///   }, [debouncedText]);
///
///   return TextField(onChanged: setSearchText);
/// }
/// ```
T useDebouncedValue<T>(
  T value, {
  Duration? duration,
}) {
  final debouncedValue = useState(value);
  final debouncer = useDebouncer(duration: duration);

  useEffect(() {
    debouncer.call(() {
      debouncedValue.value = value;
    });
    return null;
  }, [value]);

  return debouncedValue.value;
}

/// Hook for throttled value.
///
/// Returns the throttled version of a value.
///
/// **Example:**
/// ```dart
/// Widget build(BuildContext context) {
///   final [scrollOffset, setScrollOffset] = useState(0.0);
///   final throttledOffset = useThrottledValue(
///     scrollOffset,
///     duration: Duration(milliseconds: 16), // ~60fps
///   );
///
///   return NotificationListener<ScrollNotification>(
///     onNotification: (n) {
///       setScrollOffset(n.metrics.pixels);
///       return false;
///     },
///     child: ListView(...),
///   );
/// }
/// ```
T useThrottledValue<T>(
  T value, {
  Duration? duration,
}) {
  final throttledValue = useState(value);
  final throttler = useThrottler(duration: duration);

  useEffect(() {
    throttler.call(() {
      throttledValue.value = value;
    });
    return null;
  }, [value]);

  return throttledValue.value;
}

/// Hook to get an AsyncDebouncer instance.
AsyncDebouncer useAsyncDebouncer({
  Duration? duration,
  bool debugMode = false,
  String? name,
  List<Object?>? keys,
}) {
  return use(_AsyncDebouncerHook(
    duration: duration,
    debugMode: debugMode,
    name: name,
    keys: keys,
  ));
}

class _AsyncDebouncerHook extends Hook<AsyncDebouncer> {
  final Duration? duration;
  final bool debugMode;
  final String? name;

  const _AsyncDebouncerHook({
    this.duration,
    this.debugMode = false,
    this.name,
    super.keys,
  });

  @override
  _AsyncDebouncerHookState createState() => _AsyncDebouncerHookState();
}

class _AsyncDebouncerHookState
    extends HookState<AsyncDebouncer, _AsyncDebouncerHook> {
  late AsyncDebouncer _debouncer;

  @override
  void initHook() {
    super.initHook();
    _debouncer = AsyncDebouncer(
      duration: hook.duration,
      debugMode: hook.debugMode,
      name: hook.name,
    );
  }

  @override
  AsyncDebouncer build(BuildContext context) => _debouncer;

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }
}

/// Hook to get an AsyncThrottler instance.
AsyncThrottler useAsyncThrottler({
  Duration? maxDuration,
  bool debugMode = false,
  String? name,
  List<Object?>? keys,
}) {
  return use(_AsyncThrottlerHook(
    maxDuration: maxDuration,
    debugMode: debugMode,
    name: name,
    keys: keys,
  ));
}

class _AsyncThrottlerHook extends Hook<AsyncThrottler> {
  final Duration? maxDuration;
  final bool debugMode;
  final String? name;

  const _AsyncThrottlerHook({
    this.maxDuration,
    this.debugMode = false,
    this.name,
    super.keys,
  });

  @override
  _AsyncThrottlerHookState createState() => _AsyncThrottlerHookState();
}

class _AsyncThrottlerHookState
    extends HookState<AsyncThrottler, _AsyncThrottlerHook> {
  late AsyncThrottler _throttler;

  @override
  void initHook() {
    super.initHook();
    _throttler = AsyncThrottler(
      maxDuration: hook.maxDuration,
      debugMode: hook.debugMode,
      name: hook.name,
    );
  }

  @override
  AsyncThrottler build(BuildContext context) => _throttler;

  @override
  void dispose() {
    _throttler.dispose();
    super.dispose();
  }
}
