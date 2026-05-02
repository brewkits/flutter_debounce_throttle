import 'dart:async';

import 'package:flutter_debounce_throttle/flutter_debounce_throttle.dart';
import 'package:flutter_test/flutter_test.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _SearchViewModel with EventLimiterMixin {
  List<String> results = [];
  int searchCount = 0;
  int cancelledCount = 0;

  Future<void> onSearch(String query) async {
    // debounceAsync returns T? — null means cancelled or actual null result
    final data = await debounceAsync<List<String>>(
      'search',
      () async {
        await Future.delayed(const Duration(milliseconds: 30));
        return ['result:$query'];
      },
      duration: const Duration(milliseconds: 50),
    );
    if (data != null) {
      results = data;
      searchCount++;
    } else {
      cancelledCount++;
    }
  }

  void dispose() => cancelAll();
}

class _BlocLikeController with EventLimiterMixin {
  final List<String> states = [];
  int emitCount = 0;

  void emit(String state) {
    states.add(state);
    emitCount++;
  }

  Future<void> onQueryChanged(String query) async {
    final data = await debounceAsync<List<String>>(
      'query',
      () async {
        await Future.delayed(const Duration(milliseconds: 20));
        return ['item:$query'];
      },
      duration: const Duration(milliseconds: 40),
    );
    if (data != null) {
      emit('Loaded(${data.length})');
    } else {
      emit('Idle');
    }
  }

  void dispose() => cancelAll();
}

class _MultiKeyController with EventLimiterMixin {
  int totalDebounces = 0;
  int totalThrottles = 0;

  void debounceKey(String key) {
    debounce(key, () => totalDebounces++,
        duration: const Duration(milliseconds: 50));
  }

  void throttleKey(String key) {
    throttle(key, () => totalThrottles++,
        duration: const Duration(milliseconds: 50));
  }

  void dispose() => cancelAll();
}

class _PaymentController with EventLimiterMixin {
  int successCount = 0;
  int attemptCount = 0;

  void submitPayment() {
    attemptCount++;
    throttle('payment', () => successCount++,
        duration: const Duration(milliseconds: 200));
  }

  void dispose() => cancelAll();
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  // ─── EventLimiterMixin Stress ────────────────────────────────────────────

  group('EventLimiterMixin stress', () {
    test('50 unique debounce keys all fire independently', () async {
      final controller = _MultiKeyController();

      for (var i = 0; i < 50; i++) {
        controller.debounceKey('key_$i');
      }

      await Future.delayed(const Duration(milliseconds: 200));

      expect(controller.totalDebounces, 50);
      controller.dispose();
    });

    test('rapid calls on same key collapse to 1 execution', () async {
      final controller = _MultiKeyController();

      for (var i = 0; i < 100; i++) {
        controller.debounceKey('same_key');
      }

      await Future.delayed(const Duration(milliseconds: 200));

      expect(controller.totalDebounces, 1);
      controller.dispose();
    });

    test('50 unique throttle keys all fire independently', () async {
      final controller = _MultiKeyController();

      for (var i = 0; i < 50; i++) {
        controller.throttleKey('throttle_$i');
      }

      expect(controller.totalThrottles, 50);
      controller.dispose();
    });

    test('cancelAll stops all pending debounces', () async {
      final controller = _MultiKeyController();

      for (var i = 0; i < 10; i++) {
        controller.debounceKey('key_$i');
      }

      controller.cancelAll();

      await Future.delayed(const Duration(milliseconds: 200));

      expect(controller.totalDebounces, 0);
      controller.dispose();
    });

    test('cancel(id) stops only the targeted key', () async {
      final controller = _MultiKeyController();

      controller.debounceKey('target');
      controller.debounceKey('keep');

      controller.cancel('target');

      await Future.delayed(const Duration(milliseconds: 200));

      expect(controller.totalDebounces, 1);
      controller.dispose();
    });

    test('dispose() is safe to call multiple times', () {
      final controller = _MultiKeyController();
      for (var i = 0; i < 5; i++) {
        controller.debounceKey('key_$i');
      }
      expect(() {
        controller.dispose();
        controller.dispose();
      }, returnsNormally);
    });

    test('isLimiterActive returns true while pending', () async {
      final controller = _MultiKeyController();

      controller.debounceKey('watch');
      expect(controller.isLimiterActive('watch'), true);

      await Future.delayed(const Duration(milliseconds: 200));
      expect(controller.isLimiterActive('watch'), false);

      controller.dispose();
    });

    test('activeLimitersCount tracks unique active keys', () async {
      final controller = _MultiKeyController();

      for (var i = 0; i < 5; i++) {
        controller.debounceKey('key_$i');
      }

      expect(controller.activeLimitersCount, greaterThanOrEqualTo(1));
      controller.dispose();
    });

    test('reusing the same ID reuses the limiter object', () async {
      final controller = _MultiKeyController();

      controller.debounceKey('reuse');
      final countBefore = controller.activeLimitersCount;

      controller.debounceKey('reuse');
      final countAfter = controller.activeLimitersCount;

      expect(countAfter, countBefore);
      controller.dispose();
    });

    test('100 throttle calls on same key: only 1 executes in interval',
        () async {
      final controller = _MultiKeyController();

      for (var i = 0; i < 100; i++) {
        controller.throttleKey('burst');
      }

      expect(controller.totalThrottles, 1);
      controller.dispose();
    });
  });

