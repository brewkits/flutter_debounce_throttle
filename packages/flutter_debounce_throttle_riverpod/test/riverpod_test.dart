import 'dart:async';

import 'package:flutter_debounce_throttle_riverpod/flutter_debounce_throttle_riverpod.dart';
import 'package:riverpod/riverpod.dart';
import 'package:test/test.dart';

// ─── Fake Ref ─────────────────────────────────────────────────────────────────

/// Minimal Ref-like that captures onDispose callbacks for testing.
class _FakeRef {
  final List<void Function()> _onDispose = [];

  void onDispose(void Function() cb) => _onDispose.add(cb);

  void dispose() {
    for (final cb in _onDispose) {
      cb();
    }
    _onDispose.clear();
  }
}

class _FakeRiverpodRef implements Ref {
  final _fake = _FakeRef();

  @override
  void onDispose(void Function() cb) => _fake.onDispose(cb);

  void simulateDispose() => _fake.dispose();

  // Stub remaining Ref members — not used in tests
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

EventLimiterController _controller(_FakeRiverpodRef ref) =>
    EventLimiterController(ref);

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  // ─── Constructor & Lifecycle ─────────────────────────────────────────────

  group('EventLimiterController — lifecycle', () {
    test('registers onDispose with ref on construction', () {
      final ref = _FakeRiverpodRef();
      _controller(ref);
      expect(ref._fake._onDispose.length, 1);
    });

    test('standalone() does not register ref.onDispose', () {
      final ctrl = EventLimiterController.standalone();
      // No exception — no ref involved
      expect(() => ctrl.debounce('x', () {}), returnsNormally);
      ctrl.dispose();
    });

    test('ref.eventLimiter() extension creates controller', () {
      final ref = _FakeRiverpodRef();
      final ctrl = ref.eventLimiter();
      expect(ctrl, isA<EventLimiterController>());
    });

    test('cancelAll is called when provider is disposed', () async {
      final ref = _FakeRiverpodRef();
      final ctrl = _controller(ref);
      var fired = false;

      ctrl.debounce('x', () => fired = true,
          duration: const Duration(milliseconds: 200));

      ref.simulateDispose(); // triggers cancelAll via onDispose

      await Future.delayed(const Duration(milliseconds: 300));
      expect(fired, false); // debounce was cancelled
    });

    test('dispose() is idempotent', () {
      final ctrl = EventLimiterController.standalone();
      expect(() {
        ctrl.dispose();
        ctrl.dispose();
        ctrl.dispose();
      }, returnsNormally);
    });

    test('calls after dispose are silently dropped', () async {
      final ref = _FakeRiverpodRef();
      final ctrl = _controller(ref);
      ref.simulateDispose();

      var fired = false;
      ctrl.debounce('x', () => fired = true);
      ctrl.throttle('y', () => fired = true);
      await ctrl.debounceAsync('z', () async => fired = true);

      await Future.delayed(const Duration(milliseconds: 100));
      expect(fired, false);
    });

    test('multiple providers each get independent controllers', () {
      final ref1 = _FakeRiverpodRef();
      final ref2 = _FakeRiverpodRef();

      final ctrl1 = _controller(ref1);
      final ctrl2 = _controller(ref2);

      expect(identical(ctrl1, ctrl2), false);

      ref1.simulateDispose();
      // ctrl2 still usable
      expect(() => ctrl2.debounce('x', () {}), returnsNormally);
      ref2.simulateDispose();
    });
  });

  // ─── Debounce ────────────────────────────────────────────────────────────

