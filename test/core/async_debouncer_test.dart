import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_debounce_throttle/core.dart';

void main() {
  group('AsyncDebouncer', () {
    late AsyncDebouncer debouncer;

    tearDown(() {
      debouncer.dispose();
    });

    test('executes async callback after delay', () async {
      debouncer = AsyncDebouncer(duration: const Duration(milliseconds: 50));
      int? result;

      debouncer.call(() async {
        await Future.delayed(const Duration(milliseconds: 10));
        return 42;
      }).then((r) => result = r);

      expect(result, isNull);

      await Future.delayed(const Duration(milliseconds: 80));
      expect(result, 42);
    });

    test('cancels previous calls and only returns last result', () async {
      debouncer = AsyncDebouncer(duration: const Duration(milliseconds: 50));
      final results = <int>[];

      debouncer.call(() async {
        await Future.delayed(const Duration(milliseconds: 10));
        return 1;
      }).then((r) {
        if (r != null) results.add(r);
      });

      debouncer.call(() async {
        await Future.delayed(const Duration(milliseconds: 10));
        return 2;
      }).then((r) {
        if (r != null) results.add(r);
      });

      debouncer.call(() async {
        await Future.delayed(const Duration(milliseconds: 10));
        return 3;
      }).then((r) {
        if (r != null) results.add(r);
      });

      await Future.delayed(const Duration(milliseconds: 100));
      expect(results, [3]);
    });

    test('returns null for cancelled calls', () async {
      debouncer = AsyncDebouncer(duration: const Duration(milliseconds: 50));
      int? result1;
      int? result2;

      debouncer.call(() async => 1).then((r) => result1 = r);
      debouncer.call(() async => 2).then((r) => result2 = r);

      await Future.delayed(const Duration(milliseconds: 100));

      expect(result1, isNull); // Cancelled
      expect(result2, 2); // Executed
    });

    test('isPending returns correct state', () async {
      debouncer = AsyncDebouncer(duration: const Duration(milliseconds: 50));

      expect(debouncer.isPending, false);

      debouncer.call(() async {
        await Future.delayed(const Duration(milliseconds: 10));
        return 1;
      });

      expect(debouncer.isPending, true);

      await Future.delayed(const Duration(milliseconds: 80));
      expect(debouncer.isPending, false);
    });

    test('cancel() prevents pending execution', () async {
      debouncer = AsyncDebouncer(duration: const Duration(milliseconds: 50));
      int? result;

      debouncer.call(() async => 42).then((r) => result = r);
      debouncer.cancel();

      await Future.delayed(const Duration(milliseconds: 100));
      expect(result, isNull);
    });

    test('enabled=false bypasses debounce', () async {
      debouncer = AsyncDebouncer(
        duration: const Duration(milliseconds: 100),
        enabled: false,
      );

      final result = await debouncer.call(() async => 42);
      expect(result, 42);
    });

    test('debugMode logs messages', () async {
      debouncer = AsyncDebouncer(
        duration: const Duration(milliseconds: 50),
        debugMode: true,
        name: 'TestAsyncDebouncer',
      );

      final result = await debouncer.call(() async => 42);
      expect(result, 42);
    });

    test('dispose cancels pending operations', () async {
      debouncer = AsyncDebouncer(duration: const Duration(milliseconds: 100));
      int? result;

      debouncer.call(() async => 42).then((r) => result = r);

      await Future.delayed(const Duration(milliseconds: 20));
      debouncer.dispose();

      await Future.delayed(const Duration(milliseconds: 100));
      expect(result, isNull);
    });

    test('rapid calls only execute last', () async {
      debouncer = AsyncDebouncer(duration: const Duration(milliseconds: 50));
      int executionCount = 0;

      for (var i = 0; i < 10; i++) {
        debouncer.call(() async {
          executionCount++;
          return i;
        });
      }

      await Future.delayed(const Duration(milliseconds: 100));
      expect(executionCount, 1);
    });

    test('works with different return types', () async {
      final stringDebouncer = AsyncDebouncer(
        duration: const Duration(milliseconds: 50),
      );

      final result = await stringDebouncer.call(() async => 'hello');
      expect(result, 'hello');

      stringDebouncer.dispose();
    });

    test('handles errors in async callback', () async {
      debouncer = AsyncDebouncer(duration: const Duration(milliseconds: 50));

      expect(
        () async {
          await debouncer.call(() async {
            throw Exception('Test error');
          });
        },
        throwsException,
      );
    });
  });
}
