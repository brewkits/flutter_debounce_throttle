# flutter_debounce_throttle_hooks

[![pub package](https://img.shields.io/pub/v/flutter_debounce_throttle_hooks.svg)](https://pub.dev/packages/flutter_debounce_throttle_hooks)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![GitHub stars](https://img.shields.io/github/stars/brewkits/flutter_debounce_throttle?style=social)](https://github.com/brewkits/flutter_debounce_throttle/stargazers)

## The Traffic Control System — Hooks Edition

> No dispose. No initState. No boilerplate. Just hooks.

![Hooks Demo](https://raw.githubusercontent.com/brewkits/flutter_debounce_throttle/main/docs/images/demo_hooks_debounce.gif)

All the power of [flutter_debounce_throttle](https://pub.dev/packages/flutter_debounce_throttle) — debounce, throttle, async cancellation, race condition control — with **automatic lifecycle management** the hooks way.

```dart
class SearchWidget extends HookWidget {
  Widget build(BuildContext context) {
    // ✅ One line. Auto-cleanup on unmount. Zero boilerplate.
    final debouncedSearch = useDebouncedCallback<String>(
      (text) => api.search(text),
      duration: 300.ms,
    );

    return TextField(onChanged: debouncedSearch);
  }
}
```

---

## Why Hooks?

| Capability | StatefulWidget | Hooks Edition |
|------------|:---:|:---:|
| Memory Safe (Auto-dispose) | ✅ (Manual) | ✅ **Automatic** |
| Async Support | ✅ | ✅ |
| Boilerplate Lines | 15+ | **1** |
| Logic Reuse | ❌ Difficult | ✅ **High** |

---

## 5-Second Start

**Debounced Search:**
```dart
final debouncedSearch = useDebouncedCallback<String>(
  (text) => api.search(text),
  duration: 300.ms,
);
TextField(onChanged: debouncedSearch)
```

**Throttled Button:**
```dart
final throttledSubmit = useThrottledCallback(
  () => submitForm(),
  duration: 500.ms,
);
ElevatedButton(onPressed: throttledSubmit, child: Text('Submit'))
```

---

## Quality Assurance

| Guarantee | How |
|-----------|-----|
| **570+ tests** | Built on battle-tested core (100% verified) |
| **Type-safe** | Full generic support for all 8 production-ready hooks |
| **Memory-safe** | Automatic cleanup on unmount |
| **Battle-tested** | Zero boilerplate, zero leaks |

---

## Which Package?

| You are building... | Package |
|---------------------|---------|
| Flutter app + **hooks** | **`flutter_debounce_throttle_hooks`** ← you are here |
| Flutter app (no hooks) | [`flutter_debounce_throttle`](https://pub.dev/packages/flutter_debounce_throttle) |
| Dart server / CLI / Serverpod | [`dart_debounce_throttle`](https://pub.dev/packages/dart_debounce_throttle) |

---

<p align="center">
  <a href="https://github.com/brewkits/flutter_debounce_throttle">GitHub</a> ·
  <a href="https://github.com/brewkits/flutter_debounce_throttle/blob/main/FAQ.md">FAQ</a> ·
  <a href="https://github.com/brewkits/flutter_debounce_throttle/blob/main/docs/API_REFERENCE.md">API Reference</a>
</p>

<p align="center">
  Made with craftsmanship by <a href="https://github.com/brewkits">Brewkits</a>
</p>