  group('EventLimiterController — debounce', () {
    test('executes action after duration', () async {
      final ref = _FakeRiverpodRef();
      final ctrl = _controller(ref);
      var count = 0;

      ctrl.debounce('x', () => count++,
          duration: const Duration(milliseconds: 60));
      expect(count, 0);

      await Future.delayed(const Duration(milliseconds: 120));
      expect(count, 1);
      ref.simulateDispose();
    });

    test('100 rapid calls collapse to 1 execution', () async {
      final ref = _FakeRiverpodRef();
      final ctrl = _controller(ref);
      var count = 0;

      for (var i = 0; i < 100; i++) {
        ctrl.debounce('search', () => count++,
            duration: const Duration(milliseconds: 60));
      }

      await Future.delayed(const Duration(milliseconds: 120));
      expect(count, 1);
      ref.simulateDispose();
    });

    test('last value wins', () async {
      final ref = _FakeRiverpodRef();
      final ctrl = _controller(ref);
      var last = 0;

      for (var i = 1; i <= 10; i++) {
        final v = i;
        ctrl.debounce('x', () => last = v,
            duration: const Duration(milliseconds: 60));
      }

      await Future.delayed(const Duration(milliseconds: 120));
      expect(last, 10);
      ref.simulateDispose();
    });

    test('different IDs are independent', () async {
      final ref = _FakeRiverpodRef();
      final ctrl = _controller(ref);
      final log = <String>[];

      ctrl.debounce('a', () => log.add('a'),
          duration: const Duration(milliseconds: 60));
      ctrl.debounce('b', () => log.add('b'),
          duration: const Duration(milliseconds: 60));

      await Future.delayed(const Duration(milliseconds: 120));
      expect(log, containsAll(['a', 'b']));
      ref.simulateDispose();
    });

    test('cancel(id) prevents specific debounce from firing', () async {
      final ref = _FakeRiverpodRef();
      final ctrl = _controller(ref);
      var fired = false;

      ctrl.debounce('x', () => fired = true,
          duration: const Duration(milliseconds: 80));
      ctrl.cancel('x');

      await Future.delayed(const Duration(milliseconds: 150));
      expect(fired, false);
      ref.simulateDispose();
    });

    test('cancelAll() stops all pending debounces', () async {
      final ref = _FakeRiverpodRef();
      final ctrl = _controller(ref);
      var count = 0;

      for (var i = 0; i < 5; i++) {
        ctrl.debounce('k$i', () => count++,
            duration: const Duration(milliseconds: 80));
      }

      ctrl.cancelAll();

      await Future.delayed(const Duration(milliseconds: 150));
      expect(count, 0);
      ref.simulateDispose();
    });

    test('reuse same ID: timer resets correctly', () async {
      final ref = _FakeRiverpodRef();
      final ctrl = _controller(ref);
      var count = 0;

      ctrl.debounce('x', () => count++,
          duration: const Duration(milliseconds: 60));
      await Future.delayed(const Duration(milliseconds: 30));
      ctrl.debounce('x', () => count++,
          duration: const Duration(milliseconds: 60));

      await Future.delayed(const Duration(milliseconds: 120));
      expect(count, 1);
      ref.simulateDispose();
    });

    test('sequential debounces (with gap) each execute once', () async {
      final ref = _FakeRiverpodRef();
      final ctrl = _controller(ref);
      var count = 0;

      ctrl.debounce('x', () => count++,
          duration: const Duration(milliseconds: 50));
      await Future.delayed(const Duration(milliseconds: 100));

      ctrl.debounce('x', () => count++,
          duration: const Duration(milliseconds: 50));
      await Future.delayed(const Duration(milliseconds: 100));

      expect(count, 2);
      ref.simulateDispose();
    });
  });

  // ─── Throttle ────────────────────────────────────────────────────────────

