import 'package:test/test.dart';
import 'package:dart_debounce_throttle/dart_debounce_throttle.dart';

void main() {
  // ─── ThrottlerResult ─────────────────────────────────────────────────────

  group('ThrottlerResult', () {
    test('executed() has correct state', () {
      const r = ThrottlerResult.executed();
      expect(r.isExecuted, true);
      expect(r.isDropped, false);
      expect(r.toString(), 'ThrottlerResult.executed');
    });

    test('dropped() has correct state', () {
      const r = ThrottlerResult.dropped();
      expect(r.isExecuted, false);
      expect(r.isDropped, true);
      expect(r.toString(), 'ThrottlerResult.dropped');
    });

    group('when()', () {
      test('calls onExecuted branch for executed result', () {
        const r = ThrottlerResult.executed();
        final value = r.when(onExecuted: () => 'ran', onDropped: () => 'drop');
        expect(value, 'ran');
      });

      test('calls onDropped branch for dropped result', () {
        const r = ThrottlerResult.dropped();
        final value = r.when(onExecuted: () => 'ran', onDropped: () => 'drop');
        expect(value, 'drop');
      });

      test('returns value from the matched branch', () {
        const r = ThrottlerResult.executed();
        final count = r.when(onExecuted: () => 42, onDropped: () => 0);
        expect(count, 42);
      });

      test('never calls the non-matching branch', () {
        var called = false;
        ThrottlerResult.executed().when(
          onExecuted: () => null,
          onDropped: () => called = true,
        );
        expect(called, false);
      });
    });

    group('whenExecuted()', () {
      test('runs action when executed', () {
        var ran = false;
        ThrottlerResult.executed().whenExecuted(() => ran = true);
        expect(ran, true);
      });

      test('skips action when dropped', () {
        var ran = false;
        ThrottlerResult.dropped().whenExecuted(() => ran = true);
        expect(ran, false);
      });

      test('returns this for chaining', () {
        const r = ThrottlerResult.executed();
        final chained = r.whenExecuted(() {});
        expect(identical(chained, r), true);
      });
    });

    group('whenDropped()', () {
      test('runs action when dropped', () {
        var ran = false;
        ThrottlerResult.dropped().whenDropped(() => ran = true);
        expect(ran, true);
      });

      test('skips action when executed', () {
        var ran = false;
        ThrottlerResult.executed().whenDropped(() => ran = true);
        expect(ran, false);
      });

      test('chaining whenExecuted + whenDropped covers both branches', () {
        final log = <String>[];

        ThrottlerResult.executed()
            .whenExecuted(() => log.add('exec'))
            .whenDropped(() => log.add('drop'));
        expect(log, ['exec']);

        log.clear();
        ThrottlerResult.dropped()
            .whenExecuted(() => log.add('exec'))
            .whenDropped(() => log.add('drop'));
        expect(log, ['drop']);
      });
    });

    group('integration with ConcurrentAsyncThrottler', () {
      test('drop mode: locked throttler returns dropped', () async {
        final throttler = ConcurrentAsyncThrottler(
          mode: ConcurrencyMode.drop,
          maxDuration: const Duration(seconds: 5),
        );

        // Lock the throttler.
        throttler.call(() async {
          await Future.delayed(const Duration(milliseconds: 100));
        });

        final result = await throttler.call(() async {});
        expect(result.isDropped, true);

        throttler.dispose();
      });

      test('enqueue mode: overflow returns dropped, executed returns executed',
          () async {
        final throttler = ConcurrentAsyncThrottler(
          mode: ConcurrencyMode.enqueue,
          maxDuration: const Duration(seconds: 5),
          maxQueueSize: 1,
          queueOverflowStrategy: QueueOverflowStrategy.dropNewest,
        );

        throttler.call(() async {
          await Future.delayed(const Duration(milliseconds: 100));
        });
        throttler.call(() async {}); // fills the queue

        final dropped = await throttler.call(() async {}); // overflow
        expect(dropped.isDropped, true);

        await Future.delayed(const Duration(milliseconds: 200));

        final executed = await throttler.call(() async {});
        expect(executed.isExecuted, true);

        throttler.dispose();
      });

      test('when() enables architecture-clean MVVM pattern', () async {
        final throttler = ConcurrentAsyncThrottler(
          mode: ConcurrencyMode.enqueue,
          maxDuration: const Duration(seconds: 5),
          maxQueueSize: 1,
          queueOverflowStrategy: QueueOverflowStrategy.dropNewest,
        );

        throttler.call(() async {
          await Future.delayed(const Duration(milliseconds: 100));
        });
        throttler.call(() async {}); // fill queue

        final log = <String>[];

        final result = await throttler.call(() async {});
        result.when(
          onExecuted: () => log.add('emit(Success)'),
          onDropped: () => log.add('emit(Dropped)'),
        );

        expect(log, ['emit(Dropped)']);
        throttler.dispose();
      });
    });
  });

  // ─── DebounceResult ───────────────────────────────────────────────────────

  group('DebounceResult', () {
    test('success() has correct state', () {
      final r = DebounceResult.success(42);
      expect(r.isSuccess, true);
      expect(r.isCancelled, false);
      expect(r.value, 42);
      expect(r.toString(), 'DebounceResult.success(42)');
    });

    test('success() with null value is not cancelled', () {
      final r = DebounceResult<String>.success(null);
      expect(r.isSuccess, true);
      expect(r.isCancelled, false);
      expect(r.value, null);
    });

    test('cancelled() has correct state', () {
      final r = DebounceResult<int>.cancelled();
      expect(r.isCancelled, true);
      expect(r.isSuccess, false);
      expect(r.value, null);
      expect(r.toString(), 'DebounceResult.cancelled');
    });

    group('when()', () {
      test('calls onSuccess with value for successful result', () {
        final r = DebounceResult.success('hello');
        final out = r.when(
          onSuccess: (v) => 'got: $v',
          onCancelled: () => 'cancelled',
        );
        expect(out, 'got: hello');
      });

      test('calls onCancelled for cancelled result', () {
        final r = DebounceResult<String>.cancelled();
        final out = r.when(
          onSuccess: (v) => 'got: $v',
          onCancelled: () => 'cancelled',
        );
        expect(out, 'cancelled');
      });

      test('never calls non-matching branch', () {
        var called = false;
        DebounceResult.success(1).when(
          onSuccess: (_) => null,
          onCancelled: () => called = true,
        );
        expect(called, false);
      });

      test('MVI BLoC emit pattern', () {
        final log = <String>[];

        DebounceResult.success(['result1', 'result2']).when(
          onSuccess: (data) => log.add('emit(SearchLoaded(${data?.length}))'),
          onCancelled: () => log.add('emit(SearchIdle)'),
        );
        expect(log, ['emit(SearchLoaded(2))']);

        log.clear();
        DebounceResult<List<String>>.cancelled().when(
          onSuccess: (data) => log.add('emit(SearchLoaded)'),
          onCancelled: () => log.add('emit(SearchIdle)'),
        );
        expect(log, ['emit(SearchIdle)']);
      });
    });

    group('whenSuccess()', () {
      test('runs action with value when successful', () {
        String? got;
        DebounceResult.success('hi').whenSuccess((v) => got = v);
        expect(got, 'hi');
      });

      test('skips action when cancelled', () {
        String? got;
        DebounceResult<String>.cancelled().whenSuccess((v) => got = v);
        expect(got, null);
      });

      test('returns this for chaining', () {
        final r = DebounceResult.success(1);
        final chained = r.whenSuccess((_) {});
        expect(identical(chained, r), true);
      });
    });

    group('whenCancelled()', () {
      test('runs action when cancelled', () {
        var ran = false;
        DebounceResult<int>.cancelled().whenCancelled(() => ran = true);
        expect(ran, true);
      });

      test('skips action when successful', () {
        var ran = false;
        DebounceResult.success(1).whenCancelled(() => ran = true);
        expect(ran, false);
      });

      test('fluent chain covers both branches', () {
        final log = <String>[];

        DebounceResult.success('data')
            .whenSuccess((v) => log.add('loaded:$v'))
            .whenCancelled(() => log.add('idle'));
        expect(log, ['loaded:data']);

        log.clear();
        DebounceResult<String>.cancelled()
            .whenSuccess((v) => log.add('loaded:$v'))
            .whenCancelled(() => log.add('idle'));
        expect(log, ['idle']);
      });
    });

    group('integration with AsyncDebouncer', () {
      test('when() works end-to-end with callWithResult', () async {
        final debouncer = AsyncDebouncer(
          duration: const Duration(milliseconds: 50),
        );
        final log = <String>[];

        final result = await debouncer.callWithResult(() async => 'data');
        result.when(
          onSuccess: (v) => log.add('success:$v'),
          onCancelled: () => log.add('cancelled'),
        );

        expect(log, ['success:data']);
        debouncer.dispose();
      });

      test('cancelled result after rapid calls', () async {
        final debouncer = AsyncDebouncer(
          duration: const Duration(milliseconds: 50),
        );
        final log = <String>[];

        // First call gets cancelled by the second.
        final f1 = debouncer.callWithResult(() async => 'first');
        final f2 = debouncer.callWithResult(() async => 'second');

        (await f1).when(
          onSuccess: (v) => log.add('f1:$v'),
          onCancelled: () => log.add('f1:cancelled'),
        );
        (await f2).when(
          onSuccess: (v) => log.add('f2:$v'),
          onCancelled: () => log.add('f2:cancelled'),
        );

        expect(log, ['f1:cancelled', 'f2:second']);
        debouncer.dispose();
      });
    });
  });
}
