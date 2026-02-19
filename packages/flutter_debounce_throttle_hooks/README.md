# flutter_debounce_throttle_hooks

[![pub package](https://img.shields.io/pub/v/flutter_debounce_throttle_hooks.svg)](https://pub.dev/packages/flutter_debounce_throttle_hooks)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![GitHub stars](https://img.shields.io/github/stars/brewkits/flutter_debounce_throttle?style=social)](https://github.com/brewkits/flutter_debounce_throttle/stargazers)

## The Traffic Control System — Hooks Edition

> No dispose. No initState. No boilerplate. Just hooks.

All the power of [flutter_debounce_throttle](https://pub.dev/packages/flutter_debounce_throttle) — debounce, throttle, async cancellation, race condition control — with **automatic lifecycle management** the hooks way.

```dart
class SearchWidget extends HookWidget {
  Widget build(BuildContext context) {
    // One line. Auto-cleanup on unmount. Zero boilerplate.
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

| With StatefulWidget | With Hooks |
|---------------------|------------|
| `late Debouncer _debouncer;` | - |
| `@override initState() { ... }` | - |
| `@override dispose() { _debouncer.dispose(); }` | - |
| 15+ lines of boilerplate | **1 line** |

```dart
// StatefulWidget way (15+ lines)
class _SearchState extends State<Search> {
  late Debouncer _debouncer;

  @override
  void initState() {
    super.initState();
    _debouncer = Debouncer(duration: Duration(ms: 300));
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }
  // ...
}

// Hooks way (1 line)
final debouncer = useDebouncer(duration: 300.ms);
```

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

**Debounced Value:**
```dart
final searchText = useState('');
final debouncedText = useDebouncedValue(searchText.value, duration: 300.ms);

useEffect(() {
  if (debouncedText.isNotEmpty) api.search(debouncedText);
  return null;
}, [debouncedText]);
```

---

## Available Hooks

| Hook | Returns | Use Case |
|------|---------|----------|
| `useDebouncedCallback<T>` | `void Function(T)` | Search input, form validation |
| `useThrottledCallback` | `VoidCallback` | Button spam prevention |
| `useDebouncedValue<T>` | `T` | Reactive debounced value |
| `useThrottledValue<T>` | `T` | Reactive throttled value |
| `useDebouncer` | `Debouncer` | Direct controller access |
| `useThrottler` | `Throttler` | Direct controller access |
| `useAsyncDebouncer` | `AsyncDebouncer` | Async with auto-cancel |
| `useAsyncThrottler` | `AsyncThrottler` | Async with lock |

---

## Complete Example

```dart
class AutocompleteSearch extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final results = useState<List<String>>([]);
    final isLoading = useState(false);

    // Auto-dispose on unmount. No cleanup needed.
    final asyncDebouncer = useAsyncDebouncer(duration: 300.ms);

    Future<void> handleSearch(String text) async {
      if (text.isEmpty) {
        results.value = [];
        return;
      }

      isLoading.value = true;

      // Old requests are automatically cancelled
      final result = await asyncDebouncer(() async {
        return await api.search(text);
      });

      if (result != null) {
        results.value = result;
      }
      isLoading.value = false;
    }

    return Column(
      children: [
        TextField(
          onChanged: handleSearch,
          decoration: InputDecoration(
            suffixIcon: isLoading.value
                ? CircularProgressIndicator()
                : Icon(Icons.search),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: results.value.length,
            itemBuilder: (_, i) => ListTile(
              title: Text(results.value[i]),
            ),
          ),
        ),
      ],
    );
  }
}
```

---

## Installation

```yaml
dependencies:
  flutter_debounce_throttle_hooks: ^2.4.4
  flutter_hooks: ^0.21.3
```

---

## Quality Assurance

| Guarantee | How |
|-----------|-----|
| **Type-safe** | Full generic support with 8 production-ready hooks |
| **Memory-safe** | Auto-cleanup on unmount |
| **Lifecycle-aware** | No manual dispose needed |
| **Battle-tested** | Built on flutter_debounce_throttle (450+ tests) |

---

## Which Package Should I Use?

| You are building... | Package |
|---------------------|---------|
| Flutter app + `flutter_hooks` | **`flutter_debounce_throttle_hooks`** ← you are here |
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
