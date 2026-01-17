# flutter_debounce_throttle

[![pub package](https://img.shields.io/pub/v/flutter_debounce_throttle.svg)](https://pub.dev/packages/flutter_debounce_throttle)

## The Complete Event Rate Limiting Solution for Flutter

**All-in-one package** combining ready-to-use widgets, builders, and mixins for debounce, throttle, rate limiting, and async concurrency control. Replaces `easy_debounce` + manual timers + custom race condition handling.

**Prevents:** Double-tap bugs, stale API results, memory leaks, race conditions

```dart
// One widget to prevent double-tap payment bugs forever
ThrottledInkWell(
  duration: 500.ms,
  onTap: () => processPayment(),
  child: Text('Pay \$99'),
)
```

---

## Why This Package?

| Capability | What You Get |
|------------|-------------|
| **Memory Safe** | Auto-dispose with widget lifecycle — no manual cleanup |
| **Race Condition Control** | 4 concurrency modes: `drop`, `replace`, `enqueue`, `keepLatest` |
| **Loading States** | Built-in `isLoading` for async widgets |
| **State Management Ready** | Mixin for Provider, Bloc, GetX, Riverpod, MobX |
| **Pure Dart Core** | Same API works on backend — shared logic |

---

## Installation

```yaml
dependencies:
  flutter_debounce_throttle: ^1.1.0
```

---

## Quick Start

### Prevent Double Clicks
```dart
ThrottledInkWell(
  duration: Duration(milliseconds: 500),
  onTap: () => processPayment(),
  child: Text('Pay Now'),
)
```

### Search with Loading State
```dart
DebouncedQueryBuilder<List<User>>(
  duration: Duration(milliseconds: 300),
  onQuery: (text) async => await api.search(text),
  onResult: (users) => setState(() => _users = users),
  builder: (context, search, isLoading) => TextField(
    onChanged: search,
    decoration: InputDecoration(
      suffixIcon: isLoading ? CircularProgressIndicator() : Icon(Icons.search),
    ),
  ),
)
```

### Cancel Stale Requests
```dart
ConcurrentAsyncThrottledBuilder(
  mode: ConcurrencyMode.replace,  // Cancel old, keep new
  builder: (context, throttle, isLoading) => ElevatedButton(
    onPressed: () => throttle(() async => await api.fetch()),
    child: isLoading ? CircularProgressIndicator() : Text('Fetch'),
  ),
)
```

---

## Widgets

| Widget | Use Case |
|--------|----------|
| `ThrottledInkWell` | Button with ripple + throttle |
| `ThrottledBuilder` | Custom throttled widget |
| `DebouncedBuilder` | Custom debounced widget |
| `DebouncedQueryBuilder` | Search with loading state |
| `ConcurrentAsyncThrottledBuilder` | Race condition control |
| `StreamDebounceListener` | Debounce stream events |
| `StreamThrottleListener` | Throttle stream events |

---

## State Management Mixin

Works with **Provider, Bloc, GetX, Riverpod, MobX**:

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
    cancelAll();  // Important!
    super.dispose();
  }
}
```

**Mixin Methods:**
```dart
debounce(id, callback)      // Debounce by ID
throttle(id, callback)      // Throttle by ID
debounceAsync(id, callback) // Async debounce
throttleAsync(id, callback) // Async throttle
cancel(id)                  // Cancel specific
cancelAll()                 // Cancel all
```

---

## Concurrency Modes

| Mode | Behavior | Use Case |
|------|----------|----------|
| `drop` | Ignore while busy | Payment buttons |
| `replace` | Cancel old, run new | Search autocomplete |
| `enqueue` | Queue in order | Chat messages |
| `keepLatest` | Current + last only | Auto-save |

---

## v1.1.0 Features

```dart
// Duration extensions
ThrottledInkWell(duration: 500.ms, ...)

// Leading + trailing edge
Debouncer(leading: true, trailing: true)

// Rate limiter (Token Bucket)
RateLimiter(maxTokens: 10, refillRate: 2)

// Queue backpressure
ConcurrentAsyncThrottler(maxQueueSize: 10)
```

---

## Related Packages

| Package | Use When |
|---------|----------|
| [flutter_debounce_throttle_core](https://pub.dev/packages/flutter_debounce_throttle_core) | Pure Dart (Server/CLI) |
| [flutter_debounce_throttle_hooks](https://pub.dev/packages/flutter_debounce_throttle_hooks) | Flutter + Hooks |

---

<p align="center">
  <a href="https://github.com/brewkits/flutter_debounce_throttle">GitHub</a> ·
  <a href="https://github.com/brewkits/flutter_debounce_throttle/blob/main/docs/API_REFERENCE.md">API Reference</a> ·
  <a href="https://github.com/brewkits/flutter_debounce_throttle/blob/main/docs/BEST_PRACTICES.md">Best Practices</a>
</p>
