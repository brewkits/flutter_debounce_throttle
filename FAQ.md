# Frequently Asked Questions (FAQ)

## Table of Contents

- [Can you cancel a running Future in Dart?](#can-you-cancel-a-running-future-in-dart)
- [Why not just use a Semaphore?](#why-not-just-use-a-semaphore)
- [How does Logical Cancellation work?](#how-does-logical-cancellation-work)
- [What are Concurrency Modes?](#what-are-concurrency-modes)
- [How does this prevent "setState() after dispose"?](#how-does-this-prevent-setstate-after-dispose)
- [Performance: Does the old Future keep running?](#performance-does-the-old-future-keep-running)

---

## Can you cancel a running Future in Dart?

**Short answer:** No, you can't forcefully "kill" a Future once it has started executing in Dart.

**How this library handles it:**

This library uses **Logical Cancellation** instead of physical cancellation. Here's how:

### 1. Internal Version Tracking (AsyncDebouncer)

Every async call gets a unique internal ID:

```dart
final debouncer = AsyncDebouncer(duration: 300.ms);

// Call 1 - ID: 1
debouncer.call(() async => await api.search('a'));

// Call 2 - ID: 2 (Call 1 is now obsolete)
debouncer.call(() async => await api.search('ab'));

// When Call 1 finishes, library checks:
// if (currentID != 1) return null;  // Discarded!
```

**Result:** Call 1 completes but returns `null`. Your UI only receives data from Call 2.

### 2. Concurrency Modes (Replace Strategy)

In `ConcurrentAsyncThrottler` with `mode: replace`:

```dart
final controller = ConcurrentAsyncThrottler(mode: ConcurrencyMode.replace);

// Task 1 starts running
controller(() async {
  await Future.delayed(Duration(seconds: 2));
  return 'Old Data';
});

// Task 2 immediately marks Task 1 as obsolete
controller(() async {
  await Future.delayed(Duration(seconds: 1));
  return 'New Data';
});

// Task 1 completes later, but UI never sees 'Old Data'
```

**Result:** Task 1 runs to completion in the background, but its result is discarded. The caller immediately gets a "cancelled" status.

### 3. Lifecycle Safety (Flutter)

Even if a Future completes, the library checks Widget lifecycle:

```dart
class _MyWidgetState extends State<MyWidget> {
  final debouncer = AsyncDebouncer(duration: 300.ms);

  void search() {
    debouncer.call(() async {
      final results = await api.search(query);
      // ⚠️ Widget might be disposed by now
      setState(() => _results = results);  // Would crash!
    });
  }

  @override
  void dispose() {
    debouncer.dispose();  // Aborts all pending callbacks
    super.dispose();
  }
}
```

**Result:** If the widget is disposed while the Future is running, the callback is never executed. This eliminates the infamous **"setState() called after dispose()" crash**.

---

## Why not just use a Semaphore?

**Short answer:** A Semaphore controls **how many** tasks run. This library controls **when** and **which** tasks run.

### Semaphore: Mutual Exclusion Only

A semaphore ensures only N tasks run concurrently:

```dart
final semaphore = Semaphore(1);  // Only 1 at a time

await semaphore.acquire();
try {
  await processTask();
} finally {
  semaphore.release();
}
```

**Problem:** This doesn't handle:
- ⏱️ **Timing** - "Wait 300ms after the last event"
- 🔄 **Replacement** - "Cancel old task when new one arrives"
- 📊 **Batching** - "Group 100 events → 1 operation"

### This Library: Time-Aware Rate Limiting

#### 1. Timing vs Mutual Exclusion

**Debounce example (CLI stream processing):**

```dart
// Semaphore approach (doesn't work for debounce)
final semaphore = Semaphore(1);
stdin.listen((event) async {
  await semaphore.acquire();
  // ❌ How do you wait 300ms after the LAST event?
  processEvent(event);
  semaphore.release();
});

// This library (clean & correct)
final debouncer = Debouncer(duration: 300.ms);
stdin.listen((event) {
  debouncer(() => processEvent(event));  // ✅ Auto-waits 300ms after last
});
```

#### 2. Advanced Async Strategies

**Replace Mode (ignore stale data):**

```dart
// With semaphore (waits for old task to finish)
await semaphore.acquire();
final data = await fetchData();  // Takes 2 seconds
semaphore.release();
// ❌ New request must wait, even if old data is obsolete

// This library (immediate replacement)
final controller = ConcurrentAsyncThrottler(mode: ConcurrencyMode.replace);
controller(() async => await fetchData());  // ✅ Old task ignored
```

**KeepLatest Mode (process first + last only):**

```dart
// High-frequency data stream
// Want: Process first item, skip middle items, process last item

// With semaphore: Processes EVERYTHING sequentially ❌
stream.listen((data) async {
  await semaphore.acquire();
  await process(data);
  semaphore.release();
});

// This library: Smart queue management ✅
final controller = ConcurrentAsyncThrottler(mode: ConcurrencyMode.keepLatest);
stream.listen((data) {
  controller(() async => await process(data));
  // First: Executes immediately
  // Middle: Dropped
  // Last: Queued and executes after first completes
});
```

#### 3. Resource Safety (Memory Leaks)

**Manual Timer + Semaphore (error-prone):**

```dart
Timer? _timer;
final semaphore = Semaphore(1);

void debounce(VoidCallback action) {
  _timer?.cancel();  // ⚠️ Easy to forget
  _timer = Timer(Duration(milliseconds: 300), () async {
    await semaphore.acquire();
    try {
      action();
    } finally {
      semaphore.release();  // ⚠️ Must be in finally
    }
  });
}

// If you forget to cancel _timer on dispose → MEMORY LEAK
```

**This library (automatic cleanup):**

```dart
final debouncer = Debouncer(duration: 300.ms);
debouncer(() => action());  // ✅ Auto-manages Timer

// Cleanup is automatic
debouncer.dispose();  // All timers and resources released
```

### Summary: Semaphore vs This Library

| Feature | Semaphore | This Library |
|---------|-----------|--------------|
| **Concurrency Control** | ✅ How many | ✅ How many + **When** + **Which** |
| **Time-based Limiting** | ❌ | ✅ Debounce, Throttle |
| **Stale Data Handling** | ❌ Waits for old | ✅ Replace mode |
| **Batching** | ❌ Manual | ✅ Built-in |
| **Resource Cleanup** | ⚠️ Manual | ✅ Automatic |
| **Widget Lifecycle** | ❌ | ✅ Auto-dispose |
| **Lines of Code** | ~20-50 lines | **1 line** |

**You can definitely build this manually with semaphores + timers + try/finally blocks**, but this library provides:

- ✅ **140+ tests** covering edge cases
- ✅ **Type-safe API** with generics
- ✅ **Zero boilerplate** - focus on business logic
- ✅ **Production-tested** - used in real apps

---

## How does Logical Cancellation work?

Under the hood, the library uses **Version Tracking** to ensure data integrity:

### AsyncDebouncer Implementation (Simplified)

```dart
class AsyncDebouncer<T> {
  int _requestId = 0;
  Timer? _timer;

  Future<T?> call(Future<T> Function() action) {
    final currentId = ++_requestId;  // Increment version

    _timer?.cancel();
    _timer = Timer(duration, () async {
      final result = await action();

      // Check if this is still the latest request
      if (_requestId == currentId) {
        return result;  // ✅ Latest - use it
      } else {
        return null;     // ❌ Obsolete - discard
      }
    });
  }
}
```

### Key Insight

The Future **still runs** to completion, but:
- ✅ We track which version is "current"
- ✅ Old results are discarded before they affect state
- ✅ UI always reflects the **latest user intent**, not the last API response to arrive

This is called **Optimistic Cancellation** - we don't stop the work, but we neutralize the side effects.

---

## What are Concurrency Modes?

When async tasks overlap, you need a strategy. This library provides 4 built-in strategies:

### 1. `drop` (Default for Throttle)

**Behavior:** If busy, ignore new tasks entirely.

```dart
final throttler = ConcurrentAsyncThrottler(mode: ConcurrencyMode.drop);

throttler(() async => await api.call());  // ✅ Executes
throttler(() async => await api.call());  // ❌ Dropped (busy)
```

**Use case:** Payment buttons, file uploads (prevent duplicates)

### 2. `replace` (Perfect for Search)

**Behavior:** New task immediately marks old task as obsolete.

```dart
final throttler = ConcurrentAsyncThrottler(mode: ConcurrencyMode.replace);

throttler(() async => await search('a'));   // Started
throttler(() async => await search('ab'));  // First task cancelled, this runs
```

**Use case:** Search autocomplete, switching tabs, real-time filters

### 3. `enqueue` (Queue)

**Behavior:** Tasks wait in line for their turn.

```dart
final throttler = ConcurrentAsyncThrottler(mode: ConcurrencyMode.enqueue);

throttler(() async => await send('msg1'));  // ✅ Runs now
throttler(() async => await send('msg2'));  // Queued, runs after msg1
throttler(() async => await send('msg3'));  // Queued, runs after msg2
```

**Use case:** Chat messages, ordered operations, webhook handling

### 4. `keepLatest` (Current + Last Only)

**Behavior:** Only keep current running task + one latest queued task.

```dart
final throttler = ConcurrentAsyncThrottler(mode: ConcurrencyMode.keepLatest);

throttler(() async => await sync('v1'));  // ✅ Runs now
throttler(() async => await sync('v2'));  // Queued
throttler(() async => await sync('v3'));  // Replaces v2 in queue

// Result: v1 completes, v2 dropped, v3 runs
```

**Use case:** Auto-save, data sync (always save latest, but don't spam)

---

## How does this prevent "setState() after dispose"?

This is one of the most common Flutter crashes. Here's how we eliminate it:

### The Problem

```dart
class _MyWidgetState extends State<MyWidget> {
  void loadData() async {
    final data = await api.fetch();
    setState(() => _data = data);  // ☠️ CRASH if widget disposed!
  }

  @override
  void dispose() {
    super.dispose();
    // Widget is gone, but Future is still running...
  }
}
```

### The Solution (Auto-Dispose)

```dart
class _MyWidgetState extends State<MyWidget> {
  final debouncer = AsyncDebouncer(duration: 300.ms);

  void loadData() {
    debouncer(() async {
      final data = await api.fetch();
      setState(() => _data = data);  // ✅ Never crashes
    });
  }

  @override
  void dispose() {
    debouncer.dispose();  // Cancels all pending operations
    super.dispose();
  }
}
```

**What happens internally:**

1. `dispose()` sets an internal flag: `_disposed = true`
2. When Future completes, library checks: `if (_disposed) return;`
3. Callback is never executed → No crash

### Even Easier: Widget Builders

```dart
AsyncDebouncedCallbackBuilder<String>(
  duration: 300.ms,
  onChanged: (query) async => await api.search(query),
  onSuccess: (results) => setState(() => _results = results),
  builder: (context, callback, isLoading) => TextField(
    onChanged: callback,
  ),
)
// ✅ Auto-dispose on unmount
// ✅ mounted check built-in
// ✅ Zero boilerplate
```

---

## Performance: Does the old Future keep running?

**Yes, the Dart VM doesn't allow killing a Future.** But here's why it's not a problem:

### 1. Network Requests

When you "cancel" a search request:

```dart
final debouncer = AsyncDebouncer(duration: 300.ms);
debouncer(() async => await http.get('api.com/search?q=a'));
debouncer(() async => await http.get('api.com/search?q=ab'));  // New request
```

**What happens:**
- ✅ First HTTP request **does complete** (Dart can't cancel it)
- ✅ But the response is **discarded before parsing**
- ✅ Your UI only receives data from the second request

**Cost:** Network bandwidth used, but CPU/memory safe (no JSON parsing, no state update)

### 2. Computation

For CPU-bound tasks:

```dart
final debouncer = AsyncDebouncer(duration: 100.ms);
debouncer(() async {
  // This WILL run even if cancelled
  final result = expensiveComputation();
  return result;  // Result discarded if obsolete
});
```

**Mitigation strategies:**

1. **Use Isolates for heavy computation:**
```dart
final debouncer = AsyncDebouncer(duration: 100.ms);
debouncer(() async {
  final result = await compute(heavyTask, data);  // Runs in isolate
  return result;
});
```

2. **Check cancellation flag inside task:**
```dart
Future<List<int>> processLargeList(List<int> data) async {
  final results = <int>[];
  for (var i = 0; i < data.length; i++) {
    if (_cancelled) return [];  // Early exit
    results.add(process(data[i]));
  }
  return results;
}
```

### 3. Database Operations

For database writes:

```dart
final batcher = BatchThrottler(
  duration: 1.seconds,
  onBatchExecute: (actions) async {
    final logs = actions.map((a) => a()).toList();
    await db.insertBatch(logs);  // ✅ 100 calls → 1 write
  },
);
```

**No wasted work** - batching reduces actual operations by 100x.

### Summary: Performance Impact

| Scenario | Old Future Runs? | Performance Impact |
|----------|------------------|-------------------|
| **Network Request** | ✅ Yes | ⚠️ Bandwidth used, but JSON parsing/state update skipped |
| **CPU Computation** | ✅ Yes | ⚠️ Use isolates for heavy tasks |
| **Database Write** | N/A | ✅ Batching prevents operation entirely |
| **UI Update** | ❌ No | ✅ Zero impact (callback not executed) |

**Real-world impact:** Negligible. The cost of a completed-but-discarded HTTP request is **far less** than the cost of:
- Parsing stale JSON
- Updating state with old data
- Re-rendering UI with wrong information
- Debugging race conditions

---

## Additional Resources

- [API Reference](docs/API_REFERENCE.md)
- [Best Practices](docs/BEST_PRACTICES.md)
- [Migration Guide](MIGRATION_GUIDE.md)
- [Examples](example/)

---

**Have more questions?** [Open an issue](https://github.com/brewkits/flutter_debounce_throttle/issues)
