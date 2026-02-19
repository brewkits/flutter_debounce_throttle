# flutter_debounce_throttle Demo App

Interactive demo showcasing all features of the `flutter_debounce_throttle` library.

## Running the Demo

```bash
cd example
flutter run
```

## Demo Tabs

### 1. Throttle Demo

Demonstrates basic throttling behavior.

**What you'll see:**
- Tap the button rapidly
- Raw clicks counter increases on every tap
- Throttled counter only increases once per 500ms
- Blocked counter shows how many clicks were prevented

**Use case:** Prevent button spam, API rate limiting

---

### 2. Debounce Demo

Demonstrates debouncing for text input.

**What you'll see:**
- Type rapidly in the text field
- Keystrokes counter increases on every keystroke
- Callbacks counter only increases 500ms after you stop typing
- "API Saved" shows how many unnecessary API calls were prevented

**Use case:** Search input, form validation, auto-save

---

### 3. Search Demo

Demonstrates `AsyncDebouncedTextController` with real search functionality.

**What you'll see:**
- Type "apple" or "berry" to search fruits
- Loading indicator while searching
- Results appear after debounce delay
- Clear button to reset

**Use case:** Live search with API integration

---

### 4. Button Demo

Demonstrates `AsyncThrottledBuilder` for async operations.

**What you'll see:**
- Click "Submit Form" button
- Button shows loading state for 2 seconds
- Rapid clicks during loading are ignored
- Submission log shows successful submissions

**Use case:** Form submission, payment buttons, any async action

---

### 5. Advanced Demo (Concurrency Modes)

Demonstrates all 4 `ConcurrencyMode` options with `ConcurrentAsyncThrottledBuilder`.

**Modes:**
| Mode | Behavior |
|------|----------|
| `drop` | Ignore new calls while busy |
| `enqueue` | Queue and execute in order |
| `replace` | Cancel current, start new |
| `keepLatest` | Keep only the latest pending |

**What you'll see:**
- Select a mode from the chips
- Click "Start Operation" rapidly
- Watch how different modes handle concurrent operations
- Operation log shows start/complete events

**Use case:**
- `drop`: Payment processing (prevent double-charge)
- `enqueue`: Chat messages (preserve order)
- `replace`: Search autocomplete (cancel stale requests)
- `keepLatest`: Auto-save (only save latest version)

---

### 6. Enterprise Demo

Showcases extensions, rate limiting, leading/trailing edge, and batch processing.

#### 6.1 RateLimiter (Token Bucket)

**What you'll see:**
- Token gauge showing available tokens (max 3)
- Tokens refill at 1 per second
- Click rapidly to drain tokens
- Requests blocked when tokens exhausted
- Log shows ALLOWED vs BLOCKED requests

**Use case:** API rate limiting, DDoS protection, cost control

#### 6.2 Duration & Callback Extensions

**What you'll see:**
- Code examples of `300.ms`, `2.seconds` syntax
- Tap button to trigger both debounced and throttled callbacks
- Compare raw clicks vs debounced vs throttled counts

```dart
// Duration extensions
final debouncer = Debouncer(duration: 300.ms);

// Callback extensions
final debouncedFn = myFunction.debounced(300.ms);
final throttledFn = myFunction.throttled(500.ms);
```

#### 6.3 Leading/Trailing Edge

**What you'll see:**
- Toggle leading and trailing checkboxes
- Click rapidly and observe execution timing
- Leading: executes immediately on first click
- Trailing: executes after 1 second pause
- Both: executes on first click AND after pause

| Mode | First Click | During Burst | After Pause |
|------|-------------|--------------|-------------|
| Trailing only | Waits | Resets timer | Executes |
| Leading only | Executes | Blocked | - |
| Both | Executes | Resets timer | Executes |

#### 6.4 BatchThrottler with maxBatchSize

**What you'll see:**
- Add items rapidly to batch (max 3 items)
- Select overflow strategy: `dropOldest`, `dropNewest`, `flushAndAdd`
- Watch batch execute after 2 seconds
- Log shows items added and batch executions

**Use case:** Analytics batching, bulk database writes

#### 6.5 Queue Limit (maxQueueSize)

**What you'll see:**
- Make requests rapidly (2 second processing time)
- Queue limited to 2 items
- Select overflow strategy: `dropNewest`, `dropOldest`
- Watch requests complete or get dropped
- Log shows queued, completed, and dropped requests

**Use case:** Backpressure control for message queues

---

## Code Structure

```
example/lib/main.dart
├── DemoApp              # Material 3 app with navigation
├── ThrottleDemo         # Basic throttle visualization
├── DebounceDemo         # Text input debouncing
├── SearchDemo           # AsyncDebouncedTextController
├── ButtonDemo           # AsyncThrottledBuilder
├── AdvancedDemo         # ConcurrencyMode comparison
└── EnterpriseDemo       # v1.1.0 features
    ├── _RateLimiterDemo
    ├── _ExtensionsDemo
    ├── _LeadingTrailingDemo
    ├── _BatchThrottlerDemo
    └── _QueueLimitDemo
```

## Features Demonstrated

| Feature | Demo Tab | Widget/Class Used |
|---------|----------|-------------------|
| Basic Throttle | Throttle | `Throttler` |
| Basic Debounce | Debounce | `Debouncer` |
| Async Search | Search | `AsyncDebouncedTextController` |
| Async Button | Button | `AsyncThrottledBuilder` |
| Concurrency Modes | Advanced | `ConcurrentAsyncThrottledBuilder` |
| Token Bucket | Enterprise > RateLimiter | `RateLimiter` |
| Duration Extensions | Enterprise > Extensions | `300.ms`, `2.seconds` |
| Callback Extensions | Enterprise > Extensions | `.debounced()`, `.throttled()` |
| Leading/Trailing | Enterprise > Leading/Trailing | `Debouncer(leading:, trailing:)` |
| Batch Processing | Enterprise > BatchThrottler | `BatchThrottler` |
| Queue Backpressure | Enterprise > Queue Limit | `ConcurrentAsyncThrottler(maxQueueSize:)` |

---

## Screenshots

*Run the app to see interactive demos with Material 3 design, real-time counters, and event logs.*

---

Made by [Brewkits](https://github.com/brewkits)
