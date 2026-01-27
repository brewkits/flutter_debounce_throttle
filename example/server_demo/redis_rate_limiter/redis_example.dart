// Example usage of Redis-backed distributed rate limiting
//
// This example demonstrates:
// 1. Basic Redis connection and rate limiting
// 2. Non-atomic usage (with warnings about race conditions)
// 3. Atomic usage with Lua script (production-ready)
// 4. Middleware patterns for Dart Frog/Shelf
// 5. Error handling and monitoring

// Uncomment these imports when you have Redis package installed:
// import 'dart:io';
// import 'package:redis/redis.dart';
import 'package:dart_debounce_throttle/dart_debounce_throttle.dart';
import 'redis_store_example.dart';

/// Example 1: Basic Redis Rate Limiting (Non-Atomic)
///
/// ⚠️ WARNING: This has race conditions in high-concurrency scenarios!
/// Use only for low-traffic internal APIs or testing.
/// For production, use Example 3 (Atomic Lua Script).
Future<void> example1BasicUsage() async {
  print('=== Example 1: Basic Redis Rate Limiting ===\n');

  // Uncomment when Redis package is installed:
  /*
  // 1. Connect to Redis
  final redisConn = RedisConnection();
  final redis = await redisConn.connect('localhost', 6379);
  print('✓ Connected to Redis');

  // 2. Create store with TTL
  final store = RedisRateLimiterStore(
    redis: redis,
    keyPrefix: 'example:ratelimit:',
    ttl: Duration(minutes: 5), // Auto-expire after 5 minutes
  );

  // 3. Create rate limiter for a user
  final userId = 'user-123';
  final limiter = DistributedRateLimiter(
    key: userId,
    store: store,
    maxTokens: 10,
    refillRate: 2,
    refillInterval: Duration(seconds: 1),
  );

  // 4. Simulate API requests
  print('\nSimulating 12 API requests (limit: 10):');
  for (int i = 1; i <= 12; i++) {
    final allowed = await limiter.tryAcquire();
    if (allowed) {
      print('  Request $i: ✓ Allowed');
    } else {
      print('  Request $i: ✗ Rate limited (wait ${limiter.timeUntilNextToken.inMilliseconds}ms)');
    }
    await Future.delayed(Duration(milliseconds: 100));
  }

  // 5. Wait for refill
  print('\nWaiting 2 seconds for token refill...');
  await Future.delayed(Duration(seconds: 2));

  // 6. Try again (should have ~4 tokens now)
  final allowed = await limiter.tryAcquire();
  print('After refill: ${allowed ? "✓ Allowed" : "✗ Still limited"}');

  // 7. Check store health
  final healthy = await store.isHealthy();
  print('\nRedis health: ${healthy ? "✓ Healthy" : "✗ Unhealthy"}');

  // 8. Cleanup
  await store.clearState(userId);
  print('✓ Cleaned up test data');
  */

  print('\n💡 To run this example:');
  print('   1. Install Redis: brew install redis (macOS) or apt-get install redis (Linux)');
  print('   2. Start Redis: redis-server');
  print('   3. Add to pubspec.yaml: redis: ^4.0.0');
  print('   4. Uncomment the code in this function');
}

