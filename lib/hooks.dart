// lib/hooks.dart
//
// DEPRECATED: Hooks have moved to a separate package.
//
// ============================================================================
// MIGRATION: Use flutter_debounce_throttle_hooks instead
// ============================================================================
//
// 1. Add the hooks package to your pubspec.yaml:
//
//   dependencies:
//     flutter_debounce_throttle: ^1.1.0
//     flutter_debounce_throttle_hooks: ^1.1.0  # Add this
//
// 2. Update your imports:
//
//   // Old (deprecated):
//   import 'package:flutter_debounce_throttle/hooks.dart';
//
//   // New:
//   import 'package:flutter_debounce_throttle_hooks/flutter_debounce_throttle_hooks.dart';
//
// ============================================================================

// This file is kept for backward compatibility documentation only.
// The actual hooks implementation is in flutter_debounce_throttle_hooks package.

@Deprecated(
  'Hooks have moved to flutter_debounce_throttle_hooks package. '
  'Add flutter_debounce_throttle_hooks to pubspec.yaml and import from there.',
)
library hooks;

// Re-export core for convenience (this still works)
export 'core.dart';
