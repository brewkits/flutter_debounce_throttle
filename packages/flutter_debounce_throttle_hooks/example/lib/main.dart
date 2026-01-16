import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_debounce_throttle_hooks/flutter_debounce_throttle_hooks.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Debounce Throttle Hooks Example',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const ExamplePage(),
    );
  }
}

class ExamplePage extends HookWidget {
  const ExamplePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Auto-disposed debouncer via hook
    final debouncer = useDebouncer(duration: const Duration(milliseconds: 500));

    // Auto-disposed throttler via hook
    final throttler = useThrottler(duration: const Duration(milliseconds: 500));

    final searchResults = useState('');
    final clickCount = useState(0);

    return Scaffold(
      appBar: AppBar(title: const Text('Hooks Example')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              onChanged: (query) {
                debouncer.call(() {
                  searchResults.value = 'Search results for: $query';
                });
              },
              decoration: const InputDecoration(
                labelText: 'Search (debounced with hook)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text(searchResults.value),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                throttler.call(() {
                  clickCount.value++;
                });
              },
              child: const Text('Click rapidly (throttled with hook)'),
            ),
            const SizedBox(height: 16),
            Text(
              'Click count: ${clickCount.value}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text(
              'Controllers are auto-disposed when widget unmounts',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
