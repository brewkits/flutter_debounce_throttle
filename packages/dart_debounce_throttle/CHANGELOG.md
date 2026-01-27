## 2.4.2

**World Class Release** - Production-grade distributed rate limiting architecture.

### 🏗️ Architecture Refactoring

- **REMOVED: Redis/Memcached stores from core package**
  - Moved to `example/server_demo/redis_rate_limiter/` as reference implementation
  - **Rationale**: Optional dependencies should not bloat core package (95% users don't need Redis)
  - **Impact**: Zero breaking changes (stores were never exported in public API)
  - **Migration**: Copy implementation from examples if needed

### 🔒 Production Safety Enhancements

- **ADDED: Race condition warnings in distributed rate limiting**
  - Documented fetch-calculate-save race condition in `AsyncRateLimiterStore`
  - Added concurrency warnings in `DistributedRateLimiter.tryAcquire()`
  - Provided trade-off analysis (atomic vs non-atomic operations)

- **ADDED: Atomic operations guide**
  - Redis Lua script example for 100% accurate rate limiting
  - PostgreSQL transaction pattern with `SELECT FOR UPDATE`
  - MongoDB `findAndModify` guidance
  - Performance impact analysis (~2-5ms overhead)

### 📚 Documentation Improvements

- **Enhanced distributed rate limiting guide**
  - Clear separation: Redis for servers, NOT for mobile apps
  - Step-by-step Redis integration tutorial
  - Dart Frog/Shelf middleware examples
  - Security best practices (TLS, authentication)

### 🔄 Migration Guide

**If you were using RedisRateLimiterStore:**

1. Copy implementation from `example/server_demo/redis_rate_limiter/redis_store_example.dart`
2. Add to your pubspec.yaml:
   ```yaml
   dependencies:
     redis: ^4.0.0
   ```
3. For production: Use Lua script (see `example/.../lua/atomic_rate_limit.lua`)

**No other breaking changes.**

---

## 2.4.1

**Quality & Lint Fixes** - Improved pub.dev score.

### 🔧 Fixed
- Fixed redundant length check in `RateLimiterState.fromList()` (pub.dev lint)
- Applied dart fix auto-fixes across codebase

### 📊 Pub.dev Score
- Fixed lint issues for improved pub points (150/160 → targeting 160/160)

---

## 2.4.0

**Enterprise Features** - Distributed Rate Limiting for multi-server environments.

### 🚀 New Features

#### DistributedRateLimiter
- Async rate limiter for multi-server environments (Redis/Memcached)
- Token Bucket algorithm with distributed state
- Perfect for microservices and serverless architectures

```dart
final limiter = DistributedRateLimiter(
  key: 'user-$userId',
  store: RedisRateLimiterStore(redis: redis),
  maxTokens: 100,
  refillRate: 10,
);

if (!await limiter.tryAcquire()) {
  return Response.tooManyRequests();
}
```

### 📦 Added
- `RateLimiterStore` interfaces (sync + async)
- `InMemoryRateLimiterStore` implementation
- `RedisRateLimiterStore` reference implementation
- `MemcachedRateLimiterStore` reference implementation
- 35+ tests for distributed rate limiting

### 🔄 Migration
No breaking changes. All existing code works without modifications.

---

## 2.3.1

**Metadata** - Fixed package description to meet pub.dev requirements.

- Shortened description to 129 characters (within 60-180 limit)
- Improved pub.dev score compliance

---

## 2.3.0

**Production-Safe Defaults** - Auto-cleanup enabled by default to prevent memory leaks.

- Default `limiterAutoCleanupTTL`: null → Duration(minutes: 10)
- Memory leaks from dynamic IDs now prevented automatically
- Enterprise-grade positioning and documentation
- Enhanced pub.dev SEO with production-safe keywords

---

## 2.2.0

**Production Safety & Memory Management** - Enhanced error handling and automatic cleanup.

- TTL Auto-Cleanup for EventLimiterMixin
- Manual cleanup APIs (`cleanupInactive`, `cleanupUnused`)
- Error handling callbacks (`onError`) for all limiters
- Performance optimization (O(1) hash lookup)

---

## 2.1.1

**Documentation** - Enhanced README and improved safety warnings.

- Add comprehensive comparison vs rxdart, easy_debounce, manual Timer
- Add "Why Choose This Over Alternatives" section to README
- Improve documentation for ConcurrentAsyncThrottler maxQueueSize warning
- Add memory guard test cases
- Create ROADMAP.md for v2.2.0 features

---

## 2.1.0

**Feature** - Stream extensions for rxdart-style debounce and throttle.

- Add `.debounce()` extension method for streams
- Add `.throttle()` extension method for streams
- Support both single-subscription and broadcast streams
- Zero additional dependencies

**Example:**
```dart
searchController.stream
  .debounce(Duration(milliseconds: 300))
  .listen((query) => performSearch(query));
```

---

## 2.0.0+1

**Fix** - Update repository URL for pub.dev validation.

- Fix repository URL to point to package subdirectory
- Improves pub.dev score by passing repository validation check

---

## 2.0.0

**BREAKING CHANGE** - Package renamed to follow Dart naming conventions.

### What Changed

The package has been renamed from `flutter_debounce_throttle_core` to `dart_debounce_throttle`.

Pure Dart packages should not have the `flutter_` prefix, as this package has zero Flutter dependencies and works in any Dart environment (server, CLI, web, mobile).

### Migration Guide

**1. Update pubspec.yaml:**

```yaml
# Before
dependencies:
  flutter_debounce_throttle_core: ^1.1.0

# After
dependencies:
  dart_debounce_throttle: ^2.0.0
```

**2. Update imports:**

```dart
// Before
import 'package:flutter_debounce_throttle_core/flutter_debounce_throttle_core.dart';

// After
import 'package:dart_debounce_throttle/dart_debounce_throttle.dart';
```

**3. Run pub get:**

```bash
dart pub get  # or flutter pub get
```

### No API Changes

All classes, methods, and functionality remain exactly the same. Only the package name and import path have changed.

---

## 1.1.1

**Documentation** - Enhanced README for better pub.dev presentation.

- Improved package description and badges
- Added server-problem examples (API cost, DB overload, DDoS)
- Added comparison table vs manual implementation
- Better Token Bucket and Batch Processing documentation

---

## 1.1.0

**Enterprise Features** - Advanced event limiting capabilities for production workloads.

### New Classes

- **`RateLimiter`** - Token Bucket algorithm for burst-capable rate limiting
  - Allow burst of N requests then throttle to sustained rate
  - Perfect for API rate limiting, game input, server protection
  - `tryAcquire()`, `call()`, `callAsync()`, `availableTokens`, `timeUntilNextToken`

### New Extension Methods

- **Duration shortcuts:** `300.ms`, `2.seconds`, `5.minutes`, `1.hours`
- **Callback extensions:** `myFunc.debounced(300.ms)`, `myFunc.throttled(500.ms)`

### Enhanced Debouncer

- **Leading edge:** `leading: true` - Execute immediately on first call
- **Trailing edge:** `trailing: true` - Execute after pause (default)
- **Both edges:** Combine for lodash-style behavior

```dart
final debouncer = Debouncer(
  duration: Duration(milliseconds: 300),
  leading: true,   // Execute immediately
  trailing: true,  // Also execute after pause
);
```

### Enhanced BatchThrottler

- **`maxBatchSize`** - Prevent OOM by limiting batch size
- **`BatchOverflowStrategy`** - Choose behavior when batch is full:
  - `dropOldest` - Remove oldest action to make room
  - `dropNewest` - Reject new action
  - `flushAndAdd` - Immediately flush batch, then add new action

### Enhanced ConcurrentAsyncThrottler

- **`maxQueueSize`** - Limit queue size in enqueue mode
- **`QueueOverflowStrategy`** - Choose behavior when queue is full:
  - `dropNewest` - Reject new call
  - `dropOldest` - Remove oldest queued call

All new features are backward compatible with null defaults.

## 1.0.1

- Fix package description length to meet pub.dev requirements (60-180 chars)
- Add example demonstrating debounce and throttle usage
- Update meta dependency to ^1.16.0 for better Flutter SDK compatibility

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
