import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';
import 'package:flutter_debounce_throttle/flutter_debounce_throttle.dart';

class TestController extends ChangeNotifier with EventLimiterMixin {
  int count = 0;

  void simulateDynamicLimiter(String id) {
    debounce(id, () {
      count++;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    cancelAll();
    super.dispose();
  }
}

void main() {
  group('EventLimiterMixin Memory Safety', () {
    testWidgets('Dynamic limiters do not leak after cancelAll (dispose)',
        experimentalLeakTesting: LeakTesting.settings.withTrackedAll(),
        (WidgetTester tester) async {
      final controller = TestController();

      // Simulate dynamic usage
      for (int i = 0; i < 50; i++) {
        controller.simulateDynamicLimiter('dynamic_id_$i');
      }

      expect(controller.totalLimitersCount, 50);

      // Verify that after disposing, all resources are freed
      controller.dispose();

      expect(controller.totalLimitersCount, 0);
    });
  });
}
