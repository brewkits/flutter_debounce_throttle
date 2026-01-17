# flutter_debounce_throttle_hooks

[![pub package](https://img.shields.io/pub/v/flutter_debounce_throttle_hooks.svg)](https://pub.dev/packages/flutter_debounce_throttle_hooks)

## Event Rate Limiting Hooks — Zero Boilerplate, Full Power

The **flutter_hooks integration** for [flutter_debounce_throttle](https://pub.dev/packages/flutter_debounce_throttle). All the enterprise-grade debounce, throttle, and async concurrency control — with automatic lifecycle management the hooks way.

**No dispose. No state classes. Just works.**

```dart
class SearchWidget extends HookWidget {
  Widget build(BuildContext context) {
    // Automatic cleanup on unmount — zero boilerplate
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

| Feature | Benefit |
|---------|---------|
| **Zero boilerplate** | No dispose, no initState, no state management |
| **Automatic cleanup** | Unmount = auto-cancel pending operations |
| **Reactive values** | `useDebouncedValue`, `useThrottledValue` |
| **Full ecosystem** | Access to all core controllers and modes |

---

## Installation

```yaml
dependencies:
  flutter_debounce_throttle_hooks: ^1.1.0
  flutter_hooks: ^0.21.0
```

---

## Quick Start

### Debounced Callback
```dart
final debouncedSearch = useDebouncedCallback<String>(
  (text) => api.search(text),
  duration: Duration(milliseconds: 300),
);

TextField(onChanged: debouncedSearch)
```

### Throttled Callback
```dart
final throttledSubmit = useThrottledCallback(
  () => submitForm(),
  duration: Duration(milliseconds: 500),
);

ElevatedButton(onPressed: throttledSubmit, child: Text('Submit'))
```

### Debounced Value
```dart
final searchText = useState('');
final debouncedText = useDebouncedValue(
  searchText.value,
  duration: Duration(milliseconds: 300),
);

useEffect(() {
  if (debouncedText.isNotEmpty) {
    api.search(debouncedText);
  }
  return null;
}, [debouncedText]);
```

---

## Available Hooks

| Hook | Returns | Use Case |
|------|---------|----------|
| `useDebouncer` | `Debouncer` | Direct controller access |
| `useThrottler` | `Throttler` | Direct controller access |
| `useAsyncDebouncer` | `AsyncDebouncer` | Async with cancellation |
| `useAsyncThrottler` | `AsyncThrottler` | Async with lock |
| `useDebouncedCallback<T>` | `void Function(T)` | Debounced callback |
| `useThrottledCallback` | `VoidCallback` | Throttled callback |
| `useDebouncedValue<T>` | `T` | Reactive debounced value |
| `useThrottledValue<T>` | `T` | Reactive throttled value |

---

## Complete Example

```dart
class AutocompleteSearch extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final results = useState<List<String>>([]);
    final isLoading = useState(false);

    final asyncDebouncer = useAsyncDebouncer(duration: 300.ms);

    Future<void> handleSearch(String text) async {
      if (text.isEmpty) {
        results.value = [];
        return;
      }

      isLoading.value = true;
      final result = await asyncDebouncer(() async => await api.search(text));

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
            itemBuilder: (_, i) => ListTile(title: Text(results.value[i])),
          ),
        ),
      ],
    );
  }
}
```

---

## v1.1.0 Features

```dart
// Duration extensions work with hooks too
final debouncer = useDebouncer(duration: 300.ms);
final throttler = useThrottler(duration: 500.ms);

// All core features available
final debouncedValue = useDebouncedValue(value, duration: 300.ms);
```

---

## Related Packages

| Package | Use When |
|---------|----------|
| [flutter_debounce_throttle](https://pub.dev/packages/flutter_debounce_throttle) | Flutter without hooks |
| [flutter_debounce_throttle_core](https://pub.dev/packages/flutter_debounce_throttle_core) | Pure Dart (Server/CLI) |

---

<p align="center">
  <a href="https://github.com/brewkits/flutter_debounce_throttle">GitHub</a> ·
  <a href="https://github.com/brewkits/flutter_debounce_throttle/blob/main/docs/API_REFERENCE.md">API Reference</a>
</p>
