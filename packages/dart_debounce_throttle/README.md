# dart_debounce_throttle

[![pub package](https://img.shields.io/pub/v/dart_debounce_throttle.svg)](https://pub.dev/packages/dart_debounce_throttle)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Tests](https://img.shields.io/badge/tests-150%2B%20passed-brightgreen)](https://github.com/brewkits/flutter_debounce_throttle)
[![Pure Dart](https://img.shields.io/badge/pure-Dart-02569B)](https://dart.dev)
[![GitHub stars](https://img.shields.io/github/stars/brewkits/flutter_debounce_throttle?style=social)](https://github.com/brewkits/flutter_debounce_throttle/stargazers)

## The Traffic Control System for Dart

> Debounce, throttle, rate limit, and batch — for Dart servers, CLI tools, and shared business logic. Zero Flutter dependencies.

---

## 5-Second Start

```dart
// Rate limit outbound API calls (Token Bucket)
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
| `Throttler` | Basic rate limiting — one call per interval |
| `Debouncer` | Wait for pause (leading/trailing edge) |
| `AsyncDebouncer` | Auto-cancel stale async calls |
| `AsyncThrottler` | Async operations with timeout |
| `ConcurrentAsyncThrottler` | 4 concurrency modes |
| `DistributedRateLimiter` | Multi-server rate limiting (Redis/Memcached) |
| `HighFrequencyThrottler` | 60fps events — no Timer overhead |
| **Stream Extensions** | rxdart-style `.debounce()` / `.throttle()` |

---

## Server Problems This Solves

| Problem | Impact | Solution |
|---------|--------|----------|
| **API Cost Explosion** | OpenAI/Maps API called every request → $$$$ bill | `RateLimiter` controls outbound calls |
| **Database Overload** | Writing logs one-by-one → DB locks up | `BatchThrottler` batches 100→1 |
| **DDoS Vulnerability** | No rate limiting → server goes down | `RateLimiter` with Token Bucket |
| **Cache Stampede** | 1000 requests hit expired cache → backend dies | `Debouncer` with `leading: true` |

---

## Token Bucket Rate Limiting

Enterprise-grade rate limiting with burst support:

```dart
final limiter = RateLimiter(
  maxTokens: 100,              // Burst capacity
  refillRate: 10,              // Tokens per interval
  refillInterval: 1.seconds,   // Refill every second
);

if (limiter.tryAcquire()) {
  await callOpenAI(prompt);
} else {
  return Response.tooManyRequests(
    headers: {'Retry-After': '${limiter.timeUntilNextToken.inSeconds}'},
  );
}
```

---

## Distributed Rate Limiting (Enterprise)

Synchronize your rate limits across multiple servers, pods, or cloud functions using an external data store like Redis or Memcached. Perfect for Dart Frog, Serverpod, or Firebase Functions.

```dart
import 'package:redis/redis.dart';
import 'package:dart_debounce_throttle/dart_debounce_throttle.dart';

// 1. Setup your external store
final redis = await RedisConnection().connect('localhost', 6379);
final store = RedisRateLimiterStore(redis: redis);

// 2. Create the limiter
final limiter = DistributedRateLimiter(
  key: 'user:$userId',
  store: store,
  maxTokens: 100,             // Burst capacity
  refillRate: 10,             // 10 requests per interval
  refillInterval: 1.seconds,
);

// 3. Use across your distributed system
if (await limiter.tryAcquire()) {
  await callExpensiveAPI();
} else {
  return Response.tooManyRequests();
}
```

---

## Batch Processing

Reduce database load by 100x:

```dart
final uploadBatcher = BatchThrottler(
  duration: 5.seconds,
  maxBatchSize: 100,
  onBatchExecute: (_) async {
    final pendingLogs = await db.getUnsyncedLogs();
    if (pendingLogs.isNotEmpty) {
      await api.uploadBatch(pendingLogs);  // 1 network call
      await db.markAsSynced(pendingLogs);
    }
  },
);

void trackEvent(String action) {
  // 1. Immediate local save (prevents data loss on crash)
  db.insertLog(action); 
  
  // 2. Trigger the batch schedule
  uploadBatcher(() {});
}
```

---

## No Silent Failures — Honest API

Most debounce/throttle libraries let operations silently disappear when dropped or cancelled.
This library makes the outcome explicit — the compiler forces you to handle it.

#### The Problem with `void`-returning APIs

```dart
// ❌ With other libraries — silent failure
await throttler.call(() async => await processPayment(order));
sendConfirmationEmail(order); // Runs even if payment was NEVER processed!
```

#### The Solution: `ThrottlerResult` + `when()`

```dart
// ✅ Honest API — both branches required at compile time
final result = await throttler.call(() async => await processPayment(order));

result.when(
  onExecuted: () => sendConfirmationEmail(order),  // Safe: payment ran
  onDropped:  () => log.warn('Payment dropped — queue full'),
);
```

The compiler **rejects** code that ignores `onDropped`. You cannot accidentally forget it.

#### Fluent Side-Effect Style

```dart
(await debouncer.callWithResult(() => searchApi(query)))
  .whenSuccess((results) => cache.set(query, results))
  .whenCancelled(() => metrics.increment('search.cancelled'));
```

#### `DebounceResult` — Distinguishes Null from Cancelled

```dart
// ❌ Ambiguous — is null "no result" or "cancelled"?
final result = await debouncer.call(() async => db.findUser(id));
if (result == null) { /* no idea why */ }

// ✅ Unambiguous
final result = await debouncer.callWithResult(() async => db.findUser(id));
result.when(
  onSuccess:   (user) => respond(user),   // user may be null (not found) — that's fine
  onCancelled: ()     => respond(null),   // cancelled by newer call
);
```

---

## Concurrency Modes (Async)

| Mode | Behavior | Use Case |
|------|----------|----------|
| `drop` | Ignore new while busy | Prevent duplicate background jobs |
| `replace` | Cancel old, run new | Always process latest data |
| `enqueue` | Queue in order | Job queues, webhook handling |
| `keepLatest` | Current + last only | Efficient data sync |

```dart
final processor = ConcurrentAsyncThrottler(
  mode: ConcurrencyMode.enqueue,
  maxQueueSize: 100,
  queueOverflowStrategy: QueueOverflowStrategy.dropOldest,
);

// ThrottlerResult tells you what actually happened
final result = await processor.call(() async => processJob(job));
result.when(
  onExecuted: () => log.info('Job processed'),
  onDropped:  () => log.warn('Job dropped — queue full, retry later'),
);
```

---

## Stream Extensions

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

## How It Works — Visualized

#### ➤ Throttle (Rate Limiting)
Executes **immediately**, then **locks** for the duration.

```
API Calls: (Call1)    (Call2)    (Call3)              (Call4)
Time:      |─ 0ms ─────── 100ms ──── 200ms ──── 300ms ──── 400ms ──|
           ▼                                     ▲
Execution: [EXECUTE] ····················· [LOCKED/DROP] ······· [EXECUTE]
           └─────── 300ms cooldown ──────┘
```

#### ➤ Debounce (Cache Stampede Protection)
Waits for a **pause** before executing. `leading: true` → execute first call immediately.

```
Requests:  (Req1)   (Req2)   (Req3)    [Pause]
Time:      |─ 0ms ── 100ms ── 200ms ────────────── 500ms ──────|
           ▼                                        ▲
Execution: [EXECUTE] ·····················  [SKIP rest during cooldown]
           (leading: true)
```

#### ➤ Batch Processing
```
Individual Calls:    1  2  3  4  5  6  7  8  9  10 ... 100
Time:                |──────────── 2 seconds ────────────|
                                                         ▼
Batch Execution:                                    [INSERT 100 rows]
Result: 100 individual calls → 1 database operation (100x reduction)
```

---

## Extensions & Utilities

```dart
// Duration extensions — write durations naturally
300.ms        // Duration(milliseconds: 300)
2.seconds     // Duration(seconds: 2)
5.minutes     // Duration(minutes: 5)

// Callback extensions
final debouncedFn = myFunction.debounced(300.ms);
final throttledFn = myFunction.throttled(500.ms);

// Leading + trailing edge (Lodash-style)
Debouncer(leading: true, trailing: true)

// Overflow strategies
BatchThrottler(overflowStrategy: BatchOverflowStrategy.dropOldest)
ConcurrentAsyncThrottler(queueOverflowStrategy: QueueOverflowStrategy.dropNewest)
```

---

## Installation

```yaml
dependencies:
  dart_debounce_throttle: ^2.4.6
```

**For:** Serverpod, Dart Frog, shelf, Alfred, CLI apps, shared business logic

---

## Quality Assurance

| Guarantee | How |
|-----------|-----|
| **150+ tests** | Unit, integration, stress, performance & boundary tests |
| **Zero dependencies** | Only `meta` package |
| **Honest API** | `ThrottlerResult` / `DebounceResult` — no silent failures |
| **Type-safe** | No `dynamic`, no `as`, full generics |
| **Compile-time safety** | `when()` forces exhaustive handling of dropped/cancelled states |

---

## Which Package Should I Use?

| You are building... | Package |
|---------------------|---------|
| Dart server / CLI / Serverpod (no Flutter) | **`dart_debounce_throttle`** ← you are here |
| Flutter app | [`flutter_debounce_throttle`](https://pub.dev/packages/flutter_debounce_throttle) |
| Flutter app + `flutter_hooks` | [`flutter_debounce_throttle_hooks`](https://pub.dev/packages/flutter_debounce_throttle_hooks) |

---

## Why Choose This Over Alternatives?

### vs rxdart
| Feature | dart_debounce_throttle | rxdart |
|---------|:---:|:---:|
| **Package Size** | ~25 KB | ~150 KB |
| **Dependencies** | 0 (only `meta`) | Multiple |
| **Stream Extensions** | ✅ `.debounce()` `.throttle()` | ✅ Full suite |
| **Token Bucket** | ✅ | ❌ |
| **Batch Processing** | ✅ | ❌ |

**Use rxdart if:** You need full reactive programming (combineLatest, merge, zip, etc.)
**Use this if:** You need debounce/throttle + rate limiting with zero bloat

### vs easy_debounce
| Feature | dart_debounce_throttle | easy_debounce |
|---------|:---:|:---:|
| **Type Safety** | ✅ Generics | ❌ No generics |
| **Honest API** | ✅ `ThrottlerResult` / `DebounceResult` | ❌ Silent void |
| **Async Support** | ✅ Full | ⚠️ Limited |
| **Rate Limiting** | ✅ Token Bucket | ❌ |
| **Batch Processing** | ✅ | ❌ |
| **Memory Safety** | ✅ Auto-dispose + leak detection | ⚠️ Manual |
| **Tests** | 50+ | ~10 |

### vs Manual Timer
| Feature | This Package | Manual `Timer` |
|---------|:---:|:---:|
| **Code Lines** | 1 line | 10-20 lines |
| **Memory Leaks** | ✅ Auto-prevented | ❌ Easy to leak |
| **Async Cancellation** | ✅ Built-in | ❌ Complex logic |
| **Race Conditions** | ✅ 4 strategies + `ThrottlerResult` | ❌ Manual handling |
| **Silent Failures** | ✅ Impossible — compiler enforces | ❌ Default behavior |

---

<p align="center">
  <a href="https://github.com/brewkits/flutter_debounce_throttle">GitHub</a> ·
  <a href="https://github.com/brewkits/flutter_debounce_throttle/blob/main/FAQ.md">FAQ</a> ·
  <a href="https://github.com/brewkits/flutter_debounce_throttle/blob/main/docs/API_REFERENCE.md">API Reference</a>
</p>

<p align="center">
  Made with craftsmanship by <a href="https://github.com/brewkits">Brewkits</a>
</p>