  // ─── System: ViewModel (MVVM) Pattern ───────────────────────────────────

  group('System: ViewModel (MVVM) pattern', () {
    test('rapid search input: only last query resolves with data', () async {
      final vm = _SearchViewModel();

      for (var i = 0; i < 5; i++) {
        unawaited(vm.onSearch('query_$i'));
        await Future.delayed(const Duration(milliseconds: 20));
      }

      await Future.delayed(const Duration(milliseconds: 200));

      expect(vm.searchCount, 1);
      expect(vm.results, ['result:query_4']);
      vm.dispose();
    });

    test('cancelled searches increment cancelledCount', () async {
      final vm = _SearchViewModel();

      for (var i = 0; i < 3; i++) {
        unawaited(vm.onSearch('q$i'));
        await Future.delayed(const Duration(milliseconds: 20));
      }

      await Future.delayed(const Duration(milliseconds: 200));

      expect(vm.cancelledCount, greaterThan(0));
      vm.dispose();
    });

    test('dispose during pending search: no crash', () async {
      final vm = _SearchViewModel();
      unawaited(vm.onSearch('query'));
      vm.dispose();

      await Future.delayed(const Duration(milliseconds: 200));
    });

    test('sequential searches (with gap) each complete successfully',
        () async {
      final vm = _SearchViewModel();

      unawaited(vm.onSearch('first'));
      await Future.delayed(const Duration(milliseconds: 200));

      unawaited(vm.onSearch('second'));
      await Future.delayed(const Duration(milliseconds: 200));

      expect(vm.searchCount, 2);
      expect(vm.results, ['result:second']);
      vm.dispose();
    });

    test('ViewModel cancelAll + re-use: state resets correctly', () async {
      final vm = _SearchViewModel();

      unawaited(vm.onSearch('first'));
      await Future.delayed(const Duration(milliseconds: 200));

      expect(vm.searchCount, 1);
      vm.cancelAll();

      unawaited(vm.onSearch('second'));
      await Future.delayed(const Duration(milliseconds: 200));

      expect(vm.searchCount, 2);
      vm.dispose();
    });
  });

  // ─── System: BLoC Pattern ────────────────────────────────────────────────

