## 1.0.0

### Initial release

- `EventLimiterController` — debounce/throttle controller that auto-disposes with a Riverpod `Ref` lifecycle.
- `Ref.eventLimiter()` extension for zero-boilerplate setup inside `build()`.
- `EventLimiterController.standalone()` constructor for use in `ConsumerStatefulWidget` without a ref.
- Supports debounce, throttle, async debounce (with `DebounceResult`), and async throttle keyed by string ID.
- Pure Dart — no Flutter dependency; works with any Riverpod notifier type.