/// Example 2: Dart Frog Middleware Pattern
///
/// Rate limiting middleware for Dart Frog applications.
void example2DartFrogMiddleware() {
  print('\n=== Example 2: Dart Frog Middleware ===\n');
  print('File: routes/_middleware.dart\n');
  print('''
import 'package:dart_frog/dart_frog.dart';
import 'package:redis/redis.dart';
import 'your_project/redis_store_example.dart';

// Singleton Redis connection
late final Command redisCommand;
late final RedisRateLimiterStore rateLimitStore;

// Initialize in main.dart or init()
Future<void> init() async {
  final redisConn = RedisConnection();
  redisCommand = await redisConn.connect('localhost', 6379);
  rateLimitStore = RedisRateLimiterStore(
    redis: redisCommand,
    keyPrefix: 'myapp:ratelimit:',
    ttl: Duration(hours: 1),
  );
}

// Rate limiting middleware
Handler rateLimitMiddleware(Handler handler) {
  return (context) async {
    // Get client identifier (IP or user ID)
    final ip = context.request.headers['x-forwarded-for'] ??
               context.request.headers['x-real-ip'] ??
               'unknown';

    // Create limiter for this client
    final limiter = DistributedRateLimiter(
      key: 'ip:\$ip',
      store: rateLimitStore,
      maxTokens: 100,      // 100 requests
      refillRate: 10,      // +10 requests
      refillInterval: Duration(seconds: 1), // per second
    );

    // Check rate limit
    if (!await limiter.tryAcquire()) {
      return Response(
        statusCode: HttpStatus.tooManyRequests,
        headers: {
          'Retry-After': '\${limiter.timeUntilNextToken.inSeconds}',
          'X-RateLimit-Limit': '100',
          'X-RateLimit-Remaining': '0',
          'X-RateLimit-Reset': '\${DateTime.now().add(limiter.timeUntilNextToken).millisecondsSinceEpoch}',
        },
        body: 'Rate limit exceeded. Try again later.',
      );
    }

    // Add rate limit headers to response
    final response = await handler(context);
    return response.copyWith(
      headers: {
        ...response.headers,
        'X-RateLimit-Limit': '100',
        'X-RateLimit-Remaining': '\${limiter.availableTokens.floor()}',
      },
    );
  };
}

// Usage in routes
Handler middleware(Handler handler) {
  return handler
    .use(rateLimitMiddleware)
    .use(requestLogger());
}
''');
}

/// Example 3: Atomic Rate Limiting with Lua Script (Production-Ready)
///
/// This eliminates race conditions by executing all logic server-side.
Future<void> example3AtomicLuaScript() async {
  print('\n=== Example 3: Atomic Lua Script (Production) ===\n');

  // Uncomment when Redis package is installed:
  /*
  final redisConn = RedisConnection();
  final redis = await redisConn.connect('localhost', 6379);

  // Load Lua script
  final luaScript = File('lua/atomic_rate_limit.lua').readAsStringSync();
  print('✓ Loaded Lua script (${luaScript.length} bytes)');

  // Helper function for atomic rate limiting
  Future<bool> tryAcquireAtomic({
    required String key,
    required int maxTokens,
    required double refillRate,
    required Duration refillInterval,
    int tokensToAcquire = 1,
    Duration? ttl,
  }) async {
    final nowMicros = DateTime.now().microsecondsSinceEpoch;
    final ttlSeconds = ttl?.inSeconds ?? 3600;

    final result = await redis.send_object([
      'EVAL',
      luaScript,
      1, // number of keys
      key, // KEYS[1]
      maxTokens, // ARGV[1]
      refillRate, // ARGV[2]
      refillInterval.inMicroseconds, // ARGV[3]
      tokensToAcquire, // ARGV[4]
      nowMicros, // ARGV[5]
      ttlSeconds, // ARGV[6]
    ]) as List;

    final success = result[0] as int;
    final remainingTokens = result[1] as int;

    print('Atomic check: ${success == 1 ? "✓" : "✗"} (remaining: $remainingTokens)');
    return success == 1;
  }

  // Simulate 15 concurrent requests
  print('Simulating 15 concurrent requests (limit: 10):');
  final futures = <Future<bool>>[];
  for (int i = 1; i <= 15; i++) {
    futures.add(tryAcquireAtomic(
      key: 'user:456',
      maxTokens: 10,
      refillRate: 2,
      refillInterval: Duration(seconds: 1),
    ));
  }

  final results = await Future.wait(futures);
  final allowed = results.where((r) => r).length;
  final denied = results.where((r) => !r).length;

  print('\nResults:');
  print('  ✓ Allowed: $allowed');
  print('  ✗ Denied: $denied');
  print('  Expected: 10 allowed, 5 denied');
  print('  Accuracy: ${allowed == 10 ? "✓ 100% accurate" : "✗ Race condition detected!"}');
  */

  print('\n💡 Atomic operations guarantee:');
  print('   • No lost updates');
  print('   • 100% accurate rate limiting');
  print('   • Suitable for payment APIs, compliance systems');
  print('   • Trade-off: ~2-5ms latency overhead');
}

