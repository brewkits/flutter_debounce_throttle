# flutter_debounce_throttle_core

Pure Dart core library for debounce and throttle operations. **Zero Flutter dependencies** - works on Mobile, Web, Desktop, Server, and CLI.

## Installation

```yaml
dependencies:
  flutter_debounce_throttle_core: ^1.0.0
```

## Quick Start

### Basic Throttle (prevent spam clicks)
```dart
final throttler = Throttler(duration: Duration(milliseconds: 500));
throttler.call(() => submitForm());
// Don't forget to dispose!
throttler.dispose();
```

### Basic Debounce (wait for user to stop)
```dart
final debouncer = Debouncer(duration: Duration(milliseconds: 300));
debouncer.call(() => search(query));
debouncer.dispose();
```

### Async Throttle (API calls)
```dart
final asyncThrottler = AsyncThrottler(maxDuration: Duration(seconds: 15));
await asyncThrottler.call(() async => await api.submit());
asyncThrottler.dispose();
```

### Async Debounce (search autocomplete)
```dart
final asyncDebouncer = AsyncDebouncer(duration: Duration(milliseconds: 300));
final result = await asyncDebouncer.run(() async => await searchApi(query));
if (result == null) return; // Cancelled by newer call
updateResults(result);
asyncDebouncer.dispose();
```

### Server-side Batching
```dart
final batcher = BatchThrottler(
  duration: Duration(seconds: 1),
  onBatchExecute: (actions) async {
    final logs = actions.map((a) => a()).toList();
    await database.insertAll(logs);
  },
);
batcher.add(() => 'User logged in');
batcher.add(() => 'Page viewed');
// After 1 second, all logs inserted in single batch
batcher.dispose();
```

## Available Classes

### Sync Controllers
- `Throttler`: Immediate execution, blocks for duration
- `Debouncer`: Delayed execution after pause
- `HighFrequencyThrottler`: Optimized for scroll/resize (no Timer overhead)
- `ThrottleDebouncer`: Leading + trailing edge execution

### Async Controllers
- `AsyncThrottler`: Lock-based async throttle
- `AsyncDebouncer`: Debounce with auto-cancel for async operations
- `ConcurrentAsyncThrottler`: Advanced async with drop/enqueue/replace/keepLatest modes

### Utilities
- `BatchThrottler`: Batch multiple actions for bulk execution
- `DebounceThrottleConfig`: Global configuration
- `EventLimiterLogger`: Centralized logging

## Configuration

```dart
void main() {
  DebounceThrottleConfig.init(
    defaultDebounceDuration: Duration(milliseconds: 300),
    defaultThrottleDuration: Duration(milliseconds: 500),
    enableDebugLog: true,
  );

  // Your app code...
}
```

## Related Packages

- [flutter_debounce_throttle](https://pub.dev/packages/flutter_debounce_throttle) - Flutter widgets + mixin
- [flutter_debounce_throttle_hooks](https://pub.dev/packages/flutter_debounce_throttle_hooks) - Flutter Hooks integration
