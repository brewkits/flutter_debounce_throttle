# flutter_debounce_throttle_riverpod

[![pub package](https://img.shields.io/pub/v/flutter_debounce_throttle_riverpod.svg)](https://pub.dev/packages/flutter_debounce_throttle_riverpod)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Riverpod integration for [flutter_debounce_throttle](https://pub.dev/packages/flutter_debounce_throttle).  
`EventLimiterController` ties debounce/throttle timers to a Riverpod `Ref` lifecycle — zero boilerplate, auto-cleanup on provider dispose.

| Debounced Search Notifier | Provider Auto-Dispose |
|:---:|:---:|
| ![Riverpod Search](https://raw.githubusercontent.com/brewkits/flutter_debounce_throttle/main/docs/images/demo_riverpod_debounce.gif) | ![Auto-Dispose](https://raw.githubusercontent.com/brewkits/flutter_debounce_throttle/main/docs/images/demo_riverpod_autodispose.gif) |

---

## Installation

```yaml
dependencies:
  flutter_debounce_throttle_riverpod: ^1.0.0
```

---

## Quick start

```dart
import 'package:flutter_debounce_throttle_riverpod/flutter_debounce_throttle_riverpod.dart';
```

### Notifier (recommended)

```dart
@riverpod
class SearchNotifier extends _$SearchNotifier {
  late final EventLimiterController _limiter;

  @override
  SearchState build() {
    _limiter = ref.eventLimiter(); // auto-disposes with provider
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

### AsyncNotifier

```dart
@riverpod
class OrderNotifier extends _$OrderNotifier {
  late final EventLimiterController _limiter;

  @override
  Future<Order?> build() async {
    _limiter = ref.eventLimiter();
    return null;
  }

  Future<void> submitOrder(Order order) async {
    final result = await _limiter.debounceAsyncResult<Order>(
      'submit',
      () async => api.submit(order),
    );
    result.when(
      onSuccess: (order) => state = AsyncData(order),
      onCancelled: () {}, // stale — ignore
    );
  }
}
```

### ConsumerStatefulWidget (standalone)

```dart
class _SearchPageState extends ConsumerState<SearchPage> {
  late final EventLimiterController _limiter;

  @override
  void initState() {
    super.initState();
    _limiter = EventLimiterController.standalone();
  }

  @override
  void dispose() {
    _limiter.dispose();
    super.dispose();
  }

  void _onQueryChanged(String q) {
    _limiter.debounce('search', () => ref.read(searchProvider.notifier).search(q));
  }
}
```

---

## API

### `EventLimiterController`

| Method | Description |
|---|---|
| `debounce(id, action, {duration})` | Debounce by key — last call within duration wins |
| `throttle(id, action, {duration})` | Throttle by key — first call executes, rest drop |
| `debounceAsync<T>(id, action, {duration})` | Async debounce — returns `T?` (`null` = cancelled) |
| `debounceAsyncResult<T>(id, action, {duration})` | Async debounce — returns `DebounceResult<T>` (distinguishes null from cancellation) |
| `throttleAsync(id, action, {maxDuration})` | Async throttle — ignores concurrent calls while locked |
| `cancel(id)` | Cancel and remove limiter with `id` |
| `cancelAll()` | Cancel all pending operations |
| `dispose()` | Cancel all and mark disposed (standalone usage) |
| `isActive(id)` | Whether a limiter with `id` is currently active |

### `Ref.eventLimiter()`

Extension method on `Ref`. Equivalent to `EventLimiterController(ref)`.

---

## Why a separate package?

Riverpod's `Notifier<T>` and `AsyncNotifier<T>` classes don't share a Flutter-mixin-compatible base, so the `EventLimiterMixin` from `flutter_debounce_throttle` can't be applied directly. This package provides the equivalent functionality through a composable controller that hooks into `Ref.onDispose()`.

For non-Riverpod state management (Provider, GetX, BLoC, MobX), use `EventLimiterMixin` from the main [`flutter_debounce_throttle`](https://pub.dev/packages/flutter_debounce_throttle) package instead.

---

## License

MIT — see [LICENSE](LICENSE)
