import 'dart:async';

import 'package:dart_debounce_throttle/dart_debounce_throttle.dart';
import 'package:test/test.dart';

void main() {
  group('Stream Extensions', () {
    test('debounce should delay stream events', () async {
      final controller = StreamController<int>();
      final results = <int>[];

      final subscription = controller.stream
          .debounce(const Duration(milliseconds: 100))
          .listen(results.add);

      controller.add(1);
      await Future.delayed(const Duration(milliseconds: 50));
      controller.add(2);
      await Future.delayed(const Duration(milliseconds: 50));
      controller.add(3);

      await Future.delayed(const Duration(milliseconds: 150));

      expect(results, [3]);

      await subscription.cancel();
      await controller.close();
    });

    test('throttle should emit first event immediately', () async {
      final controller = StreamController<int>();
      final results = <int>[];

      final subscription = controller.stream
          .throttle(const Duration(milliseconds: 100))
          .listen(results.add);

      controller.add(1);
      await Future.delayed(const Duration(milliseconds: 50));
      controller.add(2);
      await Future.delayed(const Duration(milliseconds: 50));
      controller.add(3);

      await Future.delayed(const Duration(milliseconds: 150));
      controller.add(4);

      await Future.delayed(const Duration(milliseconds: 50));

      expect(results, [1, 4]);

      await subscription.cancel();
      await controller.close();
    });

    test('debounce should handle broadcast streams', () async {
      final controller = StreamController<int>.broadcast();
      final results1 = <int>[];
      final results2 = <int>[];

      final debouncedStream = controller.stream
          .debounce(const Duration(milliseconds: 100));

      final subscription1 = debouncedStream.listen(results1.add);
      final subscription2 = debouncedStream.listen(results2.add);

      controller.add(1);
      await Future.delayed(const Duration(milliseconds: 50));
      controller.add(2);

      await Future.delayed(const Duration(milliseconds: 150));

      expect(results1, [2]);
      expect(results2, [2]);

      await subscription1.cancel();
      await subscription2.cancel();
      await controller.close();
    });

    test('throttle should handle broadcast streams', () async {
      final controller = StreamController<int>.broadcast();
      final results1 = <int>[];
      final results2 = <int>[];

      final throttledStream = controller.stream
          .throttle(const Duration(milliseconds: 100));

      final subscription1 = throttledStream.listen(results1.add);
      final subscription2 = throttledStream.listen(results2.add);

      controller.add(1);
      await Future.delayed(const Duration(milliseconds: 50));
      controller.add(2);

      await Future.delayed(const Duration(milliseconds: 150));
      controller.add(3);

      await Future.delayed(const Duration(milliseconds: 50));

      expect(results1, [1, 3]);
      expect(results2, [1, 3]);

      await subscription1.cancel();
      await subscription2.cancel();
      await controller.close();
    });
  });
}
