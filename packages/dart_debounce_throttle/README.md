# dart_debounce_throttle

[![pub package](https://img.shields.io/pub/v/dart_debounce_throttle.svg)](https://pub.dev/packages/dart_debounce_throttle)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Tests](https://img.shields.io/badge/tests-50%2B%20passed-brightgreen)](https://github.com/brewkits/flutter_debounce_throttle)
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

// Called 1000 times per second — results in ~10 DB writes
batcher(() => LogEntry(user: userId, action: 'page_view'));
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

processor(() async => await processJob(job));
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
  dart_debounce_throttle: ^2.4.4
```

**For:** Serverpod, Dart Frog, shelf, Alfred, CLI apps, shared business logic

---

## Quality Assurance

| Guarantee | How |
|-----------|-----|
| **50+ tests** | Comprehensive coverage |
| **Zero dependencies** | Only `meta` package |
| **Type-safe** | No `dynamic`, full generics |
| **Battle-tested** | 50+ unit & integration tests |

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
| **Race Conditions** | ✅ 4 strategies | ❌ Manual handling |

---

<p align="center">
  <a href="https://github.com/brewkits/flutter_debounce_throttle">GitHub</a> ·
  <a href="https://github.com/brewkits/flutter_debounce_throttle/blob/main/FAQ.md">FAQ</a> ·
  <a href="https://github.com/brewkits/flutter_debounce_throttle/blob/main/docs/API_REFERENCE.md">API Reference</a>
</p>

<p align="center">
  Made with craftsmanship by <a href="https://github.com/brewkits">Brewkits</a>
</p>
