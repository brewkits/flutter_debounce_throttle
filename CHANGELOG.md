## 1.0.0

Initial release of flutter_debounce_throttle - The Safe, Unified & Universal Event Limiter for Flutter & Dart.

### Core Limiters (Pure Dart)
- `Throttler` - Execute immediately, block subsequent calls for duration
- `Debouncer` - Delay execution until pause in calls
- `AsyncDebouncer` - Async debounce with cancellation support
- `AsyncThrottler` - Lock-based async throttle with timeout
- `HighFrequencyThrottler` - Optimized for 60fps events (scroll, mouse)
- `BatchThrottler` - Batch multiple operations into single execution
- `ConcurrentAsyncThrottler` - 4 concurrency modes (drop, enqueue, replace, keepLatest)
- `ThrottleDebouncer` - Combined leading + trailing edge execution

### Flutter Widgets
- `ThrottledBuilder` - Universal throttle wrapper widget
- `ThrottledInkWell` - Material button with built-in throttle
- `DebouncedBuilder` - Debounce wrapper widget
- `AsyncThrottledBuilder` - Async throttle with loading state
- `AsyncDebouncedBuilder` - Async debounce with loading state
- `AsyncDebouncedCallbackBuilder` - Async debounce for callbacks
- `ConcurrentAsyncThrottledBuilder` - Concurrency modes widget

### Stream Listeners
- `StreamSafeListener` - Auto-cancel stream subscription on dispose
- `StreamDebounceListener` - Debounce stream events
- `StreamThrottleListener` - Throttle stream events

### Text Controllers
- `DebouncedTextController` - TextField controller with debouncing
- `AsyncDebouncedTextController` - Async search controller with loading state

### State Management
- `EventLimiterMixin` - ID-based limiters for any controller (Provider, GetX, Bloc, etc.)

### Flutter Hooks
- `useDebouncer` - Hook for Debouncer instance
- `useThrottler` - Hook for Throttler instance
- `useAsyncDebouncer` - Hook for AsyncDebouncer instance
- `useAsyncThrottler` - Hook for AsyncThrottler instance
- `useDebouncedCallback` - Hook for debounced callback
- `useThrottledCallback` - Hook for throttled callback
- `useDebouncedValue` - Hook for debounced value
- `useThrottledValue` - Hook for throttled value

### Configuration
- `FlutterDebounceThrottle.init()` - Global configuration
- Debug logging with configurable log levels
- Named instances for easy debugging

### Architecture
- Pure Dart core (`core.dart`) - Works on servers without Flutter
- Layered architecture with clean separation of concerns
- Full type safety
- Automatic lifecycle management
