# flutter_debounce_throttle

[![pub package](https://img.shields.io/pub/v/flutter_debounce_throttle.svg)](https://pub.dev/packages/flutter_debounce_throttle)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Tests](https://img.shields.io/badge/tests-360%2B%20passed-brightgreen)](https://github.com/brewkits/flutter_debounce_throttle)
[![Coverage](https://img.shields.io/badge/coverage-95%25-brightgreen)](https://github.com/brewkits/flutter_debounce_throttle)
[![Pure Dart](https://img.shields.io/badge/pure-Dart-02569B)](https://dart.dev)

## The Traffic Control System for Your App Architecture

> Stop using manual Timers. They cause memory leaks and crashes.
> Switch to the standard traffic control system for Flutter & Dart.

Production-ready library unifying **debounce, throttle, rate limiting, and async concurrency control** into a single, battle-tested package. Like **ABS brakes** for your app — smooth, safe, and automatic.

```
┌─────────────────────────────────────────────────────────────────────┐
│                   flutter_debounce_throttle                         │
├─────────────────────────────────────────────────────────────────────┤
│  Debounce  │  Throttle  │  Rate Limit  │  Async Queue  │  Batch    │
├─────────────────────────────────────────────────────────────────────┤
│  Flutter UI  │  Dart Backend  │  CLI  │  Serverpod  │  Dart Frog  │
└─────────────────────────────────────────────────────────────────────┘
```

### Core Values

| | |
|:---:|---|
| **Universal** | Runs everywhere — Mobile, Web, Desktop, Server |
| **Safety First** | No crashes, no memory leaks, lifecycle-aware |
| **Zero Friction** | Simple API, no boilerplate, zero dependencies |

---

## Why You Need This

### 📱 Mobile Problems

| Problem | Impact | Solution |
|---------|--------|----------|
| **Phantom Clicks** | User taps "Buy" 10x → 10 orders → refund nightmare | `ThrottledInkWell` blocks duplicates |
| **Battery Drain** | Search fires every keystroke → drains battery, burns data | `Debouncer` waits for typing pause |
| **UI Jank** | Scroll events fire 60x/sec → laggy animations | `HighFrequencyThrottler` at 16ms |
| **Race Conditions** | Old search results override new ones | `ConcurrencyMode.replace` cancels stale |

### 🖥️ Server Problems

| Problem | Impact | Solution |
|---------|--------|----------|
| **Cost Explosion** | Calling OpenAI/Maps API every request → $$$$ bill | `RateLimiter` controls outbound calls |
| **Database Overload** | Writing logs one-by-one → DB locks up | `BatchThrottler` batches 100 writes → 1 |
| **DDoS Vulnerability** | No rate limiting → server goes down | `RateLimiter` with Token Bucket |

---

## Solution Matrix

*"What should I use for...?"*

| Environment | Use Case | Solution | Why It's Better |
|-------------|----------|----------|-----------------|
| **Flutter UI** | Button Click | `ThrottledBuilder` | Auto loading state, auto dispose |
| **Flutter UI** | Search Input | `DebouncedTextController` | One line, integrates with TextField |
| **State Mgmt** | Provider/Bloc/GetX | `EventLimiterMixin` | No manual Timer management |
| **Streams** | Socket/Sensor data | `StreamDebounceListener` | Auto-cancel subscription |
| **Hooks** | Functional widgets | `useDebouncedCallback` | No nested widgets, clean code |
| **Server** | Batch DB writes | `BatchThrottler` | 100x fewer DB calls |
| **Server** | Rate limit API | `RateLimiter` | Token Bucket algorithm |

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

## 5-Second Start

Just need a throttled button? **One line:**

```dart
ThrottledInkWell(onTap: () => pay(), child: Text('Pay'))
```

Just need debounced search? **One line:**

```dart
TextField(onChanged: (s) => debouncer(() => search(s)))
```

That's it. No setup. No dispose. Works immediately.

---

## Quick Start by Level

### 🟢 Basic — Just Works

**Anti-Spam Button** (prevents double-tap)
```dart
ThrottledInkWell(
  duration: 500.ms,
  onTap: () => processPayment(),
  child: Text('Pay \$99'),
)
```

**Debounced Search** (waits for typing pause)
```dart
final debouncer = Debouncer(duration: 300.ms);

TextField(
  onChanged: (text) => debouncer(() => search(text)),
)
```

### 🟡 Intermediate — More Control

**Async with Loading State**
```dart
AsyncThrottledBuilder(
  builder: (context, throttle) => ElevatedButton(
    onPressed: throttle(() async => await submitForm()),
    child: Text('Submit'),
  ),
)
```

**Cancel Stale Requests** (search autocomplete)
```dart
final controller = ConcurrentAsyncThrottler(mode: ConcurrencyMode.replace);

void onSearch(String query) {
  controller(() async {
    final results = await api.search(query);  // Old requests auto-cancelled
    updateUI(results);
  });
}
```

### 🔴 Advanced — Enterprise Features

**Server-Side Batching** (100x fewer DB writes)
```dart
final batcher = BatchThrottler(
  duration: 2.seconds,
  maxBatchSize: 50,
  onBatchExecute: (logs) => database.insertBatch(logs),
);

batcher(() => logEntry);  // 1000 calls → 20 batches
```

**Token Bucket Rate Limiting** (API cost control)
```dart
final limiter = RateLimiter(maxTokens: 100, refillRate: 10);

if (!limiter.tryAcquire()) {
  return Response.tooManyRequests();
}
```

---

## Coming from easy_debounce?

Migration takes 2 minutes. You get memory safety for free.

```dart
// Before (easy_debounce) - manual cancel, possible memory leak
EasyDebounce.debounce('search', Duration(ms: 300), () => search(q));

// After - auto-dispose, lifecycle-aware
final debouncer = Debouncer(duration: 300.ms);
debouncer(() => search(q));
```

See full [Migration Guide](MIGRATION_GUIDE.md) →

---

## Installation

```yaml
# Flutter App
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

## Quality Assurance

| Guarantee | How |
|-----------|-----|
| **Stability** | 360+ tests, 95% coverage |
| **Type Safety** | No `dynamic`, full generic support |
| **Lifecycle Safe** | Auto-checks `mounted`, auto-cancel on dispose |
| **Memory Safe** | Zero leaks (verified with LeakTracker) |
| **Zero Dependencies** | Only `meta` package in core |

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

## Roadmap

We're committed to long-term maintenance and improvement.

| Version | Status | Features |
|---------|--------|----------|
| **v1.0** | ✅ Released | Core debounce/throttle, widgets, mixin |
| **v1.1** | ✅ Released | RateLimiter, extensions, leading/trailing edge, batch limits |
| **v1.2** | 🔜 Planned | Retry policies, circuit breaker pattern |
| **v2.0** | 📋 Roadmap | Web Workers support, isolate-safe controllers |

Have a feature request? [Open an issue](https://github.com/brewkits/flutter_debounce_throttle/issues)

---

<p align="center">
  <b>360+ tests</b> · <b>Zero dependencies</b> · <b>Type-safe</b> · <b>Production-ready</b>
</p>

<p align="center">
  Made with craftsmanship by <a href="https://github.com/brewkits">Brewkits</a>
</p>
