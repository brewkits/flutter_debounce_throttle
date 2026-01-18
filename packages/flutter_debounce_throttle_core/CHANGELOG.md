## 1.1.2

**⚠️ DISCONTINUED** - This package has been renamed to `dart_debounce_throttle`.

### What Happened

This package has been renamed to follow Dart naming conventions. Pure Dart packages should not have the `flutter_` prefix.

### Migration

**Replace this package:**
```yaml
dependencies:
  flutter_debounce_throttle_core: ^1.1.0  # ❌ Discontinued
```

**With the new package:**
```yaml
dependencies:
  dart_debounce_throttle: ^2.0.0  # ✅ Active
```

**Update imports:**
```dart
// Before
import 'package:flutter_debounce_throttle_core/flutter_debounce_throttle_core.dart';

// After
import 'package:dart_debounce_throttle/dart_debounce_throttle.dart';
```

### No API Changes

All functionality remains identical. Only the package name has changed.

### Links

- New package: https://pub.dev/packages/dart_debounce_throttle
- Full migration guide: https://github.com/brewkits/flutter_debounce_throttle

---

This package will not receive further updates. Please migrate to `dart_debounce_throttle`.

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
- **Trailing edge:** `trailing: true` - Execute after delay (default behavior)
- **Both edges:** `leading: true, trailing: true` - Execute both immediately AND after delay

### Enhanced BatchThrottler

- **Batch size limits:** `maxBatchSize: 100` - Auto-flush when batch is full
- **Overflow strategies:** `BatchOverflowStrategy.dropOldest`, `dropNewest`, `flushAndAdd`

### Enhanced ConcurrentAsyncThrottler

- **Queue limits:** `maxQueueSize: 10` - Prevent unbounded queue growth
- **Queue overflow:** `QueueOverflowStrategy.dropOldest`, `dropNewest`, `throwError`

### Documentation

- Added comprehensive concurrency mode examples
- Added real-world server scenarios (rate limiting, batching)
- Improved API documentation with edge cases

---

## 1.0.0

Initial release - Production-ready debounce and throttle for Pure Dart.

### Core Classes

- **Debouncer** - Wait for pause in events
- **Throttler** - Rate limit events
- **AsyncDebouncer** - Debounce with auto-cancel for async
- **AsyncThrottler** - Throttle async operations with timeout
- **ConcurrentAsyncThrottler** - Advanced async with 4 concurrency modes
- **HighFrequencyThrottler** - Optimized for 60fps events
- **ThrottleDebouncer** - Leading + trailing edge execution
- **BatchThrottler** - Batch multiple actions for bulk execution

### Features

- Zero external dependencies (only `meta`)
- Type-safe with full generic support
- Memory-safe with automatic cleanup
- 140+ tests with 95% coverage
- Works on Mobile, Web, Desktop, Server, CLI