/// Example 4: Multi-Tier Rate Limiting
///
/// Combine different rate limits (per-user, per-IP, global).
Future<void> example4MultiTierLimiting() async {
  print('\n=== Example 4: Multi-Tier Rate Limiting ===\n');

  print('Pattern: Check multiple rate limits in sequence\n');
  print('''
// middleware/multi_tier_rate_limit.dart
Handler multiTierRateLimitMiddleware(Handler handler) {
  return (context) async {
    final ip = context.request.headers['x-forwarded-for'] ?? 'unknown';
    final userId = context.read<User?>()?.id ?? 'anonymous';

    // Tier 1: Global limit (protect against DDoS)
    final globalLimiter = DistributedRateLimiter(
      key: 'global',
      store: rateLimitStore,
      maxTokens: 10000,     // 10k requests
      refillRate: 1000,     // +1k requests
      refillInterval: Duration(seconds: 1),  // per second
    );
    if (!await globalLimiter.tryAcquire()) {
      return Response(503, body: 'Service temporarily unavailable');
    }

    // Tier 2: Per-IP limit (prevent single IP abuse)
    final ipLimiter = DistributedRateLimiter(
      key: 'ip:\$ip',
      store: rateLimitStore,
      maxTokens: 100,       // 100 requests
      refillRate: 10,       // +10 requests
      refillInterval: Duration(seconds: 1),  // per second
    );
    if (!await ipLimiter.tryAcquire()) {
      return Response(429, body: 'Too many requests from this IP');
    }

    // Tier 3: Per-user limit (fair usage)
    if (userId != 'anonymous') {
      final userLimiter = DistributedRateLimiter(
        key: 'user:\$userId',
        store: rateLimitStore,
        maxTokens: 1000,    // 1k requests
        refillRate: 100,    // +100 requests
        refillInterval: Duration(seconds: 1),  // per second
      );
      if (!await userLimiter.tryAcquire()) {
        return Response(429, body: 'User rate limit exceeded');
      }
    }

    // All checks passed
    return handler(context);
  };
}
''');

  print('\n💡 Benefits:');
  print('   • Global limit prevents DDoS');
  print('   • IP limit prevents single-source abuse');
  print('   • User limit ensures fair usage');
  print('   • Different limits for different tiers (free vs premium)');
}

/// Example 5: Monitoring and Observability
///
/// Track rate limit metrics for monitoring.
void example5Monitoring() {
  print('\n=== Example 5: Monitoring & Observability ===\n');

  print('''
// monitoring/rate_limit_metrics.dart
import 'package:prometheus_client/prometheus_client.dart';

final rateLimitCounter = Counter(
  name: 'rate_limit_requests_total',
  help: 'Total rate limit checks',
  labelNames: ['status', 'tier'],
);

final rateLimitHistogram = Histogram(
  name: 'rate_limit_check_duration_seconds',
  help: 'Rate limit check duration',
);

Handler rateLimitWithMetrics(Handler handler) {
  return (context) async {
    final stopwatch = Stopwatch()..start();

    final allowed = await limiter.tryAcquire();

    rateLimitCounter.labels([
      allowed ? 'allowed' : 'denied',
      'user',
    ]).inc();

    rateLimitHistogram.observe(stopwatch.elapsedMicroseconds / 1000000);

    if (!allowed) {
      return Response(429, body: 'Rate limited');
    }

    return handler(context);
  };
}

// Alert on high rate limit denials
// Prometheus query:
// rate(rate_limit_requests_total{status="denied"}[5m]) > 100
''');

  print('\n💡 Metrics to track:');
  print('   • Rate limit hit rate (denied / total)');
  print('   • Check latency (p50, p95, p99)');
  print('   • Redis connection errors');
  print('   • Top rate-limited IPs/users');
}

/// Main function: Run all examples
void main() async {
  print('╔════════════════════════════════════════════════════════╗');
  print('║  Redis Rate Limiting Examples                         ║');
  print('║  dart_debounce_throttle v2.4.2                        ║');
  print('╚════════════════════════════════════════════════════════╝\n');

  await example1BasicUsage();
  example2DartFrogMiddleware();
  await example3AtomicLuaScript();
  await example4MultiTierLimiting();
  example5Monitoring();

  print('\n' + '═' * 60);
  print('📚 Next Steps:');
  print('═' * 60);
  print('1. Copy redis_store_example.dart to your project');
  print('2. Add redis: ^4.0.0 to pubspec.yaml');
  print('3. For production: Use Lua script (example 3)');
  print('4. Add monitoring (example 5)');
  print('5. Test with realistic traffic patterns');
  print('');
  print('📖 Full documentation: README.md');
  print('═' * 60 + '\n');
}
