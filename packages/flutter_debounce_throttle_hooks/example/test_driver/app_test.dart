import 'dart:io';
import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

void main() {
  final String? testName = Platform.environment['TEST_NAME'];

  group('Recording Hooks Demos', () {
    late FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      await driver.close();
    });

    test('demo_hooks_debounce', () async {
      if (testName != null && testName != 'demo_hooks_debounce') return;

      final textField = find.byType('TextField');
      await driver.tap(textField);

      const query = 'hooks';
      for (int i = 0; i < query.length; i++) {
        await driver.enterText(query.substring(0, i + 1));
        await Future.delayed(const Duration(milliseconds: 150));
      }

      await Future.delayed(const Duration(seconds: 3));
    });
  });
}
