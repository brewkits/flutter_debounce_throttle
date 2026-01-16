import 'package:flutter/material.dart';
import 'package:flutter_debounce_throttle/flutter_debounce_throttle.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Debounce Throttle Example',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const ExamplePage(),
    );
  }
}

class ExamplePage extends StatefulWidget {
  const ExamplePage({super.key});

  @override
  State<ExamplePage> createState() => _ExamplePageState();
}

class _ExamplePageState extends State<ExamplePage> {
  final _searchController = TextEditingController();
  String _searchResults = '';
  int _clickCount = 0;

  late final Debouncer _debouncer;
  late final Throttler _throttler;

  @override
  void initState() {
    super.initState();
    _debouncer = Debouncer(duration: const Duration(milliseconds: 500));
    _throttler = Throttler(duration: const Duration(milliseconds: 500));
  }

  @override
  void dispose() {
    _debouncer.dispose();
    _throttler.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debouncer.call(() {
      setState(() => _searchResults = 'Search results for: $query');
    });
  }

  void _onButtonPressed() {
    _throttler.call(() {
      setState(() => _clickCount++);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Debounce & Throttle Example')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: const InputDecoration(
                labelText: 'Search (debounced)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text(_searchResults),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _onButtonPressed,
              child: const Text('Click rapidly (throttled)'),
            ),
            const SizedBox(height: 16),
            Text('Click count: $_clickCount',
                style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }
}
