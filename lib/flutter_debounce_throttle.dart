// lib/flutter_debounce_throttle.dart
//
// The Safe, Unified & Universal Event Limiter for Flutter & Dart.
//
// ============================================================================
// AVAILABLE IMPORTS
// ============================================================================
//
// 1. Main (Flutter Widgets + Core) - NO extra dependencies:
//    import 'package:flutter_debounce_throttle/flutter_debounce_throttle.dart';
//
// 2. Core Only (Pure Dart, Server-side compatible):
//    import 'package:flutter_debounce_throttle/core.dart';
//
// 3. Hooks (OPTIONAL - requires flutter_hooks in your pubspec.yaml):
//    import 'package:flutter_debounce_throttle/hooks.dart';
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

// Core (Pure Dart)
export 'core.dart';

// Mixin for State Management
export 'src/mixin/event_limiter_mixin.dart';

// Flutter Widgets
export 'src/flutter/widgets/callback_widgets.dart';
export 'src/flutter/widgets/stream_listeners.dart';

// Flutter Controllers
export 'src/flutter/controllers/text_controllers.dart';
