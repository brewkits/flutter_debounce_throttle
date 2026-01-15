import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_debounce_throttle/flutter_debounce_throttle.dart';

class TestController with EventLimiterMixin {
  int value = 0;
  List<String> log = [];
}

void main() {
  group('EventLimiterMixin', () {
    late TestController controller;

    setUp(() {
      controller = TestController();
    });

    tearDown(() {
      controller.cancelAll();
    });

    group('debounce', () {
      test('delays execution', () async {
        controller.debounce('test', () => controller.value++);

        expect(controller.value, 0);

        await Future.delayed(const Duration(milliseconds: 400));

        expect(controller.value, 1);
      });

      test('resets timer on subsequent calls', () async {
        controller.debounce('test', () => controller.value++);
        await Future.delayed(const Duration(milliseconds: 150));
        controller.debounce('test', () => controller.value++);
        await Future.delayed(const Duration(milliseconds: 150));
        controller.debounce('test', () => controller.value++);

        expect(controller.value, 0);

        await Future.delayed(const Duration(milliseconds: 400));

        expect(controller.value, 1);
      });

      test('different IDs work independently', () async {
        controller.debounce('search', () => controller.log.add('search'));
        controller.debounce('validate', () => controller.log.add('validate'));

        await Future.delayed(const Duration(milliseconds: 400));

        expect(controller.log, contains('search'));
        expect(controller.log, contains('validate'));
        expect(controller.log.length, 2);
      });

      test('custom duration works', () async {
        controller.debounce(
          'test',
          () => controller.value++,
          duration: const Duration(milliseconds: 50),
        );

        await Future.delayed(const Duration(milliseconds: 60));

        expect(controller.value, 1);
      });
    });

    group('throttle', () {
      test('executes immediately', () {
        controller.throttle('test', () => controller.value++);

        expect(controller.value, 1);
      });

      test('blocks subsequent calls', () {
        controller.throttle('test', () => controller.value++);
        controller.throttle('test', () => controller.value++);
        controller.throttle('test', () => controller.value++);

        expect(controller.value, 1);
      });

      test('allows calls after duration', () async {
        controller.throttle(
          'test',
          () => controller.value++,
          duration: const Duration(milliseconds: 50),
        );

        expect(controller.value, 1);

        await Future.delayed(const Duration(milliseconds: 60));

        controller.throttle(
          'test',
          () => controller.value++,
          duration: const Duration(milliseconds: 50),
        );

        expect(controller.value, 2);
      });

      test('different IDs work independently', () {
        controller.throttle('action1', () => controller.log.add('action1'));
        controller.throttle('action2', () => controller.log.add('action2'));
        controller.throttle('action1', () => controller.log.add('action1-2'));
        controller.throttle('action2', () => controller.log.add('action2-2'));

        expect(controller.log, ['action1', 'action2']);
      });
    });

    group('debounceAsync', () {
      test('returns result after delay', () async {
        final result = await controller.debounceAsync(
          'test',
          () async {
            await Future.delayed(const Duration(milliseconds: 10));
            return 42;
          },
        );

        expect(result, 42);
      });

      test('cancels previous and returns last result', () async {
        final results = <int?>[];

        controller.debounceAsync('test', () async => 1).then((r) {
          if (r != null) results.add(r);
        });

        controller.debounceAsync('test', () async => 2).then((r) {
          if (r != null) results.add(r);
        });

        controller.debounceAsync('test', () async => 3).then((r) {
          if (r != null) results.add(r);
        });

        await Future.delayed(const Duration(milliseconds: 500));

        expect(results, [3]);
      });
    });

    group('throttleAsync', () {
      test('executes immediately', () async {
        int value = 0;

        await controller.throttleAsync(
          'test',
          () async {
            value = 42;
          },
        );

        expect(value, 42);
      });

      test('blocks while processing', () async {
        int executionCount = 0;

        final future1 = controller.throttleAsync('test', () async {
          await Future.delayed(const Duration(milliseconds: 50));
          executionCount++;
        });

        // This should be blocked since we're still processing
        final future2 = controller.throttleAsync('test', () async {
          executionCount++;
        });

        await Future.wait([future1, future2]);

        // Only the first should have executed
        expect(executionCount, 1);
      });
    });

    group('control methods', () {
      test('cancel cancels specific limiter', () async {
        controller.debounce('test', () => controller.value++);

        controller.cancel('test');

        await Future.delayed(const Duration(milliseconds: 400));

        expect(controller.value, 0);
      });

      test('cancelAll cancels all', () async {
        controller.debounce('test1', () => controller.log.add('test1'));
        controller.debounce('test2', () => controller.log.add('test2'));

        controller.cancelAll();

        await Future.delayed(const Duration(milliseconds: 400));

        expect(controller.log, isEmpty);
      });

      test('isLimiterActive returns correct state', () async {
        expect(controller.isLimiterActive('test'), false);

        controller.debounce('test', () {});

        expect(controller.isLimiterActive('test'), true);

        await Future.delayed(const Duration(milliseconds: 400));

        expect(controller.isLimiterActive('test'), false);
      });

      test('activeLimitersCount returns correct count', () {
        expect(controller.activeLimitersCount, 0);

        controller.debounce('test1', () {});
        expect(controller.activeLimitersCount, 1);

        controller.throttle('test2', () {});
        expect(controller.activeLimitersCount, 2);

        controller.cancel('test1');
        expect(controller.activeLimitersCount, 1);
      });
    });

    group('reuse', () {
      test('same ID reuses limiter', () async {
        controller.debounce('search', () => controller.value = 1);
        await Future.delayed(const Duration(milliseconds: 100));
        controller.debounce('search', () => controller.value = 2);
        await Future.delayed(const Duration(milliseconds: 100));
        controller.debounce('search', () => controller.value = 3);

        await Future.delayed(const Duration(milliseconds: 400));

        expect(controller.value, 3);
      });

      test('throttle with same ID reuses', () async {
        controller.throttle(
          'submit',
          () => controller.value++,
          duration: const Duration(milliseconds: 50),
        );
        controller.throttle(
          'submit',
          () => controller.value++,
          duration: const Duration(milliseconds: 50),
        );

        expect(controller.value, 1);

        await Future.delayed(const Duration(milliseconds: 60));

        controller.throttle(
          'submit',
          () => controller.value++,
          duration: const Duration(milliseconds: 50),
        );

        expect(controller.value, 2);
      });
    });
  });
}
