// flutter_debounce_throttle_hooks
//
// Flutter Hooks support for flutter_debounce_throttle.
//
// ============================================================================
// IMPORTANT: This package requires flutter_hooks.
// ============================================================================
//
// To use hooks, add flutter_hooks to YOUR project's pubspec.yaml:
//
//   dependencies:
//     flutter_debounce_throttle_hooks: ^1.0.0
//     flutter_hooks: ^0.20.0  # Required for hooks support
//
// ============================================================================
// QUICK START
// ============================================================================
//
// **Usage:**
// ```dart
// import 'package:flutter_debounce_throttle_hooks/flutter_debounce_throttle_hooks.dart';
//
// class MyWidget extends HookWidget {
//   @override
//   Widget build(BuildContext context) {
//     final debouncer = useDebouncer(duration: Duration(milliseconds: 300));
//     final throttler = useThrottler(duration: Duration(milliseconds: 500));
//
//     final debouncedSearch = useDebouncedCallback<String>(
//       (text) => search(text),
//       duration: Duration(milliseconds: 300),
//     );
//
//     return Column(
//       children: [
//         TextField(onChanged: debouncedSearch),
//         ElevatedButton(
//           onPressed: throttler.wrap(() => submit()),
//           child: Text('Submit'),
//         ),
//       ],
//     );
//   }
// }
// ```
//
// ============================================================================
// AVAILABLE HOOKS
// ============================================================================
//
// **Basic Hooks:**
// - useDebouncer: Get a Debouncer instance with auto-dispose
// - useThrottler: Get a Throttler instance with auto-dispose
// - useAsyncDebouncer: Get an AsyncDebouncer instance with auto-dispose
// - useAsyncThrottler: Get an AsyncThrottler instance with auto-dispose
//
// **Callback Hooks:**
// - useDebouncedCallback: Create a debounced callback function
// - useThrottledCallback: Create a throttled callback function
//
// **Value Hooks:**
// - useDebouncedValue: Get the debounced version of a value
// - useThrottledValue: Get the throttled version of a value

// Re-export flutter_debounce_throttle (includes core)
export 'package:flutter_debounce_throttle/flutter_debounce_throttle.dart';

// Export hooks
export 'src/hooks.dart';
