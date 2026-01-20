// Mixin for State Management integration (Provider, GetX, Bloc, etc.)
// Works with dart_debounce_throttle.

import 'dart:async';

import 'package:dart_debounce_throttle/dart_debounce_throttle.dart';
import 'package:meta/meta.dart';

/// Mixin for adding event limiting to Controllers/ViewModels.
///
/// Works with any class: ChangeNotifier, GetxController, Cubit, MobX Store,
/// and even Dart Server controllers.
///
/// **Important:** Use static IDs for limiters. If you use dynamic IDs like
/// `debounce('post_$postId')`, you have several cleanup options:
/// 1. Call [remove] manually when items are deleted
/// 2. Enable auto-cleanup via global config (see [DebounceThrottleConfig])
/// 3. Call [cleanupInactive] or [cleanupUnused] periodically
///
/// **Memory Management with Dynamic IDs:**
/// ```dart
/// // Option 1: Enable auto-cleanup globally (recommended for production)
/// void main() {
///   DebounceThrottleConfig.init(
///     limiterAutoCleanupTTL: Duration(minutes: 5),     // Auto-remove after 5min of inactivity
///     limiterAutoCleanupThreshold: 100,               // Trigger cleanup when >100 limiters
///   );
///   runApp(MyApp());
/// }
///
/// // Option 2: Manual cleanup in controller lifecycle
/// class InfiniteScrollController extends GetxController with EventLimiterMixin {
///   @override
///   void onInit() {
///     super.onInit();
///     // Periodic cleanup every 5 minutes
///     Timer.periodic(Duration(minutes: 5), (_) {
///       cleanupInactive();  // Remove inactive limiters
///     });
///   }
/// }
///
/// // Option 3: Explicit removal when items are deleted
/// void onPostDeleted(String postId) {
///   remove('like_$postId');  // Clean up specific limiter
/// }
/// ```
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

  // Track last usage time for auto-cleanup
  final Map<String, DateTime> _debouncersLastUsed = {};
  final Map<String, DateTime> _throttlersLastUsed = {};
  final Map<String, DateTime> _asyncDebouncersLastUsed = {};
  final Map<String, DateTime> _asyncThrottlersLastUsed = {};

  /// Debounce a callback by ID.
  ///
  /// Delays execution until no calls for [duration].
  /// Cancels previous pending call for this ID.
  void debounce(
    String id,
    void Function() action, {
    Duration? duration,
  }) {
    // Only check cleanup when creating new instance (performance optimization)
    if (!_debouncers.containsKey(id)) {
      _debouncers[id] = Debouncer(
        duration:
            duration ?? DebounceThrottleConfig.config.defaultDebounceDuration,
      );
      _checkLimiterCount();
    }
    _debouncersLastUsed[id] = DateTime.now();
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
    // Only check cleanup when creating new instance (performance optimization)
    if (!_throttlers.containsKey(id)) {
      _throttlers[id] = Throttler(
        duration:
            duration ?? DebounceThrottleConfig.config.defaultThrottleDuration,
      );
      _checkLimiterCount();
    }
    _throttlersLastUsed[id] = DateTime.now();
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
    // Only check cleanup when creating new instance (performance optimization)
    if (!_asyncDebouncers.containsKey(id)) {
      _asyncDebouncers[id] = AsyncDebouncer(
        duration:
            duration ?? DebounceThrottleConfig.config.defaultDebounceDuration,
      );
      _checkLimiterCount();
    }
    _asyncDebouncersLastUsed[id] = DateTime.now();
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
    // Only check cleanup when creating new instance (performance optimization)
    if (!_asyncThrottlers.containsKey(id)) {
      _asyncThrottlers[id] = AsyncThrottler(
        maxDuration:
            maxDuration ?? DebounceThrottleConfig.config.defaultAsyncTimeout,
      );
      _checkLimiterCount();
    }
    _asyncThrottlersLastUsed[id] = DateTime.now();
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
    _debouncersLastUsed.remove(id);
    _throttlers[id]?.dispose();
    _throttlers.remove(id);
    _throttlersLastUsed.remove(id);
    _asyncDebouncers[id]?.dispose();
    _asyncDebouncers.remove(id);
    _asyncDebouncersLastUsed.remove(id);
    _asyncThrottlers[id]?.dispose();
    _asyncThrottlers.remove(id);
    _asyncThrottlersLastUsed.remove(id);
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
    _debouncersLastUsed.clear();
    _throttlersLastUsed.clear();
    _asyncDebouncersLastUsed.clear();
    _asyncThrottlersLastUsed.clear();
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

  /// Get count of active limiters (currently pending/locked).
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

  /// Get total count of all limiter instances (active + inactive).
  ///
  /// Useful for monitoring memory usage with dynamic IDs.
  ///
  /// Example:
  /// ```dart
  /// print('Total limiters: ${controller.totalLimitersCount}');
  /// ```
  int get totalLimitersCount => _getTotalLimiterCount();

  /// Internal: Check limiter count, auto-cleanup if needed, and warn if too many instances exist.
  ///
  /// Helps detect potential memory leaks from using dynamic IDs without
  /// calling [remove].
  void _checkLimiterCount() {
    // Auto-cleanup if TTL is configured
    _autoCleanupIfNeeded();

    final totalCount = _getTotalLimiterCount();

    if (totalCount > 100) {
      assert(
        false,
        'WARNING: EventLimiterMixin has over 100 limiter instances ($totalCount). '
        'This may indicate a memory leak. If you are using dynamic IDs (e.g., '
        '"post_\$postId"), make sure to call remove(id) when items are deleted. '
        'For static IDs, this warning can be ignored.',
      );
    }
  }

  /// Auto-cleanup limiters that haven't been used within TTL period.
  ///
  /// Only runs if TTL is configured and threshold is reached.
  void _autoCleanupIfNeeded() {
    // Only run if TTL is configured
    final ttl = DebounceThrottleConfig.config.limiterAutoCleanupTTL;
    if (ttl == null) return;

    // Only run if threshold is reached
    final totalCount = _getTotalLimiterCount();
    final threshold = DebounceThrottleConfig.config.limiterAutoCleanupThreshold;
    if (totalCount <= threshold) return;

    // Remove limiters that haven't been used within TTL
    final now = DateTime.now();
    _cleanupMapByTTL(_debouncers, _debouncersLastUsed, now, ttl);
    _cleanupMapByTTL(_throttlers, _throttlersLastUsed, now, ttl);
    _cleanupMapByTTL(_asyncDebouncers, _asyncDebouncersLastUsed, now, ttl);
    _cleanupMapByTTL(_asyncThrottlers, _asyncThrottlersLastUsed, now, ttl);
  }

  void _cleanupMapByTTL<T>(
    Map<String, T> limiterMap,
    Map<String, DateTime> timestampMap,
    DateTime now,
    Duration ttl,
  ) {
    final idsToRemove = <String>[];

    for (final id in limiterMap.keys) {
      final lastUsed = timestampMap[id];
      if (lastUsed == null) continue;

      final inactiveDuration = now.difference(lastUsed);
      if (inactiveDuration > ttl) {
        idsToRemove.add(id);
      }
    }

    for (final id in idsToRemove) {
      (limiterMap[id] as dynamic)?.dispose();
      limiterMap.remove(id);
      timestampMap.remove(id);
    }
  }

  /// Remove all inactive limiters (not currently pending/locked).
  ///
  /// Useful for periodic cleanup in long-running apps with dynamic IDs.
  ///
  /// Returns the number of limiters removed.
  ///
  /// Example:
  /// ```dart
  /// class MyController extends GetxController with EventLimiterMixin {
  ///   @override
  ///   void onInit() {
  ///     super.onInit();
  ///     // Cleanup every 5 minutes
  ///     Timer.periodic(Duration(minutes: 5), (_) {
  ///       cleanupInactive();
  ///     });
  ///   }
  /// }
  /// ```
  int cleanupInactive() {
    int removed = 0;
    removed += _cleanupInactiveMap(_debouncers, (d) => !d.isPending);
    removed += _cleanupInactiveMap(_throttlers, (t) => !t.isPending);
    removed += _cleanupInactiveMap(_asyncDebouncers, (d) => !d.isPending);
    removed += _cleanupInactiveMap(_asyncThrottlers, (t) => !t.isLocked);
    return removed;
  }

  /// Remove limiters that haven't been used for [inactivityPeriod].
  ///
  /// Useful for cleaning up dynamic IDs that are no longer relevant.
  ///
  /// Returns the number of limiters removed.
  ///
  /// Example:
  /// ```dart
  /// // Remove limiters unused for 10 minutes
  /// controller.cleanupUnused(Duration(minutes: 10));
  /// ```
  int cleanupUnused(Duration inactivityPeriod) {
    final now = DateTime.now();
    int removed = 0;

    removed += _cleanupUnusedMap(
        _debouncers, _debouncersLastUsed, now, inactivityPeriod);
    removed += _cleanupUnusedMap(
        _throttlers, _throttlersLastUsed, now, inactivityPeriod);
    removed += _cleanupUnusedMap(
        _asyncDebouncers, _asyncDebouncersLastUsed, now, inactivityPeriod);
    removed += _cleanupUnusedMap(
        _asyncThrottlers, _asyncThrottlersLastUsed, now, inactivityPeriod);

    return removed;
  }

  int _cleanupInactiveMap<T>(Map<String, T> map, bool Function(T) isInactive) {
    final idsToRemove = <String>[];

    for (final entry in map.entries) {
      if (isInactive(entry.value)) {
        idsToRemove.add(entry.key);
      }
    }

    for (final id in idsToRemove) {
      (map[id] as dynamic)?.dispose();
      map.remove(id);
      // Also remove from timestamp maps
      _debouncersLastUsed.remove(id);
      _throttlersLastUsed.remove(id);
      _asyncDebouncersLastUsed.remove(id);
      _asyncThrottlersLastUsed.remove(id);
    }

    return idsToRemove.length;
  }

  int _cleanupUnusedMap<T>(
    Map<String, T> limiterMap,
    Map<String, DateTime> timestampMap,
    DateTime now,
    Duration inactivityPeriod,
  ) {
    final idsToRemove = <String>[];

    for (final id in limiterMap.keys) {
      final lastUsed = timestampMap[id];
      if (lastUsed != null) {
        final inactiveDuration = now.difference(lastUsed);
        if (inactiveDuration > inactivityPeriod) {
          idsToRemove.add(id);
        }
      }
    }

    for (final id in idsToRemove) {
      (limiterMap[id] as dynamic)?.dispose();
      limiterMap.remove(id);
      timestampMap.remove(id);
    }

    return idsToRemove.length;
  }

  int _getTotalLimiterCount() {
    return _debouncers.length +
        _throttlers.length +
        _asyncDebouncers.length +
        _asyncThrottlers.length;
  }

  // =================================================================
  // Test-only getters (visible for testing)
  // =================================================================

  /// Visible for testing: Access to internal debouncer map.
  @visibleForTesting
  Map<String, Debouncer> get testDebouncers => _debouncers;

  /// Visible for testing: Access to internal throttler map.
  @visibleForTesting
  Map<String, Throttler> get testThrottlers => _throttlers;

  /// Visible for testing: Access to internal async debouncer map.
  @visibleForTesting
  Map<String, AsyncDebouncer> get testAsyncDebouncers => _asyncDebouncers;

  /// Visible for testing: Access to internal async throttler map.
  @visibleForTesting
  Map<String, AsyncThrottler> get testAsyncThrottlers => _asyncThrottlers;

  /// Visible for testing: Access to debouncer timestamp map.
  @visibleForTesting
  Map<String, DateTime> get testDebouncersLastUsed => _debouncersLastUsed;

  /// Visible for testing: Access to throttler timestamp map.
  @visibleForTesting
  Map<String, DateTime> get testThrottlersLastUsed => _throttlersLastUsed;

  /// Visible for testing: Access to async debouncer timestamp map.
  @visibleForTesting
  Map<String, DateTime> get testAsyncDebouncersLastUsed =>
      _asyncDebouncersLastUsed;

  /// Visible for testing: Access to async throttler timestamp map.
  @visibleForTesting
  Map<String, DateTime> get testAsyncThrottlersLastUsed =>
      _asyncThrottlersLastUsed;
}
