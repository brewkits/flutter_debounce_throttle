# Redis Rate Limiting for Distributed Systems

This example demonstrates how to implement distributed rate limiting using Redis for server-side Dart applications (Dart Frog, Shelf, backend microservices).

## ⚠️ Important: For Server-Side Only

**DO NOT use Redis directly from Flutter mobile apps!**

- ✅ **Server-side**: Dart Frog, Shelf, backend microservices
- ❌ **Mobile apps**: Never connect mobile apps directly to Redis (security risk)

For Flutter UI rate limiting (button clicks, scroll events), use the core package without Redis.

## Quick Start

### 1. Add Dependencies

```yaml
dependencies:
  dart_debounce_throttle: ^2.4.2
  redis: ^4.0.0  # or latest version
```

### 2. Copy the Store Implementation

Copy `redis_store_example.dart` to your project and customize as needed.

### 3. Basic Usage

```dart
import 'package:redis/redis.dart';
import 'your_project/redis_store_example.dart';

// 1. Connect to Redis
final redisConn = RedisConnection();
final redis = await redisConn.connect('localhost', 6379);

// 2. Create store
final store = RedisRateLimiterStore(
  redis: redis,
  keyPrefix: 'ratelimit:',
  ttl: Duration(hours: 1),
);

// 3. Create rate limiter
final limiter = DistributedRateLimiter(
  key: 'user-${userId}',
  store: store,
  maxTokens: 100,
  refillRate: 10,
  refillInterval: Duration(seconds: 1),
);

// 4. Rate limit API calls
if (await limiter.tryAcquire()) {
  return await handleRequest();
} else {
  return Response.tooManyRequests();
}
```

## 🔒 Production: Atomic Operations Required

**The basic implementation has race conditions!** In high-concurrency scenarios, the fetch-calculate-save pattern can lose updates:

```
Server A: fetch (tokens=10) → compute (9) → save (9)
Server B: fetch (tokens=10) → compute (9) → save (9)
Expected: 8, Actual: 9 ❌ Lost update!
```

### Solution: Use Lua Scripts

Redis Lua scripts execute atomically, eliminating race conditions.

**See: `lua/atomic_rate_limit.lua`** for a production-ready implementation.

#### Using the Lua Script

```dart
import 'dart:io';
import 'package:redis/redis.dart';

class AtomicRedisRateLimiter {
  final Command redis;
  final String luaScript;

  AtomicRedisRateLimiter(this.redis, {required String scriptPath})
      : luaScript = File(scriptPath).readAsStringSync();

  Future<bool> tryAcquire({
    required String key,
    required int maxTokens,
    required double refillRate,
    required int refillIntervalMicros,
    int tokensToAcquire = 1,
    Duration? ttl,
  }) async {
    final nowMicros = DateTime.now().microsecondsSinceEpoch;
    final ttlSeconds = ttl?.inSeconds ?? 3600;

    // Execute Lua script atomically
    final result = await redis.send_object([
      'EVAL',
      luaScript,
      1, // number of keys
      key, // KEYS[1]
      maxTokens, // ARGV[1]
      refillRate, // ARGV[2]
      refillIntervalMicros, // ARGV[3]
      tokensToAcquire, // ARGV[4]
      nowMicros, // ARGV[5]
      ttlSeconds, // ARGV[6]
    ]) as List;

    final success = result[0] as int;
    final remainingTokens = result[1] as int;

    print('Rate limit check: success=$success, remaining=$remainingTokens');
    return success == 1;
  }
}

// Usage
final limiter = AtomicRedisRateLimiter(
  redis,
  scriptPath: 'lua/atomic_rate_limit.lua',
);

if (await limiter.tryAcquire(
  key: 'user:123',
  maxTokens: 100,
  refillRate: 10,
  refillIntervalMicros: Duration(seconds: 1).inMicroseconds,
)) {
  // Request allowed
} else {
  // Rate limit exceeded
}
```

## 🚀 Middleware Examples

### Dart Frog

```dart
// routes/_middleware.dart
import 'package:dart_frog/dart_frog.dart';
import 'package:redis/redis.dart';

// Singleton Redis connection
late final Command redisCommand;

Handler rateLimitMiddleware(Handler handler) {
  return (context) async {
    final ip = context.request.headers['x-forwarded-for'] ??
               context.request.headers['x-real-ip'] ??
               'unknown';

    final limiter = DistributedRateLimiter(
      key: 'ip:$ip',
      store: RedisRateLimiterStore(redis: redisCommand),
      maxTokens: 100,
      refillRate: 10,
      refillInterval: Duration(seconds: 1),
    );

    if (!await limiter.tryAcquire()) {
      return Response(
        statusCode: HttpStatus.tooManyRequests,
        headers: {
          'Retry-After': '${limiter.timeUntilNextToken.inSeconds}',
          'X-RateLimit-Limit': '100',
          'X-RateLimit-Remaining': '0',
        },
        body: 'Rate limit exceeded. Try again later.',
      );
    }

    return handler(context);
  };
}
```

