import 'package:flutter_debounce_throttle_core/flutter_debounce_throttle_core.dart';

void main() async {
  print('=== Debounce Example ===');
  final debouncer = Debouncer(duration: Duration(milliseconds: 500));

  // Rapid calls - only the last one executes after 500ms of silence
  for (int i = 0; i < 5; i++) {
    debouncer.call(() => print('Debounced: $i'));
    await Future.delayed(Duration(milliseconds: 100));
  }

  await Future.delayed(Duration(seconds: 1));

  print('\n=== Throttle Example ===');
  final throttler = Throttler(duration: Duration(milliseconds: 500));

  // Rapid calls - first executes immediately, rest are blocked for 500ms
  for (int i = 0; i < 5; i++) {
    throttler.call(() => print('Throttled: $i'));
    await Future.delayed(Duration(milliseconds: 100));
  }

  await Future.delayed(Duration(seconds: 1));

  // Cleanup
  debouncer.dispose();
  throttler.dispose();
}