  group('System: BLoC pattern', () {
    test('rapid query events: only last emits Loaded', () async {
      final bloc = _BlocLikeController();

      for (var i = 0; i < 5; i++) {
        unawaited(bloc.onQueryChanged('q$i'));
        await Future.delayed(const Duration(milliseconds: 15));
      }

      await Future.delayed(const Duration(milliseconds: 200));

      final loadedStates = bloc.states.where((s) => s.startsWith('Loaded'));
      expect(loadedStates.length, 1);
      expect(loadedStates.first, 'Loaded(1)');
      bloc.dispose();
    });

    test('cancelled calls emit Idle state', () async {
      final bloc = _BlocLikeController();

      for (var i = 0; i < 3; i++) {
        unawaited(bloc.onQueryChanged('q$i'));
        await Future.delayed(const Duration(milliseconds: 15));
      }

      await Future.delayed(const Duration(milliseconds: 200));

      expect(bloc.states, contains('Idle'));
      bloc.dispose();
    });

    test('sequential queries emit correct state sequence', () async {
      final bloc = _BlocLikeController();

      unawaited(bloc.onQueryChanged('first'));
      await Future.delayed(const Duration(milliseconds: 150));

      unawaited(bloc.onQueryChanged('second'));
      await Future.delayed(const Duration(milliseconds: 150));

      expect(bloc.emitCount, 2);
      bloc.dispose();
    });

    test('emit count matches expected (1 success per burst)', () async {
      final bloc = _BlocLikeController();

      // 3 bursts with gaps
      for (var burst = 0; burst < 3; burst++) {
        for (var i = 0; i < 5; i++) {
          unawaited(bloc.onQueryChanged('b${burst}_q$i'));
          await Future.delayed(const Duration(milliseconds: 10));
        }
        await Future.delayed(const Duration(milliseconds: 150));
      }

      final loadedCount =
          bloc.states.where((s) => s.startsWith('Loaded')).length;
      expect(loadedCount, 3);
      bloc.dispose();
    });
  });

  // ─── System: Payment Button (Throttle Pattern) ───────────────────────────

  group('System: payment button (throttle pattern)', () {
    test('rapid double-taps produce 1 payment, rest dropped', () async {
      final ctrl = _PaymentController();

      // Simulate rapid taps in quick succession
      for (var i = 0; i < 5; i++) {
        ctrl.submitPayment();
        await Future.delayed(const Duration(milliseconds: 10));
      }

      // Only 1 should have succeeded (throttle locks for 200ms)
      expect(ctrl.successCount, 1);
      expect(ctrl.attemptCount, 5);
      ctrl.dispose();
    });

    test('payment after cooldown succeeds again', () async {
      final ctrl = _PaymentController();

      ctrl.submitPayment();
      await Future.delayed(const Duration(milliseconds: 300));

      ctrl.submitPayment();
      await Future.delayed(const Duration(milliseconds: 300));

      expect(ctrl.successCount, 2);
      ctrl.dispose();
    });

    test('burst then cooldown: exactly N executions across N windows',
        () async {
      final ctrl = _PaymentController();

      // 3 windows of rapid taps, each separated by 300ms cooldown
      for (var window = 0; window < 3; window++) {
        for (var tap = 0; tap < 5; tap++) {
          ctrl.submitPayment();
          await Future.delayed(const Duration(milliseconds: 10));
        }
        await Future.delayed(const Duration(milliseconds: 300));
      }

      expect(ctrl.successCount, 3);
      ctrl.dispose();
    });

    test('single payment always succeeds when no contention', () async {
      final ctrl = _PaymentController();

      ctrl.submitPayment();

      expect(ctrl.successCount, 1);
      ctrl.dispose();
    });
  });

  // ─── System: High-Frequency UI Events ───────────────────────────────────

  group('System: high-frequency UI events', () {
    test('scroll handler: 60fps events throttled to reasonable rate', () async {
      final controller = _MultiKeyController();
      var scrollHandled = 0;

      final timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
        controller.throttle(
          'scroll',
          () => scrollHandled++,
          duration: const Duration(milliseconds: 100),
        );
      });

      await Future.delayed(const Duration(milliseconds: 500));
      timer.cancel();

      // ~30 events at 60fps over 500ms; with 100ms throttle: at most 5-6
      expect(scrollHandled, lessThanOrEqualTo(10));
      expect(scrollHandled, greaterThanOrEqualTo(3));
      controller.dispose();
    });

