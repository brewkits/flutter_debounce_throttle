import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_debounce_throttle/flutter_debounce_throttle.dart';

void main() {
  group('DebouncedTextController', () {
    late DebouncedTextController controller;

    tearDown(() {
      controller.dispose();
    });

    testWidgets('debounces text changes', (tester) async {
      String? lastValue;

      controller = DebouncedTextController(
        duration: const Duration(milliseconds: 100),
        onChanged: (text) => lastValue = text,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextField(controller: controller.textController),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'h');
      await tester.enterText(find.byType(TextField), 'he');
      await tester.enterText(find.byType(TextField), 'hel');
      await tester.enterText(find.byType(TextField), 'hell');
      await tester.enterText(find.byType(TextField), 'hello');

      await tester.pump();
      expect(lastValue, isNull);

      await tester.pump(const Duration(milliseconds: 150));
      expect(lastValue, 'hello');
    });

    testWidgets('works with initial value', (tester) async {
      String? lastValue;

      controller = DebouncedTextController(
        initialValue: 'initial',
        duration: const Duration(milliseconds: 100),
        onChanged: (text) => lastValue = text,
      );

      expect(controller.text, 'initial');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextField(controller: controller.textController),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'changed');
      await tester.pump(const Duration(milliseconds: 150));

      expect(lastValue, 'changed');
    });

    test('cancel prevents callback', () async {
      String? lastValue;

      controller = DebouncedTextController(
        duration: const Duration(milliseconds: 100),
        onChanged: (text) => lastValue = text,
      );

      controller.textController.text = 'test';
      controller.cancel();

      await Future.delayed(const Duration(milliseconds: 150));

      expect(lastValue, isNull);
    });

    test('flush executes immediately', () {
      String? lastValue;

      controller = DebouncedTextController(
        duration: const Duration(milliseconds: 100),
        onChanged: (text) => lastValue = text,
      );

      controller.textController.text = 'test';
      expect(lastValue, isNull);

      controller.flush();
      expect(lastValue, 'test');
    });

    test('setText sets text value', () {
      controller = DebouncedTextController(
        duration: const Duration(milliseconds: 100),
        onChanged: (text) {},
      );

      controller.setText('hello');
      expect(controller.text, 'hello');
    });

    test('clear clears text value', () {
      controller = DebouncedTextController(
        duration: const Duration(milliseconds: 100),
        onChanged: (text) {},
        initialValue: 'hello',
      );

      controller.clear();
      expect(controller.text, '');
    });

    testWidgets('works with external controller', (tester) async {
      final externalController = TextEditingController(text: 'external');
      String? lastValue;

      controller = DebouncedTextController(
        controller: externalController,
        duration: const Duration(milliseconds: 100),
        onChanged: (text) => lastValue = text,
      );

      expect(controller.text, 'external');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextField(controller: controller.textController),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'changed');
      await tester.pump(const Duration(milliseconds: 150));

      expect(lastValue, 'changed');

      // External controller should still work after dispose
      controller.dispose();
      expect(externalController.text, 'changed');
      externalController.dispose();
    });
  });

  group('AsyncDebouncedTextController', () {
    testWidgets('performs async search with debounce', (tester) async {
      List<String>? results;

      final controller = AsyncDebouncedTextController<List<String>>(
        duration: const Duration(milliseconds: 50),
        onChanged: (query) async {
          return ['Result for $query'];
        },
        onSuccess: (r) => results = r,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextField(controller: controller.textController),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'test');

      await tester.pump();
      expect(results, isNull);

      // Wait for debounce + async operation
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 50));
      expect(results, ['Result for test']);

      controller.dispose();
    });

    testWidgets('cancels previous search on new input', (tester) async {
      final searchCalls = <String>[];

      final controller = AsyncDebouncedTextController<String>(
        duration: const Duration(milliseconds: 100),
        onChanged: (query) async {
          searchCalls.add(query);
          await Future.delayed(const Duration(milliseconds: 50));
          return query;
        },
        onSuccess: (r) {},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextField(controller: controller.textController),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'a');
      await tester.pump(const Duration(milliseconds: 50));
      await tester.enterText(find.byType(TextField), 'ab');
      await tester.pump(const Duration(milliseconds: 50));
      await tester.enterText(find.byType(TextField), 'abc');

      await tester.pump(const Duration(milliseconds: 200));

      // Only last search should complete
      expect(searchCalls.last, 'abc');

      controller.dispose();
    });

    testWidgets('handles errors', (tester) async {
      Object? receivedError;

      final controller = AsyncDebouncedTextController<String>(
        duration: const Duration(milliseconds: 100),
        onChanged: (query) async {
          throw Exception('Search failed');
        },
        onSuccess: (r) {},
        onError: (e, stackTrace) => receivedError = e,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextField(controller: controller.textController),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump(const Duration(milliseconds: 200));

      expect(receivedError, isA<Exception>());

      controller.dispose();
    });

    test('isLoading returns correct state', () async {
      final controller = AsyncDebouncedTextController<String>(
        duration: const Duration(milliseconds: 50),
        onChanged: (query) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return query;
        },
        onSuccess: (r) {},
      );

      expect(controller.isLoading, false);

      controller.textController.text = 'test';

      // Wait for debounce + a bit
      await Future.delayed(const Duration(milliseconds: 70));
      expect(controller.isLoading, true);

      // Wait for async to complete
      await Future.delayed(const Duration(milliseconds: 150));
      expect(controller.isLoading, false);

      controller.dispose();
    });

    test('cancel stops loading', () async {
      final controller = AsyncDebouncedTextController<String>(
        duration: const Duration(milliseconds: 50),
        onChanged: (query) async {
          await Future.delayed(const Duration(milliseconds: 200));
          return query;
        },
        onSuccess: (r) {},
      );

      controller.textController.text = 'test';
      await Future.delayed(const Duration(milliseconds: 70));

      controller.cancel();
      expect(controller.isLoading, false);

      controller.dispose();
    });

    test('setText sets text value', () {
      final controller = AsyncDebouncedTextController<String>(
        duration: const Duration(milliseconds: 100),
        onChanged: (query) async => query,
        onSuccess: (r) {},
      );

      controller.setText('hello');
      expect(controller.text, 'hello');

      controller.dispose();
    });

    test('clear clears text value', () {
      final controller = AsyncDebouncedTextController<String>(
        duration: const Duration(milliseconds: 100),
        onChanged: (query) async => query,
        onSuccess: (r) {},
        initialValue: 'hello',
      );

      controller.clear();
      expect(controller.text, '');

      controller.dispose();
    });
  });
}
