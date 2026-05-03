import 'dart:async';

import 'package:dart_debounce_throttle/dart_debounce_throttle.dart';
import 'package:riverpod/riverpod.dart';

/// Debounce/throttle controller that ties its lifecycle to a Riverpod [Ref].
///
/// Create one inside a Riverpod notifier's `build()` method — it automatically
/// cancels all pending timers when the provider is disposed or re-built.
///
/// Works with any ref type: [Ref], notifier refs, and [WidgetRef]-compatible
/// objects that implement `onDispose`.
///
/// ---
///
/// ### Notifier (code-gen or manual)
/// ```dart
/// @riverpod
/// class SearchNotifier extends _$SearchNotifier {
///   late final EventLimiterController _limiter;
///
///   @override
///   SearchState build() {
///     _limiter = ref.eventLimiter();   // auto-disposes with provider
///     return SearchState.initial();
///   }
///
///   void onSearch(String query) {
///     _limiter.debounce('search', () async {
///       state = SearchState.loading();
///       state = SearchState.data(await api.search(query));
///     });
///   }
/// }
/// ```
///
/// ### AsyncNotifier
/// ```dart
/// @riverpod
/// class OrderNotifier extends _$OrderNotifier {
///   late final EventLimiterController _limiter;
///
///   @override
///   Future<Order?> build() async {
///     _limiter = ref.eventLimiter();
///     return null;
///   }
///
///   Future<void> submitOrder(Order order) async {
///     final result = await _limiter.debounceAsync<Order>(
///       'submit',
///       () async => api.submit(order),
///     );
///     if (result != null) state = AsyncData(result);
///   }
/// }
/// ```
///
/// ### ConsumerWidget / HookConsumerWidget
/// ```dart
/// class SearchPage extends ConsumerStatefulWidget {
///   @override
///   ConsumerState<SearchPage> createState() => _SearchPageState();
/// }
///
/// class _SearchPageState extends ConsumerState<SearchPage> {
///   late final EventLimiterController _limiter;
///
///   @override
///   void initState() {
///     super.initState();
///     _limiter = EventLimiterController.standalone();
///   }
///
///   @override
///   void dispose() {
///     _limiter.dispose();
///     super.dispose();
///   }
///   // Use _limiter.debounce(...) / _limiter.throttle(...)
/// }
/// ```
class EventLimiterController {
  final Map<String, Debouncer> _debouncers = {};
  final Map<String, Throttler> _throttlers = {};
  final Map<String, AsyncDebouncer> _asyncDebouncers = {};
  final Map<String, AsyncThrottler> _asyncThrottlers = {};

  bool _disposed = false;

  /// Creates a controller tied to [ref]'s lifecycle.
  ///
  /// Registers [cancelAll] via `ref.onDispose` — all pending timers are
  /// automatically cleaned up when the provider is disposed.
  EventLimiterController(Ref ref) {
    ref.onDispose(dispose);
  }

  /// Creates a standalone controller not tied to any Riverpod ref.
  ///
  /// You are responsible for calling [dispose] when done (e.g. in
  /// `State.dispose()` or a teardown function).
  EventLimiterController.standalone();

  // ─── Debounce ─────────────────────────────────────────────────────────────

  /// Debounce a callback by [id]. Resets the timer on every call.
  ///
  /// Only the last call within [duration] executes. Reuses the same timer
  /// for repeated calls with the same [id].
  ///
  /// ```dart
  /// _limiter.debounce('search', () => ref.read(searchProvider.notifier).search(query));
  /// ```
  void debounce(
    String id,
    void Function() action, {
    Duration? duration,
  }) {
    if (_disposed) return;
    _debouncers[id] ??= Debouncer(duration: duration);
    _debouncers[id]!.call(action);
  }

  // ─── Throttle ─────────────────────────────────────────────────────────────

  /// Throttle a callback by [id]. Executes immediately, then locks for [duration].
  ///
  /// ```dart
  /// _limiter.throttle('submit', () => submitForm());
  /// ```
  void throttle(
    String id,
    void Function() action, {
    Duration? duration,
  }) {
    if (_disposed) return;
    _throttlers[id] ??= Throttler(duration: duration);
    _throttlers[id]!.call(action);
  }

  // ─── Async Debounce ───────────────────────────────────────────────────────

