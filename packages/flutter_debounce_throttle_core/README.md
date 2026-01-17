# flutter_debounce_throttle_core

[![pub package](https://img.shields.io/pub/v/flutter_debounce_throttle_core.svg)](https://pub.dev/packages/flutter_debounce_throttle_core)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Tests](https://img.shields.io/badge/tests-340%2B%20passed-brightgreen)](https://github.com/brewkits/flutter_debounce_throttle)
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

## Why This Package?

| Feature | This Package | Manual Implementation |
|---------|:---:|:---:|
| **Token Bucket Rate Limiter** | ✅ | ❌ Complex math |
| **4 Concurrency Modes** | ✅ | ❌ Error-prone |
| **Batch Processing** | ✅ | ❌ Boilerplate |
| **Async Cancellation** | ✅ | ❌ Memory leaks |
| **Zero Dependencies** | ✅ Only `meta` | - |
| **340+ Tests** | ✅ | ❌ Untested |

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
  flutter_debounce_throttle_core: ^1.1.0
```

**For:** Serverpod, Dart Frog, shelf, Alfred, CLI apps, shared business logic

---

## v1.1.0 Features

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

// Overflow strategies
BatchThrottler(overflowStrategy: BatchOverflowStrategy.dropOldest)
ConcurrentAsyncThrottler(queueOverflowStrategy: QueueOverflowStrategy.dropNewest)
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
  <a href="https://github.com/brewkits/flutter_debounce_throttle/blob/main/docs/API_REFERENCE.md">API Reference</a>
</p>

<p align="center">
  Made with craftsmanship by <a href="https://github.com/brewkits">Brewkits</a>
</p>
