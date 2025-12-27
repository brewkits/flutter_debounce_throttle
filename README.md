# flutter_debounce_throttle

[![pub package](https://img.shields.io/pub/v/flutter_debounce_throttle.svg)](https://pub.dev/packages/flutter_debounce_throttle)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

**The Safe, Unified & Universal Event Limiter for Flutter & Dart.**

Debounce, throttle, and rate limit with automatic lifecycle management. Prevent double clicks, race conditions, and memory leaks. Works on Mobile, Web, Desktop, and Server.

---

## Why This Package?

| Problem | Solution |
|---------|----------|
| Double button clicks | `ThrottledInkWell` blocks for duration |
| Search API spam | `AsyncDebouncedCallbackBuilder` with loading state |
| Race conditions | `ConcurrentAsyncThrottler` with 4 modes |
| Memory leaks | Auto-dispose with StatefulWidget lifecycle |
| Server compatibility | Pure Dart core via `core.dart` |
| State management | `EventLimiterMixin` for any controller |

---

## Features

- **Throttle**: Execute immediately, block subsequent calls for duration
- **Debounce**: Delay execution until pause in calls
- **Async Support**: Handle async operations with cancellation
- **Concurrency Control**: 4 modes - drop, enqueue, replace, keepLatest
- **High Frequency**: Optimized for scroll/mouse events (60fps)
- **Batch Operations**: Group multiple calls into single execution
- **Stream Listeners**: Safe stream subscriptions with auto-cancel
- **Flutter Hooks**: Full hooks integration
- **State Management Mixin**: Works with Provider, GetX, Bloc, etc.
- **Pure Dart Core**: Server-side compatible

---

## Installation

```yaml
dependencies:
  flutter_debounce_throttle: ^1.0.0
```

**For Dart Server (no Flutter):**
```dart
import 'package:flutter_debounce_throttle/core.dart';
```

**For Flutter Hooks:**
```dart
import 'package:flutter_debounce_throttle/hooks.dart';
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
AsyncDebouncedCallbackBuilder<List<User>>(
  duration: Duration(milliseconds: 300),
  onChanged: (text) async => await searchApi(text),
  onSuccess: (results) => setState(() => _results = results),
  builder: (context, callback, isLoading) => TextField(
    onChanged: callback,
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

### Async Limiters

#### AsyncDebouncer

```dart
final debouncer = AsyncDebouncer(duration: Duration(milliseconds: 300));

// Returns result, cancels previous if pending
final result = await debouncer.run(() async {
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
final batcher = BatchThrottler<String>(
  duration: Duration(milliseconds: 100),
  onBatch: (items) => saveAll(items),
);

batcher.add('item1');
batcher.add('item2');
batcher.add('item3');
// After 100ms: saveAll(['item1', 'item2', 'item3'])
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
    onChanged: (text) => debounce(() => validate(text)),
  ),
)
```

### AsyncDebouncedCallbackBuilder

Async debounce with loading state:

```dart
AsyncDebouncedCallbackBuilder<List<User>>(
  duration: Duration(milliseconds: 300),
  onChanged: (query) async => await searchUsers(query),
  onSuccess: (users) => setState(() => _users = users),
  onError: (e) => showError(e),
  builder: (context, callback, isLoading) => Column(
    children: [
      TextField(onChanged: callback),
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
    cancelAllLimiters(); // Clean up all limiters
    super.dispose();
  }
}
```

### Available Methods

```dart
mixin EventLimiterMixin {
  // Sync limiters
  void debounce(String id, VoidCallback action, {Duration? duration});
  void throttle(String id, VoidCallback action, {Duration? duration});

  // Async limiters
  Future<T?> debounceAsync<T>(String id, Future<T> Function() action, {Duration? duration});
  Future<T?> throttleAsync<T>(String id, Future<T> Function() action, {Duration? duration});

  // Control
  void cancelLimiter(String id);
  void cancelAllLimiters();

  // Status
  bool isLimiterActive(String id);
  int get activeLimitersCount;
}
```

### Works With

- **Provider**: `ChangeNotifier`
- **GetX**: `GetxController`
- **Bloc**: `Cubit`, `Bloc`
- **Riverpod**: `Notifier`, `AsyncNotifier`
- **MobX**: Store classes
- **Dart Server**: Any controller class

---

## Flutter Hooks

Requires `flutter_hooks` package:

```yaml
dependencies:
  flutter_hooks: ^0.20.0
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
  FlutterDebounceThrottle.init(
    defaultDebounceDuration: Duration(milliseconds: 300),
    defaultThrottleDuration: Duration(milliseconds: 500),
    debugMode: kDebugMode,
    logLevel: LogLevel.warning,
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
import 'package:flutter_debounce_throttle/core.dart';

class ApiController {
  final _rateLimiter = Throttler(duration: Duration(seconds: 1));

  Future<Response> handleRequest(Request request) async {
    // Rate limit API calls
    return _rateLimiter.call(() async {
      return await processRequest(request);
    }) ?? Response.tooManyRequests();
  }
}
```

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
```

---

## License

MIT License - see [LICENSE](LICENSE)

---

## Contributing

Contributions welcome! Please read our [contributing guidelines](CONTRIBUTING.md).

---

**Made with ❤️ by [brewkits.dev](https://brewkits.dev)**