### Shelf

```dart
import 'package:shelf/shelf.dart';
import 'package:redis/redis.dart';

Middleware rateLimitMiddleware(RedisRateLimiterStore store) {
  return (Handler handler) {
    return (Request request) async {
      final ip = request.headers['x-forwarded-for'] ?? 'unknown';

      final limiter = DistributedRateLimiter(
        key: 'ip:$ip',
        store: store,
        maxTokens: 100,
        refillRate: 10,
        refillInterval: Duration(seconds: 1),
      );

      if (!await limiter.tryAcquire()) {
        return Response(
          429,
          headers: {'Retry-After': '${limiter.timeUntilNextToken.inSeconds}'},
          body: 'Rate limit exceeded',
        );
      }

      return handler(request);
    };
  };
}

// Setup
void main() async {
  final redisConn = RedisConnection();
  final redis = await redisConn.connect('localhost', 6379);
  final store = RedisRateLimiterStore(redis: redis);

  final handler = Pipeline()
    .addMiddleware(rateLimitMiddleware(store))
    .addHandler(_echoRequest);

  await serve(handler, 'localhost', 8080);
}
```

## 🗄️ Alternative: PostgreSQL with Transactions

For teams already using PostgreSQL, you can achieve atomic operations with `SELECT FOR UPDATE`:

```dart
import 'package:postgres/postgres.dart';

class PostgresRateLimiterStore implements AsyncRateLimiterStore {
  final Connection conn;

  PostgresRateLimiterStore(this.conn);

  @override
  Future<bool> tryAcquireAtomic(
    String key,
    int maxTokens,
    double refillRate,
    Duration refillInterval,
    int tokensToAcquire,
  ) async {
    return await conn.runTx((ctx) async {
      // 1. Fetch state with row lock (blocks concurrent updates)
      final result = await ctx.execute(
        'SELECT tokens, last_refill_micros FROM rate_limits '
        'WHERE key = @key FOR UPDATE',
        parameters: {'key': key},
      );

      double tokens = maxTokens.toDouble();
      int lastRefillMicros = DateTime.now().microsecondsSinceEpoch;

      if (result.isNotEmpty) {
        tokens = result[0][0] as double;
        lastRefillMicros = result[0][1] as int;
      }

      // 2. Calculate refill (same logic as non-atomic)
      final nowMicros = DateTime.now().microsecondsSinceEpoch;
      if (lastRefillMicros > 0 && nowMicros > lastRefillMicros) {
        final elapsed = nowMicros - lastRefillMicros;
        final intervals = elapsed / refillInterval.inMicroseconds;
        final tokensToAdd = intervals * refillRate;
        tokens = (tokens + tokensToAdd).clamp(0, maxTokens.toDouble());
        lastRefillMicros = nowMicros;
      }

      // 3. Try to acquire
      if (tokens < tokensToAcquire) {
        return false;
      }

      tokens -= tokensToAcquire;

      // 4. Save atomically (still holding row lock)
      await ctx.execute(
        'INSERT INTO rate_limits (key, tokens, last_refill_micros) '
        'VALUES (@key, @tokens, @micros) '
        'ON CONFLICT (key) DO UPDATE SET '
        'tokens = @tokens, last_refill_micros = @micros',
        parameters: {
          'key': key,
          'tokens': tokens,
          'micros': lastRefillMicros,
        },
      );

      return true;
    });
  }
}

// Schema
/*
CREATE TABLE rate_limits (
  key TEXT PRIMARY KEY,
  tokens DOUBLE PRECISION NOT NULL,
  last_refill_micros BIGINT NOT NULL,
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_rate_limits_updated ON rate_limits(updated_at);
*/
```

## 📊 Performance Trade-offs

| Approach | Consistency | Throughput | Latency | Complexity |
|----------|-------------|------------|---------|------------|
| **Non-atomic** | ~99% | 10k+ req/s | <1ms | Simple |
| **Lua script** | 100% | 8k req/s | 2-5ms | Medium |
| **PostgreSQL TX** | 100% | 5k req/s | 5-10ms | High |

