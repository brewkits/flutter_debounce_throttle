import 'dart:async';

import 'package:dart_debounce_throttle/dart_debounce_throttle.dart';

void main() async {
  print('=== Stream Extensions Example ===\n');

  // Debounce example
  print('1. Debounce Example:');
  final debounceController = StreamController<String>();

  debounceController.stream
      .debounce(const Duration(milliseconds: 300))
      .listen((query) {
    print('   Debounced search: $query');
  });

  print('   Typing: h');
  debounceController.add('h');
  await Future.delayed(const Duration(milliseconds: 100));

  print('   Typing: he');
  debounceController.add('he');
  await Future.delayed(const Duration(milliseconds: 100));

  print('   Typing: hel');
  debounceController.add('hel');
  await Future.delayed(const Duration(milliseconds: 100));

  print('   Typing: hello');
  debounceController.add('hello');

  await Future.delayed(const Duration(milliseconds: 400));
  print('   (Only "hello" should be searched)\n');

  // Throttle example
  print('2. Throttle Example:');
  final throttleController = StreamController<int>();

  throttleController.stream
      .throttle(const Duration(milliseconds: 500))
      .listen((click) {
    print('   Button click #$click processed');
  });

  for (var i = 1; i <= 5; i++) {
    print('   Click #$i');
    throttleController.add(i);
    await Future.delayed(const Duration(milliseconds: 100));
  }

  await Future.delayed(const Duration(milliseconds: 600));

  for (var i = 6; i <= 8; i++) {
    print('   Click #$i');
    throttleController.add(i);
    await Future.delayed(const Duration(milliseconds: 100));
  }

  await Future.delayed(const Duration(milliseconds: 200));
  print('   (Only clicks #1 and #6 should be processed)\n');

  await debounceController.close();
  await throttleController.close();

  print('=== Example Complete ===');
}
