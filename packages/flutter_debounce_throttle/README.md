# flutter_debounce_throttle

[![pub package](https://img.shields.io/pub/v/flutter_debounce_throttle.svg)](https://pub.dev/packages/flutter_debounce_throttle)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Tests](https://img.shields.io/badge/tests-300%2B%20passed-brightgreen)](https://github.com/brewkits/flutter_debounce_throttle)
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

### Concurrency Modes (Async)

#### Mode: `replace` (Perfect for Search)
New task **cancels** the old one.

```
Task 1:  [──────── 500ms API Call ──X Cancelled
Task 2:              ↓ New search query
                     [──────── 500ms API Call ────────]  ✅ Result shown
```

**Use:** Search autocomplete, tab switching

---

#### Mode: `drop` (Default)
If busy, new tasks are **ignored**.

```
Task 1:  [──────── 500ms API Call ────────]  ✅ Completes
Task 2:            ↓ User taps again
                   [DROPPED ❌]
```

**Use:** Payment buttons, preventing double-tap

---

#### Mode: `enqueue`
Tasks **queue** and run in order.

```
Task 1:  [──────── 500ms ────────]  ✅
Task 2:            ↓ Queued
                   [Waiting...]      [──────── 500ms ────────]  ✅
```

**Use:** Chat messages, ordered operations

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
| `ThrottledGestureDetector` 🆕 | Full GestureDetector with throttling (tap, pan, scale, drag) |
| `ThrottledInkWell` | Button with ripple + throttle |
| `ThrottledBuilder` | Custom throttled widget |
| `DebouncedBuilder` | Custom debounced widget |
| `DebouncedQueryBuilder` | Search with loading state |
| `AsyncThrottledBuilder` | Async with lock |
| `ConcurrentAsyncThrottledBuilder` | 4 concurrency modes |
| `StreamDebounceListener` | Debounce stream events |
| `StreamThrottleListener` | Throttle stream events |

### 🆕 ThrottledGestureDetector

Prevent gesture spam with full GestureDetector API support:

```dart
ThrottledGestureDetector(
  continuousDuration: ThrottleDuration.ultraSmooth, // 8ms for 120Hz displays
  onTap: () => handleTap(),
  onLongPress: () => showMenu(),
  onPanUpdate: (details) => updatePosition(details),
  onScaleUpdate: (details) => zoom(details.scale),
  child: MyWidget(),
)
```

**Features:**
- ✅ All 40+ gesture callbacks supported
- ✅ Smart dual-throttle: discrete (500ms) + continuous (16ms/60fps)
- ✅ 120Hz display support with `ThrottleDuration` presets
- ✅ Automatic cleanup on dispose

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

> **⚠️ Important:** When using **dynamic IDs** (e.g., `debounce('post_$postId', ...)`), you must manually call `remove(id)` when items are deleted to prevent memory leaks. The mixin does **not** automatically dispose dynamic IDs. For static IDs like `'search'` or `'submit'`, `cancelAll()` in dispose is sufficient.

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
  flutter_debounce_throttle: ^2.4.2
```

---

## 🆕 What's New in v2.4

### ThrottledGestureDetector
Drop-in replacement for GestureDetector with built-in throttling and 120Hz display support.

### ThrottleDuration Presets
```dart
ThrottleDuration.ultraSmooth    // 8ms  - iPad Pro 120Hz, iPhone 13 Pro+
ThrottleDuration.standard       // 16ms - 60fps (default)
ThrottleDuration.conservative   // 32ms - Battery saving, complex animations
```

### Power Features

```dart
// Duration extensions
ThrottledInkWell(duration: 500.ms, ...)

// Leading + trailing edge (like lodash)
Debouncer(leading: true, trailing: true)

// Rate limiter with Token Bucket
RateLimiter(maxTokens: 10, refillRate: 2)

// Queue backpressure control
ConcurrentAsyncThrottler(maxQueueSize: 10)

// Device-adaptive throttling
final duration = MediaQuery.of(context).devicePixelRatio >= 3.0
    ? ThrottleDuration.ultraSmooth
    : ThrottleDuration.standard;
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
| [`dart_debounce_throttle`](https://pub.dev/packages/dart_debounce_throttle) | Pure Dart (Server/CLI) |
| [`flutter_debounce_throttle_hooks`](https://pub.dev/packages/flutter_debounce_throttle_hooks) | Flutter + Hooks |

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
