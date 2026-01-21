## 2.3.1

**Metadata Fix** - Fixed package description to meet pub.dev requirements.

### What Changed

- Shortened dart_debounce_throttle description to 129 characters (within 60-180 limit)
- Updated all package dependencies to ^2.3.1
- Improved pub.dev score compliance

### No Code Changes

This is a metadata-only release. All functionality remains identical to v2.3.0.

---

## 2.3.0

**Production-Safe Defaults** - Auto-cleanup enabled by default to prevent memory leaks.

### 🛡️ Breaking Change (Behavior)

**IMPORTANT:** Auto-cleanup is now **enabled by default** to prevent memory leaks with dynamic IDs.

- **Old behavior:** `limiterAutoCleanupTTL` defaulted to `null` (disabled)
- **New behavior:** `limiterAutoCleanupTTL` defaults to `Duration(minutes: 10)` (enabled)

**Impact:**
- ✅ No code changes needed for most apps
- ✅ Apps using dynamic IDs are now safer by default
- ✅ Limiters unused for 10+ minutes are auto-removed when count exceeds 100
- ✅ Actively used limiters are never cleaned up

**Migration:**
```dart
// To keep old behavior (disable auto-cleanup):
DebounceThrottleConfig.init(
  limiterAutoCleanupTTL: null,  // Explicitly disable
);
```

### 📦 What Changed

- Default `limiterAutoCleanupTTL`: `null` → `Duration(minutes: 10)`
- Updated documentation to reflect new defaults
- Added tests for default behavior
- Enhanced examples to show auto-cleanup is enabled by default

### 🎯 Why This Change?

Memory leaks with dynamic IDs can cause production crashes. Making auto-cleanup the default ensures apps are safe by default, following the principle of "secure by default."

---

## 2.2.0

**Production Safety & Memory Management** - Enhanced error handling and automatic cleanup for production apps.

### 🛡️ Error Handling

- **onError Callbacks** - Added error handlers to all limiters (Debouncer, Throttler, AsyncDebouncer, AsyncThrottler)
- **Firebase Crashlytics Integration** - Track errors in production via onError callback
- **Sentry Support** - Capture exceptions with custom error handlers
- **Better Debugging** - No more silent failures in production

```dart
final debouncer = Debouncer(
  onError: (error, stackTrace) {
    FirebaseCrashlytics.instance.recordError(error, stackTrace);
  },
);
```

### 🧹 Memory Management

- **TTL Auto-Cleanup** - Prevent memory leaks with time-to-live based automatic cleanup
- **Manual Cleanup APIs** - Fine-grained control with `cleanupInactive()` and `cleanupUnused()`
- **Memory Monitoring** - Track limiter count with `totalLimitersCount` getter
- **Production Safe** - Handles dynamic IDs without OOM crashes

```dart
// Enable auto-cleanup globally
DebounceThrottleConfig.init(
  limiterAutoCleanupTTL: Duration(minutes: 5),
  limiterAutoCleanupThreshold: 100,
);
```

### ⚡ Performance

- **O(1) Optimization** - Fixed O(N) performance issue in EventLimiterMixin
- **Faster Existing Calls** - 100-1000x improvement for repeated limiter calls
- **UI Thread Safe** - Reduced unnecessary work during user interactions

### 📦 What's Included

- Error handling for all 4 limiter types
- TTL-based auto-cleanup with configurable threshold
- Manual cleanup methods for dynamic IDs
- Performance optimization in mixin
- 48 comprehensive tests (100% passing)
- Zero breaking changes - fully backward compatible

### 🔧 Migration Notes

No migration needed - all changes are opt-in and backward compatible.

---

## 1.0.0

**Enterprise Edition** - The Safe, Unified & Universal Event Limiter for Flutter & Dart.

Complete rewrite with modern API, monorepo architecture, and full server-side support. Ready for production use.

### 🎯 Highlights

- **Modern Callable Class API** - Call limiters like functions: `debouncer(() => ...)`
- **Pure Dart Core** - Works on Dart servers (Serverpod, Dart Frog, etc.)
- **Monorepo Structure** - Separate packages for core, flutter, and hooks
- **Zero Dependencies** - No external dependencies in core package
- **ID-based Limiting** - Multiple independent limiters with string IDs
- **Type-safe & Memory-safe** - Generic types, auto-dispose, mounted checks
- **143+ Tests** - Comprehensive test coverage
- **Backward Compatible** - Old APIs still work with deprecation notices

