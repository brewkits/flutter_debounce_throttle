// Pure Dart - no Flutter dependencies.
//
// Distributed rate limiter using async storage (Redis, Memcached, databases).

import 'dart:math' as math;

import 'logger.dart';
import 'rate_limiter_store.dart';

/// Distributed rate limiter for server-side applications.
///
/// Unlike [RateLimiter] which runs synchronously in-memory, this limiter
/// is fully asynchronous and stores state in external storage (Redis, Memcached, etc).
/// This enables rate limiting across multiple server instances.
///
/// **Use cases:**
/// - API rate limiting across multiple backend servers
/// - Multi-tenant SaaS rate limiting by user/org
/// - Distributed microservices rate limiting
/// - Cloud functions rate limiting
///
/// **Example (Basic usage with async in-memory store):**
/// ```dart
/// final store = AsyncInMemoryRateLimiterStore();
/// final limiter = DistributedRateLimiter(
///   key: 'user-123',
///   store: store,
///   maxTokens: 100,
///   refillRate: 10,
///   refillInterval: Duration(seconds: 1),
/// );
///
/// if (await limiter.tryAcquire()) {
///   await processRequest();
/// } else {
///   throw RateLimitExceededException();
/// }
/// ```
///
/// **Example (Production with Redis):**
/// ```dart
/// import 'package:redis/redis.dart';
/// import 'package:dart_debounce_throttle/src/rate_limiter_stores/redis_store.dart';
///
/// // Setup Redis connection
/// final redisConn = RedisConnection();
/// final redis = await redisConn.connect('localhost', 6379);
/// final store = RedisRateLimiterStore(
///   redis: redis,
///   keyPrefix: 'api:ratelimit:',
///   ttl: Duration(hours: 1),
/// );
///
/// // Rate limiter for API endpoint
/// Future<Response> handleApiRequest(String userId) async {
///   final limiter = DistributedRateLimiter(
///     key: 'user:$userId',
///     store: store,
///     maxTokens: 1000,         // Burst capacity
///     refillRate: 100,         // 100 requests per second sustained
///     refillInterval: Duration(seconds: 1),
///     name: 'api-limiter',
///     debugMode: true,
///   );
///
///   if (!await limiter.tryAcquire()) {
///     return Response.tooManyRequests(
///       retryAfter: await limiter.timeUntilNextToken,
///     );
///   }
///
///   return await processRequest();
/// }
/// ```
///
/// **Example (Middleware for Dart Frog):**
/// ```dart
/// Handler rateLimitMiddleware(Handler handler) {
///   final store = RedisRateLimiterStore(...);
///
///   return (context) async {
///     final userId = context.read<User>().id;
///     final limiter = DistributedRateLimiter(
///       key: 'user:$userId',
///       store: store,
///       maxTokens: 100,
///       refillRate: 10,
///       refillInterval: Duration(seconds: 1),
///     );
///
///     if (!await limiter.tryAcquire()) {
///       return Response(statusCode: HttpStatus.tooManyRequests);
///     }
///
///     return handler(context);
///   };
/// }
/// ```
class DistributedRateLimiter with EventLimiterLogging {
  /// Unique identifier for this rate limiter (e.g., user ID, IP, API key).
  final String key;

  /// Storage backend for persisting token state.
  final AsyncRateLimiterStore store;

  /// Maximum tokens in the bucket (burst capacity).
  final int maxTokens;

  /// Number of tokens to add per [refillInterval].
  final int refillRate;

  /// How often tokens are refilled.
  final Duration refillInterval;

  /// Whether rate limiting is enabled. If false, all calls succeed.
  final bool enabled;

  @override
  final bool debugMode;

  @override
  final String? name;

  /// Callback for metrics tracking.
  final void Function(int tokensRemaining, bool acquired)? onMetrics;

  /// Use epoch time instead of Stopwatch for timestamps.
  ///
  /// Default: true (epoch time is required for distributed systems).
  /// Set to false only for testing with Stopwatch.
  final bool useEpochTime;

  /// Creates a distributed rate limiter.
  ///
  /// - [key]: Unique identifier (e.g., "user-123", "ip-192.168.1.1")
  /// - [store]: Storage backend (Redis, Memcached, etc)
  /// - [maxTokens]: Maximum tokens (burst capacity). Must be > 0.
  /// - [refillRate]: Tokens added per interval. Defaults to 1.
  /// - [refillInterval]: How often tokens refill. Defaults to 1 second.
  /// - [enabled]: If false, all calls succeed without consuming tokens.
  /// - [debugMode]: Enable debug logging.
  /// - [name]: Optional name for logging.
  /// - [onMetrics]: Callback fired on each acquire attempt.
  /// - [useEpochTime]: Use epoch microseconds (required for distributed systems).
  DistributedRateLimiter({
    required this.key,
    required this.store,
    required this.maxTokens,
    this.refillRate = 1,
    this.refillInterval = const Duration(seconds: 1),
    this.enabled = true,
    this.debugMode = false,
    this.name,
    this.onMetrics,
    this.useEpochTime = true,
  })  : assert(key.isNotEmpty, 'key cannot be empty'),
        assert(maxTokens > 0, 'maxTokens must be positive'),
        assert(refillRate > 0, 'refillRate must be positive');

