// lib/hooks.dart
//
// Flutter Hooks support for flutter_debounce_throttle.
//
// **IMPORTANT:** This library requires flutter_hooks package.
// Add to pubspec.yaml:
//   dependencies:
//     flutter_hooks: ^0.20.0
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
//     return Column(
//       children: [
//         TextField(
//           onChanged: (text) => debouncer.call(() => search(text)),
//         ),
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
