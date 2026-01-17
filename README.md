# flutter_debounce_throttle

[![pub package](https://img.shields.io/pub/v/flutter_debounce_throttle.svg)](https://pub.dev/packages/flutter_debounce_throttle)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Tests](https://img.shields.io/badge/tests-360%2B%20passed-brightgreen)](https://github.com/brewkits/flutter_debounce_throttle)
[![Coverage](https://img.shields.io/badge/coverage-95%25-brightgreen)](https://github.com/brewkits/flutter_debounce_throttle)
[![Pure Dart](https://img.shields.io/badge/pure-Dart-02569B)](https://dart.dev)

## The Complete Event Rate Limiting Infrastructure for Dart & Flutter

Production-ready library unifying **debounce, throttle, rate limiting, and async concurrency control** into a single, battle-tested package. Built for applications where memory safety, data integrity, and cross-platform consistency are non-negotiable.

**Replaces:** `easy_debounce` + `rxdart` throttle/debounce + manual Timer hacks + custom rate limiters

```
┌─────────────────────────────────────────────────────────────────────┐
│                   flutter_debounce_throttle                         │
├─────────────────────────────────────────────────────────────────────┤
│  Debounce  │  Throttle  │  Rate Limit  │  Async Queue  │  Batch    │
├─────────────────────────────────────────────────────────────────────┤
│  Flutter UI  │  Dart Backend  │  CLI  │  Serverpod  │  Dart Frog  │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Why Not Just Use easy_debounce or rxdart?

| Capability | This Library | easy_debounce | rxdart | Manual Timer |
|------------|:---:|:---:|:---:|:---:|
| Debounce & Throttle | ✅ | ✅ | ✅ | ⚠️ Boilerplate |
| **Memory Safe** (Auto-dispose) | ✅ | ❌ | ⚠️ Manual | ❌ Leaky |
| **Async & Future Support** | ✅ | ❌ | ✅ | ❌ |
| **Concurrency Control** (4 modes) | ✅ | ❌ | ⚠️ Complex | ❌ |
| **Rate Limiter** (Token Bucket) | ✅ | ❌ | ❌ | ❌ |
| **Server-side** (Pure Dart) | ✅ | ❌ | ❌ | ✅ |
| **Flutter Widgets** | ✅ | ❌ | ❌ | ❌ |
| **State Management Mixin** | ✅ | ❌ | ❌ | ❌ |
| Dependencies | **0** | 0 | Many | 0 |

> **One library. All use cases. Zero compromises.**

---

## Real Problems, Real Solutions

### Problem: User spams payment button → Double charge

```dart
// Solution: ThrottledInkWell blocks duplicate taps
ThrottledInkWell(
  duration: 500.ms,
  onTap: () => processPayment(),
  child: Text('Pay \$99'),
)
```

### Problem: Search API fires on every keystroke → Server overload & race conditions

```dart
// Solution: ConcurrencyMode.replace cancels stale requests
final controller = ConcurrentAsyncThrottler(mode: ConcurrencyMode.replace);

void onSearch(String query) {
  controller(() async {
    final results = await api.search(query);  // Old requests auto-cancelled
    updateUI(results);
  });
}
```

### Problem: Chat messages arrive out of order

```dart
// Solution: ConcurrencyMode.enqueue preserves sequence
final sender = ConcurrentAsyncThrottler(
  mode: ConcurrencyMode.enqueue,
  maxQueueSize: 20,
);

void sendMessage(String text) {
  sender(() async => await api.send(text));  // Guaranteed order
}
```

### Problem: Analytics logs overwhelm the server

```dart
// Solution: BatchThrottler groups events
final batcher = BatchThrottler(
  duration: 2.seconds,
  maxBatchSize: 50,
  onBatchExecute: (logs) => analytics.sendBatch(logs),
);

batcher(() => 'page_view');  // 1000 calls → 20 batches
```

### Problem: API needs burst protection (DDoS, spam)

```dart
// Solution: RateLimiter with Token Bucket algorithm
final limiter = RateLimiter(
  maxTokens: 100,      // Allow burst of 100
  refillRate: 10,      // Sustain 10/second
  refillInterval: 1.seconds,
);

if (!limiter.tryAcquire()) {
  return Response.tooManyRequests(retryAfter: limiter.timeUntilNextToken);
}
```

---

## Enterprise Features

| Feature | Use Case |
|---------|----------|
| **4 Concurrency Modes** | `drop` (payments), `replace` (search), `enqueue` (chat), `keepLatest` (auto-save) |
| **Token Bucket Rate Limiter** | Backend API protection, burst control |
| **Batch Processing** | Analytics, logging, bulk operations |
| **Queue Backpressure** | `maxQueueSize` + overflow strategies |
| **Pure Dart Core** | Works on Flutter, Serverpod, Dart Frog, CLI |
| **Auto-dispose** | Memory-safe with widget lifecycle |
| **State Management Mixin** | Provider, Bloc, GetX, Riverpod, MobX |

---

## Installation

```yaml
# Flutter
dependencies:
  flutter_debounce_throttle: ^1.1.0

# Flutter + Hooks
dependencies:
  flutter_debounce_throttle_hooks: ^1.1.0

# Pure Dart (Server, CLI)
dependencies:
  flutter_debounce_throttle_core: ^1.1.0
```

---

## Quick Reference

| Problem | Solution | Mode |
|---------|----------|------|
| Button spam | `Throttler` | - |
| Search input | `AsyncDebouncer` | - |
| Cancel old requests | `ConcurrentAsyncThrottler` | `replace` |
| Preserve order | `ConcurrentAsyncThrottler` | `enqueue` |
| Save only latest | `ConcurrentAsyncThrottler` | `keepLatest` |
| API rate limiting | `RateLimiter` | Token Bucket |
| High-frequency scroll | `HighFrequencyThrottler` | 16ms (60fps) |
| Batch operations | `BatchThrottler` | `maxBatchSize` |

---

## v1.1.0 Highlights

```dart
// Duration extensions
final debouncer = Debouncer(duration: 300.ms);

// Callback extensions
final debouncedFn = myFunction.debounced(300.ms);

// Leading + trailing edge (like lodash)
Debouncer(leading: true, trailing: true);

// DebounceResult - distinguish cancelled from null
final result = await debouncer.callWithResult(() async => api.findUser(id));
if (result.isCancelled) return;
showUser(result.value);  // May be null, but not cancelled

// Rate limiter with Token Bucket
RateLimiter(maxTokens: 100, refillRate: 10, refillInterval: 1.seconds);

// Queue backpressure control
ConcurrentAsyncThrottler(maxQueueSize: 10, queueOverflowStrategy: ...);
```

---

## Documentation

| | |
|---|---|
| [**API Reference**](docs/API_REFERENCE.md) | Complete API documentation |
| [**Best Practices**](docs/BEST_PRACTICES.md) | Patterns & recommendations |
| [**Migration Guide**](MIGRATION_GUIDE.md) | From easy_debounce, rxdart |
| [**Examples**](example/) | Interactive demos |

---

## Ecosystem

| Package | Platform | Use Case |
|---------|----------|----------|
| [`flutter_debounce_throttle`](https://pub.dev/packages/flutter_debounce_throttle) | Flutter | Widgets, Mixin |
| [`flutter_debounce_throttle_hooks`](https://pub.dev/packages/flutter_debounce_throttle_hooks) | Flutter + Hooks | useDebouncer, useThrottler |
| [`flutter_debounce_throttle_core`](https://pub.dev/packages/flutter_debounce_throttle_core) | Pure Dart | Server, CLI, anywhere |

---

<p align="center">
  <b>360+ tests</b> · <b>Zero dependencies</b> (core) · <b>Type-safe</b> · <b>Production-ready</b>
</p>

<p align="center">
  Made by <a href="https://github.com/brewkits">Brewkits</a>
</p>