**Choose based on your needs:**
- **Internal APIs, soft limits** → Non-atomic is fine
- **Payment APIs, compliance** → Atomic required
- **High throughput** → Redis + Lua script
- **Already using PostgreSQL** → Transaction-based

## 🔐 Security Best Practices

### 1. TLS/SSL Encryption

```dart
// Production: Always use TLS
final redisConn = RedisConnection();
final redis = await redisConn.connect(
  'redis.example.com',
  6380, // TLS port (usually 6380)
  // Enable TLS (check your Redis client library docs)
);
```

### 2. Authentication

```bash
# Redis 6+ ACL (Access Control Lists)
redis-cli
> ACL SETUSER ratelimiter on >mypassword ~ratelimit:* +get +set +del +eval
```

```dart
// Authenticate before using
await redis.send_object(['AUTH', 'username', 'password']);
```

### 3. Network Isolation

- Run Redis on private network (VPC)
- Never expose Redis port to public internet
- Use firewall rules to restrict access

### 4. Key Namespacing

```dart
final store = RedisRateLimiterStore(
  redis: redis,
  keyPrefix: 'myapp:prod:ratelimit:', // Environment-specific
  ttl: Duration(hours: 24),
);
```

## 🧪 Testing

```dart
import 'package:test/test.dart';
import 'package:redis/redis.dart';

void main() {
  late Command redis;
  late RedisRateLimiterStore store;

  setUp(() async {
    final conn = RedisConnection();
    redis = await conn.connect('localhost', 6379);
    store = RedisRateLimiterStore(
      redis: redis,
      keyPrefix: 'test:ratelimit:',
      ttl: Duration(seconds: 10),
    );
  });

  tearDown(() async {
    await store.clearAll();
    // Close Redis connection if needed
  });

  test('allows requests within limit', () async {
    final limiter = DistributedRateLimiter(
      key: 'test-user',
      store: store,
      maxTokens: 5,
      refillRate: 1,
      refillInterval: Duration(seconds: 1),
    );

    // Should allow 5 requests
    for (int i = 0; i < 5; i++) {
      expect(await limiter.tryAcquire(), isTrue);
    }

    // 6th request should fail
    expect(await limiter.tryAcquire(), isFalse);
  });

  test('refills tokens over time', () async {
    final limiter = DistributedRateLimiter(
      key: 'test-user-2',
      store: store,
      maxTokens: 2,
      refillRate: 1,
      refillInterval: Duration(milliseconds: 100),
    );

    // Consume all tokens
    await limiter.tryAcquire();
    await limiter.tryAcquire();
    expect(await limiter.tryAcquire(), isFalse);

    // Wait for refill
    await Future.delayed(Duration(milliseconds: 150));

    // Should have 1 token now
    expect(await limiter.tryAcquire(), isTrue);
  });
}
```

## 📚 References

- [Redis Rate Limiting Guide](https://redis.io/learn/howtos/ratelimiting)
- [Build Rate Limiting with Redis and Lua](https://www.freecodecamp.org/news/build-rate-limiting-system-using-redis-and-lua/)
- [Dart Package: redis](https://pub.dev/packages/redis)
- [Token Bucket Algorithm](https://en.wikipedia.org/wiki/Token_bucket)

## 🆘 Troubleshooting

### Redis Connection Errors

```dart
// Add error handling
try {
  final redis = await redisConn.connect('localhost', 6379);
} catch (e) {
  print('Failed to connect to Redis: $e');
  // Fallback: Use in-memory store
  final store = InMemoryRateLimiterStore();
}
```

### High Memory Usage

```dart
// Use TTL to auto-expire old keys
final store = RedisRateLimiterStore(
  redis: redis,
  ttl: Duration(hours: 1), // Auto-delete after 1 hour of inactivity
);
```

### Stale Keys

```bash
# Monitor Redis memory
redis-cli INFO memory

# Find keys with pattern
redis-cli KEYS "ratelimit:*"

# Clear test keys
redis-cli DEL ratelimit:test-user
```

## 📦 Files in This Example

- **redis_store_example.dart** - Copy this to your project
- **redis_example.dart** - Usage examples and patterns
- **lua/atomic_rate_limit.lua** - Production-ready Lua script
- **README.md** - This file

## 💡 Next Steps

1. Copy `redis_store_example.dart` to your project
2. Add `redis: ^4.0.0` to your pubspec.yaml
3. For production: Implement atomic operations (Lua script or transactions)
4. Add monitoring and alerting for rate limit violations
5. Consider multi-tier rate limits (per-user, per-IP, global)
