# dart_debounce_throttle

[![pub package](https://img.shields.io/pub/v/dart_debounce_throttle.svg)](https://pub.dev/packages/dart_debounce_throttle)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Tests](https://img.shields.io/badge/tests-570%2B%20passed-brightgreen)](https://github.com/brewkits/flutter_debounce_throttle)
[![Pure Dart](https://img.shields.io/badge/pure-Dart-02569B)](https://dart.dev)
[![GitHub stars](https://img.shields.io/github/stars/brewkits/flutter_debounce_throttle?style=social)](https://github.com/brewkits/flutter_debounce_throttle/stargazers)

## The Traffic Control System for Dart

> Debounce, throttle, rate limit (Token Bucket), and batch — for Dart servers, CLI tools, and shared business logic. Zero external dependencies.

![Debounced Search Demo](https://raw.githubusercontent.com/brewkits/flutter_debounce_throttle/main/docs/images/demo_search_debounce.gif)

---

## 🚀 Honest API — No Silent Failures

Most libraries return `void`, causing "silent failures" where dropped operations appear to succeed. This library introduces **ThrottlerResult** and **DebounceResult** so the compiler forces you to handle every outcome.

```dart
// ✅ compiler forces handling of both branches
final result = await throttler.call(() async => await processPayment(order));

result.when(
  onExecuted: () => sendConfirmationEmail(order),
  onDropped:  () => log.warn('Request dropped — server busy'),
);
```

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
  onBatchExecute: (items) => db.insertBatch(items),
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
| `HighFrequencyThrottler` | High-freq events — no Timer overhead |
| **Stream Extensions** | rxdart-style `.debounce()` / `.throttle()` |

---

## Features

- **Token Bucket Rate Limiting**: Professional-grade outbound call control.
- **Distributed Rate Limiting**: Sync across Redis/Memcached (perfect for Dart Frog/Serverpod).
- **Concurrency Control**: 4 modes (`drop`, `replace`, `enqueue`, `keepLatest`) for async tasks.
- **Batch Processing**: Automatically group high-frequency items into single operations.
- **Memory Safety**: Auto-cleanup of unused limiters and verified zero leaks.

---

## Installation

```yaml
dependencies:
  dart_debounce_throttle: ^2.4.6
```

---

## Quality Assurance

| Guarantee | How |
|-----------|-----|
| **570+ tests** | Unit, integration, security, performance & stress tests |
| **Zero dependencies** | Only `meta` package in production |
| **Type-safe** | No `dynamic`, full generics |
| **Compile-time safety** | `when()` forces exhaustive handling of results |

---

<p align="center">
  <a href="https://github.com/brewkits/flutter_debounce_throttle">GitHub</a> ·
  <a href="https://github.com/brewkits/flutter_debounce_throttle/blob/main/FAQ.md">FAQ</a> ·
  <a href="https://github.com/brewkits/flutter_debounce_throttle/blob/main/docs/API_REFERENCE.md">API Reference</a>
</p>

<p align="center">
  Made with craftsmanship by <a href="https://github.com/brewkits">Brewkits</a>
</p>
