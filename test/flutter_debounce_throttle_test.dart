// Main test file - runs all tests for flutter_debounce_throttle
//
// Run all tests: flutter test
// Run specific test file: flutter test test/core/throttler_test.dart

// Core tests
import 'core/throttler_test.dart' as throttler_test;
import 'core/debouncer_test.dart' as debouncer_test;
import 'core/async_debouncer_test.dart' as async_debouncer_test;
import 'core/async_throttler_test.dart' as async_throttler_test;
import 'core/batch_throttler_test.dart' as batch_throttler_test;
import 'core/concurrent_async_throttler_test.dart'
    as concurrent_async_throttler_test;
import 'core/high_frequency_throttler_test.dart'
    as high_frequency_throttler_test;
import 'core/throttle_debouncer_test.dart' as throttle_debouncer_test;

// Flutter widget tests
import 'flutter/widgets_test.dart' as widgets_test;
import 'flutter/stream_listeners_test.dart' as stream_listeners_test;
import 'flutter/text_controllers_test.dart' as text_controllers_test;

// Mixin tests
import 'mixin/event_limiter_mixin_test.dart' as event_limiter_mixin_test;

void main() {
  // Core
  throttler_test.main();
  debouncer_test.main();
  async_debouncer_test.main();
  async_throttler_test.main();
  batch_throttler_test.main();
  concurrent_async_throttler_test.main();
  high_frequency_throttler_test.main();
  throttle_debouncer_test.main();

  // Flutter
  widgets_test.main();
  stream_listeners_test.main();
  text_controllers_test.main();

  // Mixin
  event_limiter_mixin_test.main();
}