### 🏗️ Architecture

#### Monorepo Packages
- **`flutter_debounce_throttle_core`** - Pure Dart core (no Flutter deps)
- **`flutter_debounce_throttle`** - Flutter integration (widgets + mixin)
- **`flutter_debounce_throttle_hooks`** - Optional Flutter Hooks support

#### Import Strategy
```dart
// Flutter apps
import 'package:flutter_debounce_throttle/flutter_debounce_throttle.dart';

// Hooks (optional)
import 'package:flutter_debounce_throttle_hooks/flutter_debounce_throttle_hooks.dart';

// Pure Dart (Server/CLI)
import 'package:flutter_debounce_throttle_core/flutter_debounce_throttle_core.dart';
```

### ✨ New Features

#### 1. Callable Class Pattern
Classes can now be called like functions (Dart convention):

```dart
// AsyncDebouncer
final debouncer = AsyncDebouncer(duration: Duration(milliseconds: 300));
final result = await debouncer(() async => api.search(query));

// BatchThrottler
final batcher = BatchThrottler(duration: Duration(milliseconds: 100));
batcher(() => save('item1'));
batcher(() => save('item2'));
```

**Old API (deprecated but still works):**
- `AsyncDebouncer.run()` → Use `call()` or callable syntax
- `BatchThrottler.add()` → Use `call()` or callable syntax

#### 2. Improved Mixin API
Cleaner method names for EventLimiterMixin:

```dart
class MyController with EventLimiterMixin {
  void dispose() {
    cancel('search');  // NEW: Cancel specific limiter
    cancelAll();       // NEW: Cancel all limiters
    super.dispose();
  }
}
```

**Old API (deprecated but still works):**
- `cancelLimiter(id)` → Use `cancel(id)`
- `cancelAllLimiters()` → Use `cancelAll()`

#### 3. Widget Rename
Better naming for search/query widget:

```dart
DebouncedQueryBuilder<List<User>>(  // NEW name
  onQuery: (text) async => await search(text),  // NEW parameter name
  onResult: (users) => updateUI(users),         // NEW parameter name
  builder: (context, search, isLoading) => TextField(onChanged: search),
)
```

**Old API (deprecated but still works):**
- `AsyncDebouncedCallbackBuilder` → Use `DebouncedQueryBuilder`
- `onChanged` → Use `onQuery`
- `onSuccess` → Use `onResult`

#### 4. Environment-aware Logging

```dart
void main() {
  DebounceThrottleConfig.init(
    enableDebugLog: true,
    logLevel: LogLevel.debug,
    logHandler: (level, message, name, timestamp) {
      print('[$level] $message');
    },
  );
}

// Instance-level debug mode
final debouncer = Debouncer(
  debugMode: true,
  name: 'SearchDebouncer',
);
// Output: [SearchDebouncer] Debounce executed after 305ms
```

#### 5. Server-Side Support
Pure Dart Core works on servers without Flutter:

```dart
// example/server_demo/server_example.dart
import 'package:flutter_debounce_throttle_core/flutter_debounce_throttle_core.dart';

class LogBatchingService {
  final _debouncer = Debouncer(duration: Duration(seconds: 1));

  void log(String message) {
    _pendingLogs.add(message);
    _debouncer(() {
      writeToDB(_pendingLogs);
      _pendingLogs.clear();
    });
  }
}
```

Run with: `dart run example/server_demo/server_example.dart`

### 📦 Core Limiters (Pure Dart)

All limiters work in both Flutter and pure Dart environments:

- **`Throttler`** - Execute immediately, block subsequent calls for duration
- **`Debouncer`** - Delay execution until pause in calls
- **`AsyncDebouncer`** - Async debounce with cancellation support (NEW: callable)
- **`AsyncThrottler`** - Lock-based async throttle with timeout
- **`HighFrequencyThrottler`** - Optimized for 60fps events (scroll, mouse)
- **`BatchThrottler`** - Batch multiple operations (NEW: callable)
- **`ConcurrentAsyncThrottler`** - 4 concurrency modes (drop, enqueue, replace, keepLatest)
- **`ThrottleDebouncer`** - Combined leading + trailing edge execution

