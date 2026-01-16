# Best Practices Guide

Practical patterns and recommendations for common use cases.

---

## Table of Contents

- [Button Anti-Spam](#button-anti-spam)
- [Search Input](#search-input)
- [Form Validation](#form-validation)
- [API Rate Limiting](#api-rate-limiting)
- [Scroll/Resize Events](#scrollresize-events)
- [Chat Messages](#chat-messages)
- [Auto-Save](#auto-save)
- [Analytics Batching](#analytics-batching)
- [Quick Reference](#quick-reference)
- [Common Mistakes](#common-mistakes)

---

## Button Anti-Spam

Prevent double clicks and duplicate submissions.

```dart
// BEST: ThrottledInkWell for one-time setup
ThrottledInkWell(
  duration: 500.ms,
  onTap: () => submitOrder(),
  child: Text('Submit'),
)

// GOOD: Throttler with wrap()
final _submitThrottler = Throttler(duration: 500.ms);

ElevatedButton(
  onPressed: _submitThrottler.wrap(() => submitOrder()),
  child: Text('Submit'),
)

// AVOID: AsyncThrottler without loading indicator
// User can't see why button "doesn't work"
```

---

## Search Input

Wait for user to stop typing before making API calls.

```dart
// BEST: DebouncedQueryBuilder with loading state
DebouncedQueryBuilder<List<User>>(
  duration: 300.ms,
  onQuery: (text) async => await api.search(text),
  onResult: (users) => setState(() => _users = users),
  onError: (e) => showError(e),
  builder: (context, search, isLoading) => TextField(
    onChanged: search,
    decoration: InputDecoration(
      suffixIcon: isLoading
        ? CircularProgressIndicator()
        : Icon(Icons.search),
    ),
  ),
)

// GOOD: Debouncer for simple cases
final _searchDebouncer = Debouncer(duration: 300.ms);

TextField(
  onChanged: (text) => _searchDebouncer.call(() => search(text)),
)

// TIP: Use ConcurrencyMode.replace to cancel old searches
final _searchController = ConcurrentAsyncThrottler(
  mode: ConcurrencyMode.replace,
  maxDuration: 10.seconds,
);
```

---

## Form Validation

Validate input after user stops editing.

```dart
// BEST: Debouncer with trailing edge (default)
final _validator = Debouncer(duration: 300.ms);

TextFormField(
  onChanged: (value) => _validator.call(() => validateEmail(value)),
)

// ALTERNATIVE: Leading + Trailing for immediate + final validation
final _validator = Debouncer(
  duration: 300.ms,
  leading: true,   // Immediate feedback
  trailing: true,  // Final validation after pause
);
```

---

## API Rate Limiting

Server-side rate limiting with burst capacity.

```dart
// BEST: RateLimiter for burst-capable rate limiting
final _apiLimiter = RateLimiter(
  maxTokens: 100,        // Allow burst of 100
  refillRate: 10,        // 10 requests/second sustained
  refillInterval: 1.seconds,
);

Future<Response> handleRequest(Request req) async {
  if (!_apiLimiter.tryAcquire()) {
    return Response.tooManyRequests(
      retryAfter: _apiLimiter.timeUntilNextToken,
    );
  }
  return await processRequest(req);
}

// GOOD: Simple Throttler for fixed-rate limiting
final _throttler = Throttler(duration: 100.ms); // 10 req/s max
```

---

## Scroll/Resize Events

Handle high-frequency events efficiently.

```dart
// BEST: HighFrequencyThrottler for 60fps
final _scrollThrottler = HighFrequencyThrottler(
  duration: 16.ms, // ~60fps
);

NotificationListener<ScrollNotification>(
  onNotification: (notification) {
    _scrollThrottler.call(() => updateParallax(notification.metrics.pixels));
    return false;
  },
  child: ListView(...),
)

// AVOID: Regular Throttler (uses Timer, less precise)
```

---

## Chat Messages

Send messages in order, handle backpressure.

```dart
// BEST: ConcurrentAsyncThrottler with enqueue mode
final _chatSender = ConcurrentAsyncThrottler(
  mode: ConcurrencyMode.enqueue,  // Preserve order
  maxDuration: 30.seconds,
  maxQueueSize: 20,               // Prevent memory buildup
  queueOverflowStrategy: QueueOverflowStrategy.dropOldest,
);

void sendMessage(String text) {
  _chatSender.call(() async => await api.sendMessage(text));
}
```

---

## Auto-Save

Save only the final version after rapid edits.

```dart
// BEST: ConcurrentAsyncThrottler with keepLatest mode
final _autoSaver = ConcurrentAsyncThrottler(
  mode: ConcurrencyMode.keepLatest,  // Only save final version
  maxDuration: 30.seconds,
);

void onDocumentChanged(Document doc) {
  _autoSaver.call(() async => await api.saveDraft(doc));
}

// Result: Multiple rapid edits -> Only first + last saved
```

---

## Analytics Batching

Group multiple events into single network call.

```dart
// BEST: BatchThrottler with size limit
final _analyticsBatcher = BatchThrottler(
  duration: 2.seconds,
  maxBatchSize: 50,  // Prevent memory issues
  overflowStrategy: BatchOverflowStrategy.flushAndAdd,
  onBatchExecute: (actions) async {
    final events = actions.map((a) => a()).toList();
    await analytics.trackBatch(events);
  },
);

void trackEvent(String name) {
  _analyticsBatcher(() => AnalyticsEvent(name));
}
```

---

## Quick Reference

| Use Case | Recommended Limiter | Mode/Options |
|----------|---------------------|--------------|
| Button anti-spam | `Throttler` / `ThrottledInkWell` | - |
| Search input | `Debouncer` + `ConcurrentAsyncThrottler` | `replace` mode |
| Form validation | `Debouncer` | `leading + trailing` |
| API rate limiting | `RateLimiter` | Token bucket |
| Scroll/resize | `HighFrequencyThrottler` | 16ms for 60fps |
| Chat messages | `ConcurrentAsyncThrottler` | `enqueue` mode |
| Auto-save | `ConcurrentAsyncThrottler` | `keepLatest` mode |
| Analytics | `BatchThrottler` | `maxBatchSize` |

---

## Common Mistakes

### DO

```dart
// Dispose in StatefulWidget
@override
void dispose() {
  _throttler.dispose();
  super.dispose();
}

// Use wrap() for VoidCallback
onPressed: throttler.wrap(() => submit())

// Use unique IDs in Mixin
debounce('search', () => performSearch());
debounce('validate', () => validateForm()); // Different ID!

// Always set maxDuration for async throttlers
final throttler = AsyncThrottler(maxDuration: Duration(seconds: 10));

// Handle errors in async callbacks
DebouncedQueryBuilder(
  onQuery: (text) async => await api.search(text),
  onError: (e) => showErrorSnackbar(e), // Don't forget!
)
```

### DON'T

```dart
// Create limiters in build method
Widget build(context) {
  final throttler = Throttler(...); // Creates new every build!
}

// Forget to dispose -> Memory leak!

// Use same ID for different operations
debounce('action', () => search());
debounce('action', () => validate()); // Conflicts!

// Use drop mode without loading indicator
ConcurrentAsyncThrottler(mode: ConcurrencyMode.drop) // Show loading!

// Skip maxDuration on async throttlers
AsyncThrottler() // If API hangs, UI locked forever!
```

### Recommended Timeout Values

| Use Case | Recommended `maxDuration` |
|----------|---------------------------|
| Button click API call | 10-30 seconds |
| Form submission | 30-60 seconds |
| File upload | 5-10 minutes |
| Background sync | Handle separately |
