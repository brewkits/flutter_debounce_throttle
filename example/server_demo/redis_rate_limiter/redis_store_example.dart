// Pure Dart - no Flutter dependencies.
//
// Redis implementation of AsyncRateLimiterStore.
//
// ⚠️ COPY THIS FILE TO YOUR PROJECT AND CUSTOMIZE AS NEEDED
//
// This is a REFERENCE IMPLEMENTATION showing how to integrate Redis.
// You'll need to add the 'redis' package to your pubspec.yaml:
//
// dependencies:
//   redis: ^4.0.0  # or latest version
//
// Then import it:
// import 'package:redis/redis.dart';

import 'package:dart_debounce_throttle/dart_debounce_throttle.dart';

/// Redis-backed async store for distributed rate limiting.
///
/// **Requirements:**
/// Add to pubspec.yaml:
/// ```yaml
/// dependencies:
///   redis: ^4.0.0
/// ```
///
/// **Setup:**
/// ```dart
/// // 1. Connect to Redis
/// final redisConn = RedisConnection();
/// final redis = await redisConn.connect('localhost', 6379);
///
/// // 2. Create store
/// final store = RedisRateLimiterStore(
///   redis: redis,
///   keyPrefix: 'ratelimit:', // Optional namespace
///   ttl: Duration(hours: 1),   // Optional auto-expire
/// );
///
/// // 3. Use with DistributedRateLimiter
/// final limiter = DistributedRateLimiter(
///   key: 'user-${userId}',
///   store: store,
///   maxTokens: 100,
///   refillRate: 10,
///   refillInterval: Duration(seconds: 1),
/// );
///
/// // 4. Rate limit API calls
/// if (await limiter.tryAcquire()) {
///   return await handleRequest();
/// } else {
///   return Response.tooManyRequests();
/// }
/// ```
///
/// **Server-side example (with Dart Frog or Shelf):**
/// ```dart
/// // middleware/rate_limiter.dart
/// import 'package:dart_frog/dart_frog.dart';
/// import 'package:redis/redis.dart';
///
/// final redisStore = RedisRateLimiterStore(...);
///
/// Handler rateLimitMiddleware(Handler handler) {
///   return (context) async {
///     final ip = context.request.headers['x-forwarded-for'] ?? 'unknown';
///     final limiter = DistributedRateLimiter(
///       key: 'ip:$ip',
///       store: redisStore,
///       maxTokens: 100,
///       refillRate: 10,
///       refillInterval: Duration(seconds: 1),
///     );
///
///     if (!await limiter.tryAcquire()) {
///       return Response(
///         statusCode: HttpStatus.tooManyRequests,
///         headers: {
///           'Retry-After': limiter.timeUntilNextToken.inSeconds.toString(),
///         },
///         body: 'Rate limit exceeded',
///       );
///     }
///
///     return handler(context);
///   };
/// }
/// ```
///
/// **Important notes:**
/// - Keys are stored as: `{keyPrefix}{key}` (e.g., "ratelimit:user-123")
/// - State format: "tokens,lastRefillMicros" (e.g., "9.5,1234567890")
/// - Optional TTL for auto-expiration (prevents stale keys)
/// - Thread-safe: Redis operations are atomic
class RedisRateLimiterStore implements AsyncRateLimiterStore {
  /// Redis connection/command interface.
  ///
  /// This should be the `Command` object from package:redis.
  /// Example: `final redis = await redisConn.connect('localhost', 6379);`
  final dynamic redis; // Type is 'Command' from package:redis

  /// Prefix for all keys (helps namespace and avoid collisions).
  final String keyPrefix;

  /// Optional TTL for auto-expiration of keys.
  ///
  /// If set, Redis will automatically delete keys after this duration
  /// of inactivity. Useful for cleaning up inactive users.
  final Duration? ttl;

  /// Creates a Redis store.
  ///
  /// - [redis]: Command object from package:redis
  /// - [keyPrefix]: Namespace prefix (default: 'ratelimit:')
  /// - [ttl]: Auto-expire duration (optional, e.g., Duration(hours: 24))
  RedisRateLimiterStore({
    required this.redis,
    this.keyPrefix = 'ratelimit:',
    this.ttl,
  });

  String _makeKey(String key) => '$keyPrefix$key';

  @override
  Future<RateLimiterState> fetchState(String key) async {
    try {
      final fullKey = _makeKey(key);
      // Redis GET command returns String or null
      final value = await redis.get(fullKey) as String?;

      if (value == null) {
        // Key doesn't exist, return initial state
        return const RateLimiterState(tokens: 0, lastRefillMicroseconds: 0);
      }

      // Parse format: "tokens,lastRefillMicros"
      final parts = value.split(',');
      if (parts.length != 2) {
        // Invalid format, return initial state
        return const RateLimiterState(tokens: 0, lastRefillMicroseconds: 0);
      }

      return RateLimiterState(
        tokens: double.tryParse(parts[0]) ?? 0,
        lastRefillMicroseconds: int.tryParse(parts[1]) ?? 0,
      );
    } catch (e) {
      // On error, return initial state (fail-safe: allow access)
      // In production, you might want to log this error
      return const RateLimiterState(tokens: 0, lastRefillMicroseconds: 0);
    }
  }

