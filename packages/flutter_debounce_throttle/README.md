# flutter_debounce_throttle

[![pub package](https://img.shields.io/pub/v/flutter_debounce_throttle.svg)](https://pub.dev/packages/flutter_debounce_throttle)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Tests](https://img.shields.io/badge/tests-570%2B%20passed-brightgreen)](https://github.com/brewkits/flutter_debounce_throttle)
[![Coverage](https://img.shields.io/badge/coverage-98%25-brightgreen)](https://github.com/brewkits/flutter_debounce_throttle)
[![GitHub stars](https://img.shields.io/github/stars/brewkits/flutter_debounce_throttle?style=social)](https://github.com/brewkits/flutter_debounce_throttle/stargazers)

## The Traffic Control System for Flutter Apps

> Stop using manual `Timer`. It causes memory leaks, crashes, and race conditions.

**All-in-one package** for debounce, throttle, rate limiting, and async concurrency control. Memory-safe, lifecycle-aware, and works with any state management solution.

| Debounced Search | Anti-Spam Button | Async Submit |
|:---:|:---:|:---:|
| ![Search](https://raw.githubusercontent.com/brewkits/flutter_debounce_throttle/main/docs/images/demo_search_debounce.gif) | ![Throttle](https://raw.githubusercontent.com/brewkits/flutter_debounce_throttle/main/docs/images/demo_throttle_antispam.gif) | ![Submit](https://raw.githubusercontent.com/brewkits/flutter_debounce_throttle/main/docs/images/demo_async_submit.gif) |

---

## 🚀 Honest API — No Silent Failures

Most libraries return `void`, causing "silent failures" where dropped operations appear to succeed. This library introduces **ThrottlerResult** and **DebounceResult** to ensure your code handles every outcome.

```dart
// ✅ compiler forces handling of both branches
final result = await throttler.call(() async => await submitOrder(orderId));

result.when(
  onExecuted: () => showSuccessDialog(),
  onDropped:  () => showError('Server busy — please try again.'),
);
```

---

## 30-Second Start

**Anti-Spam Button (1 line):**
```dart
ThrottledInkWell(onTap: () => processPayment(), child: Text('Pay \$99'))
```

**Debounced Search:**
```dart
final debouncer = Debouncer(duration: 300.ms);
TextField(onChanged: (s) => debouncer(() => search(s)))
```

**Async with loading state:**
```dart
AsyncThrottledBuilder(
  builder: (context, throttle, isLoading) => ElevatedButton(
    onPressed: throttle(() async => await submitForm()),
    child: Text(isLoading ? 'Submitting...' : 'Submit'),
  ),
)
```

**State management (Provider / Riverpod / GetX / Bloc):**
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

## Widgets

| Widget | Use Case |
|--------|----------|
| `ThrottledInkWell` | Button with ripple + throttle — prevent double-tap |
| `DebouncedQueryBuilder` | Search input with loading state & auto-cancel |
| `AsyncThrottledBuilder` | Async button with loading lock |
| `ConcurrentAsyncThrottledBuilder` | 4 concurrency modes (`drop`, `replace`, `enqueue`, `keepLatest`) |
| `ThrottledGestureDetector` | Drop-in `GestureDetector` replacement |
| `StreamDebounceListener` | Debounce stream events reactively |

---

## Installation

```yaml
dependencies:
  flutter_debounce_throttle: ^2.4.6
```

---

## Quality Assurance

| Guarantee | How |
|-----------|-----|
| **570+ tests** | Unit, integration, security, system, performance & stress tests |
| **98% coverage** | All edge cases and branches verified |
| **Honest API** | `ThrottlerResult` / `DebounceResult` — no silent failures |
| **Memory-safe** | Zero leaks verified with LeakTracker |
| **Architecture-neutral** | `mixin` not `extends` — works with any framework |

---

<p align="center">
  <a href="https://github.com/brewkits/flutter_debounce_throttle">GitHub</a> ·
  <a href="https://github.com/brewkits/flutter_debounce_throttle/blob/main/FAQ.md">FAQ</a> ·
  <a href="https://github.com/brewkits/flutter_debounce_throttle/blob/main/docs/API_REFERENCE.md">API Reference</a> ·
  <a href="https://github.com/brewkits/flutter_debounce_throttle/blob/main/docs/BEST_PRACTICES.md">Best Practices</a>
</p>

<p align="center">
  Made with craftsmanship by <a href="https://github.com/brewkits">Brewkits</a>
</p>
