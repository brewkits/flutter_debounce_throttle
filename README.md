# flutter_debounce_throttle

[![pub package](https://img.shields.io/pub/v/flutter_debounce_throttle.svg)](https://pub.dev/packages/flutter_debounce_throttle)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Dart 3](https://img.shields.io/badge/Dart-3.x-blue.svg)](https://dart.dev)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B.svg)](https://flutter.dev)

**The Safe, Unified & Universal Event Limiter for Flutter & Dart.**

Debounce, throttle, and rate limit with automatic lifecycle management. Prevent double clicks, race conditions, and memory leaks. Works on Mobile, Web, Desktop, and Server.

---

## Highlights

| | Feature |
|---|---------|
| **One API** | Works on Flutter (Mobile, Web, Desktop) and Pure Dart (Server, CLI) |
| **Memory Safe** | Auto-dispose with widget lifecycle, mounted checks |
| **Type Safe** | Full generic support, no dynamic types |
| **340+ Tests** | Comprehensive coverage, production ready |
| **Zero Deps** | Core package has no external dependencies |
| **Modern API** | Callable class pattern: `debouncer(() => ...)` |

---

## Packages

| Package | Description | Use When |
|---------|-------------|----------|
| [`flutter_debounce_throttle`](packages/flutter_debounce_throttle) | Flutter widgets + mixin | Flutter apps |
| [`flutter_debounce_throttle_hooks`](packages/flutter_debounce_throttle_hooks) | Flutter Hooks integration | Using flutter_hooks |
| [`flutter_debounce_throttle_core`](packages/flutter_debounce_throttle_core) | Pure Dart core | Server, CLI, no Flutter |

---

## Installation

```yaml
# Flutter App
dependencies:
  flutter_debounce_throttle: ^1.1.0

# Flutter App with Hooks
dependencies:
  flutter_debounce_throttle_hooks: ^1.1.0

# Pure Dart (Server, CLI)
dependencies:
  flutter_debounce_throttle_core: ^1.1.0
```

---

## Quick Start

### Button Anti-Spam

```dart
ThrottledInkWell(
  duration: Duration(milliseconds: 500),
  onTap: () => submitForm(),
  child: Text('Submit'),
)
```

### Search Input

```dart
DebouncedQueryBuilder<List<User>>(
  duration: Duration(milliseconds: 300),
  onQuery: (text) async => await searchApi(text),
  onResult: (results) => setState(() => _results = results),
  builder: (context, search, isLoading) => TextField(
    onChanged: search,
    decoration: InputDecoration(
      suffixIcon: isLoading ? CircularProgressIndicator() : Icon(Icons.search),
    ),
  ),
)
```

### Scroll Optimization

```dart
final throttler = HighFrequencyThrottler(duration: Duration(milliseconds: 16));

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

```
Throttle: ─●───────●───────●───────  (execute first, block rest)
Debounce: ─────────────────●────────  (wait for pause, execute last)
```

| Use Case | Throttle | Debounce |
|----------|----------|----------|
| Button clicks | ✓ | |
| Scroll events | ✓ | |
| Search input | | ✓ |
| Form validation | | ✓ |
| API rate limiting | ✓ | |

---

## What's New in v1.1.0

- **RateLimiter** - Token Bucket algorithm for burst-capable rate limiting
- **Duration Extensions** - `300.ms`, `2.seconds`, `5.minutes`
- **Callback Extensions** - `.debounced()`, `.throttled()` on functions
- **Debouncer Leading/Trailing Edge** - Like lodash `_.debounce`
- **BatchThrottler maxBatchSize** - With overflow strategies
- **ConcurrentAsyncThrottler maxQueueSize** - Queue limit with overflow handling

```dart
// Duration extensions
final delay = 300.ms;
final throttler = Throttler(duration: 500.ms);

// Callback extensions
final debouncedFn = myFunction.debounced(300.ms);

// Leading + trailing edge
final debouncer = Debouncer(
  duration: 300.ms,
  leading: true,
  trailing: true,
);

// Rate limiter
final limiter = RateLimiter(
  maxTokens: 10,
  refillRate: 2,
  refillInterval: 1.seconds,
);
```

---

## Documentation

| Document | Description |
|----------|-------------|
| [API Reference](docs/API_REFERENCE.md) | Complete API documentation |
| [Best Practices](docs/BEST_PRACTICES.md) | Use case patterns and recommendations |
| [Migration Guide](MIGRATION_GUIDE.md) | Upgrade from other libraries |
| [Server Demo](example/server_demo/) | Pure Dart examples |
| [Example App](example/) | Interactive Flutter demos |

---

## Quick Reference

| Use Case | Limiter | Mode |
|----------|---------|------|
| Button anti-spam | `Throttler` | - |
| Search input | `Debouncer` | trailing |
| Form validation | `Debouncer` | leading + trailing |
| API rate limiting | `RateLimiter` | token bucket |
| Scroll/resize | `HighFrequencyThrottler` | 16ms |
| Chat queue | `ConcurrentAsyncThrottler` | enqueue |
| Auto-save | `ConcurrentAsyncThrottler` | keepLatest |
| Analytics | `BatchThrottler` | maxBatchSize |

See [Best Practices](docs/BEST_PRACTICES.md) for detailed examples.

---

## State Management

Works with Provider, GetX, Bloc, Riverpod, MobX:

```dart
class MyController with ChangeNotifier, EventLimiterMixin {
  void onSearchChanged(String text) {
    debounce('search', () async {
      users = await api.search(text);
      notifyListeners();
    });
  }

  @override
  void dispose() {
    cancelAll();
    super.dispose();
  }
}
```

---

## Comparison

| Feature | flutter_debounce_throttle | easy_debounce | rxdart |
|---------|:------------------------:|:-------------:|:------:|
| Throttle | ✓ | ✓ | ✓ |
| Debounce | ✓ | ✓ | ✓ |
| Async Support | ✓ | ✗ | ✓ |
| Concurrency Modes | ✓ | ✗ | ✗ |
| Auto Dispose | ✓ | ✗ | ✗ |
| Flutter Widgets | ✓ | ✗ | ✗ |
| Hooks | ✓ | ✗ | ✗ |
| Server Compatible | ✓ | ✓ | ✗ |

---

## License

MIT License - see [LICENSE](LICENSE)

---

## Support

- **Issues**: [GitHub Issues](https://github.com/brewkits/flutter_debounce_throttle/issues)
- **Email**: datacenter111@gmail.com

---

Made with ❤️ by **Nguyễn Tuấn Việt** at **[Brewkits](https://github.com/brewkits)**
