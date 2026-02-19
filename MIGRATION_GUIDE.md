# Migration Guide

How to migrate from other libraries to `flutter_debounce_throttle`.

---

## From `easy_debounce`

### API Changes

#### 1. Basic Debounce

**easy_debounce:**
```dart
import 'package:easy_debounce/easy_debounce.dart';

EasyDebounce.debounce(
  'my-debouncer',
  Duration(milliseconds: 500),
  () => print('Debounced!'),
);

// Cancel
EasyDebounce.cancel('my-debouncer');
```

**flutter_debounce_throttle:**
```dart
import 'package:flutter_debounce_throttle/flutter_debounce_throttle.dart';

// Option 1: Mixin (Recommended)
class MyController with EventLimiterMixin {
  void onSearch() {
    debounce('my-debouncer', () => print('Debounced!'),
      duration: Duration(milliseconds: 500));
  }

  @override
  void dispose() {
    cancel('my-debouncer'); // or cancelAll()
    super.dispose();
  }
}

// Option 2: Debouncer directly
final debouncer = Debouncer(duration: Duration(milliseconds: 500));
debouncer.call(() => print('Debounced!'));
debouncer.dispose();
```

#### 2. Async Debounce

**easy_debounce:**
```dart
// No direct async support
EasyDebounce.debounce(
  'search',
  Duration(milliseconds: 500),
  () async {
    final results = await api.search(query);
    // Manual result handling
  },
);
```

**flutter_debounce_throttle:**
```dart
// Option 1: Mixin (Recommended)
class SearchController with EventLimiterMixin {
  Future<void> onSearch(String query) async {
    final results = await debounceAsync(
      'search',
      () => api.search(query),
      duration: Duration(milliseconds: 500),
    );

    if (results != null) {
      // null means cancelled — stale request discarded automatically
      updateResults(results);
    }
  }
}

// Option 2: AsyncDebouncer
final debouncer = AsyncDebouncer(duration: Duration(milliseconds: 500));
final results = await debouncer(() async => api.search(query));
if (results != null) {
  updateResults(results);
}
```

### Benefits of Switching

| Feature | easy_debounce | flutter_debounce_throttle |
|---------|---------------|---------------------------|
| Async support | ❌ | ✅ Auto-cancel stale requests |
| Type safety | ⚠️ String ID only | ✅ Generic types |
| Lifecycle safe | ❌ Manual | ✅ Auto dispose |
| Loading state | ❌ | ✅ Built-in |
| Throttle support | ❌ | ✅ |
| Stream support | ❌ | ✅ |
| Hooks support | ❌ | ✅ |
| Server-side | ❌ | ✅ Pure Dart |

---

## From Manual `Timer`

### Before (Manual Timer)

```dart
class SearchWidget extends StatefulWidget {
  @override
  _SearchWidgetState createState() => _SearchWidgetState();
}

class _SearchWidgetState extends State<SearchWidget> {
  Timer? _debounceTimer;

  void _onSearchChanged(String query) {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Start new timer
    _debounceTimer = Timer(Duration(milliseconds: 500), () {
      // BUG: no mounted check!
      setState(() {
        // search logic
      });
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel(); // Easy to forget!
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(onChanged: _onSearchChanged);
  }
}
```

### After (flutter_debounce_throttle)

#### Option 1: Widget-based (Simplest)

```dart
class SearchWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DebouncedBuilder(
      duration: Duration(milliseconds: 500),
      builder: (context, debounce) => TextField(
        onChanged: (query) => debounce(() {
          // Mounted check is automatic
          // search logic
        })?.call(),
      ),
    );
  }
}
// No dispose needed — handled automatically.
```

#### Option 2: Controller-based

```dart
class SearchController with ChangeNotifier, EventLimiterMixin {
  void onSearch(String query) {
    debounce('search', () {
      // search logic
    }, duration: Duration(milliseconds: 500));
  }

  @override
  void dispose() {
    cancelAll(); // One line cleans up everything
    super.dispose();
  }
}
```

### Problems Solved

| Manual Timer Problem | flutter_debounce_throttle |
|----------------------|---------------------------|
| Forgetting cancel → Memory leak | ✅ Auto dispose |
| Missing mounted check → Crash | ✅ Auto mounted check |
| Boilerplate code | ✅ One-liner |
| Hard to test | ✅ Easy to test with Mixin |
| No loading state | ✅ Built-in isLoading |

---

## From `rxdart`

### Before (rxdart)

```dart
import 'package:rxdart/rxdart.dart';

class SearchBloc {
  final _searchController = BehaviorSubject<String>();
  late final Stream<List<User>> results;

  SearchBloc() {
    results = _searchController
        .debounceTime(Duration(milliseconds: 500))
        .distinct()
        .switchMap((query) => _searchApi(query))
        .handleError((error) {
          // error handling
        });
  }

  void search(String query) => _searchController.add(query);

  Stream<List<User>> _searchApi(String query) async* {
    yield await api.search(query);
  }

  void dispose() {
    _searchController.close();
  }
}
```

