# flutter_debounce_throttle

[![pub package](https://img.shields.io/pub/v/flutter_debounce_throttle.svg)](https://pub.dev/packages/flutter_debounce_throttle)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Tests](https://img.shields.io/badge/tests-300%2B%20passed-brightgreen)](https://github.com/brewkits/flutter_debounce_throttle)
[![Coverage](https://img.shields.io/badge/coverage-95%25-brightgreen)](https://github.com/brewkits/flutter_debounce_throttle)
[![Pure Dart](https://img.shields.io/badge/pure-Dart-02569B)](https://dart.dev)

## Enterprise-Grade Event Rate Limiter & Throttle Library

> The complete traffic control system for Flutter & Dart.
> Stop UI glitches, API spam, and race conditions with production-safe debounce, throttle, and rate limiting.

> Stop using manual Timers. They cause memory leaks and crashes.
> Switch to the production-grade event rate limiting library for Flutter & Dart.

Enterprise-ready library unifying **debounce, throttle, rate limiting, and async concurrency control** into a single, battle-tested package with 360+ tests and 95% coverage.

**Like ABS brakes for your app** — prevents crashes, stops memory leaks, handles edge cases automatically.

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

## How It Works — Visualized

### Throttle vs Debounce

Understanding the core difference with `duration: 300ms`:

#### ➤ Throttle (Button Clicks)
Executes **immediately**, then locks for the duration. Subsequent events are **ignored** during the lock.

```
Events:    (Click1)    (Click2)    (Click3)              (Click4)
Time:      |─ 0ms ─────── 100ms ──── 200ms ──── 300ms ──── 400ms ──|
           ▼                                     ▲
Execution: [EXECUTE] ····················· [LOCKED/DROP] ······· [EXECUTE]
           └─────── 300ms cooldown ──────┘
```

**Use for:** Payment buttons, save buttons, scroll events

---

#### ➤ Debounce (Search Input)
Waits for a **pause** in events for the duration before executing.

```
Events:    (Type 'A')   (Type 'B')   (Type 'C')    [User stops typing]
Time:      |─ 0ms ──── 100ms ──── 200ms ────────────── 500ms ──────|
           ▼            ▼            ▼                  ▲
Execution: [WAIT] ····· [RESET] ····· [RESET] ········ [EXECUTE 'ABC']
                                      └─────── 300ms wait ──────┘
```

**Use for:** Search autocomplete, form validation, window resize

---

### Concurrency Modes (Async)

How overlapping async tasks are handled (example: two 500ms API calls):

#### ➤ Mode: `drop` (Default for Throttle)
If busy, **new tasks are ignored** entirely.

```
Task 1:  [──────── 500ms API Call ────────]  ✅ Completes
Task 2:            ↓ Try to start
                   [DROPPED ❌]
Result:  Only Task 1 runs. Task 2 is ignored.
```

**Use for:** Payment processing, file uploads

---

#### ➤ Mode: `replace` (Perfect for Search)
The new task **immediately cancels** the running task.

```
Task 1:  [──────── 500ms API Call ──X Cancelled
Task 2:              ↓ New task starts
                     [──────── 500ms API Call ────────]  ✅ Completes
Result:  Task 1 cancelled. Only Task 2's result is used.
```

**Use for:** Search autocomplete, switching tabs, real-time filters

---

#### ➤ Mode: `enqueue` (Queue)
Tasks **wait in line** for their turn.

```
Task 1:  [──────── 500ms ────────]  ✅
Task 2:            ↓ Queued
                   [Waiting...]      [──────── 500ms ────────]  ✅
Result:  Task 1 runs, then Task 2 runs immediately after.
```

**Use for:** Chat messages, notification queue, ordered operations

---

#### ➤ Mode: `keepLatest` (Current + Last Only)
Only keeps the **current running task** and **one latest queued task**.

```
Task 1:  [──────── 500ms ────────]  ✅
Task 2:            ↓ Queued
Task 3:                      ↓ Replaces Task 2 in queue
                             [Waiting...]      [──────── 500ms ────────]  ✅
Result:  Task 1 runs, Task 2 is dropped, Task 3 runs after Task 1.
```

**Use for:** Auto-save, data sync, real-time updates

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

## 🧹 Memory Management (NEW in v2.3.0)

### The Problem: Dynamic IDs Can Leak Memory

```dart
// ⚠️ This pattern can leak memory:
class InfiniteScrollController with EventLimiterMixin {
  void onPostLike(String postId) {
    debounce('like_$postId', () => api.like(postId));  // New limiter per post!
  }
}
// User scrolls through 1000+ posts → 1000+ limiters → OOM crash
```

### The Solution: Auto-Cleanup (Enabled by Default)

**v2.3.0+ automatically cleans up unused limiters:**
- Limiters unused for **10+ minutes** are auto-removed
- Cleanup triggers when limiter count exceeds **100**
- **No configuration needed** - works out of the box!

```dart
// ✅ This is now safe by default:
class SafeController with EventLimiterMixin {
  void onPostLike(String postId) {
    debounce('like_$postId', () => api.like(postId));
    // Old limiters auto-cleanup after 10 minutes of inactivity
  }
}
```

### Customization (Optional)

```dart
void main() {
  // Customize TTL and threshold
  DebounceThrottleConfig.init(
    limiterAutoCleanupTTL: Duration(minutes: 5),    // Faster cleanup
    limiterAutoCleanupThreshold: 50,                // More aggressive
  );
  runApp(MyApp());
}
```

**Learn more:** [Best Practices - Memory Management](docs/BEST_PRACTICES.md#memory-management)

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

**Distributed Rate Limiting** (Multi-server rate limits with Redis)
```dart
// Setup Redis store
final redis = await RedisConnection().connect('localhost', 6379);
final store = RedisRateLimiterStore(redis: redis, keyPrefix: 'api:');

// Rate limit across all server instances
final limiter = DistributedRateLimiter(
  key: 'user-${userId}',
  store: store,
  maxTokens: 1000,
  refillRate: 100,  // 100 requests/sec
  refillInterval: Duration(seconds: 1),
);

if (!await limiter.tryAcquire()) {
  return Response.tooManyRequests();
}
```

**Throttled Gesture Detector** (Universal gesture throttling)
```dart
// Throttle ALL gesture types automatically
ThrottledGestureDetector(
  discreteDuration: 500.ms,       // For taps, long press
  continuousDuration: 16.ms,      // For pan, scale (60fps)
  onTap: () => handleTap(),
  onLongPress: () => showMenu(),
  onPanUpdate: (details) => updatePosition(details.delta),
  onScaleUpdate: (details) => zoom(details.scale),
  child: MyWidget(),
)
```

---

## 🚀 What's New in v2.4.0

### ThrottledGestureDetector - Universal Gesture Throttling

Finally, a drop-in replacement for `GestureDetector` with built-in throttling! No more manual wrapper logic.

**Key Features:**
- ✅ **Full GestureDetector API** - All 40+ callbacks supported
- ✅ **Smart Throttling** - Discrete events (tap, long press) and continuous events (pan, scale) use different throttle strategies
- ✅ **60fps Smooth** - Continuous gestures throttled at 16ms by default for silky animations
- ✅ **Zero Config** - Just replace `GestureDetector` with `ThrottledGestureDetector`

**Example:**
```dart
// Before: Manual throttling, complex wrapper logic
GestureDetector(
  onTap: () => _throttler.call(() => handleTap()),
  onPanUpdate: (details) => _panThrottler.call(() => updatePosition(details)),
  child: MyWidget(),
)

// After: One widget, automatic throttling
ThrottledGestureDetector(
  onTap: () => handleTap(),
  onPanUpdate: (details) => updatePosition(details.delta),
  child: MyWidget(),
)
```

### DistributedRateLimiter - Scale to Multiple Servers

Rate limiting that works across your entire backend cluster. Perfect for microservices and serverless.

**Key Features:**
- ✅ **Distributed** - Share rate limits across multiple server instances
- ✅ **Redis/Memcached** - Built-in support with reference implementations
- ✅ **Custom Stores** - Implement `AsyncRateLimiterStore` for any backend
- ✅ **Production Ready** - Atomic operations, fail-safe design

**Server-Side Example (Dart Frog / Shelf):**
```dart
// Setup once
final store = RedisRateLimiterStore(
  redis: await RedisConnection().connect('redis-server', 6379),
  keyPrefix: 'ratelimit:',
  ttl: Duration(hours: 1),
);

// Middleware
Handler rateLimitMiddleware(Handler handler) {
  return (context) async {
    final userId = context.read<User>().id;

    final limiter = DistributedRateLimiter(
      key: 'user:$userId',
      store: store,
      maxTokens: 100,        // Burst capacity
      refillRate: 10,        // 10 requests/sec sustained
      refillInterval: Duration(seconds: 1),
    );

    if (!await limiter.tryAcquire()) {
      return Response(
        statusCode: 429,
        headers: {
          'Retry-After': (await limiter.timeUntilNextToken).inSeconds.toString(),
        },
      );
    }

    return handler(context);
  };
}
```

**Custom Storage Implementation:**
```dart
// Implement for any backend (PostgreSQL, MongoDB, etc)
class PostgresStore implements AsyncRateLimiterStore {
  final Database db;

  @override
  Future<RateLimiterState> fetchState(String key) async {
    final row = await db.query('SELECT tokens, last_refill FROM rate_limits WHERE key = ?', [key]);
    return row.isEmpty
      ? RateLimiterState(tokens: 0, lastRefillMicroseconds: 0)
      : RateLimiterState.fromList([row['tokens'], row['last_refill']]);
  }

  @override
  Future<void> saveState(String key, RateLimiterState state) async {
    await db.execute(
      'INSERT INTO rate_limits (key, tokens, last_refill) VALUES (?, ?, ?) '
      'ON CONFLICT (key) DO UPDATE SET tokens = ?, last_refill = ?',
      [key, state.tokens, state.lastRefillMicroseconds, state.tokens, state.lastRefillMicroseconds],
    );
  }
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
  flutter_debounce_throttle: ^2.4.0

# Flutter + Hooks
dependencies:
  flutter_debounce_throttle_hooks: ^2.4.0

# Pure Dart (Server, CLI)
dependencies:
  dart_debounce_throttle: ^2.4.0
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
| [**FAQ**](FAQ.md) | Common questions answered |
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
| [`dart_debounce_throttle`](https://pub.dev/packages/dart_debounce_throttle) | Pure Dart | Server, CLI, anywhere |

---

## Roadmap

We're committed to long-term maintenance and improvement.

| Version | Status | Features |
|---------|--------|----------|
| **v1.0** | ✅ Released | Core debounce/throttle, widgets, mixin |
| **v1.1** | ✅ Released | RateLimiter, extensions, leading/trailing edge, batch limits |
| **v2.0** | ✅ Released | Package rename to dart_debounce_throttle, improved documentation |
| **v2.2** | ✅ Released | Error handling (onError callbacks), TTL auto-cleanup, performance optimization |
| **v2.3** | ✅ Released | Memory leak prevention, auto-cleanup for EventLimiterMixin |
| **v2.4** | ✅ Released | ThrottledGestureDetector, DistributedRateLimiter with Redis/Memcached support |
| **v2.5** | 🔜 Planned | Retry policies, circuit breaker pattern |
| **v3.x** | 📋 Roadmap | Web Workers support, isolate-safe controllers |

Have a feature request? [Open an issue](https://github.com/brewkits/flutter_debounce_throttle/issues)

---

<p align="center">
  <b>300+ tests</b> · <b>Zero dependencies</b> · <b>Type-safe</b> · <b>Production-ready</b>
</p>

<p align="center">
  Made with craftsmanship by <a href="https://github.com/brewkits">Brewkits</a>
</p>