  /// Debounce an async operation by [id].
  ///
  /// Returns `null` if cancelled by a newer call. Use [debounceAsyncResult]
  /// to distinguish cancellation from a legitimate null return value.
  ///
  /// ```dart
  /// final data = await _limiter.debounceAsync('fetch', () => api.search(query));
  /// if (data != null) state = AsyncData(data);
  /// ```
  Future<T?> debounceAsync<T>(
    String id,
    Future<T> Function() action, {
    Duration? duration,
  }) {
    if (_disposed) return Future.value(null);
    _asyncDebouncers[id] ??= AsyncDebouncer(duration: duration);
    return _asyncDebouncers[id]!.call<T>(action);
  }

  /// Debounce an async operation by [id], returning a [DebounceResult].
  ///
  /// Distinguishes between cancellation (`result.isCancelled`) and a
  /// legitimate null return value (`result.isSuccess && result.value == null`).
  ///
  /// ```dart
  /// final result = await _limiter.debounceAsyncResult('fetch', () => api.findUser(id));
  /// result.when(
  ///   onSuccess: (user) => state = AsyncData(user),
  ///   onCancelled: () {},  // stale call — ignore
  /// );
  /// ```
  Future<DebounceResult<T>> debounceAsyncResult<T>(
    String id,
    Future<T> Function() action, {
    Duration? duration,
  }) {
    if (_disposed) return Future.value(DebounceResult<T>.cancelled());
    _asyncDebouncers[id] ??= AsyncDebouncer(duration: duration);
    return _asyncDebouncers[id]!.callWithResult<T>(action);
  }

  // ─── Async Throttle ───────────────────────────────────────────────────────

  /// Throttle an async operation by [id].
  ///
  /// Locks during execution; ignores concurrent calls while locked.
  ///
  /// ```dart
  /// await _limiter.throttleAsync('upload', () => api.uploadFile(file));
  /// ```
  Future<void> throttleAsync(
    String id,
    Future<void> Function() action, {
    Duration? maxDuration,
  }) {
    if (_disposed) return Future.value();
    _asyncThrottlers[id] ??= AsyncThrottler(maxDuration: maxDuration);
    return _asyncThrottlers[id]!.call(action);
  }

  // ─── Control ──────────────────────────────────────────────────────────────

  /// Cancel and remove the limiter with [id].
  void cancel(String id) {
    _debouncers.remove(id)?.dispose();
    _throttlers.remove(id)?.dispose();
    _asyncDebouncers.remove(id)?.dispose();
    _asyncThrottlers.remove(id)?.dispose();
  }

  /// Cancel all pending operations and dispose all limiters.
  ///
  /// Called automatically when the Riverpod provider is disposed.
  void cancelAll() {
    for (final d in _debouncers.values) {
      d.dispose();
    }
    for (final t in _throttlers.values) {
      t.dispose();
    }
    for (final d in _asyncDebouncers.values) {
      d.dispose();
    }
    for (final t in _asyncThrottlers.values) {
      t.dispose();
    }
    _debouncers.clear();
    _throttlers.clear();
    _asyncDebouncers.clear();
    _asyncThrottlers.clear();
  }

  /// Alias for [cancelAll]. Use for [EventLimiterController.standalone] instances.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    cancelAll();
  }

  /// Whether a limiter with [id] is currently active (pending or locked).
  bool isActive(String id) {
    return (_debouncers[id]?.isPending ?? false) ||
        (_throttlers[id]?.isThrottled ?? false) ||
        (_asyncDebouncers[id]?.isPending ?? false) ||
        (_asyncThrottlers[id]?.isLocked ?? false);
  }
}

/// Extension on [Ref] for creating an [EventLimiterController]
/// that auto-disposes with the provider.
extension EventLimiterRefExtension on Ref {
  /// Create an [EventLimiterController] tied to this [Ref]'s lifecycle.
  ///
  /// Equivalent to `EventLimiterController(ref)` — auto-disposes when
  /// the provider is disposed or re-built.
  ///
  /// ```dart
  /// @override
  /// SomeState build() {
  ///   final limiter = ref.eventLimiter();
  ///   // use limiter.debounce(...) / limiter.throttle(...)
  ///   return SomeState();
  /// }
  /// ```
  EventLimiterController eventLimiter() => EventLimiterController(this);
}