### 🎨 Flutter Widgets

- **`ThrottledBuilder`** - Universal throttle wrapper widget
- **`ThrottledInkWell`** - Material button with built-in throttle
- **`DebouncedBuilder`** - Debounce wrapper widget
- **`DebouncedQueryBuilder`** - Async query with loading state (NEW: renamed from AsyncDebouncedCallbackBuilder)
- **`AsyncThrottledBuilder`** - Async throttle with loading state
- **`AsyncDebouncedBuilder`** - Async debounce with loading state
- **`ConcurrentAsyncThrottledBuilder`** - Concurrency modes widget

### 🌊 Stream Listeners

- **`StreamSafeListener`** - Auto-cancel stream subscription on dispose
- **`StreamDebounceListener`** - Debounce stream events
- **`StreamThrottleListener`** - Throttle stream events

### ⌨️ Text Controllers

- **`DebouncedTextController`** - TextField controller with debouncing
- **`AsyncDebouncedTextController`** - Async search controller with loading state

### 🎛️ State Management

- **`EventLimiterMixin`** - ID-based limiters for any controller
  - Works with Provider, GetX, Bloc, MobX, Riverpod
  - NEW: `cancel(id)` and `cancelAll()` methods
  - Methods: `debounce()`, `throttle()`, `debounceAsync()`, `throttleAsync()`

### 🪝 Flutter Hooks (Optional Package)

- **`useDebouncer`** - Hook for Debouncer instance
- **`useThrottler`** - Hook for Throttler instance
- **`useAsyncDebouncer`** - Hook for AsyncDebouncer instance
- **`useAsyncThrottler`** - Hook for AsyncThrottler instance
- **`useDebouncedCallback`** - Hook for debounced callback
- **`useThrottledCallback`** - Hook for throttled callback
- **`useDebouncedValue`** - Hook for debounced value
- **`useThrottledValue`** - Hook for throttled value

### ⚙️ Configuration

```dart
DebounceThrottleConfig.init(
  enableDebugLog: true,
  logLevel: LogLevel.debug,
  logHandler: (level, message, name, timestamp) {
    // Custom logging
  },
);
```

**Log Levels:** `none`, `error`, `warning`, `info`, `debug`

### 📚 Documentation

- **[Migration Guide](MIGRATION_GUIDE.md)** - Migrate from easy_debounce, manual Timer, rxdart
- **[Master Plan](MASTER_PLAN_FINAL_REPORT.md)** - Complete project documentation
- **[Server Demo](example/server_demo/server_example.dart)** - Pure Dart examples
- **[Example App](example/)** - 5 interactive demos
- **143+ Tests** - Comprehensive test coverage

### 🔄 Migration from Old API

All old APIs still work but are deprecated. Update at your convenience:

```dart
// AsyncDebouncer
await debouncer.run(() async => ...)  // Old (deprecated)
await debouncer(() async => ...)       // New (callable)

// BatchThrottler
batcher.add(() => ...)  // Old (deprecated)
batcher(() => ...)      // New (callable)

// EventLimiterMixin
cancelLimiter('id')      // Old (deprecated)
cancel('id')             // New

cancelAllLimiters()      // Old (deprecated)
cancelAll()              // New

// Widgets
AsyncDebouncedCallbackBuilder  // Old (deprecated)
DebouncedQueryBuilder          // New
```

See [Migration Guide](MIGRATION_GUIDE.md) for detailed examples.

### 🎯 Quality Metrics

- ✅ **143+ tests** - All passing
- ✅ **Zero dependencies** - Core package has no external deps
- ✅ **Type-safe** - Generic types, no dynamic
- ✅ **Memory-safe** - Auto-dispose, mounted checks
- ✅ **Static analysis clean** - No issues
- ✅ **Server-ready** - Pure Dart Core proven working

### 📊 Package Sizes

- `flutter_debounce_throttle_core` - ~30KB (pure Dart)
- `flutter_debounce_throttle` - ~50KB (includes widgets)
- `flutter_debounce_throttle_hooks` - ~10KB (hooks only)

### 🙏 Acknowledgments

This release represents a complete Enterprise Edition rewrite with modern APIs, comprehensive testing, and production-grade architecture. Special thanks to all contributors and early adopters.
