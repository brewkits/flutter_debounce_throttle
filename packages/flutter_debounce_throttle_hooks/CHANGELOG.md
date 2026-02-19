## 2.4.4

**SEO & Polish** - Improved pub.dev description for better search ranking.

### What Changed
- Improved `description`: keyword-first — "Debounce and throttle hooks for Flutter..."
- Updated dependency: `flutter_debounce_throttle` to `^2.4.4`

### No Breaking Changes

---

## 2.4.3

**Documentation** - Updated README and dependency alignment.

### 📚 Documentation
- Updated installation version to `^2.4.0`
- Updated `flutter_debounce_throttle` test count reference to `450+`
- Added `## Which Package Should I Use?` section
- Updated dependency: `flutter_debounce_throttle` to `^2.4.3`

---

## 2.4.1

**Test Coverage & Documentation** - Added comprehensive tests and cleaned up docs.

### ✅ Added
- **16 comprehensive tests** covering all 8 hooks
- Tests for lifecycle management, keys parameter, and hook coexistence
- 100% hook coverage: useDebouncer, useThrottler, useDebouncedCallback,
  useThrottledCallback, useDebouncedValue, useThrottledValue,
  useAsyncDebouncer, useAsyncThrottler

### 📚 Documentation
- Removed outdated "v1.1.0 Features" section
- Fixed misleading test count claims
- Updated Quality Assurance section with accurate information

### 📦 Dependencies
- Updated dependency: `flutter_debounce_throttle` to `^2.4.1`

---

## 2.4.0

**Dependency Update** - Support for flutter_debounce_throttle 2.4.0.

- Updated `flutter_debounce_throttle` dependency to `^2.4.0`
- All hooks now benefit from new ThrottledGestureDetector widget
- Enhanced distributed rate limiting support

### No API Changes
All hooks remain exactly the same. This is a dependency update only.

---

## 2.3.1

**Metadata** - Updated dependency to flutter_debounce_throttle 2.3.1.

- Updated flutter_debounce_throttle dependency to ^2.3.1

---

## 2.3.0

**Production-Safe Defaults** - Updated to support flutter_debounce_throttle 2.3.0.

### What Changed

- Updated dependency: `flutter_debounce_throttle` to `^2.3.0`
- All hooks now benefit from auto-cleanup enabled by default
- Improved memory safety for apps using dynamic IDs with hooks

### No API Changes

All hooks remain exactly the same. This is a dependency update only.

---

## 2.0.0

**BREAKING CHANGE** - Core dependency renamed to follow Dart naming conventions.

### What Changed

The underlying packages have been updated:
- Core: `flutter_debounce_throttle_core` → `dart_debounce_throttle`
- Main: `flutter_debounce_throttle` updated to `^2.0.0`

### Migration Guide

Update pubspec.yaml:

```yaml
dependencies:
  flutter_debounce_throttle_hooks: ^2.0.0  # Update version only
```

No code changes required - all hooks work the same.

### No API Changes

All hooks (`useDebouncedCallback`, `useThrottledCallback`, etc.) remain exactly the same.

---

## 1.1.1

**Documentation** - Enhanced README for better pub.dev presentation.

- Added badges (tests, license)
- Added StatefulWidget vs Hooks comparison (15 lines → 1 line)
- Added complete autocomplete example
- Emphasized zero-boilerplate benefits

---

## 1.1.0

**Enterprise Features** - Advanced event limiting capabilities for production workloads.

Includes all features from `flutter_debounce_throttle` 1.1.0:

- **`RateLimiter`** - Token Bucket algorithm for burst-capable rate limiting
- **Duration extensions:** `300.ms`, `2.seconds`, `5.minutes`, `1.hours`
- **Callback extensions:** `myFunc.debounced(300.ms)`, `myFunc.throttled(500.ms)`
- **Debouncer leading/trailing edge:** Execute on first call and/or after pause
- **BatchThrottler `maxBatchSize`:** Prevent OOM with overflow strategies
- **ConcurrentAsyncThrottler `maxQueueSize`:** Limit queue in enqueue mode

All new features are backward compatible.

## 1.0.1

- Add example Flutter app with hooks demonstrating auto-disposal
- Update flutter_debounce_throttle dependency to ^1.0.1

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
