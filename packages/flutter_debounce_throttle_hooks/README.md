# flutter_debounce_throttle_hooks

Flutter Hooks integration for flutter_debounce_throttle. Auto-dispose debounce and throttle controllers with HookWidget.

## Installation

```yaml
dependencies:
  flutter_debounce_throttle_hooks: ^1.0.0
  flutter_hooks: ^0.20.0
```

## Quick Start

```dart
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_debounce_throttle_hooks/flutter_debounce_throttle_hooks.dart';

class SearchWidget extends HookWidget {
  @override
  Widget build(BuildContext context) {
    // Auto-dispose when widget unmounts
    final debouncer = useDebouncer(duration: Duration(milliseconds: 300));
    final throttler = useThrottler(duration: Duration(milliseconds: 500));

    // Convenient callback hooks
    final debouncedSearch = useDebouncedCallback<String>(
      (text) => searchApi(text),
      duration: Duration(milliseconds: 300),
    );

    return Column(
      children: [
        TextField(onChanged: debouncedSearch),
        ElevatedButton(
          onPressed: throttler.wrap(() => submit()),
          child: Text('Submit'),
        ),
      ],
    );
  }
}
```

## Available Hooks

### Basic Hooks
```dart
// Get controller instances (auto-dispose)
final debouncer = useDebouncer(duration: Duration(milliseconds: 300));
final throttler = useThrottler(duration: Duration(milliseconds: 500));
final asyncDebouncer = useAsyncDebouncer(duration: Duration(milliseconds: 300));
final asyncThrottler = useAsyncThrottler(maxDuration: Duration(seconds: 15));
```

### Callback Hooks
```dart
// Debounced callback
final debouncedSearch = useDebouncedCallback<String>(
  (text) => search(text),
  duration: Duration(milliseconds: 300),
);

// Throttled callback
final throttledSubmit = useThrottledCallback(
  () => submitForm(),
  duration: Duration(milliseconds: 500),
);
```

### Value Hooks
```dart
// Debounced value
final searchText = useState('');
final debouncedText = useDebouncedValue(searchText.value);

useEffect(() {
  if (debouncedText.isNotEmpty) {
    searchApi(debouncedText);
  }
  return null;
}, [debouncedText]);

// Throttled value (e.g., for scroll)
final scrollOffset = useState(0.0);
final throttledOffset = useThrottledValue(
  scrollOffset.value,
  duration: Duration(milliseconds: 16), // ~60fps
);
```

## Complete Example

```dart
class AutocompleteSearch extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final searchText = useState('');
    final results = useState<List<String>>([]);
    final isLoading = useState(false);

    final asyncDebouncer = useAsyncDebouncer(
      duration: Duration(milliseconds: 300),
    );

    Future<void> handleSearch(String text) async {
      searchText.value = text;
      if (text.isEmpty) {
        results.value = [];
        return;
      }

      isLoading.value = true;
      final result = await asyncDebouncer.run(() async {
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
            itemBuilder: (_, i) => ListTile(title: Text(results.value[i])),
          ),
        ),
      ],
    );
  }
}
```

## Related Packages

- [flutter_debounce_throttle_core](https://pub.dev/packages/flutter_debounce_throttle_core) - Pure Dart
- [flutter_debounce_throttle](https://pub.dev/packages/flutter_debounce_throttle) - Flutter widgets + mixin
