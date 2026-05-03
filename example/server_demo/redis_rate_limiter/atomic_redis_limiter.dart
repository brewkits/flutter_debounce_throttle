// Atomic Redis Rate Limiter using Lua scripts
//
// This eliminates race conditions by executing all logic server-side.
//
// ⚠️ COPY THIS FILE TO YOUR PROJECT
//
// Requirements:
// - redis: ^4.0.0 (add to pubspec.yaml)

import 'dart:io';
// import 'package:redis/redis.dart'; // Uncomment when using

/// Atomic Redis-based rate limiter using Lua scripts.
///
/// Unlike the basic `RedisRateLimiterStore` which has race conditions,
/// this implementation is 100% accurate by executing all logic atomically
/// on the Redis server using Lua scripts.
///
/// **Example:**
/// ```dart
/// final redisConn = RedisConnection();
/// final redis = await redisConn.connect('localhost', 6379);
///
/// final limiter = AtomicRedisRateLimiter(
///   redis: redis,
///   luaScriptPath: 'lua/atomic_rate_limit.lua',
/// );
///
/// // 100% accurate, no race conditions
/// if (await limiter.tryAcquire(
///   key: 'user:123',
///   maxTokens: 100,
///   refillRate: 10,
///   refillInterval: Duration(seconds: 1),
/// )) {
///   return await handleRequest();
/// } else {
///   return Response.tooManyRequests();
/// }
/// ```
///
/// **Trade-offs:**
/// - ✅ 100% accurate (no lost updates)
/// - ✅ Thread-safe across all server instances
/// - ❌ ~2-5ms latency overhead vs non-atomic
/// - ❌ Requires Lua script deployment
///
/// **When to use:**
/// - Payment APIs (strict accuracy required)
/// - Compliance systems (audit requirements)
/// - High-concurrency environments (>100 req/s per key)
///
/// **When NOT to use:**
/// - Internal APIs (eventual consistency OK)
/// - Low traffic (<10 req/s per key)
/// - Non-critical rate limiting
class AtomicRedisRateLimiter {
  /// Redis connection/command interface.
  final dynamic redis; // Type is 'Command' from package:redis

  /// Loaded Lua script content.
  final String _luaScript;

  /// Creates an atomic Redis rate limiter.
  ///
  /// - [redis]: Command object from package:redis
  /// - [luaScriptPath]: Path to atomic_rate_limit.lua file
  AtomicRedisRateLimiter({required this.redis, required String luaScriptPath})
    : _luaScript = File(luaScriptPath).readAsStringSync();

  /// Try to acquire tokens atomically (no race conditions).
  ///
  /// All computation happens server-side in Redis using Lua script.
  /// Returns `true` if tokens acquired, `false` if rate limited.
  ///
  /// **Example:**
  /// ```dart
  /// if (await limiter.tryAcquire(
  ///   key: 'user:${userId}',
  ///   maxTokens: 100,
  ///   refillRate: 10,
  ///   refillInterval: Duration(seconds: 1),
  /// )) {
  ///   // Process request
  /// } else {
  ///   // Rate limited
  /// }
  /// ```
  Future<bool> tryAcquire({
    required String key,
    required int maxTokens,
    required double refillRate,
    required Duration refillInterval,
    int tokensToAcquire = 1,
    Duration? ttl,
  }) async {
    final nowMicros = DateTime.now().microsecondsSinceEpoch;
    final ttlSeconds = ttl?.inSeconds ?? 3600;

    try {
      // Execute Lua script atomically on Redis server
      final result =
          await redis.send_object([
                'EVAL',
                _luaScript,
                1, // number of keys
                key, // KEYS[1]
                maxTokens, // ARGV[1]
                refillRate, // ARGV[2]
                refillInterval.inMicroseconds, // ARGV[3]
                tokensToAcquire, // ARGV[4]
                nowMicros, // ARGV[5]
                ttlSeconds, // ARGV[6]
              ])
              as List;

      final success = result[0] as int;
      final remainingTokens = result[1] as int;

      return success == 1;
    } catch (e) {
      // On error, fail open (allow request) to prevent service disruption
      // In production, log this error and alert
      print('ERROR: Atomic rate limit failed for key $key: $e');
      return true; // Fail-safe: allow access
    }
  }

  /// Get remaining tokens for a key.
  ///
  /// Returns the current number of tokens available.
  /// This is a read-only operation and doesn't consume tokens.
  Future<int> getRemainingTokens({
    required String key,
    required int maxTokens,
    required double refillRate,
    required Duration refillInterval,
  }) async {
    final nowMicros = DateTime.now().microsecondsSinceEpoch;

    try {
      final result =
          await redis.send_object([
                'EVAL',
                _luaScript,
                1,
                key,
                maxTokens,
                refillRate,
                refillInterval.inMicroseconds,
                0, // Don't consume any tokens
                nowMicros,
                0, // No TTL
              ])
              as List;

      return result[1] as int;
    } catch (e) {
      print('ERROR: Failed to get remaining tokens for $key: $e');
      return maxTokens; // Fail-safe: assume full capacity
    }
  }

  /// Clear rate limit state for a key.
  ///
  /// Resets the token bucket to initial state (full capacity).
  Future<void> clear(String key) async {
    try {
      await redis.send_object(['DEL', key]);
    } catch (e) {
      print('ERROR: Failed to clear rate limit for $key: $e');
    }
  }

  /// Check Redis connection health.
  Future<bool> isHealthy() async {
    try {
      final response = await redis.send_object(['PING']);
      return response == 'PONG';
    } catch (e) {
      return false;
    }
  }
}

/// Example usage with Dart Frog middleware
///
/// ```dart
/// // routes/_middleware.dart
/// import 'package:dart_frog/dart_frog.dart';
/// import 'package:redis/redis.dart';
/// import 'atomic_redis_limiter.dart';
///
/// late final AtomicRedisRateLimiter limiter;
///
/// Future<void> init() async {
///   final redisConn = RedisConnection();
///   final redis = await redisConn.connect('localhost', 6379);
///
///   limiter = AtomicRedisRateLimiter(
///     redis: redis,
///     luaScriptPath: 'lua/atomic_rate_limit.lua',
///   );
/// }
///
/// Handler rateLimitMiddleware(Handler handler) {
///   return (context) async {
///     final ip = context.request.headers['x-forwarded-for'] ?? 'unknown';
///
///     if (!await limiter.tryAcquire(
///       key: 'ip:$ip',
///       maxTokens: 100,
///       refillRate: 10,
///       refillInterval: Duration(seconds: 1),
///     )) {
///       return Response(statusCode: 429, body: 'Rate limited');
///     }
///
///     return handler(context);
///   };
/// }
/// ```