### After (flutter_debounce_throttle)

```dart
import 'package:flutter_debounce_throttle/flutter_debounce_throttle.dart';

class SearchBloc with EventLimiterMixin {
  List<User> results = [];
  bool isLoading = false;

  Future<void> search(String query) async {
    isLoading = true;
    notifyListeners(); // or emit()

    final result = await debounceAsync(
      'search',
      () => api.search(query),
      duration: Duration(milliseconds: 500),
    );

    if (result != null) {
      results = result;
      isLoading = false;
      notifyListeners();
    }
  }

  void dispose() {
    cancelAll();
    super.dispose();
  }
}
```

### When to Use Each

- **Use rxdart when:** You need full reactive programming — `combineLatest`, `merge`, `zip`, complex stream transformations.
- **Use flutter_debounce_throttle when:** You need debounce/throttle for UI events, lifecycle-safe async, or rate limiting without reactive overhead.
- **Use both:** rxdart for the data layer, flutter_debounce_throttle for the UI layer.

---

## From Custom Throttle Implementation

### Before (Custom)

```dart
class ThrottledButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Duration throttleDuration;

  const ThrottledButton({
    required this.onPressed,
    this.throttleDuration = const Duration(milliseconds: 500),
  });

  @override
  _ThrottledButtonState createState() => _ThrottledButtonState();
}

class _ThrottledButtonState extends State<ThrottledButton> {
  bool _isThrottling = false;
  Timer? _timer;

  void _handlePress() {
    if (_isThrottling) return;

    setState(() => _isThrottling = true);
    widget.onPressed();

    _timer = Timer(widget.throttleDuration, () {
      if (mounted) {
        setState(() => _isThrottling = false);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _isThrottling ? null : _handlePress,
      child: Text('Submit'),
    );
  }
}
```

### After (flutter_debounce_throttle)

```dart
import 'package:flutter_debounce_throttle/flutter_debounce_throttle.dart';

// Option 1: ThrottledInkWell (drop-in, 1 line)
ThrottledInkWell(
  duration: Duration(milliseconds: 500),
  onTap: () => print('Throttled tap!'),
  child: Container(
    padding: EdgeInsets.all(16),
    child: Text('Submit'),
  ),
)

// Option 2: ThrottledBuilder (more flexible)
ThrottledBuilder(
  duration: Duration(milliseconds: 500),
  builder: (context, throttle) => ElevatedButton(
    onPressed: throttle(() => print('Throttled!')),
    child: Text('Submit'),
  ),
)
```

---

## Migration Checklist

### Step 1: Install

```yaml
dependencies:
  flutter_debounce_throttle: ^2.4.4
```

### Step 2: Update imports

```dart
// Remove
// import 'package:easy_debounce/easy_debounce.dart';

// Add
import 'package:flutter_debounce_throttle/flutter_debounce_throttle.dart';
```

### Step 3: Update code

**In a Controller / ViewModel:**
```dart
class MyController extends ChangeNotifier
    with EventLimiterMixin { // Add mixin

  void onAction() {
    debounce('action-id', () {
      // logic
    });
  }

  @override
  void dispose() {
    cancelAll(); // Add this line
    super.dispose();
  }
}
```

**In a Widget:**
```dart
// Replace Timer logic with DebouncedBuilder or ThrottledBuilder
```

### Step 4: Verify

- Run the app — no crashes
- Navigate back and forth — no memory leaks
- Test hot reload

---

## Troubleshooting

### "setState() called after dispose()"

**Cause:** Callback fires after widget has been disposed.

```dart
// Bad
debouncer.run(() {
  setState(() {}); // May crash
});

// Good
debouncer.call(() {
  if (mounted) {
    setState(() {});
  }
});

// Best: Use DebouncedBuilder (auto-checks mounted)
DebouncedBuilder(
  builder: (context, debounce) => ...,
)
```

### Memory leak with dynamic IDs

**Cause:** Forgetting to dispose when using dynamic IDs.

```dart
@override
void dispose() {
  cancelAll(); // Required!
  super.dispose();
}
```

---

## Resources

- [API Reference](https://pub.dev/documentation/flutter_debounce_throttle/latest/)
- [Examples](https://github.com/brewkits/flutter_debounce_throttle/tree/main/example)
- [GitHub Issues](https://github.com/brewkits/flutter_debounce_throttle/issues)
- [FAQ](https://github.com/brewkits/flutter_debounce_throttle/blob/main/FAQ.md)

If you run into issues during migration, open a [New Issue](https://github.com/brewkits/flutter_debounce_throttle/issues/new) with the `migration` label.
