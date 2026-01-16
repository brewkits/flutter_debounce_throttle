# flutter_debounce_throttle

[![pub package](https://img.shields.io/pub/v/flutter_debounce_throttle.svg)](https://pub.dev/packages/flutter_debounce_throttle)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Tests](https://img.shields.io/badge/tests-340%2B%20passed-brightgreen)](https://github.com/brewkits/flutter_debounce_throttle)

> **The Complete Event Control Library for Flutter & Dart**
>
> One library to handle all your event limiting needs — from simple button debouncing to complex async queue management with backpressure control.

```dart
// Before: Manual timers, race conditions, memory leaks
Timer? _timer;
void onSearch(String query) {
  _timer?.cancel();
  _timer = Timer(Duration(milliseconds: 300), () => search(query));
}

// After: Clean, safe, powerful
final debouncer = Debouncer(duration: 300.ms);
void onSearch(String query) => debouncer(() => search(query));
```

---

## Why This Library?

| Challenge | Solution |
|-----------|----------|
| Double-tap crashes payment | `Throttler` blocks duplicate calls |
| Search API fires on every keystroke | `Debouncer` waits for typing pause |
| Old search results override new ones | `ConcurrencyMode.replace` cancels stale requests |
| Chat messages arrive out of order | `ConcurrencyMode.enqueue` preserves sequence |
| Memory leaks from undisposed timers | Auto-dispose with Flutter lifecycle |
| Server hit with traffic spikes | `RateLimiter` with Token Bucket algorithm |

---

## Throttle vs Debounce

```
User clicks:    ⬤  ⬤  ⬤  ⬤           ⬤  ⬤
                │  │  │  │           │  │
                ▼  ▼  ▼  ▼           ▼  ▼
                ────────────────────────────────▶ time

Throttle:       ⬤  ✕  ✕  ✕           ⬤  ✕
                ↓                    ↓
                Execute first,       Execute first,
                block for 500ms      block for 500ms

Debounce:       ✕  ✕  ✕  ⬤           ✕  ⬤
                         ↓              ↓
                         Wait 300ms     Wait 300ms
                         then execute   then execute
```

| | Throttle | Debounce |
|---|:---:|:---:|
| **Button clicks** | ✓ | |
| **API rate limit** | ✓ | |
| **Scroll events** | ✓ | |
| **Search input** | | ✓ |
| **Form validation** | | ✓ |
| **Window resize** | | ✓ |

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

### Debounce Search
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
final controller = ConcurrentAsyncThrottler(
  mode: ConcurrencyMode.replace,  // Cancel old, keep new
);

void onSearch(String query) {
  controller(() async => await api.search(query));
}
// User types "a" → "ab" → "abc"
// Only "abc" search executes, others cancelled
```

---

## Installation

```yaml
dependencies:
  flutter_debounce_throttle: ^1.1.0      # Flutter apps
  # OR
  flutter_debounce_throttle_hooks: ^1.1.0 # With flutter_hooks
  # OR
  flutter_debounce_throttle_core: ^1.1.0  # Pure Dart (Server/CLI)
```

---

## What's New in v1.1.0

| Feature | Description |
|---------|-------------|
| `RateLimiter` | Token Bucket algorithm — allow bursts, then limit |
| `300.ms` | Duration extensions for cleaner code |
| `fn.debounced()` | Callback extensions |
| `leading: true` | Execute immediately + after pause (like lodash) |
| `maxBatchSize` | Limit batch size with overflow strategies |
| `maxQueueSize` | Queue backpressure control |

```dart
// Token bucket rate limiting
final limiter = RateLimiter(maxTokens: 10, refillRate: 2);
if (limiter.tryAcquire()) {
  await api.call();
}

// Duration extensions
final debouncer = Debouncer(duration: 300.ms);

// Leading + trailing edge
final debouncer = Debouncer(leading: true, trailing: true);
```

---

## Complete Toolkit

| Tool | Use Case |
|------|----------|
| `Throttler` | Button clicks, scroll handlers |
| `Debouncer` | Search input, form validation |
| `AsyncThrottler` | API calls with loading state |
| `ConcurrentAsyncThrottler` | Race condition control (4 modes) |
| `HighFrequencyThrottler` | 60fps scroll/mouse events |
| `BatchThrottler` | Analytics batching |
| `RateLimiter` | API rate limiting (Token Bucket) |

**Concurrency Modes:**
| Mode | Behavior |
|------|----------|
| `drop` | Ignore while busy (payment buttons) |
| `replace` | Cancel old, run new (search) |
| `enqueue` | Queue in order (chat messages) |
| `keepLatest` | Run current + last (auto-save) |

---

## Flutter Widgets

```dart
// Ready-to-use widgets
ThrottledInkWell(onTap: () => ..., duration: 500.ms)
ThrottledBuilder(builder: (context, throttle) => ...)
DebouncedBuilder(builder: (context, debounce) => ...)
DebouncedQueryBuilder(onQuery: (q) async => ..., builder: ...)
StreamDebounceListener(stream: ..., onData: ...)
```

## State Management

Works with Provider, Bloc, GetX, Riverpod:

```dart
class MyController with ChangeNotifier, EventLimiterMixin {
  void onSearch(String text) {
    debounce('search', () async {
      _users = await api.search(text);
      notifyListeners();
    });
  }

  @override
  void dispose() {
    cancelAll();
    super.dispose();
  }
}
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

## Packages

| Package | Platform |
|---------|----------|
| [`flutter_debounce_throttle`](https://pub.dev/packages/flutter_debounce_throttle) | Flutter |
| [`flutter_debounce_throttle_hooks`](https://pub.dev/packages/flutter_debounce_throttle_hooks) | Flutter + Hooks |
| [`flutter_debounce_throttle_core`](https://pub.dev/packages/flutter_debounce_throttle_core) | Pure Dart |

---

<p align="center">
  <b>340+ tests</b> · <b>Zero dependencies</b> (core) · <b>Type-safe</b> · <b>Auto-dispose</b>
</p>

<p align="center">
  Made by <a href="https://github.com/brewkits">Brewkits</a>
</p>
