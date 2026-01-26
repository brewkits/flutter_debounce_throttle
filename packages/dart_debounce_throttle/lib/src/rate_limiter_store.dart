// Pure Dart - no Flutter dependencies.
//
// Storage interface for RateLimiter state persistence.
//
// Enables distributed rate limiting across multiple instances/servers
// by storing token state in Redis, Memcached, or databases.

/// Token state data structure.
///
/// Contains the current token count and last refill timestamp.
class RateLimiterState {
  /// Current number of tokens available.
  final double tokens;

  /// Last refill time in microseconds (from Stopwatch or epoch time).
  final int lastRefillMicroseconds;

  const RateLimiterState({
    required this.tokens,
    required this.lastRefillMicroseconds,
  });

  /// Create state from list format [tokens, lastRefillMicroseconds].
  factory RateLimiterState.fromList(List<num> data) {
    if (data.isEmpty) {
      return const RateLimiterState(tokens: 0, lastRefillMicroseconds: 0);
    }
    return RateLimiterState(
      tokens: data.length > 0 ? data[0].toDouble() : 0,
      lastRefillMicroseconds: data.length > 1 ? data[1].toInt() : 0,
    );
  }

  /// Convert to list format for storage.
  List<num> toList() => [tokens, lastRefillMicroseconds];

  @override
  String toString() =>
      'RateLimiterState(tokens: $tokens, lastRefill: $lastRefillMicroseconds)';
}

/// Synchronous storage interface for rate limiter state.
///
/// Use this for in-memory stores or when you need synchronous access.
/// For distributed systems (Redis, databases), use [AsyncRateLimiterStore] instead.
///
/// **Example (Custom sync store):**
/// ```dart
/// class FileStore implements RateLimiterStore {
///   final Map<String, RateLimiterState> _cache = {};
///
///   @override
///   RateLimiterState fetchState(String key) {
///     return _cache[key] ?? RateLimiterState(tokens: 0, lastRefillMicroseconds: 0);
///   }
///
///   @override
///   void saveState(String key, RateLimiterState state) {
///     _cache[key] = state;
///     // Optionally persist to file
///   }
/// }
/// ```
abstract class RateLimiterStore {
  /// Fetch the current state for the given key.
  ///
  /// Returns a [RateLimiterState] with tokens=0 if key doesn't exist.
  RateLimiterState fetchState(String key);

  /// Save the new state for the given key.
  void saveState(String key, RateLimiterState state);

  /// Optional: Clear state for a key (reset to initial state).
  void clearState(String key) {
    saveState(key, const RateLimiterState(tokens: 0, lastRefillMicroseconds: 0));
  }

  /// Optional: Clear all stored states.
  void clearAll();
}

/// Asynchronous storage interface for distributed rate limiting.
///
/// Use this for Redis, Memcached, databases, or any remote storage.
///
/// **Example (Redis store):**
/// ```dart
/// class RedisStore implements AsyncRateLimiterStore {
///   final RedisConnection redis;
///
///   RedisStore(this.redis);
///
///   @override
///   Future<RateLimiterState> fetchState(String key) async {
///     final data = await redis.get(key);
///     if (data == null) {
///       return RateLimiterState(tokens: 0, lastRefillMicroseconds: 0);
///     }
///     final parts = data.split(',');
///     return RateLimiterState(
///       tokens: double.parse(parts[0]),
///       lastRefillMicroseconds: int.parse(parts[1]),
///     );
///   }
///
///   @override
///   Future<void> saveState(String key, RateLimiterState state) async {
///     await redis.set(key, '${state.tokens},${state.lastRefillMicroseconds}');
///   }
/// }
/// ```
abstract class AsyncRateLimiterStore {
  /// Fetch the current state for the given key.
  ///
  /// Returns a [RateLimiterState] with tokens=0 if key doesn't exist.
  Future<RateLimiterState> fetchState(String key);

  /// Save the new state for the given key.
  Future<void> saveState(String key, RateLimiterState state);

  /// Optional: Clear state for a key (reset to initial state).
  Future<void> clearState(String key) async {
    await saveState(
        key, const RateLimiterState(tokens: 0, lastRefillMicroseconds: 0));
  }

  /// Optional: Clear all stored states.
  Future<void> clearAll();
}

/// Default in-memory store for [RateLimiter].
///
/// This is the default store used by [RateLimiter] when no store is provided.
/// Stores state in RAM - fast but not shared across instances/servers.
///
/// **Usage:**
/// ```dart
/// final store = InMemoryRateLimiterStore();
/// final limiter = RateLimiter(
///   maxTokens: 10,
///   refillRate: 1,
///   refillInterval: Duration(seconds: 1),
///   store: store,
///   key: 'user-123',
/// );
/// ```
class InMemoryRateLimiterStore implements RateLimiterStore {
  final Map<String, RateLimiterState> _cache = {};

  @override
  RateLimiterState fetchState(String key) {
    return _cache[key] ??
        const RateLimiterState(tokens: 0, lastRefillMicroseconds: 0);
  }

  @override
  void saveState(String key, RateLimiterState state) {
    _cache[key] = state;
  }

  @override
  void clearState(String key) {
    _cache.remove(key);
  }

  @override
  void clearAll() {
    _cache.clear();
  }

  /// Get the number of keys stored.
  int get keyCount => _cache.length;

  /// Check if a key exists in the store.
  bool containsKey(String key) => _cache.containsKey(key);
}

/// Default in-memory async store for [DistributedRateLimiter].
///
/// Async version of [InMemoryRateLimiterStore] for testing distributed
/// rate limiter logic without actual remote storage.
///
/// **Usage:**
/// ```dart
/// final store = AsyncInMemoryRateLimiterStore();
/// final limiter = DistributedRateLimiter(
///   key: 'api-user-123',
///   store: store,
///   maxTokens: 100,
///   refillRate: 10,
///   refillInterval: Duration(seconds: 1),
/// );
///
/// if (await limiter.tryAcquire()) {
///   await processRequest();
/// }
/// ```
class AsyncInMemoryRateLimiterStore implements AsyncRateLimiterStore {
  final Map<String, RateLimiterState> _cache = {};

  @override
  Future<RateLimiterState> fetchState(String key) async {
    return _cache[key] ??
        const RateLimiterState(tokens: 0, lastRefillMicroseconds: 0);
  }

  @override
  Future<void> saveState(String key, RateLimiterState state) async {
    _cache[key] = state;
  }

  @override
  Future<void> clearState(String key) async {
    _cache.remove(key);
  }

  @override
  Future<void> clearAll() async {
    _cache.clear();
  }

  /// Get the number of keys stored.
  int get keyCount => _cache.length;

  /// Check if a key exists in the store.
  bool containsKey(String key) => _cache.containsKey(key);
}