  group('EventLimiterController — throttle', () {
    test('first call executes immediately', () {
      final ref = _FakeRiverpodRef();
      final ctrl = _controller(ref);
      var count = 0;

      ctrl.throttle('x', () => count++,
          duration: const Duration(milliseconds: 100));
      expect(count, 1);
      ref.simulateDispose();
    });

    test('subsequent calls within duration are dropped', () {
      final ref = _FakeRiverpodRef();
      final ctrl = _controller(ref);
      var count = 0;

      for (var i = 0; i < 10; i++) {
        ctrl.throttle('x', () => count++,
            duration: const Duration(milliseconds: 200));
      }

      expect(count, 1);
      ref.simulateDispose();
    });

    test('allows execution after cooldown', () async {
      final ref = _FakeRiverpodRef();
      final ctrl = _controller(ref);
      var count = 0;

      ctrl.throttle('x', () => count++,
          duration: const Duration(milliseconds: 50));
      await Future.delayed(const Duration(milliseconds: 100));
      ctrl.throttle('x', () => count++,
          duration: const Duration(milliseconds: 50));

      expect(count, 2);
      ref.simulateDispose();
    });

    test('different IDs throttle independently', () {
      final ref = _FakeRiverpodRef();
      final ctrl = _controller(ref);
      var aCount = 0;
      var bCount = 0;

      for (var i = 0; i < 5; i++) {
        ctrl.throttle('a', () => aCount++,
            duration: const Duration(milliseconds: 200));
        ctrl.throttle('b', () => bCount++,
            duration: const Duration(milliseconds: 200));
      }

      expect(aCount, 1);
      expect(bCount, 1);
      ref.simulateDispose();
    });

    test('cancel(id) stops throttle lock — next call executes', () async {
      final ref = _FakeRiverpodRef();
      final ctrl = _controller(ref);
      var count = 0;

      ctrl.throttle('x', () => count++,
          duration: const Duration(milliseconds: 200));
      ctrl.cancel('x'); // remove lock

      ctrl.throttle('x', () => count++,
          duration: const Duration(milliseconds: 200));
      expect(count, 2);
      ref.simulateDispose();
    });

    test('isActive returns true while locked', () async {
      final ref = _FakeRiverpodRef();
      final ctrl = _controller(ref);

      ctrl.throttle('x', () {},
          duration: const Duration(milliseconds: 200));
      expect(ctrl.isActive('x'), true);

      ref.simulateDispose();
    });
  });

  // ─── Async Debounce ───────────────────────────────────────────────────────

  group('EventLimiterController — debounceAsync', () {
    test('resolves with value after duration', () async {
      final ref = _FakeRiverpodRef();
      final ctrl = _controller(ref);

      final result = await ctrl.debounceAsync(
        'fetch',
        () async => 'data',
        duration: const Duration(milliseconds: 50),
      );

      expect(result, 'data');
      ref.simulateDispose();
    });

    test('rapid calls: only last resolves with value, rest return null',
        () async {
      final ref = _FakeRiverpodRef();
      final ctrl = _controller(ref);

      final futures = <Future<String?>>[];
      for (var i = 0; i < 5; i++) {
        final v = 'result$i';
        futures.add(ctrl.debounceAsync('fetch', () async => v,
            duration: const Duration(milliseconds: 60)));
      }

      final results = await Future.wait(futures);
      final nonNull = results.where((r) => r != null).toList();
      expect(nonNull.length, 1);
      expect(nonNull.first, 'result4');
      ref.simulateDispose();
    });

    test('debounceAsyncResult distinguishes null value from cancellation',
        () async {
      final ref = _FakeRiverpodRef();
      final ctrl = _controller(ref);

      final f1 = ctrl.debounceAsyncResult<String?>(
        'search',
        () async => null, // legitimate null
        duration: const Duration(milliseconds: 60),
      );
      final f2 = ctrl.debounceAsyncResult<String?>(
        'search',
        () async => 'data',
        duration: const Duration(milliseconds: 60),
      );

      final r1 = await f1;
      final r2 = await f2;

      expect(r1.isCancelled, true);
      expect(r2.isSuccess, true);
      expect(r2.value, 'data');
      ref.simulateDispose();
    });

    test('debounceAsyncResult.when() maps to correct branch', () async {
      final ref = _FakeRiverpodRef();
      final ctrl = _controller(ref);
      final log = <String>[];

      final result = await ctrl.debounceAsyncResult<List<String>>(
        'search',
        () async => ['item1', 'item2'],
        duration: const Duration(milliseconds: 50),
      );

      result.when(
        onSuccess: (data) => log.add('loaded:${data?.length}'),
        onCancelled: () => log.add('cancelled'),
      );

      expect(log, ['loaded:2']);
      ref.simulateDispose();
    });

    test('cancellation from provider dispose resolves as null', () async {
      final ref = _FakeRiverpodRef();
      final ctrl = _controller(ref);

      final future = ctrl.debounceAsync<String>(
        'fetch',
        () async => 'data',
        duration: const Duration(milliseconds: 300),
      );

      ref.simulateDispose(); // cancels pending debounce

      final result = await future;
      expect(result, isNull);
    });

    test('cancel(id) resolves future as null', () async {
      final ref = _FakeRiverpodRef();
      final ctrl = _controller(ref);

      final future = ctrl.debounceAsync<String>(
        'fetch',
        () async => 'data',
        duration: const Duration(milliseconds: 200),
      );

      ctrl.cancel('fetch');
      final result = await future;
      expect(result, isNull);
    });
  });

