# flutter_debounce_throttle_riverpod

[![pub package](https://img.shields.io/pub/v/flutter_debounce_throttle_riverpod.svg)](https://pub.dev/packages/flutter_debounce_throttle_riverpod)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

Riverpod integration for [flutter_debounce_throttle](https://pub.dev/packages/flutter_debounce_throttle).  
`EventLimiterController` ties debounce/throttle timers to a Riverpod `Ref` lifecycle — zero boilerplate, auto-cleanup on provider dispose.

| Debounced Search Notifier | Provider Auto-Dispose |
|:---:|:---:|
| ![Riverpod Search](https://raw.githubusercontent.com/brewkits/flutter_debounce_throttle/main/docs/images/demo_riverpod_debounce.gif) | ![Auto-Dispose](https://raw.githubusercontent.com/brewkits/flutter_debounce_throttle/main/docs/images/demo_riverpod_autodispose.gif) |

---

## Why this package?

Most debounce/throttle solutions either cause memory leaks (manual `Timer`) or require 20+ lines of boilerplate in your `Notifier`. This package reduces it to **1 line** while ensuring perfect memory safety.

---

## Installation

```yaml
dependencies:
  flutter_debounce_throttle_riverpod: ^1.0.0
```

---

## Quick start

### Notifier (recommended)

```dart
@riverpod
class SearchNotifier extends _$SearchNotifier {
  late final EventLimiterController _limiter;

  @override
  SearchState build() {
    // ✅ 1 line: auto-disposes with provider
    _limiter = ref.eventLimiter(); 
    return SearchState.initial();
  }

  void onSearch(String query) {
    _limiter.debounce('search', () async {
      state = SearchState.loading();
      state = SearchState.data(await api.search(query));
    });
  }
}
```

---

## Quality Assurance

| Guarantee | How |
|-----------|-----|
| **570+ tests** | Battle-tested core (verified in all UI packages) |
| **Lifecycle-safe** | Tied to `Ref.onDispose()` — zero manual cleanup |
| **Async Support** | Handles Futures, cancellation, and race conditions |

---

## Which Package?

| You are building... | Package |
|---------------------|---------|
| Flutter app + **Riverpod** | **`flutter_debounce_throttle_riverpod`** ← you are here |
| Flutter app + hooks | [`flutter_debounce_throttle_hooks`](https://pub.dev/packages/flutter_debounce_throttle_hooks) |
| Flutter app (most users) | [`flutter_debounce_throttle`](https://pub.dev/packages/flutter_debounce_throttle) |

---

<p align="center">
  <a href="https://github.com/brewkits/flutter_debounce_throttle">GitHub</a> ·
  <a href="https://github.com/brewkits/flutter_debounce_throttle/blob/main/FAQ.md">FAQ</a> ·
  <a href="https://github.com/brewkits/flutter_debounce_throttle/blob/main/docs/API_REFERENCE.md">API Reference</a>
</p>

<p align="center">
  Made with craftsmanship by <a href="https://github.com/brewkits">Brewkits</a>
</p>
