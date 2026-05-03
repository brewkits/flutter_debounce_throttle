# flutter_debounce_throttle

[![pub package](https://img.shields.io/pub/v/flutter_debounce_throttle.svg)](https://pub.dev/packages/flutter_debounce_throttle)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Tests](https://img.shields.io/badge/tests-450%2B%20passed-brightgreen)](https://github.com/brewkits/flutter_debounce_throttle)
[![Coverage](https://img.shields.io/badge/coverage-95%25-brightgreen)](https://github.com/brewkits/flutter_debounce_throttle)
[![GitHub stars](https://img.shields.io/github/stars/brewkits/flutter_debounce_throttle?style=social)](https://github.com/brewkits/flutter_debounce_throttle/stargazers)

## The Traffic Control System for Flutter Apps

> Stop using manual `Timer`. It causes memory leaks, crashes, and race conditions.

**All-in-one package** for debounce, throttle, rate limiting, and async concurrency control. Memory-safe, lifecycle-aware, and works with any state management solution.

| Debounced Search | Anti-Spam Button | Async Submit |
|:---:|:---:|:---:|
| ![Search](https://raw.githubusercontent.com/brewkits/flutter_debounce_throttle/main/docs/images/demo_search_debounce.gif) | ![Throttle](https://raw.githubusercontent.com/brewkits/flutter_debounce_throttle/main/docs/images/demo_throttle_antispam.gif) | ![Submit](https://raw.githubusercontent.com/brewkits/flutter_debounce_throttle/main/docs/images/demo_async_submit.gif) |

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

No setup. No dispose boilerplate. Auto-cleanup on widget unmount.

---

## Widgets

| Widget | Use Case |
|--------|----------|
| `ThrottledInkWell` | Button with ripple + throttle — prevent double-tap |
| `ThrottledBuilder` | Custom throttled widget |
| `DebouncedBuilder` | Custom debounced widget |
| `DebouncedQueryBuilder` | Search input with loading state |
| `AsyncThrottledBuilder` | Async button with loading lock |
| `ConcurrentAsyncThrottledBuilder` | 4 concurrency modes |
| `ThrottledGestureDetector` | Drop-in `GestureDetector` replacement |
| `StreamDebounceListener` | Debounce stream events |
| `StreamThrottleListener` | Throttle stream events |

---

## Architecture Compatibility

`EventLimiterMixin` is designed to be **non-intrusive** — it plugs into any state management pattern without imposing its own structure.

### MVVM (Provider / Riverpod / GetX)

Logic stays in ViewModel. View never touches a Timer.

```dart
// ✅ ViewModel owns all concurrency logic
class SearchViewModel extends ChangeNotifier with EventLimiterMixin {
  List<User> users = [];
  bool isLoading = false;

  void onSearch(String text) {
    debounce('search', () async {
      isLoading = true;
      notifyListeners();

      final result = await debounceAsync('search-api', () => api.search(text));
      result?.when(
        onSuccess: (data) { users = data ?? []; isLoading = false; },
        onCancelled: () { isLoading = false; },
      );
      notifyListeners();
    });
  }

  @override
  void dispose() { cancelAll(); super.dispose(); }
}
```

### MVI / BLoC

`when()` maps directly to `emit()` — the compiler rejects missing branches.

```dart
class SearchBloc extends Bloc<SearchEvent, SearchState> with EventLimiterMixin {
  SearchBloc() : super(SearchInitial()) {
    on<SearchQueryChanged>(_onQueryChanged);
  }

  Future<void> _onQueryChanged(SearchQueryChanged event, Emitter emit) async {
    final result = await debounceAsync(
      'search',
      () => api.search(event.query),
    );

    // Both branches required — compiler rejects incomplete handling
    result?.when(
      onSuccess:   (data) => emit(SearchLoaded(data ?? [])),
      onCancelled: ()     => emit(SearchIdle()),
    );
  }

  @override
  Future<void> close() { cancelAll(); return super.close(); }
}
```

### Micro-Frontend / Modular Architecture

The `dart_debounce_throttle` core is **pure Dart** — zero Flutter dependencies. Each module can import it at the Domain layer without bloating the widget tree or conflicting with other modules' UI frameworks.

```
┌─────────────────────────────────┐
│         Shell App               │  ← DebounceThrottleConfig.init() once here
├─────────────┬───────────────────┤
│  Feature A  │     Feature B     │  ← Each module uses EventLimiterMixin
│  (Provider) │     (BLoC)        │     independently, no shared state
├─────────────┴───────────────────┤
│     dart_debounce_throttle      │  ← Pure Dart core, safe to share
│     (Domain / Core layer)       │
└─────────────────────────────────┘
```

> **`DebounceThrottleConfig.init()`** is application-level config. Call it once in your Shell app's `main()`. Individual feature modules should not call it.

### Why `mixin` and not `extends`?

In modular apps, your classes often already extend a framework base class. `mixin` lets you add rate-limiting without touching your inheritance tree:

```dart
// ✅ Works — no inheritance conflict
class PaymentController extends GetxController with EventLimiterMixin { ... }
class SearchCubit extends Cubit<SearchState> with EventLimiterMixin { ... }
class UserService extends BaseService with EventLimiterMixin { ... }
```

---

## No Silent Failures

Most libraries return `void` — your code continues even when the operation was dropped.

```dart
// ❌ With void-returning API — silent failure
await throttler.call(() async => await submitOrder(orderId));
showSuccessDialog(); // Runs even if the order was NEVER submitted!

// ✅ ThrottlerResult forces you to handle both outcomes
(await throttler.call(() async => await submitOrder(orderId))).when(
  onExecuted: () => showSuccessDialog(),
  onDropped:  () => showError('Server busy — please try again.'),
);
```

`when()` requires **both branches**. The Dart compiler rejects code that silently ignores a dropped call.

---

## State Management Mixin

Works with **Provider, Bloc, GetX, Riverpod, MobX** — any class:

```dart
class SearchController with ChangeNotifier, EventLimiterMixin {
  List<User> users = [];

  void onSearch(String text) {
    debounce('search', () async {
      users = await api.search(text);
      notifyListeners();
    });
  }

  @override
  void dispose() {
    cancelAll();  // Cancels all timers and async operations
    super.dispose();
  }
}
```

> **⚠️ Dynamic IDs:** When using `debounce('post_$postId', ...)`, call `remove(id)` when items are deleted. For static IDs like `'search'`, `cancelAll()` in dispose is sufficient.

---

## Concurrency Modes

Handle race conditions in async operations with 4 strategies:

| Mode | Behavior | Use Case |
|------|----------|----------|
| `drop` | Ignore new while busy | Payment buttons |
| `replace` | Cancel old, run new | Search autocomplete |
| `enqueue` | Queue in order | Chat messages |
| `keepLatest` | Current + last only | Auto-save |

```dart
ConcurrentAsyncThrottledBuilder(
  mode: ConcurrencyMode.replace,  // Cancel stale API requests
  builder: (context, throttle, isLoading, pendingCount) => ...
)
```

---

## How It Works — Visualized

### Throttle vs Debounce (Duration: 300ms)

#### ➤ Throttle (Button Clicks)
Executes **immediately**, then **locks** for the duration. Subsequent events are **ignored**.

```
Events:    (Click1)    (Click2)    (Click3)              (Click4)
Time:      |─ 0ms ─────── 100ms ──── 200ms ──── 300ms ──── 400ms ──|
           ▼                                     ▲
Execution: [EXECUTE] ····················· [LOCKED/DROP] ······· [EXECUTE]
           └─────── 300ms cooldown ──────┘
```

**Use:** Payment buttons, save buttons, scroll handlers

---

#### ➤ Debounce (Search Input)
Waits for a **pause** in events before executing.

```
Events:    (Type 'A')   (Type 'B')   (Type 'C')    [User stops typing]
Time:      |─ 0ms ──── 100ms ──── 200ms ────────────── 500ms ──────|
           ▼            ▼            ▼                  ▲
Execution: [WAIT] ····· [RESET] ····· [RESET] ········ [EXECUTE 'ABC']
                                      └─────── 300ms wait ──────┘
```

**Use:** Search autocomplete, form validation, window resize

---

#### ➤ Concurrency: `replace` (Perfect for Search)
New task **cancels** the old one.

```
Task 1:  [──────── 500ms API Call ──X Cancelled
Task 2:              ↓ New search query
                     [──────── 500ms API Call ────────]  ✅ Result shown
```

---

## Extensions & Utilities

```dart
// Duration extensions — write durations naturally
ThrottledInkWell(duration: 500.ms, ...)
Debouncer(duration: 300.ms)
RateLimiter(refillInterval: 1.seconds)

// Leading + trailing edge (like lodash)
Debouncer(leading: true, trailing: true)

// Rate limiter with Token Bucket
RateLimiter(maxTokens: 10, refillRate: 2)

// Queue backpressure control
ConcurrentAsyncThrottler(maxQueueSize: 10)

// Callback extensions
final debouncedFn = myFunction.debounced(300.ms);
final throttledFn = myFunction.throttled(500.ms);
```

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
| **450+ tests** | Unit, integration, stress, system, performance & boundary tests |
| **95% coverage** | All edge cases covered |
| **Honest API** | `ThrottlerResult` / `DebounceResult` — no silent failures |
| **Type-safe** | No `dynamic`, no `as`, full generics |
| **Compile-time safety** | `when()` forces exhaustive handling — compiler rejects incomplete code |
| **Memory-safe** | Zero leaks verified with LeakTracker |
| **Architecture-neutral** | `mixin` not `extends` — works with any state management |

---

## Which Package Should I Use?

| You are building... | Package |
|---------------------|---------|
| Flutter app (most users) | **`flutter_debounce_throttle`** ← you are here |
| Flutter app + `flutter_hooks` | [`flutter_debounce_throttle_hooks`](https://pub.dev/packages/flutter_debounce_throttle_hooks) |
| Dart server / CLI / Serverpod | [`dart_debounce_throttle`](https://pub.dev/packages/dart_debounce_throttle) |

---

## Why Not Just Use easy_debounce?

| Capability | This Package | easy_debounce | Manual Timer |
|------------|:---:|:---:|:---:|
| **No Silent Failures** | ✅ `ThrottlerResult.when()` | ❌ void return | ❌ void return |
| **Memory Safe** (Auto-dispose) | ✅ | ❌ | ❌ Leaky |
| **Async & Future Support** | ✅ | ❌ | ❌ |
| **Race Condition Control** | ✅ 4 modes | ❌ | ❌ |
| **Architecture Neutral** | ✅ `mixin` — any pattern | ❌ Global static | ❌ |
| **Ready-to-use Widgets** | ✅ | ❌ | ❌ |
| **State Management Mixin** | ✅ | ❌ | ❌ |
| **Loading States Built-in** | ✅ | ❌ | ❌ |

---

<p align="center">
  <a href="https://github.com/brewkits/flutter_debounce_throttle">GitHub</a> ·
  <a href="https://github.com/brewkits/flutter_debounce_throttle/blob/main/FAQ.md">FAQ</a> ·
  <a href="https://github.com/brewkits/flutter_debounce_throttle/blob/main/docs/API_REFERENCE.md">API Reference</a> ·
  <a href="https://github.com/brewkits/flutter_debounce_throttle/blob/main/docs/BEST_PRACTICES.md">Best Practices</a> ·
  <a href="https://github.com/brewkits/flutter_debounce_throttle/blob/main/MIGRATION_GUIDE.md">Migration Guide</a>
</p>

<p align="center">
  Made with craftsmanship by <a href="https://github.com/brewkits">Brewkits</a>
</p>