    test('resize handler: debounced to fire once after pause', () async {
      final controller = _MultiKeyController();

      // Simulate rapid resize events
      for (var i = 0; i < 30; i++) {
        controller.debounce(
          'resize',
          () => controller.totalDebounces++,
          duration: const Duration(milliseconds: 100),
        );
        await Future.delayed(const Duration(milliseconds: 10));
      }

      await Future.delayed(const Duration(milliseconds: 200));

      expect(controller.totalDebounces, 1);
      controller.dispose();
    });

    test('keyboard input: debounce prevents search on every keystroke',
        () async {
      final controller = _MultiKeyController();
      const input = 'hello world';

      for (final _ in input.split('')) {
        controller.debounce(
          'search',
          () => controller.totalDebounces++,
          duration: const Duration(milliseconds: 80),
        );
        await Future.delayed(const Duration(milliseconds: 20));
      }

      await Future.delayed(const Duration(milliseconds: 200));

      expect(controller.totalDebounces, 1);
      controller.dispose();
    });

    test('button with throttle: prevents double-submit', () async {
      final controller = _MultiKeyController();

      // Simulate rapid clicks (double-tap)
      for (var i = 0; i < 5; i++) {
        controller.throttle('submit', () => controller.totalThrottles++,
            duration: const Duration(milliseconds: 300));
        await Future.delayed(const Duration(milliseconds: 50));
      }

      expect(controller.totalThrottles, 1);
      controller.dispose();
    });

