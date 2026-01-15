// lib/hooks.dart
//
// Flutter Hooks support for flutter_debounce_throttle.
//
// ============================================================================
// IMPORTANT: This is an OPTIONAL module that requires flutter_hooks package.
// ============================================================================
//
// To use hooks, add flutter_hooks to YOUR project's pubspec.yaml:
//
//   dependencies:
//     flutter_debounce_throttle: ^1.0.0
//     flutter_hooks: ^0.20.0  # Required for hooks support
//
// If you don't need hooks, just use the main import instead:
//   import 'package:flutter_debounce_throttle/flutter_debounce_throttle.dart';
//
// **Usage:**
// ```dart
// import 'package:flutter_debounce_throttle/hooks.dart';
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

export 'src/flutter/hooks/hooks.dart';

// Also export core for convenience
export 'core.dart';
