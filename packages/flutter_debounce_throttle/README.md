# flutter_debounce_throttle

The Safe, Unified & Universal Event Limiter for Flutter. Debounce, throttle, and rate limit with automatic lifecycle management.

## Installation

```yaml
dependencies:
  flutter_debounce_throttle: ^1.0.0
```

## Quick Start

### Button Anti-spam
```dart
ThrottledInkWell(
  duration: Duration(milliseconds: 500),
  onTap: () => submit(),
  child: MyButton(),
)
```

### Search Input with Loading
```dart
AsyncDebouncedCallbackBuilder<List<User>>(
  duration: Duration(milliseconds: 300),
  onChanged: (text) async => await searchApi(text),
  onSuccess: (results) => setState(() => _results = results),
  onError: (e, stack) => showError(e),
  builder: (context, callback, isLoading) => TextField(
    onChanged: callback,
    decoration: InputDecoration(
      suffixIcon: isLoading
        ? CircularProgressIndicator()
        : Icon(Icons.search),
    ),
  ),
)
```

### State Management with Mixin
```dart
class SearchProvider extends ChangeNotifier with EventLimiterMixin {
  List<User> _results = [];

  void onSearch(String text) {
    debounce('search', () async {
      _results = await api.search(text);
      notifyListeners();
    });
  }

  @override
  void dispose() {
    cancelAllLimiters(); // IMPORTANT!
    super.dispose();
  }
}
```

## Available Widgets

### Callback Widgets
- `ThrottledCallback` / `DebouncedCallback`
- `ThrottledBuilder` / `DebouncedBuilder`
- `AsyncThrottledBuilder` / `AsyncDebouncedBuilder`
- `AsyncThrottledCallbackBuilder` / `AsyncDebouncedCallbackBuilder`
- `ConcurrentAsyncThrottledBuilder`

### Tap Widgets
- `ThrottledInkWell` - Throttled tap with ripple effect
- `ThrottledTapWidget` - Throttled tap without ripple
- `DebouncedTapWidget` - Debounced tap

### Stream Listeners
- `StreamSafeListener` - Auto-cancel on dispose
- `StreamDebounceListener` - Debounced stream events
- `StreamThrottleListener` - Throttled stream events

### Controllers
- `DebouncedTextController` - TextField with debounce
- `AsyncDebouncedTextController` - Async TextField with loading state

## Mixin for State Management

Works with Provider, GetX, Bloc, MobX, and more:

```dart
// Provider
class MyProvider extends ChangeNotifier with EventLimiterMixin { ... }

// GetX
class MyController extends GetxController with EventLimiterMixin { ... }

// Bloc
class MyBloc extends Bloc<E, S> with EventLimiterMixin { ... }
```

## Related Packages

- [flutter_debounce_throttle_core](https://pub.dev/packages/flutter_debounce_throttle_core) - Pure Dart (no Flutter)
- [flutter_debounce_throttle_hooks](https://pub.dev/packages/flutter_debounce_throttle_hooks) - Flutter Hooks