  // ─── Async Throttle ───────────────────────────────────────────────────────

  group('EventLimiterController — throttleAsync', () {
    test('first call executes, concurrent calls are ignored', () async {
      final ref = _FakeRiverpodRef();
      final ctrl = _controller(ref);
      var count = 0;

      // Fire and forget first (slow)
      unawaited(ctrl.throttleAsync(
        'upload',
        () async {
          await Future.delayed(const Duration(milliseconds: 100));
          count++;
        },
      ));

      // These are ignored while first is running
      for (var i = 0; i < 5; i++) {
        unawaited(ctrl.throttleAsync('upload', () async => count++));
      }

      await Future.delayed(const Duration(milliseconds: 200));
      expect(count, 1);
      ref.simulateDispose();
    });

    test('executes after previous completes', () async {
      final ref = _FakeRiverpodRef();
      final ctrl = _controller(ref);
      var count = 0;

      await ctrl.throttleAsync(
        'x',
        () async {
          await Future.delayed(const Duration(milliseconds: 30));
          count++;
        },
        maxDuration: const Duration(seconds: 5),
      );

      await ctrl.throttleAsync(
        'x',
        () async => count++,
        maxDuration: const Duration(seconds: 5),
      );

      expect(count, 2);
      ref.simulateDispose();
    });
  });

  // ─── isActive ─────────────────────────────────────────────────────────────

  group('EventLimiterController — isActive', () {
    test('isActive false for unknown key', () {
      final ref = _FakeRiverpodRef();
      final ctrl = _controller(ref);
      expect(ctrl.isActive('unknown'), false);
      ref.simulateDispose();
    });

    test('isActive true while debounce pending', () async {
      final ref = _FakeRiverpodRef();
      final ctrl = _controller(ref);

      ctrl.debounce('x', () {},
          duration: const Duration(milliseconds: 200));
      expect(ctrl.isActive('x'), true);

      ref.simulateDispose();
    });

    test('isActive false after cancel', () {
      final ref = _FakeRiverpodRef();
      final ctrl = _controller(ref);

      ctrl.debounce('x', () {},
          duration: const Duration(milliseconds: 200));
      ctrl.cancel('x');

      expect(ctrl.isActive('x'), false);
      ref.simulateDispose();
    });
  });

  // ─── Real-World: Search Notifier Simulation ───────────────────────────────

