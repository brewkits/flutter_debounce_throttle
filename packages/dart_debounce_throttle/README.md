# dart_debounce_throttle

[![pub package](https://img.shields.io/pub/v/dart_debounce_throttle.svg)](https://pub.dev/packages/dart_debounce_throttle)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Tests](https://img.shields.io/badge/tests-300%2B%20passed-brightgreen)](https://github.com/brewkits/flutter_debounce_throttle)
[![Pure Dart](https://img.shields.io/badge/pure-Dart-02569B)](https://dart.dev)

## The Traffic Control System for Dart Backend

> Your API is getting hammered. Your database is locking up. Your OpenAI bill is exploding.

**Production-ready** debounce, throttle, rate limiting, and batch processing for **Dart servers, CLI tools, and any non-Flutter environment**. Zero Flutter dependencies.

```dart
// Token Bucket rate limiting — protect your API from abuse
final limiter = RateLimiter(maxTokens: 100, refillRate: 10, refillInterval: 1.seconds);

if (!limiter.tryAcquire()) {
  return Response.tooManyRequests(retryAfter: limiter.timeUntilNextToken);
}
```

---

## Server Problems This Solves

| Problem | Impact | Solution |
|---------|--------|----------|
| **API Cost Explosion** | OpenAI/Maps API called every request → $$$$ bill | `RateLimiter` controls outbound calls |
| **Database Overload** | Writing logs one-by-one → DB locks up | `BatchThrottler` batches 100→1 |
| **DDoS Vulnerability** | No rate limiting → server goes down | `RateLimiter` with Token Bucket |
| **Cache Stampede** | 1000 requests hit expired cache → backend dies | `Debouncer` with `leading: true` |

---

## Why Choose This Over Alternatives?

### vs rxdart
| Feature | dart_debounce_throttle | rxdart |
|---------|:---:|:---:|
| **Package Size** | ~25 KB | ~150 KB |
| **Dependencies** | 0 (only `meta`) | Multiple |
| **Stream Extensions** | ✅ `.debounce()` `.throttle()` | ✅ Full suite |
| **Widget Support** | Via `flutter_debounce_throttle` | ❌ |
| **Token Bucket** | ✅ | ❌ |
| **Batch Processing** | ✅ | ❌ |
| **Server-Ready** | ✅ Pure Dart | ✅ |

**Use rxdart if:** You need full reactive programming suite (combineLatest, merge, zip, etc.)
**Use this if:** You only need debounce/throttle + zero bloat + Flutter widgets

### vs easy_debounce
| Feature | dart_debounce_throttle | easy_debounce |
|---------|:---:|:---:|
| **Type Safety** | ✅ Generics | ❌ No generics |
| **Async Support** | ✅ Full | ⚠️ Limited |
| **Rate Limiting** | ✅ Token Bucket | ❌ |
| **Batch Processing** | ✅ | ❌ |
| **Memory Safety** | ✅ Auto-dispose + leak detection | ⚠️ Manual |
| **Tests** | 340+ | ~10 |

### vs Manual Timer
| Feature | This Package | Manual `Timer` |
|---------|:---:|:---:|
| **Code Lines** | 1 line | 10-20 lines |
| **Memory Leaks** | ✅ Auto-prevented | ❌ Easy to leak |
| **Async Cancellation** | ✅ Built-in | ❌ Complex logic |
| **Race Conditions** | ✅ 4 strategies | ❌ Manual handling |
| **Production Ready** | ✅ Battle-tested | ❌ Untested |

---

## Why This Package?

### 🎯 Enterprise-Ready Features

✅ **Zero Dependencies** - Only `meta` (type annotations)
✅ **Pure Dart** - Works everywhere: Mobile, Web, Desktop, **Server**, CLI
✅ **300+ Tests** - Comprehensive coverage, all edge cases
✅ **Memory Safe** - Auto-dispose, leak detection, TTL auto-cleanup
✅ **Type Safe** - Full generics, no `dynamic`
✅ **Production Proven** - Used in real-world apps and backends
✅ **Error Tracking** - onError callbacks for Crashlytics/Sentry integration

### 🚀 Unique Features

| Feature | Description |
|---------|-------------|
| **Token Bucket Rate Limiter** | Enterprise-grade API protection with burst support |
| **4 Concurrency Modes** | drop, enqueue, replace, keepLatest - handle race conditions |
| **Batch Processing** | Reduce DB writes from 100→1 |
| **Stream Extensions** | rxdart-style `.debounce()` without the bloat |
| **Async Cancellation** | Auto-cancel stale requests, prevent memory leaks |
| **Leading/Trailing Edge** | Lodash-style debounce modes |
| **Error Handling (v2.2)** | onError callbacks for production error tracking |
| **TTL Auto-Cleanup (v2.2)** | Prevent memory leaks with automatic cleanup |

---

## How It Works — Visualized

### Throttle vs Debounce

#### ➤ Throttle (Rate Limiting)
Executes **immediately**, then **locks** for the duration.

```
API Calls: (Call1)    (Call2)    (Call3)              (Call4)
Time:      |─ 0ms ─────── 100ms ──── 200ms ──── 300ms ──── 400ms ──|
           ▼                                     ▲
Execution: [EXECUTE] ····················· [LOCKED/DROP] ······· [EXECUTE]
           └─────── 300ms cooldown ──────┘
```

**Use:** Rate limiting, preventing API spam

---

#### ➤ Debounce (Cache Stampede Protection)
Waits for a **pause** before executing. Use `leading: true` to execute immediately on first call.

```
Requests:  (Req1)   (Req2)   (Req3)    [Pause]
Time:      |─ 0ms ── 100ms ── 200ms ────────────── 500ms ──────|
           ▼                                        ▲
Execution: [EXECUTE] ····························· [Skip subsequent]
           (leading: true mode - executes first, ignores rest during cooldown)
```

**Use:** Cache refresh, database connection pooling

---

### Batch Processing

Reduce database load by batching writes:

```
Individual Calls:    1  2  3  4  5  6  7  8  9  10 ... 100
Time:                |──────────── 2 seconds ────────────|
                                                         ▼
Batch Execution:                                    [INSERT 100 rows]

Result: 100 individual calls → 1 database operation (100x reduction)
```

**Use:** Log aggregation, analytics events, bulk inserts

---

### Token Bucket Rate Limiting

Enterprise-grade rate limiting with burst support:

```
Bucket Capacity: 10 tokens
Refill Rate: 2 tokens/second

Time:     0s      1s      2s      3s      4s      5s
          │       │       │       │       │       │
Tokens:  10 ─────▶ 8 ───▶ 6 ────▶ 8 ───▶ 10 ───▶ 10
          │  -4   │  -4   │  -2   │  -0   │  -0   │
Requests: ████    ████    ██      ──      ──      ──
          (4 OK)  (4 OK)  (2 OK)  (burst capacity preserved)
```

**Use:** API cost control, preventing DDoS, fair resource allocation

---

### Concurrency Modes (Async)

#### Mode: `drop`
If busy, new tasks are **ignored**.

```
Task 1:  [──────── 500ms Job ────────]  ✅ Completes
Task 2:            ↓ Try to start
                   [DROPPED ❌]
```

**Use:** Preventing duplicate background jobs

---

#### Mode: `replace`
New task **cancels** the old one.

```
Task 1:  [──────── 500ms Job ──X Cancelled
Task 2:              ↓ Higher priority job
                     [──────── 500ms Job ────────]  ✅ Completes
```

**Use:** Always process latest data, cancel stale computations

---

#### Mode: `enqueue`
Tasks **queue** and execute in order.

```
Task 1:  [──────── 500ms ────────]  ✅
Task 2:            ↓ Queued
                   [Waiting...]      [──────── 500ms ────────]  ✅
Task 3:                      ↓ Queued
                                     [Waiting...]      [──────── 500ms ────────]  ✅
```

**Use:** Job queues, ordered processing, webhook handling

---

#### Mode: `keepLatest`
Current task + **one latest** queued task only.

```
Task 1:  [──────── 500ms ────────]  ✅
Task 2:            ↓ Queued
Task 3:                      ↓ Replaces Task 2
                             [Waiting...]      [──────── 500ms ────────]  ✅
Result: Task 1 runs, Task 2 dropped, Task 3 runs after Task 1.
```

**Use:** Data sync, efficient update propagation

---

## 5-Second Start

```dart
// Rate limit outbound API calls
final limiter = RateLimiter(maxTokens: 10, refillRate: 2);
if (limiter.tryAcquire()) await callExpensiveAPI();

// Batch database writes (1000 calls → 10 DB writes)
final batcher = BatchThrottler(
  duration: 1.seconds,
  maxBatchSize: 100,
  onBatchExecute: (logs) => db.insertBatch(logs),
);
batcher(() => logEntry);

// Debounce with leading edge (cache stampede protection)
final debouncer = Debouncer(duration: 5.seconds, leading: true);
debouncer(() => refreshCache());
```

---

## Complete Toolkit

| Class | Use Case |
|-------|----------|
| `RateLimiter` | Token Bucket algorithm — API cost control |
| `BatchThrottler` | Batch operations — 100x fewer DB writes |
| `Throttler` | Basic rate limiting |
| `Debouncer` | Wait for pause (leading/trailing edge) |
| `AsyncDebouncer` | Auto-cancel stale async calls |
| `AsyncThrottler` | Async operations with timeout |
| `ConcurrentAsyncThrottler` | 4 concurrency modes |
| `HighFrequencyThrottler` | 60fps events (no Timer overhead) |
| **Stream Extensions** | rxdart-style `.debounce()` / `.throttle()` |

### Stream Extensions

Apply debounce and throttle directly to streams:

```dart
// Debounce stream events
searchController.stream
  .debounce(Duration(milliseconds: 300))
  .listen((query) => performSearch(query));

// Throttle stream events
clickController.stream
  .throttle(Duration(milliseconds: 500))
  .listen((event) => handleClick(event));
```

---

## Token Bucket Rate Limiting

Enterprise-grade rate limiting with burst support:

```dart
final limiter = RateLimiter(
  maxTokens: 100,              // Burst capacity
  refillRate: 10,              // Tokens per interval
  refillInterval: 1.seconds,   // Refill every second
);

// Check before calling expensive API
if (limiter.tryAcquire()) {
  await callOpenAI(prompt);
} else {
  return Response.tooManyRequests(
    headers: {'Retry-After': '${limiter.timeUntilNextToken.inSeconds}'},
  );
}

// Check available tokens
print('Available: ${limiter.availableTokens}');
```

---

## Distributed Rate Limiting with Redis

For server-side distributed rate limiting across multiple instances, see the Redis integration example:

**📁 [example/server_demo/redis_rate_limiter/](../../../example/server_demo/redis_rate_limiter/)**

The example includes:
- ✅ Redis store implementation (copy to your project)
- ✅ Atomic Lua script (eliminates race conditions)
- ✅ Dart Frog/Shelf middleware examples
- ✅ PostgreSQL alternative with transactions

**Important**: Redis integration is optional and not included in the core package. You'll need to:
1. Copy the store implementation to your project
2. Add `redis: ^4.0.0` to your pubspec.yaml
3. Use Lua scripts for production systems (avoid race conditions)

### Quick Example

```dart
// 1. Add Redis to pubspec.yaml
dependencies:
  redis: ^4.0.0

// 2. Copy redis_store_example.dart from example/ to your project

// 3. Create distributed rate limiter
final redisConn = RedisConnection();
final redis = await redisConn.connect('localhost', 6379);

final store = RedisRateLimiterStore(
  redis: redis,
  keyPrefix: 'ratelimit:',
  ttl: Duration(hours: 1),
);

final limiter = DistributedRateLimiter(
  key: 'user-${userId}',
  store: store,
  maxTokens: 100,
  refillRate: 10,
  refillInterval: Duration(seconds: 1),
);

// 4. Rate limit across all server instances
if (await limiter.tryAcquire()) {
  return await handleRequest();
} else {
  return Response.tooManyRequests();
}
```

**⚠️ For Mobile Apps**: Do NOT connect Flutter apps directly to Redis (security risk). Use Redis only for server-side Dart Frog, Shelf, or backend microservices.

See the [full Redis integration guide](../../../example/server_demo/redis_rate_limiter/README.md) for production setup with atomic operations.

---

## Batch Processing

Reduce database load by 100x:

```dart
final batcher = BatchThrottler(
  duration: 2.seconds,
  maxBatchSize: 100,
  overflowStrategy: BatchOverflowStrategy.flushAndAdd,
  onBatchExecute: (actions) async {
    final logs = actions.map((a) => a()).toList();
    await database.insertBatch(logs);  // 1 DB call instead of 100
  },
);

// Called 1000 times per second
batcher(() => LogEntry(user: userId, action: 'page_view'));
// Result: 10 database writes instead of 1000
```

---

## Concurrency Modes

| Mode | Behavior | Use Case |
|------|----------|----------|
| `drop` | Ignore new while busy | Prevent duplicate jobs |
| `replace` | Cancel old, run new | Latest data only |
| `enqueue` | Queue in order | Job queues |
| `keepLatest` | Current + last only | Efficient updates |

```dart
final processor = ConcurrentAsyncThrottler(
  mode: ConcurrencyMode.enqueue,
  maxQueueSize: 100,
  queueOverflowStrategy: QueueOverflowStrategy.dropOldest,
);

processor(() async => await processJob(job));
```

---

## Installation

```yaml
dependencies:
  dart_debounce_throttle: ^2.4.2
```

**For:** Serverpod, Dart Frog, shelf, Alfred, CLI apps, shared business logic

---

## 🆕 What's New in v2.4

### ThrottledGestureDetector (Flutter only)
Drop-in replacement for GestureDetector with built-in throttling:
```dart
ThrottledGestureDetector(
  onTap: () => handleTap(),
  onPanUpdate: (details) => updatePosition(details),
  child: MyWidget(),
)
```

### Distributed Rate Limiting
Production-ready Redis integration for multi-server environments:
```dart
final limiter = DistributedRateLimiter(
  key: 'user-$userId',
  store: RedisRateLimiterStore(redis: redis),
  maxTokens: 100,
  refillRate: 10,
);
```
*See `example/server_demo/redis_rate_limiter/` for complete guide*

### Power Features

```dart
// Duration extensions
300.ms        // Duration(milliseconds: 300)
2.seconds     // Duration(seconds: 2)
5.minutes     // Duration(minutes: 5)

// Callback extensions
final debouncedFn = myFunction.debounced(300.ms);
final throttledFn = myFunction.throttled(500.ms);

// Leading + trailing edge
Debouncer(leading: true, trailing: true)

// Batch processing
BatchThrottler(
  duration: 2.seconds,
  maxBatchSize: 100,
  onBatchExecute: (actions) => database.insertBatch(actions),
)

// Stream extensions
searchStream.debounce(300.ms).listen((query) => search(query));
clickStream.throttle(500.ms).listen((event) => handle(event));
```

---

## Quality Assurance

| Guarantee | How |
|-----------|-----|
| **340+ tests** | Comprehensive coverage |
| **Type-safe** | No `dynamic`, full generics |
| **Zero dependencies** | Only `meta` package |
| **Production-proven** | Used in real backends |

---

## Related Packages

| Package | Use When |
|---------|----------|
| [`flutter_debounce_throttle`](https://pub.dev/packages/flutter_debounce_throttle) | Flutter apps with widgets |
| [`flutter_debounce_throttle_hooks`](https://pub.dev/packages/flutter_debounce_throttle_hooks) | Flutter + Hooks |

---

<p align="center">
  <a href="https://github.com/brewkits/flutter_debounce_throttle">GitHub</a> ·
  <a href="https://github.com/brewkits/flutter_debounce_throttle/blob/main/FAQ.md">FAQ</a> ·
  <a href="https://github.com/brewkits/flutter_debounce_throttle/blob/main/docs/API_REFERENCE.md">API Reference</a>
</p>

<p align="center">
  Made with craftsmanship by <a href="https://github.com/brewkits">Brewkits</a>
</p>
