# flutter_debounce_throttle

[![pub package](https://img.shields.io/pub/v/flutter_debounce_throttle.svg)](https://pub.dev/packages/flutter_debounce_throttle)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Tests](https://img.shields.io/badge/tests-500%2B%20passed-brightgreen)](https://github.com/brewkits/flutter_debounce_throttle)
[![Coverage](https://img.shields.io/badge/coverage-95%25-brightgreen)](https://github.com/brewkits/flutter_debounce_throttle)

Debounce, throttle, rate limiting, and async concurrency control for Flutter & Dart. Memory-safe, lifecycle-aware, zero external dependencies.

---

## Quick Start

**Anti-spam button — 1 line:**
```dart
ThrottledInkWell(onTap: () => processPayment(), child: Text('Pay \$99'))
```

**Debounced search:**
```dart
final debouncer = Debouncer(duration: 300.ms);
TextField(onChanged: (s) => debouncer(() => search(s)))
```

**State management (works with Provider, Riverpod, GetX, Bloc):**
```dart
class SearchController with ChangeNotifier, EventLimiterMixin {
  void onSearch(String text) {
    debounce('search', () async {
      _results = await api.search(text);
      notifyListeners();
    });
  }

  @override
  void dispose() { cancelAll(); super.dispose(); }
}
```

---

## Which Package?

| You are building... | Install |
|---------------------|---------|
| Flutter app | `flutter_debounce_throttle` |
| Flutter app + flutter_hooks | `flutter_debounce_throttle_hooks` |
| Dart server / CLI / Serverpod | `dart_debounce_throttle` |

---

## Why Not easy_debounce or Manual Timer?

| Capability | This Library | easy_debounce | Manual Timer |
|------------|:---:|:---:|:---:|
| Memory safe (auto-dispose) | ✅ | ❌ | ❌ Leaky |
| Async & Future support | ✅ | ❌ | ❌ |
| Race condition control (4 modes) | ✅ | ❌ | ❌ |
| Ready-to-use widgets | ✅ | ❌ | ❌ |
| State management mixin | ✅ | ❌ | ❌ |
| Loading states built-in | ✅ | ❌ | ❌ |
| Rate limiting (Token Bucket) | ✅ | ❌ | ❌ |
| Server-side (Pure Dart) | ✅ | ❌ | ✅ |
| External dependencies | **0** | 0 | 0 |

---

## Quick Start by Level

### Basic — Just works

```dart
// Prevent double-tap payment
ThrottledInkWell(
  duration: 500.ms,
  onTap: () => processPayment(),
  child: Text('Pay \$99'),
)

// Debounced search
final debouncer = Debouncer(duration: 300.ms);
TextField(onChanged: (text) => debouncer(() => search(text)))
```

### Intermediate — Async control

```dart
// Async button with loading state
AsyncThrottledBuilder(
  builder: (context, throttle, isLoading) => ElevatedButton(
    onPressed: throttle(() async => await submitForm()),
    child: Text(isLoading ? 'Submitting...' : 'Submit'),
  ),
)

// Cancel stale search requests automatically
ConcurrentAsyncThrottledBuilder(
  mode: ConcurrencyMode.replace,
  builder: (context, throttle, isLoading, _) => TextField(
    onChanged: (text) => throttle(() async {
      setState(() => _results = await api.search(text));
    }),
  ),
)
```

### Advanced — Server & Enterprise

```dart
// Rate limiting (Token Bucket)
final limiter = RateLimiter(maxTokens: 100, refillRate: 10);
if (!limiter.tryAcquire()) return Response.tooManyRequests();

// Batch DB writes (1000 calls → 10 DB writes)
final batcher = BatchThrottler(
  duration: 2.seconds,
  maxBatchSize: 100,
  onBatchExecute: (items) => db.insertBatch(items),
);

// Throttle all 40+ gesture types
ThrottledGestureDetector(
  onTap: () => handleTap(),
  onPanUpdate: (d) => updatePosition(d.delta),
  child: MyWidget(),
)
```

---

## Memory Management

Dynamic IDs (e.g. `debounce('post_$postId', ...)`) can accumulate without cleanup. Since **v2.3.0**, unused limiters are auto-removed after 10 minutes by default:

```dart
// Safe by default — old limiters auto-cleanup
class FeedController with EventLimiterMixin {
  void onLike(String postId) {
    debounce('like_$postId', () => api.like(postId));
  }
}

// Override if needed
DebounceThrottleConfig.init(
  limiterAutoCleanupTTL: Duration(minutes: 5),
  limiterAutoCleanupThreshold: 50,
);
```

---

## Installation

```yaml
# Flutter
dependencies:
  flutter_debounce_throttle: ^2.4.0

# Flutter + Hooks
dependencies:
  flutter_debounce_throttle_hooks: ^2.4.0

# Pure Dart (Server, CLI)
dependencies:
  dart_debounce_throttle: ^2.4.0
```

---

## Quality

| | |
|---|---|
| **500+ tests** | Unit, widget, integration, memory leak tests |
| **95% coverage** | All edge cases covered |
| **Zero dependencies** | Only `meta` in production |
| **Type-safe** | Full generics, no `dynamic` |
| **Memory-safe** | Verified with Flutter LeakTracker |

---

## Documentation

| | |
|---|---|
| [FAQ](FAQ.md) | Common questions |
| [API Reference](docs/API_REFERENCE.md) | Complete class/method docs |
| [Best Practices](docs/BEST_PRACTICES.md) | Patterns & recommendations |
| [Migration Guide](MIGRATION_GUIDE.md) | From easy_debounce, rxdart, manual Timer |
| [Example App](example/) | 6 interactive demos |

---

## Packages

| Package | Platform | Use Case |
|---------|----------|----------|
| [`flutter_debounce_throttle`](https://pub.dev/packages/flutter_debounce_throttle) | Flutter | Widgets, Mixin, Text Controllers |
| [`flutter_debounce_throttle_hooks`](https://pub.dev/packages/flutter_debounce_throttle_hooks) | Flutter + Hooks | useDebouncer, useThrottler |
| [`dart_debounce_throttle`](https://pub.dev/packages/dart_debounce_throttle) | Pure Dart | Server, CLI, Serverpod, Dart Frog |

---

## Roadmap

| Version | Status | Highlights |
|---------|--------|------------|
| v2.2 | ✅ Released | Error handling, TTL auto-cleanup |
| v2.3 | ✅ Released | Auto-cleanup enabled by default |
| v2.4 | ✅ Released | ThrottledGestureDetector, DistributedRateLimiter |
| v2.5 | 🔜 Planned | Retry policies, circuit breaker pattern |
| v3.x | 📋 Roadmap | Web Workers, isolate-safe controllers |

---

<p align="center">
  Made with craftsmanship by <a href="https://github.com/brewkits">Brewkits</a>
</p>
