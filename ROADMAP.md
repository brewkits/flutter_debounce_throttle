# Roadmap

## v2.2.0 - Enterprise Backend & Advanced Features (Q1 2026)

### 🎯 Goals
Make `dart_debounce_throttle` the **#1 choice** for Dart backend servers (Serverpod, Dart Frog, Shelf) with distributed rate limiting and advanced Flutter widgets.

### 🚀 Planned Features

#### 1. Distributed Rate Limiting (Priority: HIGH)

**Problem:** Current `RateLimiter` is in-memory only. In multi-instance deployments (load balancing) or after server restarts, rate limits reset, making DDoS protection ineffective.

**Solution:** Store abstraction layer

```dart
abstract class RateLimiterStore {
  Future<bool> tryAcquire(String key, {required int tokens});
  Future<int> getAvailableTokens(String key);
  Future<void> reset(String key);
}

// Built-in implementations
class InMemoryStore implements RateLimiterStore { ... }  // Default
class RedisStore implements RateLimiterStore { ... }     // Optional package
```

**Usage:**
```dart
// Single server (default)
final limiter = RateLimiter(
  maxTokens: 100,
  refillRate: 10,
);

// Multi-server with Redis
final limiter = RateLimiter(
  maxTokens: 100,
  refillRate: 10,
  store: RedisStore(
    host: 'redis.example.com',
    key: 'api:rate_limit:user_$userId',
  ),
);
```

**Impact:**
- Makes the library production-ready for **distributed systems**
- Direct competitor to enterprise rate limiting solutions
- Opens door to Serverpod, Dart Frog integrations

---

#### 2. ThrottledGestureDetector (Priority: MEDIUM)

**Problem:** `ThrottledInkWell` only works with Material InkWell. Custom buttons, images, or gesture-based UIs can't use throttling easily.

**Solution:** Universal gesture throttler

```dart
ThrottledGestureDetector(
  duration: Duration(milliseconds: 500),
  onTap: () => handleTap(),
  onDoubleTap: () => handleDoubleTap(),
  onLongPress: () => handleLongPress(),
  onPanUpdate: (details) => handlePan(details),
  child: CustomWidget(),
)
```

**Features:**
- Map all `GestureDetector` callbacks
- Configurable throttle duration per gesture type
- Support for simultaneous gestures

**Impact:**
- Covers 100% of Flutter touch interactions
- Solves gesture spam issues in games, drawing apps, custom UIs

---

#### 3. Smart Network Awareness (Priority: MEDIUM)

**Problem:** When offline, debounced/throttled network requests still execute and fail, wasting resources and confusing users.

**Solution:** Global pause/resume with network awareness

```dart
// Simple API (no external dependencies)
void main() {
  runApp(MyApp());

  // Listen to network changes
  Connectivity().onConnectivityChanged.listen((result) {
    if (result == ConnectivityResult.none) {
      DebounceThrottleConfig.pauseAll();  // Pause all limiters
    } else {
      DebounceThrottleConfig.resumeAll(); // Resume all limiters
    }
  });
}
```

**Advanced features:**
- Per-limiter pause/resume
- Configurable behavior: discard vs queue when offline
- Automatic retry when back online

**Impact:**
- Better UX in mobile apps
- Reduces failed network calls
- Saves battery and data

---

#### 4. Enhanced Memory Safety

**Improvements:**
- Auto-cleanup for EventLimiterMixin dynamic IDs after N minutes of inactivity
- Optional strict mode that throws exception instead of warning
- Memory profiler tool to track limiter allocations

```dart
DebounceThrottleConfig.init(
  strictMemoryMode: true,  // Throw on >100 instances
  autoCleanupAfter: Duration(minutes: 5),  // Auto-remove inactive limiters
);
```

---

### 📊 Performance Optimizations

- [ ] Reduce Timer allocations in high-frequency scenarios
- [ ] Lazy initialization for limiters in EventLimiterMixin
- [ ] Benchmark suite for measuring overhead

---

### 📚 Documentation & Ecosystem

- [ ] Interactive playground on pub.dev
- [ ] Video tutorials for common patterns
- [ ] Official Serverpod plugin
- [ ] Official Dart Frog middleware
- [ ] Community recipes repository

---

## v2.3.0 - Advanced Patterns (Q2 2026)

### Potential Features (Under Consideration)

- **Adaptive Rate Limiting** - Auto-adjust rates based on load
- **Priority Queues** - VIP vs normal user rate limits
- **Time-based Rules** - Different limits for day/night
- **Circuit Breaker** - Auto-pause after N failures
- **Metrics & Telemetry** - Built-in performance tracking

---

## How to Contribute

We welcome contributions! If you want to work on any roadmap item:

1. Open an issue to discuss the approach
2. Submit a PR with tests and documentation
3. Update this roadmap with your progress

---

## Version History

- **v2.1.x** - Stream Extensions, Memory Guards, Safety Improvements
- **v2.0.0** - Package Rename (dart_debounce_throttle)
- **v1.1.0** - Rate Limiter, Leading/Trailing Edge
- **v1.0.0** - Initial Release

---

*Last updated: 2026-01-19*
