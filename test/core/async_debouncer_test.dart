import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_debounce_throttle/flutter_debounce_throttle.dart';

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

  group('DebounceResult', () {
    test('cancelled result has correct properties', () {
      const result = DebounceResult<int>.cancelled();

      expect(result.isCancelled, true);
      expect(result.isSuccess, false);
      expect(result.value, isNull);
      expect(result.toString(), 'DebounceResult.cancelled');
    });

    test('success result with value has correct properties', () {
      const result = DebounceResult<int>.success(42);

      expect(result.isCancelled, false);
      expect(result.isSuccess, true);
      expect(result.value, 42);
      expect(result.toString(), 'DebounceResult.success(42)');
    });

    test('success result with null value has correct properties', () {
      const result = DebounceResult<int?>.success(null);

      expect(result.isCancelled, false);
      expect(result.isSuccess, true);
      expect(result.value, isNull);
      expect(result.toString(), 'DebounceResult.success(null)');
    });
  });

  group('AsyncDebouncer.callWithResult', () {
    late AsyncDebouncer debouncer;

    tearDown(() {
      debouncer.dispose();
    });

    test('returns success result with value', () async {
      debouncer = AsyncDebouncer(duration: const Duration(milliseconds: 50));

      final result = await debouncer.callWithResult(() async => 42);

      expect(result.isSuccess, true);
      expect(result.isCancelled, false);
      expect(result.value, 42);
    });

    test('returns success result with null value (not cancelled)', () async {
      debouncer = AsyncDebouncer(duration: const Duration(milliseconds: 50));

      final result = await debouncer.callWithResult<int?>(() async => null);

      expect(result.isSuccess, true);
      expect(result.isCancelled, false);
      expect(result.value, isNull);
    });

    test('returns cancelled result when superseded', () async {
      debouncer = AsyncDebouncer(duration: const Duration(milliseconds: 50));

      DebounceResult<int>? result1;
      DebounceResult<int>? result2;

      debouncer.callWithResult(() async => 1).then((r) => result1 = r);
      debouncer.callWithResult(() async => 2).then((r) => result2 = r);

      await Future.delayed(const Duration(milliseconds: 100));

      expect(result1!.isCancelled, true);
      expect(result1!.value, isNull);
      expect(result2!.isSuccess, true);
      expect(result2!.value, 2);
    });

    test('distinguishes cancelled from actual null result', () async {
      debouncer = AsyncDebouncer(duration: const Duration(milliseconds: 50));

      DebounceResult<String?>? cancelledResult;
      DebounceResult<String?>? nullResult;

      // First call will be cancelled
      debouncer.callWithResult<String?>(() async => 'first').then((r) => cancelledResult = r);
      // Second call returns actual null
      debouncer.callWithResult<String?>(() async => null).then((r) => nullResult = r);

      await Future.delayed(const Duration(milliseconds: 100));

      // Cancelled call
      expect(cancelledResult!.isCancelled, true);
      expect(cancelledResult!.value, isNull);

      // Actual null result (not cancelled)
      expect(nullResult!.isCancelled, false);
      expect(nullResult!.isSuccess, true);
      expect(nullResult!.value, isNull);
    });

    test('returns cancelled when cancel() is called', () async {
      debouncer = AsyncDebouncer(duration: const Duration(milliseconds: 100));

      DebounceResult<int>? result;
      debouncer.callWithResult(() async => 42).then((r) => result = r);

      await Future.delayed(const Duration(milliseconds: 20));
      debouncer.cancel();

      await Future.delayed(const Duration(milliseconds: 100));

      expect(result!.isCancelled, true);
    });

    test('enabled=false bypasses debounce and returns success', () async {
      debouncer = AsyncDebouncer(
        duration: const Duration(milliseconds: 100),
        enabled: false,
      );

      final result = await debouncer.callWithResult(() async => 42);

      expect(result.isSuccess, true);
      expect(result.value, 42);
    });

    test('handles errors and does not return cancelled', () async {
      debouncer = AsyncDebouncer(duration: const Duration(milliseconds: 50));

      expect(
        () async {
          await debouncer.callWithResult(() async {
            throw Exception('Test error');
          });
        },
        throwsException,
      );
    });
  });
}
