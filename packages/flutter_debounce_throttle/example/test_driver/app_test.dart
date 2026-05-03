import 'dart:io';
import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

void main() {
  final String? testName = Platform.environment['TEST_NAME'];

  group('Recording Demos', () {
    late FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      await driver.close();
    });

    test('demo_throttle_antispam', () async {
      if (testName != null && testName != 'demo_throttle_antispam') return;

      await driver.tap(find.text('Anti-Spam'));

      final payButton = find.text('Pay \$99');
      for (int i = 0; i < 8; i++) {
        await driver.tap(payButton);
        await Future.delayed(const Duration(milliseconds: 100));
      }

      await Future.delayed(const Duration(seconds: 2));
      await driver.tap(payButton);
      await Future.delayed(const Duration(seconds: 1));
    });

    test('demo_search_debounce', () async {
      if (testName != null && testName != 'demo_search_debounce') return;

      await driver.tap(find.text('Search'));

      final textField = find.byType('TextField');
      await driver.tap(textField);

      const query = 'flutter';
      for (int i = 0; i < query.length; i++) {
        await driver.enterText(query.substring(0, i + 1));
        await Future.delayed(const Duration(milliseconds: 150));
      }

      await Future.delayed(const Duration(seconds: 3));
    });

    test('demo_async_submit', () async {
      if (testName != null && testName != 'demo_async_submit') return;

      await driver.tap(find.text('Async Form'));

      final submitButton = find.text('Submit Form');
      await driver.tap(submitButton);

      for (int i = 0; i < 4; i++) {
        await driver.tap(submitButton);
        await Future.delayed(const Duration(milliseconds: 200));
      }

      await Future.delayed(const Duration(seconds: 3));
    });

    test('demo_concurrency_replace', () async {
      if (testName != null && testName != 'demo_concurrency_replace') return;

      await driver.tap(find.text('Concurrency'));

      final textField = find.byType('TextField');
      await driver.tap(textField);

      final queries = ['d', 'da', 'dar', 'dart'];
      for (final q in queries) {
        await driver.enterText(q);
        await Future.delayed(const Duration(milliseconds: 200));
      }

      await Future.delayed(const Duration(seconds: 4));
    });
  });
}
