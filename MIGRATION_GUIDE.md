# Migration Guide

Hướng dẫn di chuyển từ các thư viện khác sang `flutter_debounce_throttle`.

---

## 📦 Từ `easy_debounce`

### Thay đổi API

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

// Option 1: Sử dụng Mixin (Recommended)
class MyController with EventLimiterMixin {
  void onSearch() {
    debounce('my-debouncer', () => print('Debounced!'),
      duration: Duration(milliseconds: 500));
  }

  @override
  void dispose() {
    cancel('my-debouncer'); // Hoặc cancelAll()
    super.dispose();
  }
}

// Option 2: Sử dụng Debouncer trực tiếp
final debouncer = Debouncer(duration: Duration(milliseconds: 500));
debouncer.call(() => print('Debounced!'));
debouncer.dispose();
```

#### 2. Async Debounce

**easy_debounce:**
```dart
// Không hỗ trợ trực tiếp
EasyDebounce.debounce(
  'search',
  Duration(milliseconds: 500),
  () async {
    final results = await api.search(query);
    // Xử lý kết quả thủ công
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
      // Xử lý kết quả (null = cancelled)
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

### Lợi ích khi chuyển

| Tính năng | easy_debounce | flutter_debounce_throttle |
|-----------|---------------|---------------------------|
| Async support | ❌ | ✅ Auto-cancel |
| Type safety | ⚠️ String ID | ✅ Generic types |
| Lifecycle safe | ❌ Manual | ✅ Auto dispose |
| Loading state | ❌ | ✅ Built-in |
| Throttle support | ❌ | ✅ |
| Stream support | ❌ | ✅ |
| Hooks support | ❌ | ✅ |
| Server-side | ❌ | ✅ Pure Dart Core |

---

## 📦 Từ Manual `Timer`

### Trước (Manual Timer)

```dart
class SearchWidget extends StatefulWidget {
  @override
  _SearchWidgetState createState() => _SearchWidgetState();
}

class _SearchWidgetState extends State<SearchWidget> {
  Timer? _debounceTimer;

  void _onSearchChanged(String query) {
    // Cancel timer cũ
    _debounceTimer?.cancel();

    // Tạo timer mới
    _debounceTimer = Timer(Duration(milliseconds: 500), () {
      // BUG POTENTIAL: Không check mounted!
      setState(() {
        // Search logic
      });
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel(); // Dễ quên!
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(onChanged: _onSearchChanged);
  }
}
```

### Sau (flutter_debounce_throttle)

#### Option 1: Widget-based (Simplest)

```dart
class SearchWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DebouncedBuilder(
      duration: Duration(milliseconds: 500),
      builder: (context, debounce) => TextField(
        onChanged: (query) => debounce(() {
          // Tự động check mounted!
          // Search logic
        })?.call(),
      ),
    );
  }
}
// Không cần dispose! Tự động xử lý.
```

#### Option 2: Controller-based

```dart
class SearchController with ChangeNotifier, EventLimiterMixin {
  void onSearch(String query) {
    debounce('search', () {
      // Search logic
    }, duration: Duration(milliseconds: 500));
  }

  @override
  void dispose() {
    cancelAll(); // Một dòng clean up tất cả!
    super.dispose();
  }
}
```

### Lợi ích

| Vấn đề với Manual Timer | flutter_debounce_throttle |
|--------------------------|---------------------------|
| Quên cancel → Memory leak | ✅ Auto dispose |
| Không check mounted → Crash | ✅ Auto mounted check |
| Boilerplate code | ✅ One-liner |
| Khó test | ✅ Dễ test với Mixin |
| Không có loading state | ✅ Built-in isLoading |

---

## 📦 Từ `rxdart` (Transform)

### Trước (RxDart)

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
          // Error handling
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

### Sau (flutter_debounce_throttle)

```dart
import 'package:flutter_debounce_throttle/flutter_debounce_throttle.dart';

class SearchBloc with EventLimiterMixin {
  List<User> results = [];
  bool isLoading = false;

  Future<void> search(String query) async {
    isLoading = true;
    notifyListeners(); // hoặc emit()

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

### Lưu ý

- **RxDart tốt cho:** Complex stream transformations, reactive programming
- **flutter_debounce_throttle tốt cho:** UI events, simple debouncing, lifecycle-aware operations
- **Có thể kết hợp:** Dùng RxDart cho data layer, dùng flutter_debounce_throttle cho UI layer

---

## 📦 Từ Custom Throttle Implementation

### Trước (Custom)

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

### Sau (flutter_debounce_throttle)

```dart
import 'package:flutter_debounce_throttle/flutter_debounce_throttle.dart';

// Option 1: ThrottledInkWell (Built-in)
ThrottledInkWell(
  duration: Duration(milliseconds: 500),
  onTap: () => print('Throttled tap!'),
  child: Container(
    padding: EdgeInsets.all(16),
    child: Text('Submit'),
  ),
)

// Option 2: ThrottledBuilder (More flexible)
ThrottledBuilder(
  duration: Duration(milliseconds: 500),
  builder: (context, throttle) => ElevatedButton(
    onPressed: throttle(() => print('Throttled!')),
    child: Text('Submit'),
  ),
)
```

---

## 🎯 Checklist Di Chuyển

### Bước 1: Cài đặt
```yaml
dependencies:
  flutter_debounce_throttle: ^1.0.0
```

### Bước 2: Import mới
```dart
// Xóa
// import 'package:easy_debounce/easy_debounce.dart';

// Thêm
import 'package:flutter_debounce_throttle/flutter_debounce_throttle.dart';
```

### Bước 3: Update code

**Nếu dùng trong Controller/ViewModel:**
```dart
class MyController extends ChangeNotifier
    with EventLimiterMixin { // Thêm mixin

  void onAction() {
    debounce('action-id', () {
      // Logic
    });
  }

  @override
  void dispose() {
    cancelAll(); // Thêm dòng này!
    super.dispose();
  }
}
```

**Nếu dùng trong Widget:**
```dart
// Replace Timer logic với DebouncedBuilder hoặc ThrottledBuilder
```

### Bước 4: Test
- ✅ Chạy app, verify không có crash
- ✅ Test memory leak (navigate back/forth)
- ✅ Test hot reload

---

## 🆘 Troubleshooting

### Lỗi: "Unhandled Exception: setState() called after dispose()"

**Nguyên nhân:** Callback được gọi sau khi widget đã dispose

**Giải pháp:**
```dart
// BAD
debouncer.run(() {
  setState(() {}); // Có thể crash!
});

// GOOD
debouncer.call(() {
  if (mounted) { // Check mounted
    setState(() {});
  }
});

// BEST: Dùng DebouncedBuilder (tự động check)
DebouncedBuilder(
  builder: (context, debounce) => ...,
)
```

### Lỗi: Memory leak

**Nguyên nhân:** Quên dispose

**Giải pháp:**
```dart
@override
void dispose() {
  cancelAll(); // IMPORTANT!
  super.dispose();
}
```

---

## 📚 Tài liệu thêm

- [API Reference](https://pub.dev/documentation/flutter_debounce_throttle/latest/)
- [Examples](https://github.com/brewkits/flutter_debounce_throttle/tree/main/example)
- [GitHub Issues](https://github.com/brewkits/flutter_debounce_throttle/issues)

---

## 💡 Cần trợ giúp?

Nếu gặp vấn đề trong quá trình migration, vui lòng:
1. Đọc [README](../README.md) và [Examples](../example)
2. Tìm trong [Closed Issues](https://github.com/brewkits/flutter_debounce_throttle/issues?q=is%3Aissue+is%3Aclosed)
3. Tạo [New Issue](https://github.com/brewkits/flutter_debounce_throttle/issues/new) với tag `migration`