    test('window resize: trailing-only debounce fires after silence', () async {
      final controller = _MultiKeyController();

      for (var i = 0; i < 10; i++) {
        controller.debounce(
          'window_resize',
          () => controller.totalDebounces++,
          duration: const Duration(milliseconds: 80),
        );
        await Future.delayed(const Duration(milliseconds: 30));
      }

      await Future.delayed(const Duration(milliseconds: 200));

      expect(controller.totalDebounces, 1);
      controller.dispose();
    });
  });

  // ─── System: Mixed Patterns ──────────────────────────────────────────────

  group('System: mixed debounce + throttle patterns', () {
    test('independent debounce and throttle on same controller work together',
        () async {
      final controller = _MultiKeyController();
      var throttleCount = 0;
      var debounceCount = 0;

      // Burst: throttle fires once, debounce fires once after silence
      // 10 events × 15ms = 150ms total, throttle duration 300ms → only 1 execution
      for (var i = 0; i < 10; i++) {
        controller.throttle(
          'rate_limit',
          () => throttleCount++,
          duration: const Duration(milliseconds: 300),
        );
        controller.debounce(
          'search',
          () => debounceCount++,
          duration: const Duration(milliseconds: 80),
        );
        await Future.delayed(const Duration(milliseconds: 15));
      }

      await Future.delayed(const Duration(milliseconds: 200));

      expect(throttleCount, 1);
      expect(debounceCount, 1);
      controller.dispose();
    });

    test('separate IDs never interfere with each other', () async {
      final controller = _MultiKeyController();

      // Throttle A: fires immediately
      controller.throttleKey('A');

      // Debounce B: pending
      controller.debounceKey('B');

      // Cancel B, A is still active
      controller.cancel('B');

      await Future.delayed(const Duration(milliseconds: 200));

      // Only A's throttle fired; B was cancelled
      expect(controller.totalThrottles, 1);
      expect(controller.totalDebounces, 0);
      controller.dispose();
    });

    test('remove(id) frees a key so it can be reused without stale state',
        () async {
      final controller = _MultiKeyController();

      controller.debounceKey('dynamic_post_1');
      controller.remove('dynamic_post_1');

      // Re-add: no stale state from previous
      controller.debounceKey('dynamic_post_1');

      await Future.delayed(const Duration(milliseconds: 200));

      expect(controller.totalDebounces, 1);
      controller.dispose();
    });

    test('EventLimiterMixin: 20 mixed keys + cancelAll = clean state',
        () async {
      final controller = _MultiKeyController();

      for (var i = 0; i < 10; i++) {
        controller.debounceKey('d_$i');
        controller.throttleKey('t_$i');
      }

      controller.cancelAll();

      await Future.delayed(const Duration(milliseconds: 200));

      // No debounces fired (all cancelled)
      expect(controller.totalDebounces, 0);
      controller.dispose();
    });

    test('debounce + throttle on same key ID are independent namespaces',
        () async {
      final controller = _MultiKeyController();
      var debounced = 0;
      var throttled = 0;

      // Both use 'action' as key but go to different internal maps
      controller.debounce('action', () => debounced++,
          duration: const Duration(milliseconds: 60));
      controller.throttle('action', () => throttled++,
          duration: const Duration(milliseconds: 200));

      await Future.delayed(const Duration(milliseconds: 200));

      expect(debounced, 1);
      expect(throttled, 1);
      controller.dispose();
    });
  });

  // ─── System: Dispose Safety ──────────────────────────────────────────────

  group('System: dispose safety', () {
    test('dispose during debounce pending: callback never fires', () async {
      final controller = _MultiKeyController();

      controller.debounceKey('pending');
      controller.dispose();

      await Future.delayed(const Duration(milliseconds: 200));

      expect(controller.totalDebounces, 0);
    });

    test('dispose during throttle lock: no crash after timer would fire',
        () async {
      final controller = _MultiKeyController();

      controller.throttleKey('locked');
      controller.dispose();

      await Future.delayed(const Duration(milliseconds: 200));
      // No crash
    });

    test('ViewModel dispose during pending search: no callbacks fire',
        () async {
      final vm = _SearchViewModel();

      unawaited(vm.onSearch('test'));
      vm.dispose();

      await Future.delayed(const Duration(milliseconds: 200));
      expect(vm.searchCount, 0);
    });

    test('BLoC dispose: cancellation produces Idle (not Loaded)', () async {
      final bloc = _BlocLikeController();

      unawaited(bloc.onQueryChanged('search'));
      bloc.dispose();

      await Future.delayed(const Duration(milliseconds: 300));

      // Cancellation completes the future with null → bloc emits 'Idle'
      // It must NOT emit 'Loaded' (which would mean the async ran after dispose)
      expect(bloc.states, isNot(contains('Loaded(1)')));
    });

    test('multiple controllers disposed concurrently: no cross-contamination',
        () async {
      final controllers =
          List.generate(10, (_) => _MultiKeyController());

      for (final c in controllers) {
        for (var i = 0; i < 5; i++) {
          c.debounceKey('key_$i');
        }
      }

      await Future.wait(controllers.map((c) async => c.dispose()));

      await Future.delayed(const Duration(milliseconds: 200));

      for (final c in controllers) {
        expect(c.totalDebounces, 0);
      }
    });

    test('cancel + re-use cycle 10 times: consistent behavior', () async {
      final controller = _MultiKeyController();

      for (var cycle = 0; cycle < 10; cycle++) {
        controller.debounceKey('cycled');
        controller.cancel('cycled');
      }

      await Future.delayed(const Duration(milliseconds: 200));
      expect(controller.totalDebounces, 0);
      controller.dispose();
    });

    test('late call after dispose is silently dropped', () async {
      final controller = _MultiKeyController();
      controller.dispose();

      // Calling after dispose should not crash
      expect(() => controller.debounceKey('late'), returnsNormally);
    });

    test('all keys removed via remove() individually: callbacks all suppressed',
        () async {
      final controller = _MultiKeyController();
      const keyCount = 5;

      for (var i = 0; i < keyCount; i++) {
        controller.debounceKey('key_$i');
      }

      for (var i = 0; i < keyCount; i++) {
        controller.remove('key_$i');
      }

      await Future.delayed(const Duration(milliseconds: 200));

      expect(controller.totalDebounces, 0);
      controller.dispose();
    });
  });
}