  group('Real-world: search notifier simulation', () {
    test('debounced search: only last query reaches API', () async {
      final ref = _FakeRiverpodRef();
      final ctrl = _controller(ref);
      final apiHits = <String>[];

      Future<void> onSearch(String query) async {
        await ctrl.debounceAsync<List<String>>(
          'search',
          () async {
            apiHits.add(query);
            return ['result:$query'];
          },
          duration: const Duration(milliseconds: 60),
        );
      }

      unawaited(onSearch('a'));
      await Future.delayed(const Duration(milliseconds: 20));
      unawaited(onSearch('ab'));
      await Future.delayed(const Duration(milliseconds: 20));
      unawaited(onSearch('abc'));

      await Future.delayed(const Duration(milliseconds: 150));

      expect(apiHits, ['abc']); // Only the last query hit the API
      ref.simulateDispose();
    });

    test('throttled save: rapid saves produce 1 API call', () async {
      final ref = _FakeRiverpodRef();
      final ctrl = _controller(ref);
      var saveCount = 0;

      for (var i = 0; i < 10; i++) {
        ctrl.throttle('save', () => saveCount++,
            duration: const Duration(milliseconds: 200));
        await Future.delayed(const Duration(milliseconds: 10));
      }

      expect(saveCount, 1);
      ref.simulateDispose();
    });

    test('provider dispose cancels in-flight debounce', () async {
      final ref = _FakeRiverpodRef();
      final ctrl = _controller(ref);
      var stateUpdated = false;

      unawaited(ctrl.debounceAsync<String>(
        'search',
        () async {
          await Future.delayed(const Duration(milliseconds: 100));
          return 'result';
        },
        duration: const Duration(milliseconds: 50),
      ).then((result) {
        if (result != null) stateUpdated = true;
      }));

      await Future.delayed(const Duration(milliseconds: 60));
      ref.simulateDispose(); // Provider invalidated

      await Future.delayed(const Duration(milliseconds: 200));
      expect(stateUpdated, false); // State not updated after dispose
    });

    test('DebounceResult.when() enables clean BLoC/Notifier emit pattern',
        () async {
      final ref = _FakeRiverpodRef();
      final ctrl = _controller(ref);
      final states = <String>[];

      Future<void> onQuery(String query) async {
        final result = await ctrl.debounceAsyncResult<List<String>>(
          'query',
          () async => ['item:$query'],
          duration: const Duration(milliseconds: 40),
        );
        result.when(
          onSuccess: (data) => states.add('Loaded(${data?.length})'),
          onCancelled: () => states.add('Idle'),
        );
      }

      // Rapid burst → only last completes as success
      unawaited(onQuery('a'));
      await Future.delayed(const Duration(milliseconds: 15));
      unawaited(onQuery('ab'));
      await Future.delayed(const Duration(milliseconds: 15));
      unawaited(onQuery('abc'));

      await Future.delayed(const Duration(milliseconds: 150));

      final loaded = states.where((s) => s.startsWith('Loaded'));
      expect(loaded.length, 1);
      expect(loaded.first, 'Loaded(1)');
      ref.simulateDispose();
    });

    test('multiple operations on same controller are independent', () async {
      final ref = _FakeRiverpodRef();
      final ctrl = _controller(ref);
      var searchCount = 0;
      var saveCount = 0;

      // Debounce search: rapid calls collapse
      for (var i = 0; i < 5; i++) {
        ctrl.debounce('search', () => searchCount++,
            duration: const Duration(milliseconds: 60));
        await Future.delayed(const Duration(milliseconds: 10));
      }

      // Throttle save: fires once
      for (var i = 0; i < 5; i++) {
        ctrl.throttle('save', () => saveCount++,
            duration: const Duration(milliseconds: 100));
      }

      await Future.delayed(const Duration(milliseconds: 150));

      expect(searchCount, 1);
      expect(saveCount, 1);
      ref.simulateDispose();
    });
  });

  // ─── Standalone Usage ─────────────────────────────────────────────────────

  group('EventLimiterController.standalone', () {
    test('debounce works without ref', () async {
      final ctrl = EventLimiterController.standalone();
      var count = 0;

      ctrl.debounce('x', () => count++,
          duration: const Duration(milliseconds: 50));
      await Future.delayed(const Duration(milliseconds: 100));

      expect(count, 1);
      ctrl.dispose();
    });

    test('dispose cancels pending timers', () async {
      final ctrl = EventLimiterController.standalone();
      var fired = false;

      ctrl.debounce('x', () => fired = true,
          duration: const Duration(milliseconds: 100));
      ctrl.dispose();

      await Future.delayed(const Duration(milliseconds: 200));
      expect(fired, false);
    });

    test('throttle works without ref', () {
      final ctrl = EventLimiterController.standalone();
      var count = 0;

      ctrl.throttle('x', () => count++,
          duration: const Duration(milliseconds: 100));
      ctrl.throttle('x', () => count++,
          duration: const Duration(milliseconds: 100));

      expect(count, 1);
      ctrl.dispose();
    });
  });
}
