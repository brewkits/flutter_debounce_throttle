// Mixin for State Management integration (Provider, GetX, Bloc, etc.)
// Works with flutter_debounce_throttle_core.

import 'dart:async';

import 'package:flutter_debounce_throttle_core/flutter_debounce_throttle_core.dart';

/// Mixin for adding event limiting to Controllers/ViewModels.
///
/// Works with any class: ChangeNotifier, GetxController, Cubit, MobX Store,
/// and even Dart Server controllers.
///
/// **Important:** Use static IDs for limiters. If you use dynamic IDs like
/// `debounce('post_$postId')`, call [remove] to clean up when the item is
/// removed, otherwise the internal maps will grow unbounded.
///
/// **Example with Provider:**
/// ```dart
/// class SearchProvider extends ChangeNotifier with EventLimiterMixin {
///   List<User> _results = [];
///   bool _isLoading = false;
///
///   void onSearch(String text) {
///     debounce('search', () async {
///       _isLoading = true;
///       notifyListeners();
///
///       _results = await api.search(text);
///       _isLoading = false;
///       notifyListeners();
///     });
///   }
///
///   @override
///   void dispose() {
///     cancelAll(); // IMPORTANT: Always call this!
///     super.dispose();
///   }
/// }
/// ```
///
/// **Example with GetX:**
/// ```dart
/// class SearchController extends GetxController with EventLimiterMixin {
///   final results = <User>[].obs;
///   final isLoading = false.obs;
///
///   void onSearch(String text) {
///     debounce('search', () async {
///       isLoading.value = true;
///       results.value = await api.search(text);
///       isLoading.value = false;
///     });
///   }
///
///   @override
///   void onClose() {
///     cancelAll();
///     super.onClose();
///   }
/// }
/// ```
///
/// **Example with Bloc:**
/// ```dart
/// class SearchBloc extends Bloc<SearchEvent, SearchState> with EventLimiterMixin {
///   SearchBloc() : super(SearchInitial()) {
///     on<SearchQueryChanged>(_onQueryChanged);
///   }
///
///   void _onQueryChanged(SearchQueryChanged event, Emitter emit) {
///     debounce('search', () async {
///       emit(SearchLoading());
///       final results = await api.search(event.query);
///       emit(SearchLoaded(results));
///     });
///   }
///
///   @override
///   Future<void> close() {
///     cancelAll();
///     return super.close();
///   }
/// }
/// ```
///
/// **Example on Dart Server (Serverpod):**
/// ```dart
/// class RateLimitedService with EventLimiterMixin {
///   void processRequest(String data) {
///     throttle('api-call', () {
///       externalApi.call(data);
///     }, duration: Duration(seconds: 1));
///   }
///
///   void batchLog(String message) {
///     debounce('log', () {
///       database.insertLogs(_pendingLogs);
///       _pendingLogs.clear();
///     }, duration: Duration(seconds: 1));
///     _pendingLogs.add(message);
///   }
///
///   void shutdown() {
///     cancelAll();
///   }
/// }
/// ```
mixin EventLimiterMixin {
  final Map<String, Debouncer> _debouncers = {};
  final Map<String, Throttler> _throttlers = {};
  final Map<String, AsyncDebouncer> _asyncDebouncers = {};
  final Map<String, AsyncThrottler> _asyncThrottlers = {};

  /// Debounce a callback by ID.
  ///
  /// Delays execution until no calls for [duration].
  /// Cancels previous pending call for this ID.
  void debounce(
    String id,
    void Function() action, {
    Duration? duration,
  }) {
    _debouncers[id] ??= Debouncer(
      duration:
          duration ?? DebounceThrottleConfig.config.defaultDebounceDuration,
    );
    _debouncers[id]!.call(action);
  }

  /// Throttle a callback by ID.
  ///
  /// Executes immediately, then blocks for [duration].
  void throttle(
    String id,
    void Function() action, {
    Duration? duration,
  }) {
    _throttlers[id] ??= Throttler(
      duration:
          duration ?? DebounceThrottleConfig.config.defaultThrottleDuration,
    );
    _throttlers[id]!.call(action);
  }

  /// Async debounce by ID.
  ///
  /// Returns null if cancelled by a newer call.
  Future<T?> debounceAsync<T>(
    String id,
    Future<T> Function() action, {
    Duration? duration,
  }) {
    _asyncDebouncers[id] ??= AsyncDebouncer(
      duration:
          duration ?? DebounceThrottleConfig.config.defaultDebounceDuration,
    );
    // ignore: deprecated_member_use_from_same_package
    return _asyncDebouncers[id]!.call(action);
  }

  /// Async throttle by ID.
  ///
  /// Locks during execution, ignores calls while locked.
  Future<void> throttleAsync(
    String id,
    Future<void> Function() action, {
    Duration? maxDuration,
  }) {
    _asyncThrottlers[id] ??= AsyncThrottler(
      maxDuration:
          maxDuration ?? DebounceThrottleConfig.config.defaultAsyncTimeout,
    );
    return _asyncThrottlers[id]!.call(action);
  }

  /// Cancel a specific limiter by ID (keeps the limiter instance).
  ///
  /// Example: `cancel('search')` to cancel search debouncer.
  void cancel(String id) {
    _debouncers[id]?.cancel();
    _throttlers[id]?.cancel();
    _asyncDebouncers[id]?.cancel();
    _asyncThrottlers[id]?.reset();
  }

  /// Remove and dispose a limiter by ID.
  ///
  /// Use this when using dynamic IDs (e.g., `'post_$postId'`) to prevent
  /// memory leaks. Unlike [cancel], this also removes the limiter instance
  /// from internal maps.
  ///
  /// Example:
  /// ```dart
  /// // When item is removed from infinite scroll list
  /// void onItemRemoved(String postId) {
  ///   remove('like_$postId');
  /// }
  /// ```
  void remove(String id) {
    _debouncers[id]?.dispose();
    _debouncers.remove(id);
    _throttlers[id]?.dispose();
    _throttlers.remove(id);
    _asyncDebouncers[id]?.dispose();
    _asyncDebouncers.remove(id);
    _asyncThrottlers[id]?.dispose();
    _asyncThrottlers.remove(id);
  }

  /// Alias for [cancel]. Prefer using `cancel()`.
  @Deprecated('Use cancel() instead. Will be removed in v2.0.0')
  void cancelLimiter(String id) => cancel(id);

  /// Cancel all limiters. Call in dispose/onClose.
  void cancelAll() {
    for (final debouncer in _debouncers.values) {
      debouncer.dispose();
    }
    for (final throttler in _throttlers.values) {
      throttler.dispose();
    }
    for (final debouncer in _asyncDebouncers.values) {
      debouncer.dispose();
    }
    for (final throttler in _asyncThrottlers.values) {
      throttler.dispose();
    }
    _debouncers.clear();
    _throttlers.clear();
    _asyncDebouncers.clear();
    _asyncThrottlers.clear();
  }

  /// Alias for [cancelAll]. Prefer using `cancelAll()`.
  @Deprecated('Use cancelAll() instead. Will be removed in v2.0.0')
  void cancelAllLimiters() => cancelAll();

  /// Check if a limiter is active.
  bool isLimiterActive(String id) {
    return (_debouncers[id]?.isPending ?? false) ||
        (_throttlers[id]?.isPending ?? false) ||
        (_asyncDebouncers[id]?.isPending ?? false) ||
        (_asyncThrottlers[id]?.isLocked ?? false);
  }

  /// Get count of active limiters.
  int get activeLimitersCount {
    int count = 0;
    for (final d in _debouncers.values) {
      if (d.isPending) count++;
    }
    for (final t in _throttlers.values) {
      if (t.isPending) count++;
    }
    for (final d in _asyncDebouncers.values) {
      if (d.isPending) count++;
    }
    for (final t in _asyncThrottlers.values) {
      if (t.isLocked) count++;
    }
    return count;
  }
}
