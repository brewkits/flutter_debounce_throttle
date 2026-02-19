# flutter_debounce_throttle

[![pub package](https://img.shields.io/pub/v/flutter_debounce_throttle.svg)](https://pub.dev/packages/flutter_debounce_throttle)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Tests](https://img.shields.io/badge/tests-450%2B%20passed-brightgreen)](https://github.com/brewkits/flutter_debounce_throttle)
[![Coverage](https://img.shields.io/badge/coverage-95%25-brightgreen)](https://github.com/brewkits/flutter_debounce_throttle)

## The Traffic Control System for Flutter Apps

> Stop using manual `Timer`. It causes memory leaks, crashes, and race conditions.

**All-in-one package** for debounce, throttle, rate limiting, and async concurrency control. Memory-safe, lifecycle-aware, and works with any state management solution.

---

## 30-Second Start

**Anti-Spam Button (1 line):**
```dart
ThrottledInkWell(onTap: () => processPayment(), child: Text('Pay \$99'))
```

**Debounced Search:**
```dart
final debouncer = Debouncer(duration: 300.ms);
TextField(onChanged: (s) => debouncer(() => search(s)))
```

**Async with loading state:**
```dart
AsyncThrottledBuilder(
  builder: (context, throttle, isLoading) => ElevatedButton(
    onPressed: throttle(() async => await submitForm()),
    child: Text(isLoading ? 'Submitting...' : 'Submit'),
  ),
)
```

**State management (Provider / Riverpod / GetX / Bloc):**
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

No setup. No dispose boilerplate. Auto-cleanup on widget unmount.

---

## Widgets

| Widget | Use Case |
|--------|----------|
| `ThrottledInkWell` | Button with ripple + throttle — prevent double-tap |
| `ThrottledBuilder` | Custom throttled widget |
| `DebouncedBuilder` | Custom debounced widget |
| `DebouncedQueryBuilder` | Search input with loading state |
| `AsyncThrottledBuilder` | Async button with loading lock |
| `ConcurrentAsyncThrottledBuilder` | 4 concurrency modes |
| `ThrottledGestureDetector` | Drop-in `GestureDetector` replacement |
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

> **⚠️ Important:** When using **dynamic IDs** (e.g., `debounce('post_$postId', ...)`), call `remove(id)` when items are deleted. For static IDs like `'search'`, `cancelAll()` in dispose is sufficient.

---

## Concurrency Modes

Handle race conditions in async operations with 4 strategies:

| Mode | Behavior | Use Case |
|------|----------|----------|
| `drop` | Ignore new while busy | Payment buttons |
| `replace` | Cancel old, run new | Search autocomplete |
| `enqueue` | Queue in order | Chat messages |
| `keepLatest` | Current + last only | Auto-save |

```dart
ConcurrentAsyncThrottledBuilder(
  mode: ConcurrencyMode.replace,  // Cancel stale API requests
  builder: (context, throttle, isLoading, pendingCount) => ...
)
```

---

## How It Works — Visualized

### Throttle vs Debounce (Duration: 300ms)

#### ➤ Throttle (Button Clicks)
Executes **immediately**, then **locks** for the duration. Subsequent events are **ignored**.

```
Events:    (Click1)    (Click2)    (Click3)              (Click4)
Time:      |─ 0ms ─────── 100ms ──── 200ms ──── 300ms ──── 400ms ──|
           ▼                                     ▲
Execution: [EXECUTE] ····················· [LOCKED/DROP] ······· [EXECUTE]
           └─────── 300ms cooldown ──────┘
```

**Use:** Payment buttons, save buttons, scroll handlers

---

#### ➤ Debounce (Search Input)
Waits for a **pause** in events before executing.

```
Events:    (Type 'A')   (Type 'B')   (Type 'C')    [User stops typing]
Time:      |─ 0ms ──── 100ms ──── 200ms ────────────── 500ms ──────|
           ▼            ▼            ▼                  ▲
Execution: [WAIT] ····· [RESET] ····· [RESET] ········ [EXECUTE 'ABC']
                                      └─────── 300ms wait ──────┘
```

**Use:** Search autocomplete, form validation, window resize

---

#### ➤ Concurrency: `replace` (Perfect for Search)
New task **cancels** the old one.

```
Task 1:  [──────── 500ms API Call ──X Cancelled
Task 2:              ↓ New search query
                     [──────── 500ms API Call ────────]  ✅ Result shown
```

---

## Extensions & Utilities

```dart
// Duration extensions — write durations naturally
ThrottledInkWell(duration: 500.ms, ...)
Debouncer(duration: 300.ms)
RateLimiter(refillInterval: 1.seconds)

// Leading + trailing edge (like lodash)
Debouncer(leading: true, trailing: true)

// Rate limiter with Token Bucket
RateLimiter(maxTokens: 10, refillRate: 2)

// Queue backpressure control
ConcurrentAsyncThrottler(maxQueueSize: 10)

// Callback extensions
final debouncedFn = myFunction.debounced(300.ms);
final throttledFn = myFunction.throttled(500.ms);
```

---

## Installation

```yaml
dependencies:
  flutter_debounce_throttle: ^2.4.0
```

---

## Quality Assurance

| Guarantee | How |
|-----------|-----|
| **450+ tests** | Comprehensive unit & integration tests |
| **95% coverage** | All edge cases covered |
| **Type-safe** | No `dynamic`, full generics |
| **Memory-safe** | Zero leaks verified with LeakTracker |

---

## Which Package Should I Use?

| You are building... | Package |
|---------------------|---------|
| Flutter app (most users) | **`flutter_debounce_throttle`** ← you are here |
| Flutter app + `flutter_hooks` | [`flutter_debounce_throttle_hooks`](https://pub.dev/packages/flutter_debounce_throttle_hooks) |
| Dart server / CLI / Serverpod | [`dart_debounce_throttle`](https://pub.dev/packages/dart_debounce_throttle) |

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

<p align="center">
  <a href="https://github.com/brewkits/flutter_debounce_throttle">GitHub</a> ·
  <a href="https://github.com/brewkits/flutter_debounce_throttle/blob/main/FAQ.md">FAQ</a> ·
  <a href="https://github.com/brewkits/flutter_debounce_throttle/blob/main/docs/API_REFERENCE.md">API Reference</a> ·
  <a href="https://github.com/brewkits/flutter_debounce_throttle/blob/main/docs/BEST_PRACTICES.md">Best Practices</a>
</p>

<p align="center">
  Made with craftsmanship by <a href="https://github.com/brewkits">Brewkits</a>
</p>
