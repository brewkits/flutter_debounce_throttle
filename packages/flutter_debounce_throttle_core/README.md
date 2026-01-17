# flutter_debounce_throttle_core

[![pub package](https://img.shields.io/pub/v/flutter_debounce_throttle_core.svg)](https://pub.dev/packages/flutter_debounce_throttle_core)
[![Pure Dart](https://img.shields.io/badge/pure-Dart-02569B)](https://dart.dev)

## Pure Dart Event Rate Limiting — For Backend, CLI & Beyond

The **zero-dependency foundation** of the [flutter_debounce_throttle](https://pub.dev/packages/flutter_debounce_throttle) ecosystem. Production-ready debounce, throttle, rate limiting, and async concurrency control for Dart servers, CLI tools, and any platform where Flutter isn't available.

**Perfect for:** Serverpod, Dart Frog, shelf, CLI apps, shared business logic

```dart
// Token Bucket rate limiting for your API
final limiter = RateLimiter(maxTokens: 100, refillRate: 10, refillInterval: 1.seconds);

if (!limiter.tryAcquire()) {
  return Response.tooManyRequests(retryAfter: limiter.timeUntilNextToken);
}
```

---

## Why This Package?

| Feature | Benefit |
|---------|---------|
| **Zero dependencies** | Only `meta` package — minimal footprint |
| **Server-ready** | No Flutter required, pure Dart |
| **Token Bucket Rate Limiter** | Enterprise-grade API protection |
| **4 Concurrency Modes** | `drop`, `replace`, `enqueue`, `keepLatest` |
| **Battle-tested** | 340+ tests, production-proven |

---

## Installation

```yaml
dependencies:
  flutter_debounce_throttle_core: ^1.1.0
```

---

## Quick Start

### Throttle (Rate Limit)
```dart
final throttler = Throttler(duration: Duration(milliseconds: 500));
throttler(() => processRequest());
```

### Debounce (Wait for Pause)
```dart
final debouncer = Debouncer(duration: Duration(milliseconds: 300));
debouncer(() => search(query));
```

### Async with Cancellation
```dart
final asyncDebouncer = AsyncDebouncer(duration: 300.ms);
final result = await asyncDebouncer(() async => await api.search(query));
if (result != null) updateUI(result);
```

### Token Bucket Rate Limiting
```dart
final limiter = RateLimiter(
  maxTokens: 100,     // Burst capacity
  refillRate: 10,     // 10 tokens/second
  refillInterval: 1.seconds,
);

if (limiter.tryAcquire()) {
  await processRequest();
} else {
  return Response.tooManyRequests(
    retryAfter: limiter.timeUntilNextToken,
  );
}
```

### Batch Operations
```dart
final batcher = BatchThrottler(
  duration: 1.seconds,
  maxBatchSize: 100,
  onBatchExecute: (actions) async {
    final logs = actions.map((a) => a()).toList();
    await database.insertBatch(logs);
  },
);

// 1000 log calls → 10 database writes
batcher(() => 'User logged in');
batcher(() => 'Page viewed');
```

---

## Complete Toolkit

| Class | Use Case |
|-------|----------|
| `Throttler` | Rate limiting, spam prevention |
| `Debouncer` | Search input, form validation |
| `AsyncThrottler` | Async operations with timeout |
| `AsyncDebouncer` | Auto-cancel stale async calls |
| `ConcurrentAsyncThrottler` | 4 concurrency modes |
| `HighFrequencyThrottler` | 60fps events (no Timer overhead) |
| `BatchThrottler` | Batch database writes |
| `RateLimiter` | Token Bucket algorithm |

**Concurrency Modes:**
```dart
ConcurrentAsyncThrottler(mode: ConcurrencyMode.drop)       // Ignore while busy
ConcurrentAsyncThrottler(mode: ConcurrencyMode.replace)    // Cancel old, run new
ConcurrentAsyncThrottler(mode: ConcurrencyMode.enqueue)    // Queue in order
ConcurrentAsyncThrottler(mode: ConcurrencyMode.keepLatest) // Current + last only
```

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

// Leading + trailing edge (like lodash)
Debouncer(leading: true, trailing: true)

// Overflow strategies
BatchThrottler(maxBatchSize: 50, overflowStrategy: BatchOverflowStrategy.dropOldest)
ConcurrentAsyncThrottler(maxQueueSize: 10, queueOverflowStrategy: QueueOverflowStrategy.dropNewest)
```

---

## Related Packages

| Package | Use When |
|---------|----------|
| [flutter_debounce_throttle](https://pub.dev/packages/flutter_debounce_throttle) | Flutter apps |
| [flutter_debounce_throttle_hooks](https://pub.dev/packages/flutter_debounce_throttle_hooks) | Flutter + Hooks |

---

<p align="center">
  <a href="https://github.com/brewkits/flutter_debounce_throttle">GitHub</a> ·
  <a href="https://github.com/brewkits/flutter_debounce_throttle/blob/main/docs/API_REFERENCE.md">API Reference</a>
</p>
