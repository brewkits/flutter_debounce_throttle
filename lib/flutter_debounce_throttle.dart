// lib/flutter_debounce_throttle.dart
//
// The Safe, Unified & Universal Event Limiter for Flutter & Dart.
//
// **Quick Start:**
// ```dart
// import 'package:flutter_debounce_throttle/flutter_debounce_throttle.dart';
//
// // Button anti-spam
// ThrottledInkWell(
//   onTap: () => submit(),
//   child: MyButton(),
// )
//
// // Search input with loading
// AsyncDebouncedCallbackBuilder<List<User>>(
//   onChanged: (text) async => await searchApi(text),
//   onSuccess: (results) => setState(() => _results = results),
//   builder: (context, callback, isLoading) => TextField(
//     onChanged: callback,
//     decoration: InputDecoration(
//       suffixIcon: isLoading ? CircularProgressIndicator() : Icon(Icons.search),
//     ),
//   ),
// )
// ```
//
// **For Dart Server:**
// ```dart
// import 'package:flutter_debounce_throttle/core.dart';
// ```
//
// **For Hooks:**
// ```dart
// import 'package:flutter_debounce_throttle/hooks.dart';
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