  /// Get current time in microseconds.
  int _nowMicroseconds() {
    return useEpochTime
        ? DateTime.now().microsecondsSinceEpoch
        : 0; // Stopwatch not supported in distributed mode
  }

  /// Refill tokens based on elapsed time since last refill.
  ///
  /// Returns new [RateLimiterState] with updated tokens and timestamp.
  RateLimiterState _calculateRefill(RateLimiterState currentState) {
    final nowMicros = _nowMicroseconds();
    final lastRefillMicros = currentState.lastRefillMicroseconds;

    // First time initialization
    if (lastRefillMicros == 0) {
      debugLog('First access for key "$key", initializing with $maxTokens tokens');
      return RateLimiterState(
        tokens: maxTokens.toDouble(),
        lastRefillMicroseconds: nowMicros,
      );
    }

    final elapsedMicros = nowMicros - lastRefillMicros;
    if (elapsedMicros < 0) {
      // Clock went backwards (should never happen with epoch time)
      debugLog('WARNING: Clock went backwards! Using current state.');
      return currentState;
    }

    final intervalsElapsed = elapsedMicros / refillInterval.inMicroseconds;
    final tokensToAdd = intervalsElapsed * refillRate;

    if (tokensToAdd > 0) {
      final newTokens =
          math.min(maxTokens.toDouble(), currentState.tokens + tokensToAdd);
      debugLog(
          'Refilled ${tokensToAdd.toStringAsFixed(2)} tokens for key "$key", '
          'now at ${newTokens.toStringAsFixed(2)}');
      return RateLimiterState(
        tokens: newTokens,
        lastRefillMicroseconds: nowMicros,
      );
    }

    return currentState;
  }

  /// Try to acquire [tokens] tokens. Returns true if successful.
  ///
  /// This is the main method for checking rate limits.
  /// It fetches state from storage, calculates refill, attempts acquisition,
  /// and saves the new state back.
  ///
  /// **Thread safety:** This implementation is eventually consistent.
  /// For strict atomic operations, you need to use Redis Lua scripts
  /// or database transactions in your store implementation.
  Future<bool> tryAcquire([int tokens = 1]) async {
    if (!enabled) {
      debugLog('Rate limiting disabled for key "$key", allowing acquire');
      onMetrics?.call(maxTokens, true);
      return true;
    }

    // 1. Fetch current state from store
    final currentState = await store.fetchState(key);

    // 2. Calculate refill
    final refilledState = _calculateRefill(currentState);

    // 3. Check if enough tokens
    if (refilledState.tokens >= tokens) {
      // 4. Consume tokens and save
      final newState = RateLimiterState(
        tokens: refilledState.tokens - tokens,
        lastRefillMicroseconds: refilledState.lastRefillMicroseconds,
      );

      await store.saveState(key, newState);

      debugLog('Acquired $tokens token(s) for key "$key", '
          '${newState.tokens.toStringAsFixed(2)} remaining');
      onMetrics?.call(newState.tokens.floor(), true);
      return true;
    }

    debugLog('Failed to acquire $tokens token(s) for key "$key", '
        'only ${refilledState.tokens.toStringAsFixed(2)} available');
    onMetrics?.call(refilledState.tokens.floor(), false);
    return false;
  }

  /// Execute async [callback] if token is available, otherwise return null.
  ///
  /// Returns the callback result or null if rate limited.
  Future<T?> callAsync<T>(Future<T> Function() callback,
      [int tokens = 1]) async {
    if (await tryAcquire(tokens)) {
      return await callback();
    }
    return null;
  }

  /// Get current available tokens (rounded down).
  Future<int> get availableTokens async {
    final currentState = await store.fetchState(key);
    final refilledState = _calculateRefill(currentState);
    return refilledState.tokens.floor();
  }

  /// Whether at least one token is available.
  Future<bool> get canAcquire async {
    final currentState = await store.fetchState(key);
    final refilledState = _calculateRefill(currentState);
    return refilledState.tokens >= 1;
  }

  /// Time until next token is available.
  ///
  /// Returns [Duration.zero] if tokens are already available.
  Future<Duration> get timeUntilNextToken async {
    final currentState = await store.fetchState(key);
    final refilledState = _calculateRefill(currentState);

    if (refilledState.tokens >= 1) {
      return Duration.zero;
    }

    // Calculate time needed to refill to 1 token
    final tokensNeeded = 1 - refilledState.tokens;
    final intervalsNeeded = tokensNeeded / refillRate;
    final microseconds =
        (intervalsNeeded * refillInterval.inMicroseconds).ceil();

    return Duration(microseconds: microseconds);
  }

  /// Reset to full capacity.
  Future<void> reset() async {
    final newState = RateLimiterState(
      tokens: maxTokens.toDouble(),
      lastRefillMicroseconds: _nowMicroseconds(),
    );
    await store.saveState(key, newState);
    debugLog('Reset key "$key" to full capacity ($maxTokens tokens)');
  }

  /// Clear this limiter's state from storage.
  Future<void> dispose() async {
    await store.clearState(key);
    debugLog('Disposed limiter for key "$key"');
  }
}
