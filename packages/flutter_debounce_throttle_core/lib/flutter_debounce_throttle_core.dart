// ⚠️ DISCONTINUED - Use dart_debounce_throttle instead
//
// This package has been renamed to follow Dart naming conventions.
// Pure Dart packages should not have the "flutter_" prefix.
//
// Migration:
//
// 1. Update pubspec.yaml:
//    dependencies:
//      dart_debounce_throttle: ^2.0.0  # Use this instead
//
// 2. Update imports:
//    import 'package:dart_debounce_throttle/dart_debounce_throttle.dart';
//
// No API changes - all functionality remains identical.
//
// New package: https://pub.dev/packages/dart_debounce_throttle

// Re-export dart_debounce_throttle for backward compatibility
export 'package:dart_debounce_throttle/dart_debounce_throttle.dart';

@Deprecated(
  'Use dart_debounce_throttle instead. '
  'This package has been renamed to follow Dart naming conventions. '
  'See https://pub.dev/packages/dart_debounce_throttle',
)
// Deprecated marker for pub.dev
const String packageDiscontinued = 'Use dart_debounce_throttle instead';
