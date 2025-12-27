// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_debounce_throttle/flutter_debounce_throttle.dart';

void main() {
  // Optional: Configure global defaults
  FlutterDebounceThrottle.init(
    defaultDebounceDuration: const Duration(milliseconds: 300),
    defaultThrottleDuration: const Duration(milliseconds: 500),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flutter_debounce_throttle Demo',
      home: const DemoPage(),
    );
  }
}

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  final _results = <String>[];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Event Limiter Demo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Example 1: Button Anti-Spam with ThrottledInkWell
          const Text('1. Button Anti-Spam (Throttle)',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ThrottledInkWell(
            duration: const Duration(milliseconds: 1000),
            onTap: () {
              print('Button tapped!');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Button tapped!')),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue,
              child: const Text('Tap me (throttled 1s)',
                  style: TextStyle(color: Colors.white)),
            ),
          ),

          const SizedBox(height: 24),

          // Example 2: Search Input with AsyncDebouncedCallbackBuilder
          const Text('2. Search Input (Async Debounce)',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          AsyncDebouncedCallbackBuilder<List<String>>(
            duration: const Duration(milliseconds: 500),
            onChanged: (text) async {
              // Simulate API call
              await Future.delayed(const Duration(milliseconds: 300));
              return ['Result for: $text', 'Another result', 'More results'];
            },
            onSuccess: (results) {
              setState(() {
                _results.clear();
                _results.addAll(results);
              });
            },
            builder: (context, callback, isLoading) => TextField(
              onChanged: callback,
              decoration: InputDecoration(
                hintText: 'Type to search...',
                suffixIcon: isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
              ),
            ),
          ),
          const SizedBox(height: 8),
          ..._results.map((r) => ListTile(title: Text(r))),

          const SizedBox(height: 24),

          // Example 3: ThrottledBuilder for custom usage
          const Text('3. Custom Throttle (ThrottledBuilder)',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ThrottledBuilder(
            duration: const Duration(milliseconds: 500),
            builder: (context, throttle) => ElevatedButton(
              onPressed: throttle(() => print('Throttled action!')),
              child: const Text('Throttled Button'),
            ),
          ),

          const SizedBox(height: 24),

          // Example 4: DebouncedBuilder for form validation
          const Text('4. Form Validation (Debounce)',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DebouncedBuilder(
            duration: const Duration(milliseconds: 300),
            builder: (context, debounce) => TextField(
              onChanged: (text) => debounce(() {
                print('Validating: $text');
              }),
              decoration: const InputDecoration(
                hintText: 'Type to validate...',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Example 5: Using EventLimiterMixin with a Controller
class SearchController with ChangeNotifier, EventLimiterMixin {
  List<String> results = [];
  bool isLoading = false;

  void onSearchChanged(String query) {
    debounce('search', () async {
      isLoading = true;
      notifyListeners();

      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));
      results = ['Result 1 for $query', 'Result 2 for $query'];

      isLoading = false;
      notifyListeners();
    });
  }

  void onSubmit() {
    throttle('submit', () {
      print('Form submitted!');
    });
  }

  @override
  void dispose() {
    cancelAllLimiters();
    super.dispose();
  }
}

// Example 6: Direct usage of Throttler and Debouncer
void directUsageExample() {
  // Throttler
  final throttler = Throttler(duration: const Duration(milliseconds: 500));
  throttler.call(() => print('First call executes'));
  throttler.call(() => print('Second call blocked'));

  // Debouncer
  final debouncer = Debouncer(duration: const Duration(milliseconds: 300));
  debouncer.call(() => print('Delayed execution'));
  debouncer.call(() => print('Timer reset, this executes'));

  // Don't forget to dispose!
  throttler.dispose();
  debouncer.dispose();
}
