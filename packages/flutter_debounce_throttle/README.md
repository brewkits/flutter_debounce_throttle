# flutter_debounce_throttle

[![pub package](https://img.shields.io/pub/v/flutter_debounce_throttle.svg)](https://pub.dev/packages/flutter_debounce_throttle)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Tests](https://img.shields.io/badge/tests-360%2B%20passed-brightgreen)](https://github.com/brewkits/flutter_debounce_throttle)
[![Coverage](https://img.shields.io/badge/coverage-95%25-brightgreen)](https://github.com/brewkits/flutter_debounce_throttle)

## The Traffic Control System for Flutter Apps

> Stop using manual Timers. They cause memory leaks and crashes.

**All-in-one package** for debounce, throttle, rate limiting, and async concurrency control. Memory-safe, lifecycle-aware, and works with any state management solution.

```dart
// One widget. Prevents double-tap payment bugs forever.
ThrottledInkWell(
  duration: 500.ms,
  onTap: () => processPayment(),
  child: Text('Pay \$99'),
)
```

---

## Why Not Just Use easy_debounce?

| Capability | This Package | easy_debounce | Manual Timer |
|------------|:---:|:---:|:---:|
| **Memory Safe** (Auto-dispose) | ✅ | ❌ | ❌ Leaky |
| **Async & Future Support** | ✅ | ❌ | ❌ |
| **Race Condition Control** | ✅ 4 modes | ❌ | ❌ |
| **Ready-to-use Widgets** | ✅ | ❌ | ❌ |
| **State Management Mixin** | ✅ | ❌ | ❌ |
| **Loading States Built-in** | ✅ | ❌ | ❌ |

---

## 5-Second Start

**Anti-Spam Button:**
```dart
ThrottledInkWell(onTap: () => pay(), child: Text('Pay'))
```

**Debounced Search:**
```dart
final debouncer = Debouncer(duration: 300.ms);
TextField(onChanged: (s) => debouncer(() => search(s)))
```

That's it. No setup. No dispose. Auto-cleanup on widget unmount.

---

## Widgets

| Widget | Use Case |
|--------|----------|
| `ThrottledInkWell` | Button with ripple + throttle |
| `ThrottledBuilder` | Custom throttled widget |
| `DebouncedBuilder` | Custom debounced widget |
| `DebouncedQueryBuilder` | Search with loading state |
| `AsyncThrottledBuilder` | Async with lock |
| `ConcurrentAsyncThrottledBuilder` | 4 concurrency modes |
| `StreamDebounceListener` | Debounce stream events |
| `StreamThrottleListener` | Throttle stream events |

---

## State Management Mixin

Works with **Provider, Bloc, GetX, Riverpod, MobX** — any `ChangeNotifier`:

```dart
class SearchController with ChangeNotifier, EventLimiterMixin {
  List<User> users = [];

  void onSearch(String text) {
    debounce('search', () async {
      users = await api.search(text);
      notifyListeners();
    });
  }

  @override
  void dispose() {
    cancelAll();  // Clean up all limiters
    super.dispose();
  }
}
```

---

## Concurrency Modes

Handle race conditions with 4 strategies:

| Mode | Behavior | Use Case |
|------|----------|----------|
| `drop` | Ignore new while busy | Payment buttons |
| `replace` | Cancel old, run new | Search autocomplete |
| `enqueue` | Queue in order | Chat messages |
| `keepLatest` | Current + last only | Auto-save |

```dart
ConcurrentAsyncThrottledBuilder(
  mode: ConcurrencyMode.replace,  // Cancel stale requests
  builder: (context, throttle, isLoading, pendingCount) => ...
)
```

---

## Installation

```yaml
dependencies:
  flutter_debounce_throttle: ^1.1.0
```

---

## v1.1.0 Features

```dart
// Duration extensions
ThrottledInkWell(duration: 500.ms, ...)

// Leading + trailing edge (like lodash)
Debouncer(leading: true, trailing: true)

// Rate limiter with Token Bucket
RateLimiter(maxTokens: 10, refillRate: 2)

// Queue backpressure control
ConcurrentAsyncThrottler(maxQueueSize: 10)
```

---

## Quality Assurance

| Guarantee | How |
|-----------|-----|
| **360+ tests** | Comprehensive unit & integration tests |
| **95% coverage** | All edge cases covered |
| **Type-safe** | No `dynamic`, full generics |
| **Memory-safe** | Zero leaks verified |

---

## Related Packages

| Package | Use When |
|---------|----------|
| [`flutter_debounce_throttle_core`](https://pub.dev/packages/flutter_debounce_throttle_core) | Pure Dart (Server/CLI) |
| [`flutter_debounce_throttle_hooks`](https://pub.dev/packages/flutter_debounce_throttle_hooks) | Flutter + Hooks |

---

<p align="center">
  <a href="https://github.com/brewkits/flutter_debounce_throttle">GitHub</a> ·
  <a href="https://github.com/brewkits/flutter_debounce_throttle/blob/main/docs/API_REFERENCE.md">API Reference</a> ·
  <a href="https://github.com/brewkits/flutter_debounce_throttle/blob/main/docs/BEST_PRACTICES.md">Best Practices</a>
</p>

<p align="center">
  Made with craftsmanship by <a href="https://github.com/brewkits">Brewkits</a>
</p>
