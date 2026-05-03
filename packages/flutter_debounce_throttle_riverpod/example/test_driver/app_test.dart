import 'dart:io';
import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

void main() {
  final String? testName = Platform.environment['TEST_NAME'];

  group('Recording Riverpod Demos', () {
    late FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      await driver.close();
    });

    test('demo_riverpod_debounce', () async {
      if (testName != null && testName != 'demo_riverpod_debounce') return;

      final textField = find.byType('TextField');
      await driver.tap(textField);

      const query = 'flutter';
      for (int i = 0; i < query.length; i++) {
        await driver.enterText(query.substring(0, i + 1));
        await Future.delayed(const Duration(milliseconds: 150));
      }

      await Future.delayed(const Duration(seconds: 3));
    });

    test('demo_riverpod_autodispose', () async {
      if (testName != null && testName != 'demo_riverpod_autodispose') return;

      await driver.tap(find.text('Auto-Dispose'));

      final textField = find.byType('TextField');
      await driver.tap(textField);

      await driver.enterText('test');
      await Future.delayed(const Duration(milliseconds: 100));

      await driver.tap(find.text('Reset Provider'));
      await Future.delayed(const Duration(seconds: 3));
    });
  });
}
