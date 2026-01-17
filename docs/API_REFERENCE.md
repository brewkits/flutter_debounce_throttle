# API Reference

Complete API documentation for flutter_debounce_throttle v1.1.0.

---

## Table of Contents

- [Basic Limiters](#basic-limiters)
  - [Throttler](#throttler)
  - [Debouncer](#debouncer)
- [Async Limiters](#async-limiters)
  - [AsyncDebouncer](#asyncdebouncer)
  - [AsyncThrottler](#asyncthrottler)
- [Advanced Limiters](#advanced-limiters)
  - [ConcurrentAsyncThrottler](#concurrentasyncthrottler)
  - [HighFrequencyThrottler](#highfrequencythrottler)
  - [BatchThrottler](#batchthrottler)
  - [RateLimiter](#ratelimiter)
- [Flutter Widgets](#flutter-widgets)
- [Flutter Hooks](#flutter-hooks)
- [Extensions](#extensions)
- [State Management Mixin](#state-management-mixin)

---

## Basic Limiters

### Throttler

Execute immediately, block subsequent calls for duration.

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

### Debouncer

Delay execution until pause in calls.

```dart
final debouncer = Debouncer(duration: Duration(milliseconds: 300));

// Delays execution until 300ms pause
debouncer.call(() => search(query));
debouncer.call(() => search(query)); // Resets timer
// Only last call executes after 300ms

// Force immediate execution
debouncer.flush();

// Cancel pending
debouncer.cancel();

// Cleanup
debouncer.dispose();
```

#### Leading/Trailing Edge (v1.1.0)

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

// Both edges (like lodash _.debounce)
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

---

## Async Limiters

### AsyncDebouncer

```dart
final debouncer = AsyncDebouncer(duration: Duration(milliseconds: 300));

// Callable class pattern
final result = await debouncer(() async {
  return await api.search(query);
});

// result is null if cancelled
if (result != null) {
  updateUI(result);
}
```

#### DebounceResult (v1.1.0)

Use `callWithResult()` when your async operation can return null:

```dart
// Problem: call() returns T? - can't distinguish "cancelled" from "result is null"
final user = await debouncer(() async => await api.findUser(id));
if (user == null) {
  // Cancelled? Or user not found?
}

// Solution: callWithResult() returns DebounceResult<T>
final result = await debouncer.callWithResult(() async => await api.findUser(id));

if (result.isCancelled) {
  return; // Cancelled by newer call
}

// result.value may be null (user not found), but we know it wasn't cancelled
showUser(result.value);
```

**DebounceResult properties:**
- `isCancelled` - true if operation was cancelled
- `isSuccess` - true if operation completed (not cancelled)
- `value` - the result value (may be null even if successful)

### AsyncThrottler

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

> **Warning:** Always set `maxDuration` to prevent UI lockup if async operation hangs.

---

## Advanced Limiters

### ConcurrentAsyncThrottler

Handle concurrent async operations with 4 modes:

```dart
final throttler = ConcurrentAsyncThrottler(
  mode: ConcurrencyMode.replace,
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

#### maxQueueSize (v1.1.0)

```dart
final chatSender = ConcurrentAsyncThrottler(
  mode: ConcurrencyMode.enqueue,
  maxDuration: Duration(seconds: 30),
  maxQueueSize: 10,
  queueOverflowStrategy: QueueOverflowStrategy.dropOldest,
);

// QueueOverflowStrategy options:
// - dropNewest: Reject new calls when queue is full (default)
// - dropOldest: Remove oldest queued call to make room
```

### HighFrequencyThrottler

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

### BatchThrottler

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

batcher(() => save('item1'));
batcher(() => save('item2'));
batcher(() => save('item3'));
// After 100ms: executes all 3 actions in batch
```

#### maxBatchSize (v1.1.0)

```dart
final batcher = BatchThrottler(
  duration: Duration(milliseconds: 500),
  maxBatchSize: 5,
  overflowStrategy: BatchOverflowStrategy.dropOldest,
  onBatchExecute: (actions) { /* ... */ },
);

// BatchOverflowStrategy options:
// - dropOldest: Remove oldest item when full
// - dropNewest: Reject new item when full
// - flushAndAdd: Flush immediately, then add new item
```

### RateLimiter

Token Bucket algorithm for burst-capable rate limiting:

```dart
final limiter = RateLimiter(
  maxTokens: 10,           // Burst capacity
  refillRate: 2,           // 2 tokens per interval
  refillInterval: Duration(seconds: 1),
);

// Check before calling
if (limiter.tryAcquire()) {
  await api.call();
} else {
  showRateLimitError();
}

// Or use with callback
final executed = limiter.call(() => api.submit());

// Async version
final result = await limiter.callAsync(() async => await api.getData());

// Check status
print('Available: ${limiter.availableTokens}');
print('Time until next: ${limiter.timeUntilNextToken}');
```

---

## Flutter Widgets

### ThrottledBuilder

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

```dart
ThrottledInkWell(
  duration: Duration(milliseconds: 500),
  onTap: () => navigate(),
  child: ListTile(title: Text('Go to Details')),
)
```

### DebouncedBuilder

```dart
DebouncedBuilder(
  duration: Duration(milliseconds: 300),
  builder: (context, debounce) => TextField(
    onChanged: (text) => debounce(() => validate(text))?.call(),
  ),
)
```

### DebouncedQueryBuilder

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

### Stream Listeners

```dart
// Auto-cancel on dispose
StreamSafeListener<int>(
  stream: counterStream,
  onData: (value) => updateCounter(value),
  child: CounterDisplay(),
)

// Debounce stream events
StreamDebounceListener<String>(
  stream: searchQueryStream,
  duration: Duration(milliseconds: 300),
  onData: (query) => performSearch(query),
  child: SearchResults(),
)

// Throttle stream events
StreamThrottleListener<Offset>(
  stream: mouseMoveStream,
  duration: Duration(milliseconds: 16),
  onData: (position) => updateCursor(position),
  child: Canvas(),
)
```

### Text Controllers

```dart
// Debounced text controller
final controller = DebouncedTextController(
  duration: Duration(milliseconds: 300),
  onChanged: (text) => validate(text),
);

// Async search controller
final controller = AsyncDebouncedTextController<List<User>>(
  duration: Duration(milliseconds: 300),
  onSearch: (query) async => await api.search(query),
  onResults: (users) => setState(() => _users = users),
  onLoading: (loading) => setState(() => _isLoading = loading),
);
```

---

## Flutter Hooks

```dart
import 'package:flutter_debounce_throttle_hooks/flutter_debounce_throttle_hooks.dart';

class MyWidget extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final debouncer = useDebouncer(duration: Duration(milliseconds: 300));
    final throttler = useThrottler(duration: Duration(milliseconds: 500));

    final debouncedSearch = useDebouncedCallback<String>(
      (text) => search(text),
      duration: Duration(milliseconds: 300),
    );

    final throttledSubmit = useThrottledCallback(
      () => submit(),
      duration: Duration(milliseconds: 500),
    );

    final debouncedText = useDebouncedValue(
      searchText.value,
      duration: Duration(milliseconds: 300),
    );

    return Column(
      children: [
        TextField(onChanged: debouncedSearch),
        ElevatedButton(onPressed: throttledSubmit, child: Text('Submit')),
      ],
    );
  }
}
```

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

## Extensions

### Duration Extensions (v1.1.0)

```dart
300.ms       // Duration(milliseconds: 300)
2.seconds    // Duration(seconds: 2)
5.minutes    // Duration(minutes: 5)
1.hours      // Duration(hours: 1)
```

### Callback Extensions (v1.1.0)

```dart
final search = () => api.search();
final debouncedSearch = search.debounced(300.ms);
final throttledSearch = search.throttled(500.ms);
```

---

## State Management Mixin

Works with Provider, GetX, Bloc, Riverpod, MobX, etc.

```dart
class MyController with ChangeNotifier, EventLimiterMixin {
  void onSearchChanged(String text) {
    debounce('search', () async {
      users = await api.search(text);
      notifyListeners();
    });
  }

  void onButtonPressed() {
    throttle('submit', () async {
      await api.submit();
    });
  }

  @override
  void dispose() {
    cancelAll(); // Clean up all limiters
    super.dispose();
  }
}
```

### Available Methods

```dart
mixin EventLimiterMixin {
  void debounce(String id, VoidCallback action, {Duration? duration});
  void throttle(String id, VoidCallback action, {Duration? duration});
  Future<T?> debounceAsync<T>(String id, Future<T> Function() action);
  Future<T?> throttleAsync<T>(String id, Future<T> Function() action);
  void cancel(String id);
  void cancelAll();
  bool isLimiterActive(String id);
  int get activeLimitersCount;
}
```

> **Important:** Mixin does NOT auto-dispose. Call `cancelAll()` in your controller's `dispose()` method.

---

## Global Configuration

```dart
void main() {
  DebounceThrottleConfig.init(
    enableDebugLog: kDebugMode,
    logLevel: LogLevel.warning,
    logHandler: (level, message, name, timestamp) {
      print('[$level] $message');
    },
  );
  runApp(MyApp());
}
```

### Debug Logging

```dart
final debouncer = Debouncer(
  duration: Duration(milliseconds: 300),
  debugMode: true,
  name: 'SearchDebouncer',
);

// Output:
// [SearchDebouncer] call() - scheduling
// [SearchDebouncer] _execute() - executing callback
```