  @override
  Future<void> saveState(String key, RateLimiterState state) async {
    try {
      final fullKey = _makeKey(key);
      final value = '${state.tokens},${state.lastRefillMicroseconds}';

      if (ttl != null) {
        // SET with TTL (EX = seconds)
        await redis.send_object(['SET', fullKey, value, 'EX', ttl!.inSeconds]);
      } else {
        // SET without TTL
        await redis.set(fullKey, value);
      }
    } catch (e) {
      // On error, silently fail (don't block the request)
      // In production, you might want to log this error
    }
  }

  @override
  Future<void> clearState(String key) async {
    try {
      final fullKey = _makeKey(key);
      await redis.send_object(['DEL', fullKey]);
    } catch (e) {
      // Silently fail
    }
  }

  @override
  Future<void> clearAll() async {
    try {
      // WARNING: This scans all keys with the prefix and deletes them.
      // Use with caution in production! Consider using Redis SCAN for large datasets.
      final pattern = '$keyPrefix*';
      final keys = await redis.send_object(['KEYS', pattern]) as List;

      if (keys.isNotEmpty) {
        await redis.send_object(['DEL', ...keys]);
      }
    } catch (e) {
      // Silently fail
    }
  }

  /// Check Redis connection health.
  ///
  /// Returns true if PING succeeds, false otherwise.
  Future<bool> isHealthy() async {
    try {
      final response = await redis.send_object(['PING']);
      return response == 'PONG';
    } catch (e) {
      return false;
    }
  }

  /// Get the number of rate limiter keys stored in Redis.
  ///
  /// WARNING: Uses KEYS command which can be slow on large datasets.
  /// In production, consider using SCAN instead or track count separately.
  Future<int> getKeyCount() async {
    try {
      final pattern = '$keyPrefix*';
      final keys = await redis.send_object(['KEYS', pattern]) as List;
      return keys.length;
    } catch (e) {
      return 0;
    }
  }
}

/// Memcached-backed async store for distributed rate limiting.
///
/// Similar to Redis but for Memcached. Requires 'memcache' package.
///
/// **Requirements:**
/// ```yaml
/// dependencies:
///   memcache: ^3.0.0  # or latest
/// ```
///
/// **Example:**
/// ```dart
/// import 'package:memcache/memcache.dart';
///
/// final memcache = Client([Connection('localhost', 11211)]);
/// final store = MemcachedRateLimiterStore(
///   client: memcache,
///   keyPrefix: 'ratelimit:',
///   ttl: Duration(hours: 1),
/// );
///
/// final limiter = DistributedRateLimiter(
///   key: 'user-123',
///   store: store,
///   maxTokens: 100,
///   refillRate: 10,
///   refillInterval: Duration(seconds: 1),
/// );
/// ```
class MemcachedRateLimiterStore implements AsyncRateLimiterStore {
  /// Memcache client from package:memcache
  final dynamic client; // Type is 'Client' from package:memcache

  /// Prefix for all keys
  final String keyPrefix;

  /// TTL for keys (Memcached will auto-delete after this duration)
  final Duration ttl;

  MemcachedRateLimiterStore({
    required this.client,
    this.keyPrefix = 'ratelimit:',
    this.ttl = const Duration(hours: 1),
  });

  String _makeKey(String key) => '$keyPrefix$key';

  @override
  Future<RateLimiterState> fetchState(String key) async {
    try {
      final fullKey = _makeKey(key);
      final value = await client.get(fullKey) as String?;

      if (value == null) {
        return const RateLimiterState(tokens: 0, lastRefillMicroseconds: 0);
      }

      final parts = value.split(',');
      if (parts.length != 2) {
        return const RateLimiterState(tokens: 0, lastRefillMicroseconds: 0);
      }

      return RateLimiterState(
        tokens: double.tryParse(parts[0]) ?? 0,
        lastRefillMicroseconds: int.tryParse(parts[1]) ?? 0,
      );
    } catch (e) {
      return const RateLimiterState(tokens: 0, lastRefillMicroseconds: 0);
    }
  }

  @override
  Future<void> saveState(String key, RateLimiterState state) async {
    try {
      final fullKey = _makeKey(key);
      final value = '${state.tokens},${state.lastRefillMicroseconds}';
      await client.set(fullKey, value, expiration: ttl.inSeconds);
    } catch (e) {
      // Silently fail
    }
  }

  @override
  Future<void> clearState(String key) async {
    try {
      final fullKey = _makeKey(key);
      await client.delete(fullKey);
    } catch (e) {
      // Silently fail
    }
  }

  @override
  Future<void> clearAll() async {
    // Memcached doesn't support wildcard deletion
    // You would need to track keys separately or flush all cache
    // await client.flush(); // Nuclear option: clears ALL cache
    throw UnimplementedError(
        'Memcached does not support pattern-based deletion. '
        'Consider using Redis or tracking keys separately.');
  }
}
