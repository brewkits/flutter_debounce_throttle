# flutter_debounce_throttle

[![pub package](https://img.shields.io/pub/v/flutter_debounce_throttle.svg)](https://pub.dev/packages/flutter_debounce_throttle)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Tests](https://img.shields.io/badge/tests-570%2B%20passed-brightgreen)](https://github.com/brewkits/flutter_debounce_throttle)
[![Coverage](https://img.shields.io/badge/coverage-98%25-brightgreen)](https://github.com/brewkits/flutter_debounce_throttle)
[![GitHub stars](https://img.shields.io/github/stars/brewkits/flutter_debounce_throttle?style=social)](https://github.com/brewkits/flutter_debounce_throttle/stargazers)

High-performance, memory-safe, and lifecycle-aware traffic control for Flutter & Dart. Debounce, throttle, rate limiting (Token Bucket), and async concurrency control with **Zero Silent Failures**.

| Debounced Search | Anti-Spam Button | Async Submit |
|:---:|:---:|:---:|
| ![Search](https://raw.githubusercontent.com/brewkits/flutter_debounce_throttle/main/docs/images/demo_search_debounce.gif) | ![Throttle](https://raw.githubusercontent.com/brewkits/flutter_debounce_throttle/main/docs/images/demo_throttle_antispam.gif) | ![Submit](https://raw.githubusercontent.com/brewkits/flutter_debounce_throttle/main/docs/images/demo_async_submit.gif) |

---

## 🚀 What's New in v2.4.6: The Honest API

Most libraries return `void`, causing "silent failures" where dropped operations appear to succeed. This library introduces **ThrottlerResult** and **DebounceResult** to ensure your code handles every outcome.

```dart
// ✅ Honest API — both branches required at compile time
final result = await throttler.call(() async => await processPayment(order));

result.when(
  onExecuted: () => showSuccessDialog(),  // Safe: payment actually ran
  onDropped:  () => showError('Busy!'),  // Handled: user knows it failed
);
```

---

## Quick Start

**Anti-spam button — 1 line:**
```dart
ThrottledInkWell(onTap: () => processPayment(), child: Text('Pay \$99'))
```

**Debounced search:**
```dart
final debouncer = Debouncer(duration: 300.ms);
TextField(onChanged: (s) => debouncer(() => search(s)))
```

**State management (Provider, Riverpod, GetX, Bloc):**
```dart
class SearchController with ChangeNotifier, EventLimiterMixin {
  void onSearch(String text) {
    debounce('search', () async {
      _results = await api.search(text);
      notifyListeners();
    });
  }

  @override
  void dispose() { cancelAll(); super.dispose(); }
}
```

---

## Which Package?

| You are building... | Install |
|---------------------|---------|
| Flutter app | [`flutter_debounce_throttle`](https://pub.dev/packages/flutter_debounce_throttle) |
| Flutter app + flutter_hooks | [`flutter_debounce_throttle_hooks`](https://pub.dev/packages/flutter_debounce_throttle_hooks) |
| Flutter app + Riverpod | [`flutter_debounce_throttle_riverpod`](https://pub.dev/packages/flutter_debounce_throttle_riverpod) |
| Dart server / CLI / Serverpod | [`dart_debounce_throttle`](https://pub.dev/packages/dart_debounce_throttle) |

---

## Why This Library?

| Capability | This Library | easy_debounce | Manual Timer |
|------------|:---:|:---:|:---:|
| **Honest API (No Silent Failures)** | ✅ | ❌ | ❌ |
| **Memory Safe (Auto-dispose)** | ✅ | ❌ | ❌ Leaky |
| **Async & Future Support** | ✅ | ❌ | ❌ |
| **Race Condition Control (4 modes)** | ✅ | ❌ | ❌ |
| **Ready-to-use Widgets** | ✅ | ❌ | ❌ |
| **Distributed Rate Limiting** | ✅ | ❌ | ❌ |
| **Zero External Dependencies** | **0** | 0 | 0 |

---

## Quality & Reliability

| | |
|---|---|
| **570+ tests** | Unit, widget, integration, security, performance & stress tests |
| **98% coverage** | Every branch and edge case verified |
| **Security First** | DoS protection and memory exhaustion guards built-in |
| **Type-safe** | Full generics, no `dynamic`, compile-time safety with `when()` |
| **Memory-safe** | Verified with Flutter LeakTracker to ensure zero leaks |

---

## Documentation

| | |
|---|---|
| [FAQ](FAQ.md) | Common questions |
| [API Reference](docs/API_REFERENCE.md) | Complete class/method docs |
| [Best Practices](docs/BEST_PRACTICES.md) | Patterns & recommendations |
| [Migration Guide](MIGRATION_GUIDE.md) | From easy_debounce, rxdart, manual Timer |
| [Example App](example/) | Comprehensive interactive demos |

---

<p align="center">
  Made with craftsmanship by <a href="https://github.com/brewkits">Brewkits</a>
</p>
