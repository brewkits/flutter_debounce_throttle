# flutter_debounce_throttle

[![pub package](https://img.shields.io/pub/v/flutter_debounce_throttle.svg)](https://pub.dev/packages/flutter_debounce_throttle)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Dart 3](https://img.shields.io/badge/Dart-3.x-blue.svg)](https://dart.dev)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B.svg)](https://flutter.dev)

**The Safe, Unified & Universal Event Limiter for Flutter & Dart.**

Debounce, throttle, and rate limit with automatic lifecycle management. Prevent double clicks, race conditions, and memory leaks. Works on Mobile, Web, Desktop, and Server.

---

## ✨ Highlights

| | Feature |
|---|---------|
| 🎯 | **One API, All Platforms** - Works on Flutter (Mobile, Web, Desktop) and Pure Dart (Server, CLI) |
| 🔒 | **Memory Safe** - Auto-dispose with widget lifecycle, mounted checks prevent memory leaks |
| ⚡ | **Type Safe** - Full generic support, no dynamic types, null-safe results |
| 🧪 | **Production Ready** - 340+ tests, comprehensive coverage, battle-tested |
| 🏗️ | **Zero Dependencies** - Core package has no external dependencies |
| 🎨 | **Modern API** - Callable class pattern: `debouncer(() => ...)` |
| 🔄 | **4 Concurrency Modes** - drop, enqueue, replace, keepLatest |
| 🪝 | **Flutter Hooks Support** - Optional hooks integration |
| 📦 | **Tree Shakeable** - Monorepo structure, import only what you need |

---

## Packages (Monorepo)

This project follows the **HyperRender architecture** - split into separate packages for zero unnecessary dependencies:

| Package | Description | Dependencies |
|---------|-------------|--------------|
| [`flutter_debounce_throttle_core`](packages/flutter_debounce_throttle_core) | Pure Dart core. **No Flutter deps.** Works on Server/CLI. | `meta` only |
| [`flutter_debounce_throttle`](packages/flutter_debounce_throttle) | Flutter widgets + mixin | `flutter`, `core` |
| [`flutter_debounce_throttle_hooks`](packages/flutter_debounce_throttle_hooks) | Flutter Hooks integration | `flutter_hooks`, `flutter` |

### Choose Your Package

```
Using Flutter?
     │
     ├── YES ──► Using flutter_hooks?
     │               │
     │               ├── YES ──► flutter_debounce_throttle_hooks
     │               │
     │               └── NO ───► flutter_debounce_throttle
     │
     └── NO ───► flutter_debounce_throttle_core (Pure Dart - Server, CLI)
```

---

## Why This Package?

| Problem | Solution |
|---------|----------|
| Double button clicks | `ThrottledInkWell` blocks for duration |
| Search API spam | `DebouncedQueryBuilder` with loading state |
| Race conditions | `ConcurrentAsyncThrottler` with 4 modes |
| Memory leaks | Auto-dispose with StatefulWidget lifecycle |
| Server compatibility | Pure Dart core - works on servers |
| State management | `EventLimiterMixin` for any controller |

**New in v1.1.0:** RateLimiter (Token Bucket), Duration/Callback extensions, Debouncer leading/trailing edge, BatchThrottler maxBatchSize, ConcurrentAsyncThrottler maxQueueSize. See [Migration Guide](MIGRATION_GUIDE.md) and [Server Demo](example/server_demo/)

---

## Features

- **Throttle**: Execute immediately, block subsequent calls for duration
- **Debounce**: Delay execution until pause in calls + **leading/trailing edge** (v1.1.0)
- **Async Support**: Handle async operations with cancellation
- **Concurrency Control**: 4 modes - drop, enqueue, replace, keepLatest
- **Rate Limiter**: Token Bucket algorithm for burst-capable rate limiting (v1.1.0)
- **High Frequency**: Optimized for scroll/mouse events (60fps)
- **Batch Operations**: Group multiple calls into single execution + **maxBatchSize** (v1.1.0)
- **Queue Control**: `maxQueueSize` with overflow strategies for enqueue mode (v1.1.0)
- **Duration Extensions**: `300.ms`, `2.seconds`, `5.minutes` (v1.1.0)
- **Callback Extensions**: `.debounced()`, `.throttled()` on functions (v1.1.0)
- **Stream Listeners**: Safe stream subscriptions with auto-cancel
- **Flutter Hooks**: Full hooks integration
- **State Management Mixin**: Works with Provider, GetX, Bloc, etc.
- **Pure Dart Core**: Server-side compatible

---

## Installation

### Flutter App (No Hooks)
```yaml
dependencies:
  flutter_debounce_throttle: ^1.1.0
```

### Flutter App with Hooks
```yaml
dependencies:
  flutter_debounce_throttle_hooks: ^1.1.0
  flutter_hooks: ^0.21.0
```

### Pure Dart (Server, CLI)
```yaml
dependencies:
  flutter_debounce_throttle_core: ^1.1.0
```

### Imports

```dart
// Flutter widgets + mixin
import 'package:flutter_debounce_throttle/flutter_debounce_throttle.dart';

// Flutter Hooks
import 'package:flutter_debounce_throttle_hooks/flutter_debounce_throttle_hooks.dart';

// Pure Dart (Server/CLI)
import 'package:flutter_debounce_throttle_core/flutter_debounce_throttle_core.dart';
```

---

## Quick Start

### Button Anti-Spam (Throttle)

```dart
ThrottledInkWell(
  duration: Duration(milliseconds: 500),
  onTap: () => submitForm(),
  child: Text('Submit'),
)
```

### Search Input (Debounce)

```dart
DebouncedQueryBuilder<List<User>>(
  duration: Duration(milliseconds: 300),
  onQuery: (text) async => await searchApi(text),
  onResult: (results) => setState(() => _results = results),
  builder: (context, search, isLoading) => TextField(
    onChanged: search,
    decoration: InputDecoration(
      suffixIcon: isLoading
        ? CircularProgressIndicator()
        : Icon(Icons.search),
    ),
  ),
)
```

### Scroll Optimization (High Frequency)

```dart
final throttler = HighFrequencyThrottler(
  duration: Duration(milliseconds: 16), // ~60fps
);

NotificationListener<ScrollNotification>(
  onNotification: (notification) {
    throttler.call(() => updateParallax(notification.metrics.pixels));
    return false;
  },
  child: ListView(...),
)
```

---

## Core Concepts

### Throttle vs Debounce

```
Throttle: ─●───────●───────●───────  (execute first, block rest)
Debounce: ─────────────────●────────  (wait for pause, execute last)
```

| Use Case | Throttle | Debounce |
|----------|----------|----------|
| Button clicks | ✅ | |
| Scroll events | ✅ | |
| Search input | | ✅ |
| Form validation | | ✅ |
| Window resize | | ✅ |
| API rate limiting | ✅ | |

---

## Extensions (v1.1.0)

### Duration Extensions

Create Duration objects with convenient syntax:

```dart
// Before
final delay = Duration(milliseconds: 300);

// After (v1.1.0)
final delay = 300.ms;
```

| Extension | Equivalent |
|-----------|------------|
| `300.ms` | `Duration(milliseconds: 300)` |
| `2.seconds` | `Duration(seconds: 2)` |
| `5.minutes` | `Duration(minutes: 5)` |
| `1.hours` | `Duration(hours: 1)` |

**Example usage:**

```dart
final debouncer = Debouncer(duration: 300.ms);
final throttler = Throttler(duration: 500.ms);

await Future.delayed(2.seconds);
```

### Callback Extensions

Create debounced/throttled callbacks from any function:

```dart
// Before
final debouncer = Debouncer(duration: Duration(milliseconds: 300));
void handleSearch() => debouncer.call(() => search());

// After (v1.1.0)
final search = () => api.search();
final debouncedSearch = search.debounced(300.ms);
final throttledSearch = search.throttled(500.ms);

// Use directly
debouncedSearch();
throttledSearch();
```

> **Note:** Each call to `.debounced()` or `.throttled()` creates a new internal limiter instance. For repeated use in widgets, prefer creating a `Debouncer` or `Throttler` instance directly.

---

## API Reference

### Basic Limiters

#### Throttler

```dart
final throttler = Throttler(duration: Duration(milliseconds: 500));

// Execute immediately, block for 500ms
throttler.call(() => print('Executed!'));
throttler.call(() => print('Blocked!'));

// Wrap as VoidCallback
button.onPressed = throttler.wrap(() => submit());

// Cleanup
throttler.dispose();
```

#### Debouncer

```dart
final debouncer = Debouncer(duration: Duration(milliseconds: 300));

// Delays execution until 300ms pause
debouncer.call(() => search(query));
debouncer.call(() => search(query)); // Resets timer
debouncer.call(() => search(query)); // Resets timer
// Only last call executes after 300ms

// Force immediate execution
debouncer.flush();

// Cancel pending
debouncer.cancel();

// Cleanup
debouncer.dispose();
```

**v1.1.0: Leading/Trailing Edge (like lodash):**

```dart
// Default: trailing edge only (standard debounce)
final debouncer = Debouncer(
  duration: Duration(milliseconds: 300),
  trailing: true,  // Execute after pause (default)
);

// Leading edge: execute immediately on first call
final buttonDebouncer = Debouncer(
  duration: Duration(milliseconds: 300),
  leading: true,   // Execute immediately
  trailing: false, // Don't execute after pause
);

// Both edges (like lodash _.debounce with leading & trailing)
final hybridDebouncer = Debouncer(
  duration: Duration(milliseconds: 300),
  leading: true,   // Execute immediately on first call
  trailing: true,  // Also execute after pause if new calls came
);
```

| Mode | First Call | During Debounce | After Pause |
|------|-----------|-----------------|-------------|
| `trailing: true` (default) | Waits | Resets timer | Executes |
| `leading: true` | Executes | Blocked | - |
| `leading + trailing` | Executes | Resets timer | Executes (if new calls) |

### Async Limiters

#### AsyncDebouncer

```dart
final debouncer = AsyncDebouncer(duration: Duration(milliseconds: 300));

// Callable class pattern - can be called like a function
final result = await debouncer(() async {
  return await api.search(query);
});

// Or use .call() explicitly
final result = await debouncer.call(() async {
  return await api.search(query);
});

// result is null if cancelled
if (result != null) {
  updateUI(result);
}
```

#### AsyncThrottler

```dart
final throttler = AsyncThrottler(maxDuration: Duration(seconds: 5));

// Lock until async operation completes (or timeout)
final result = await throttler.call(() async {
  return await api.submit(data);
});

// Check if currently locked
if (throttler.isLocked) {
  showLoading();
}
```

> **Warning:** Always set `maxDuration` to prevent UI lockup if async operation hangs. If API call never returns, button stays locked forever without timeout!

### Advanced Limiters

#### ConcurrentAsyncThrottler

Handle concurrent async operations with 4 modes:

```dart
final throttler = ConcurrentAsyncThrottler(
  mode: ConcurrencyMode.replace, // drop | enqueue | replace | keepLatest
  maxDuration: Duration(seconds: 10),
);

throttler.call(() async => await fetchData());
```

| Mode | Behavior |
|------|----------|
| `drop` | Ignore new calls while busy |
| `enqueue` | Queue and execute in order |
| `replace` | Cancel current, start new |
| `keepLatest` | Keep only latest pending |

**v1.1.0: maxQueueSize with overflow strategies (enqueue mode):**

```dart
final chatSender = ConcurrentAsyncThrottler(
  mode: ConcurrencyMode.enqueue,
  maxDuration: Duration(seconds: 30),
  maxQueueSize: 10,  // Limit queue to 10 items
  queueOverflowStrategy: QueueOverflowStrategy.dropOldest,
);

// QueueOverflowStrategy options:
// - dropNewest: Reject new calls when queue is full (default)
// - dropOldest: Remove oldest queued call to make room

// Check queue status
print('Queue size: ${chatSender.queueSize}');
print('Pending: ${chatSender.pendingCount}');
```

#### HighFrequencyThrottler

Optimized for high-frequency events (scroll, mouse move):

```dart
final throttler = HighFrequencyThrottler(
  duration: Duration(milliseconds: 16), // 60fps
);

// Uses DateTime comparison instead of Timer
scrollController.addListener(() {
  throttler.call(() => updateUI());
});
```

#### BatchThrottler

Batch multiple operations into single execution:

```dart
final batcher = BatchThrottler(
  duration: Duration(milliseconds: 100),
  onBatchExecute: (actions) {
    for (final action in actions) {
      action();
    }
  },
);

// Callable class pattern
batcher(() => save('item1'));
batcher(() => save('item2'));
batcher(() => save('item3'));
// After 100ms: executes all 3 actions in batch
```

**v1.1.0: maxBatchSize with overflow strategies:**

```dart
final batcher = BatchThrottler(
  duration: Duration(milliseconds: 500),
  maxBatchSize: 5, // Limit batch to 5 items
  overflowStrategy: BatchOverflowStrategy.dropOldest,
  onBatchExecute: (actions) { /* ... */ },
);

// BatchOverflowStrategy options:
// - dropOldest: Remove oldest item when full
// - dropNewest: Reject new item when full
// - flushAndAdd: Flush immediately, then add new item
```

#### RateLimiter (v1.1.0)

Token Bucket algorithm for burst-capable rate limiting:

```dart
final limiter = RateLimiter(
  maxTokens: 10,           // Burst capacity
  refillRate: 2,           // 2 tokens per interval
  refillInterval: Duration(seconds: 1),
  debugMode: true,
  name: 'api-limiter',
);

// Check before calling
if (limiter.tryAcquire()) {
  await api.call();
} else {
  showRateLimitError();
}

// Or use with callback (only executes if token available)
final executed = limiter.call(() => api.submit());

// Async version
final result = await limiter.callAsync(() async => await api.getData());

// Check status
print('Available: ${limiter.availableTokens}');
print('Time until next: ${limiter.timeUntilNextToken}');

limiter.dispose();
```

**Server-side rate limiting:**

```dart
final apiLimiter = RateLimiter(
  maxTokens: 100,          // Allow burst of 100 requests
  refillRate: 10,          // Refill 10 tokens per second
  refillInterval: Duration(seconds: 1),
  name: 'api-rate-limiter',
);

Future<Response> handleRequest(Request request) async {
  if (!apiLimiter.tryAcquire()) {
    return Response.tooManyRequests(
      retryAfter: apiLimiter.timeUntilNextToken,
    );
  }
  return await processRequest(request);
}
```

---

## Flutter Widgets

### ThrottledBuilder

Universal throttle wrapper:

```dart
ThrottledBuilder(
  duration: Duration(milliseconds: 500),
  builder: (context, throttle) => ElevatedButton(
    onPressed: throttle(() => submit()),
    child: Text('Submit'),
  ),
)
```

### ThrottledInkWell

Material button with built-in throttle:

```dart
ThrottledInkWell(
  duration: Duration(milliseconds: 500),
  onTap: () => navigate(),
  child: ListTile(title: Text('Go to Details')),
)
```

### DebouncedBuilder

Debounce wrapper for any widget:

```dart
DebouncedBuilder(
  duration: Duration(milliseconds: 300),
  builder: (context, debounce) => TextField(
    onChanged: (text) => debounce(() => validate(text))?.call(),
  ),
)
```

### DebouncedQueryBuilder

Async debounce with loading state (renamed from AsyncDebouncedCallbackBuilder):

```dart
DebouncedQueryBuilder<List<User>>(
  duration: Duration(milliseconds: 300),
  onQuery: (query) async => await searchUsers(query),
  onResult: (users) => setState(() => _users = users),
  onError: (e) => showError(e),
  builder: (context, search, isLoading) => Column(
    children: [
      TextField(onChanged: search),
      if (isLoading) LinearProgressIndicator(),
    ],
  ),
)
```

### ConcurrentAsyncThrottledBuilder

Handle concurrent operations in widgets:

```dart
ConcurrentAsyncThrottledBuilder(
  mode: ConcurrencyMode.replace,
  builder: (context, throttle, isLoading) => ElevatedButton(
    onPressed: isLoading ? null : () => throttle(() async {
      await uploadFile();
    }),
    child: isLoading ? CircularProgressIndicator() : Text('Upload'),
  ),
)
```

---

## Stream Listeners

### StreamSafeListener

Auto-cancel stream subscription on dispose:

```dart
StreamSafeListener<int>(
  stream: counterStream,
  onData: (value) => updateCounter(value),
  onError: (e) => showError(e),
  child: CounterDisplay(),
)
```

### StreamDebounceListener

Debounce stream events:

```dart
StreamDebounceListener<String>(
  stream: searchQueryStream,
  duration: Duration(milliseconds: 300),
  onData: (query) => performSearch(query),
  child: SearchResults(),
)
```

### StreamThrottleListener

Throttle stream events:

```dart
StreamThrottleListener<Offset>(
  stream: mouseMoveStream,
  duration: Duration(milliseconds: 16),
  onData: (position) => updateCursor(position),
  child: Canvas(),
)
```

---

## Text Controllers

### DebouncedTextController

TextField controller with debouncing:

```dart
final controller = DebouncedTextController(
  duration: Duration(milliseconds: 300),
  onChanged: (text) => validate(text),
);

TextField(controller: controller)

// Don't forget to dispose
controller.dispose();
```

### AsyncDebouncedTextController

Async search with loading state:

```dart
final controller = AsyncDebouncedTextController<List<User>>(
  duration: Duration(milliseconds: 300),
  onSearch: (query) async => await api.search(query),
  onResults: (users) => setState(() => _users = users),
  onLoading: (loading) => setState(() => _isLoading = loading),
);

TextField(
  controller: controller,
  decoration: InputDecoration(
    suffixIcon: _isLoading
      ? CircularProgressIndicator()
      : Icon(Icons.search),
  ),
)
```

---

## State Management Mixin

Use with any controller (Provider, GetX, Bloc, etc.):

```dart
class MyController with ChangeNotifier, EventLimiterMixin {
  String query = '';
  List<User> users = [];

  void onSearchChanged(String text) {
    query = text;

    // Debounce by ID - reuses same debouncer
    debounce('search', () async {
      users = await api.search(query);
      notifyListeners();
    });
  }

  void onButtonPressed() {
    // Throttle by ID
    throttle('submit', () async {
      await api.submit();
    });
  }

  @override
  void dispose() {
    cancelAll(); // Clean up all limiters (new API)
    super.dispose();
  }
}
```

> **Important:** Unlike Widgets and Hooks, Mixin does NOT auto-dispose. You MUST call `cancelAll()` in your controller's `dispose()` method to prevent memory leaks!

### Available Methods

```dart
mixin EventLimiterMixin {
  // Sync limiters
  void debounce(String id, VoidCallback action, {Duration? duration});
  void throttle(String id, VoidCallback action, {Duration? duration});

  // Async limiters
  Future<T?> debounceAsync<T>(String id, Future<T> Function() action, {Duration? duration});
  Future<T?> throttleAsync<T>(String id, Future<T> Function() action, {Duration? duration});

  // Control (new v1.0 API)
  void cancel(String id);      // Cancel specific limiter
  void cancelAll();            // Cancel all limiters

  // Status
  bool isLimiterActive(String id);
  int get activeLimitersCount;
}
```

> **Note:** Old method names (`cancelLimiter`, `cancelAllLimiters`) are still supported but deprecated.

### Works With

- **Provider**: `ChangeNotifier`
- **GetX**: `GetxController`
- **Bloc**: `Cubit`, `Bloc`
- **Riverpod**: `Notifier`, `AsyncNotifier`
- **MobX**: Store classes
- **Dart Server**: Any controller class

---

## Flutter Hooks (Optional)

> **Note:** This is an optional feature. Only add `flutter_hooks` if you use the Hooks architecture.

```yaml
dependencies:
  flutter_debounce_throttle: ^1.1.0
  flutter_hooks: ^0.21.0  # Add this only if you need hooks
```

```dart
import 'package:flutter_debounce_throttle/hooks.dart';

class MyWidget extends HookWidget {
  @override
  Widget build(BuildContext context) {
    // Get limiter instances
    final debouncer = useDebouncer(duration: Duration(milliseconds: 300));
    final throttler = useThrottler(duration: Duration(milliseconds: 500));

    // Debounced callback
    final debouncedSearch = useDebouncedCallback<String>(
      (text) => search(text),
      duration: Duration(milliseconds: 300),
    );

    // Throttled callback
    final throttledSubmit = useThrottledCallback(
      () => submit(),
      duration: Duration(milliseconds: 500),
    );

    // Debounced value
    final searchText = useState('');
    final debouncedText = useDebouncedValue(
      searchText.value,
      duration: Duration(milliseconds: 300),
    );

    return Column(
      children: [
        TextField(onChanged: debouncedSearch),
        ElevatedButton(
          onPressed: throttledSubmit,
          child: Text('Submit'),
        ),
      ],
    );
  }
}
```

### Available Hooks

| Hook | Returns | Description |
|------|---------|-------------|
| `useDebouncer` | `Debouncer` | Debouncer instance |
| `useThrottler` | `Throttler` | Throttler instance |
| `useAsyncDebouncer` | `AsyncDebouncer` | Async debouncer |
| `useAsyncThrottler` | `AsyncThrottler` | Async throttler |
| `useDebouncedCallback<T>` | `void Function(T)` | Debounced callback |
| `useThrottledCallback` | `VoidCallback` | Throttled callback |
| `useDebouncedValue<T>` | `T` | Debounced value |
| `useThrottledValue<T>` | `T` | Throttled value |

---

## Global Configuration

Set app-wide defaults:

```dart
void main() {
  DebounceThrottleConfig.init(
    enableDebugLog: kDebugMode,
    logLevel: LogLevel.warning,
    logHandler: (level, message, name, timestamp) {
      // Custom logging implementation
      print('[$level] $message');
    },
  );

  runApp(MyApp());
}
```

### Debug Logging

```dart
// Enable for specific limiter
final debouncer = Debouncer(
  duration: Duration(milliseconds: 300),
  debugMode: true,
  name: 'SearchDebouncer',
);

// Output:
// [SearchDebouncer] call() - scheduling
// [SearchDebouncer] _execute() - executing callback
```

---

## Pure Dart (Server)

Use on Dart servers without Flutter dependency:

```dart
import 'package:flutter_debounce_throttle_core/flutter_debounce_throttle_core.dart';

// Example 1: Log batching service
class LogBatchingService {
  final _debouncer = Debouncer(
    duration: const Duration(seconds: 1),
    debugMode: true,
    name: 'log-batcher',
  );

  final List<String> _pendingLogs = [];

  void log(String message) {
    _pendingLogs.add(message);

    // Batch logs and write to DB after 1s pause
    _debouncer(() {
      writeToDB(_pendingLogs);
      _pendingLogs.clear();
    });
  }
}

// Example 2: API rate limiter
class ApiRateLimiter {
  final _throttler = Throttler(
    duration: const Duration(seconds: 2),
    name: 'api-limiter',
  );

  Future<Response> callExternalApi(String endpoint) {
    return _throttler(() async {
      return await http.get(endpoint);
    }) ?? Response.tooManyRequests();
  }
}
```

See [Server Demo](example/server_demo/server_example.dart) for complete working examples.

---

## Comparison

| Feature | flutter_debounce_throttle | easy_debounce | rxdart |
|---------|---------------------------|---------------|--------|
| Throttle | ✅ | ✅ | ✅ |
| Debounce | ✅ | ✅ | ✅ |
| Async Support | ✅ | ❌ | ✅ |
| Concurrency Modes | ✅ 4 modes | ❌ | ❌ |
| Auto Dispose | ✅ | ❌ | ❌ |
| Flutter Widgets | ✅ | ❌ | ❌ |
| Hooks | ✅ | ❌ | ❌ |
| State Management | ✅ Mixin | ❌ | ❌ |
| Stream Listeners | ✅ | ❌ | ✅ |
| Server Compatible | ✅ | ✅ | ❌ |
| Type Safe | ✅ | ❌ | ✅ |

---

## When to Use This Package

### Use flutter_debounce_throttle when:

- You need **async operations** with loading states (API calls, database queries)
- You want **concurrency control** (cancel old request when new one arrives)
- You use **State Management** and need limiter integration (Provider, GetX, Bloc)
- You need **Flutter Widgets** with built-in throttle/debounce
- You want **type-safe** results from async operations
- You need **server-side Dart** support

### Use simpler alternatives (like easy_debounce) when:

- You only need basic debounce for a single function
- You want minimal package size
- You don't need async support or loading states

---

## Best Practices

### DO

```dart
// ✅ Dispose in StatefulWidget
@override
void dispose() {
  _throttler.dispose();
  super.dispose();
}

// ✅ Use wrap() for VoidCallback
onPressed: throttler.wrap(() => submit())

// ✅ Use ID-based limiters in controllers
debounce('search', () => performSearch());

// ✅ Always set maxDuration for async throttlers
final throttler = AsyncThrottler(maxDuration: Duration(seconds: 10));

// ✅ Handle errors in async callbacks
DebouncedQueryBuilder(
  onQuery: (text) async => await api.search(text),
  onError: (e) => showErrorSnackbar(e), // Don't forget this!
  // ...
)

// ✅ Use unique IDs for different operations in Mixin
debounce('search', () => performSearch());
debounce('validate', () => validateForm()); // Different ID!
```

### DON'T

```dart
// ❌ Create limiters in build method
Widget build(context) {
  final throttler = Throttler(...); // Creates new every build!
}

// ❌ Forget to dispose
// Memory leak!

// ❌ Use same ID for different operations
debounce('action', () => search());
debounce('action', () => validate()); // Conflicts!

// ❌ Use drop mode without loading indicator
// User won't know why button "doesn't work"
ConcurrentAsyncThrottler(mode: ConcurrencyMode.drop) // Show loading!

// ❌ Skip maxDuration on async throttlers
AsyncThrottler() // If API hangs, UI locked forever!
```

### Recommended Timeout Values

| Use Case | Recommended `maxDuration` |
|----------|---------------------------|
| Button click API call | 10-30 seconds |
| Form submission | 30-60 seconds |
| File upload | 5-10 minutes |
| Background sync | No timeout (handle separately) |

---

## Best Practices by Use Case

### Button Anti-Spam (Prevent Double Clicks)

```dart
// ✅ BEST: ThrottledInkWell for one-time setup
ThrottledInkWell(
  duration: 500.ms,
  onTap: () => submitOrder(),
  child: Text('Submit'),
)

// ✅ GOOD: Throttler with leading edge (immediate feedback)
final _submitThrottler = Throttler(duration: 500.ms);

ElevatedButton(
  onPressed: _submitThrottler.wrap(() => submitOrder()),
  child: Text('Submit'),
)

// ❌ AVOID: AsyncThrottler without loading indicator
// User can't see why button "doesn't work"
```

### Search Input (Wait for Typing to Stop)

```dart
// ✅ BEST: DebouncedQueryBuilder with loading state
DebouncedQueryBuilder<List<User>>(
  duration: 300.ms,
  onQuery: (text) async => await api.search(text),
  onResult: (users) => setState(() => _users = users),
  onError: (e) => showError(e),
  builder: (context, search, isLoading) => TextField(
    onChanged: search,
    decoration: InputDecoration(
      suffixIcon: isLoading ? CircularProgressIndicator() : Icon(Icons.search),
    ),
  ),
)

// ✅ GOOD: Debouncer for simple cases
final _searchDebouncer = Debouncer(duration: 300.ms);

TextField(
  onChanged: (text) => _searchDebouncer.call(() => search(text)),
)

// ⚠️ TIP: Use ConcurrencyMode.replace to cancel old searches
final _searchController = ConcurrentAsyncThrottler(
  mode: ConcurrencyMode.replace,
  maxDuration: 10.seconds,
);
```

### Form Validation (Validate After Input Stops)

```dart
// ✅ BEST: Debouncer with trailing edge (default)
final _validator = Debouncer(duration: 300.ms);

TextFormField(
  onChanged: (value) => _validator.call(() => validateEmail(value)),
)

// ✅ ALTERNATIVE: Leading + Trailing for immediate + final validation
final _validator = Debouncer(
  duration: 300.ms,
  leading: true,   // Immediate feedback
  trailing: true,  // Final validation after pause
);
```

### API Rate Limiting (Server-side)

```dart
// ✅ BEST: RateLimiter for burst-capable rate limiting
final _apiLimiter = RateLimiter(
  maxTokens: 100,        // Allow burst of 100
  refillRate: 10,        // 10 requests/second sustained
  refillInterval: 1.seconds,
);

Future<Response> handleRequest(Request req) async {
  if (!_apiLimiter.tryAcquire()) {
    return Response.tooManyRequests(
      retryAfter: _apiLimiter.timeUntilNextToken,
    );
  }
  return await processRequest(req);
}

// ✅ GOOD: Simple Throttler for fixed-rate limiting
final _throttler = Throttler(duration: 100.ms); // 10 req/s max
```

### Scroll/Resize Events (High Frequency)

```dart
// ✅ BEST: HighFrequencyThrottler for 60fps
final _scrollThrottler = HighFrequencyThrottler(
  duration: 16.ms, // ~60fps
);

NotificationListener<ScrollNotification>(
  onNotification: (notification) {
    _scrollThrottler.call(() => updateParallax(notification.metrics.pixels));
    return false;
  },
  child: ListView(...),
)

// ❌ AVOID: Regular Throttler uses Timer (less precise)
```

### Chat Messages (Sequential Order)

```dart
// ✅ BEST: ConcurrentAsyncThrottler with enqueue mode
final _chatSender = ConcurrentAsyncThrottler(
  mode: ConcurrencyMode.enqueue,  // Preserve order
  maxDuration: 30.seconds,
  maxQueueSize: 20,               // Prevent memory buildup
  queueOverflowStrategy: QueueOverflowStrategy.dropOldest,
);

void sendMessage(String text) {
  _chatSender.call(() async => await api.sendMessage(text));
}
```

### Auto-Save (Save Latest Version)

```dart
// ✅ BEST: ConcurrentAsyncThrottler with keepLatest mode
final _autoSaver = ConcurrentAsyncThrottler(
  mode: ConcurrencyMode.keepLatest,  // Only save final version
  maxDuration: 30.seconds,
);

void onDocumentChanged(Document doc) {
  _autoSaver.call(() async => await api.saveDraft(doc));
}

// Result: Multiple rapid edits → Only first + last saved
```

### Analytics Batching (Group Events)

```dart
// ✅ BEST: BatchThrottler with size limit
final _analyticsBatcher = BatchThrottler(
  duration: 2.seconds,
  maxBatchSize: 50,  // Prevent memory issues
  overflowStrategy: BatchOverflowStrategy.flushAndAdd,
  onBatchExecute: (actions) async {
    final events = actions.map((a) => a()).toList();
    await analytics.trackBatch(events);
  },
);

void trackEvent(String name) {
  _analyticsBatcher(() => AnalyticsEvent(name));
}
```

### Quick Reference: Which Limiter to Use?

| Use Case | Recommended Limiter | Mode/Options |
|----------|---------------------|--------------|
| Button anti-spam | `Throttler` / `ThrottledInkWell` | - |
| Search input | `Debouncer` + `ConcurrentAsyncThrottler` | `replace` mode |
| Form validation | `Debouncer` | `leading + trailing` |
| API rate limiting | `RateLimiter` | Token bucket |
| Scroll/resize | `HighFrequencyThrottler` | 16ms for 60fps |
| Chat messages | `ConcurrentAsyncThrottler` | `enqueue` mode |
| Auto-save | `ConcurrentAsyncThrottler` | `keepLatest` mode |
| Analytics | `BatchThrottler` | `maxBatchSize` |

---

## Migration

Upgrading from another library or older version? See our comprehensive [Migration Guide](MIGRATION_GUIDE.md) with examples for:
- Migrating from `easy_debounce`
- Migrating from manual Timer implementations
- Migrating from `rxdart` transforms
- Upgrading to v1.0 new API

---

## Resources

- **[Migration Guide](MIGRATION_GUIDE.md)** - Migrate from easy_debounce, Timer, rxdart
- **[Server Demo](example/server_demo/server_example.dart)** - Pure Dart Core examples
- **[Example App](example/)** - 5 interactive demos
- **[API Documentation](https://pub.dev/documentation/flutter_debounce_throttle/latest/)** - Complete API reference

---

## License

MIT License - see [LICENSE](LICENSE)

---

## Contributing

Contributions welcome! Please read our [contributing guidelines](CONTRIBUTING.md).

---

## Support

- **Issues**: [GitHub Issues](https://github.com/brewkits/flutter_debounce_throttle/issues)
- **Email**: datacenter111@gmail.com

---

Made with ❤️ by **Nguyễn Tuấn Việt** at **[Brewkits](https://github.com/brewkits)**
