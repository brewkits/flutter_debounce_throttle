// flutter_debounce_throttle
//
// The Safe, Unified & Universal Event Limiter for Flutter.
//
// ============================================================================
// AVAILABLE IMPORTS
// ============================================================================
//
// 1. Main (Flutter Widgets + Core) - This package:
//    import 'package:flutter_debounce_throttle/flutter_debounce_throttle.dart';
//
// 2. Core Only (Pure Dart, Server-side compatible):
//    import 'package:dart_debounce_throttle/dart_debounce_throttle.dart';
//
// 3. Hooks (OPTIONAL - requires flutter_hooks):
//    import 'package:flutter_debounce_throttle_hooks/flutter_debounce_throttle_hooks.dart';
//
// ============================================================================
// QUICK START
// ============================================================================
//
// **Button anti-spam:**
// ```dart
// ThrottledInkWell(
//   duration: Duration(milliseconds: 500),
//   onTap: () => submit(),
//   child: MyButton(),
// )
// ```
//
// **Search input with loading:**
// ```dart
// AsyncDebouncedCallbackBuilder<List<User>>(
//   duration: Duration(milliseconds: 300),
//   onChanged: (text) async => await searchApi(text),
//   onSuccess: (results) => setState(() => _results = results),
//   onError: (e) => showError(e), // Don't forget error handling!
//   builder: (context, callback, isLoading) => TextField(
//     onChanged: callback,
//     decoration: InputDecoration(
//       suffixIcon: isLoading ? CircularProgressIndicator() : Icon(Icons.search),
//     ),
//   ),
// )
// ```
//
// **State Management with Mixin:**
// ```dart
// class MyController with ChangeNotifier, EventLimiterMixin {
//   void onSearch(String text) {
//     debounce('search', () => performSearch(text));
//   }
//
//   @override
//   void dispose() {
//     cancelAllLimiters(); // IMPORTANT: Always call this!
//     super.dispose();
//   }
// }
// ```

// Re-export Core (Pure Dart)
export 'package:dart_debounce_throttle/dart_debounce_throttle.dart';

// Mixin for State Management
export 'src/mixin/event_limiter_mixin.dart';

// Flutter Widgets
export 'src/widgets/callback_widgets.dart';
export 'src/widgets/stream_listeners.dart';
export 'src/widgets/gesture_detector.dart';

// Flutter Controllers
export 'src/controllers/text_controllers.dart';
