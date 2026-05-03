import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_debounce_throttle_hooks/flutter_debounce_throttle_hooks.dart';

void main() => runApp(const HooksDemoApp());

class HooksDemoApp extends StatelessWidget {
  const HooksDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flutter_debounce_throttle_hooks Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const _DemoHome(),
    );
  }
}

class _DemoHome extends StatelessWidget {
  const _DemoHome();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('hooks demo'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.search), text: 'Search'),
              Tab(icon: Icon(Icons.touch_app), text: 'Submit'),
              Tab(icon: Icon(Icons.cloud_download), text: 'Async'),
              Tab(icon: Icon(Icons.preview), text: 'Live Preview'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _SearchTab(),
            _SubmitTab(),
            _AsyncTab(),
            _LivePreviewTab(),
          ],
        ),
      ),
    );
  }
}

// ─── Tab 1: Debounced Search ──────────────────────────────────────────────────

class _SearchTab extends HookWidget {
  const _SearchTab();

  @override
  Widget build(BuildContext context) {
    final keystrokes = useState(0);
    final apiCalls = useState(0);
    final results = useState(<String>[]);
    final isLoading = useState(false);

    // useDebouncer auto-disposes when widget unmounts — no manual dispose needed
    final debouncer = useDebouncer(duration: const Duration(milliseconds: 400));

    void onChanged(String query) {
      keystrokes.value++;
      debouncer.call(() async {
        if (query.isEmpty) {
          results.value = [];
          return;
        }
        isLoading.value = true;
        apiCalls.value++;
        await Future.delayed(const Duration(milliseconds: 600));
        results.value = List.generate(
          4,
          (i) => '$query · result ${i + 1}',
        );
        isLoading.value = false;
      });
    }

    final saved = (keystrokes.value - apiCalls.value).clamp(0, 9999);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: 'Type to search...',
              border: const OutlineInputBorder(),
              prefixIcon: isLoading.value
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : const Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatCard(
                  label: 'Keystrokes',
                  value: '${keystrokes.value}',
                  color: Colors.orange),
              _StatCard(
                  label: 'API Calls',
                  value: '${apiCalls.value}',
                  color: Colors.blue),
              _StatCard(label: 'Saved', value: '$saved', color: Colors.green),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: results.value.isEmpty
                ? Center(
                    child: Text(
                      'Start typing to search',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  )
                : ListView.builder(
                    itemCount: results.value.length,
                    itemBuilder: (_, i) => ListTile(
                      leading: const Icon(Icons.article_outlined),
                      title: Text(results.value[i]),
                    ),
                  ),
          ),
          _CodeSnippet(
            'final debouncer = useDebouncer(duration: 400.ms);\n'
            '\n'
            'TextField(\n'
            '  onChanged: (q) => debouncer(() => api.search(q)),\n'
            ')',
          ),
        ],
      ),
    );
  }
}

// ─── Tab 2: Throttled Submit ──────────────────────────────────────────────────

class _SubmitTab extends HookWidget {
  const _SubmitTab();

  @override
  Widget build(BuildContext context) {
    final taps = useState(0);
    final submitted = useState(0);
    final isSubmitting = useState(false);
    final lastStatus = useState('');

    // useThrottler auto-disposes — no dispose() needed
    final throttler =
        useThrottler(duration: const Duration(milliseconds: 3000));

    void onTap() {
      taps.value++;
      throttler.call(() async {
        isSubmitting.value = true;
        lastStatus.value = 'Processing...';
        await Future.delayed(const Duration(seconds: 2));
        submitted.value++;
        lastStatus.value = 'Payment successful!';
        isSubmitting.value = false;
      });
    }

    final blocked = taps.value - submitted.value;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Tap as fast as you can!',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          const Text(
            'Only 1 payment fires per 3 seconds.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 36),
          GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
              decoration: BoxDecoration(
                color: isSubmitting.value ? Colors.grey : Colors.teal,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.withAlpha(76),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSubmitting.value) ...[
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    isSubmitting.value ? 'Processing...' : 'Pay \$99',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          AnimatedOpacity(
            opacity: lastStatus.value.isNotEmpty ? 1 : 0,
            duration: const Duration(milliseconds: 300),
            child: Text(
              lastStatus.value,
              style: TextStyle(
                color: lastStatus.value.contains('success')
                    ? Colors.green
                    : Colors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatCard(
                  label: 'Taps', value: '${taps.value}', color: Colors.orange),
              _StatCard(
                  label: 'Payments',
                  value: '${submitted.value}',
                  color: Colors.green),
              _StatCard(label: 'Blocked', value: '$blocked', color: Colors.red),
            ],
          ),
          const SizedBox(height: 24),
          _CodeSnippet(
            'final throttler = useThrottler(duration: 3.seconds);\n'
            '\n'
            'GestureDetector(\n'
            '  onTap: () => throttler(() => submitPayment()),\n'
            ')',
          ),
        ],
      ),
    );
  }
}

// ─── Tab 3: Async Debounce ────────────────────────────────────────────────────

class _AsyncTab extends HookWidget {
  const _AsyncTab();

  @override
  Widget build(BuildContext context) {
    final keystrokes = useState(0);
    final apiCalls = useState(0);
    final cancelledCalls = useState(0);
    final lastResult = useState('');
    final isLoading = useState(false);

    // useAsyncDebouncer auto-disposes — no manual cleanup
    final debouncer =
        useAsyncDebouncer(duration: const Duration(milliseconds: 350));

    void onChanged(String query) {
      keystrokes.value++;
      isLoading.value = true;

      debouncer.callWithResult<String>(() async {
        apiCalls.value++;
        await Future.delayed(const Duration(milliseconds: 500));
        return 'Result for "$query"';
      }).then((result) {
        result.when(
          onSuccess: (value) {
            lastResult.value = value ?? '';
            isLoading.value = false;
          },
          onCancelled: () {
            cancelledCalls.value++;
            // isLoading stays true until the winning call resolves
          },
        );
      });
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: 'Type rapidly to see cancellations...',
              border: const OutlineInputBorder(),
              prefixIcon: isLoading.value
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : const Icon(Icons.cloud_outlined),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatCard(
                  label: 'Keystrokes',
                  value: '${keystrokes.value}',
                  color: Colors.orange),
              _StatCard(
                  label: 'Fired',
                  value: '${apiCalls.value}',
                  color: Colors.blue),
              _StatCard(
                  label: 'Cancelled',
                  value: '${cancelledCalls.value}',
                  color: Colors.red),
            ],
          ),
          const SizedBox(height: 16),
          if (lastResult.value.isNotEmpty)
            Card(
              child: ListTile(
                leading:
                    const Icon(Icons.check_circle_outline, color: Colors.green),
                title: Text(lastResult.value),
                subtitle: const Text('Last successful result'),
              ),
            ),
          const Spacer(),
          _CodeSnippet(
            'final debouncer = useAsyncDebouncer(duration: 350.ms);\n'
            '\n'
            'final result = await debouncer.callWithResult<String>(\n'
            '  () async => await api.search(query),\n'
            ');\n'
            'result.when(\n'
            '  onSuccess: (v) => setState(v),\n'
            '  onCancelled: () {},   // stale — ignore\n'
            ')',
          ),
        ],
      ),
    );
  }
}

// ─── Tab 4: Live Preview (useDebouncedValue) ──────────────────────────────────

class _LivePreviewTab extends HookWidget {
  const _LivePreviewTab();

  @override
  Widget build(BuildContext context) {
    final rawText = useState('');
    final updateCount = useState(0);
    final debouncedUpdateCount = useState(0);

    // useDebouncedValue — value only updates after 600ms of no changes
    final debouncedText = useDebouncedValue(
      rawText.value,
      duration: const Duration(milliseconds: 600),
    );

    // Track how many times each version updates
    useEffect(() {
      updateCount.value++;
      return null;
    }, [rawText.value]);

    useEffect(() {
      if (debouncedText.isNotEmpty) {
        debouncedUpdateCount.value++;
      }
      return null;
    }, [debouncedText]);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            maxLines: 3,
            onChanged: (v) => rawText.value = v,
            decoration: const InputDecoration(
              hintText: 'Type your message...',
              border: OutlineInputBorder(),
              labelText: 'Input',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatCard(
                  label: 'Raw updates',
                  value: '${updateCount.value}',
                  color: Colors.orange),
              _StatCard(
                  label: 'Preview updates',
                  value: '${debouncedUpdateCount.value}',
                  color: Colors.teal),
            ],
          ),
          const SizedBox(height: 16),
          Text('Live Preview (updates after 600ms pause)',
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: Colors.grey)),
          const SizedBox(height: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 80),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: debouncedText.isNotEmpty
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: debouncedText.isNotEmpty
                    ? Theme.of(context).colorScheme.primary.withAlpha(100)
                    : Colors.grey[300]!,
              ),
            ),
            child: Text(
              debouncedText.isEmpty
                  ? 'Preview will appear here after you stop typing...'
                  : debouncedText,
              style: TextStyle(
                color: debouncedText.isEmpty ? Colors.grey : null,
                fontSize: 15,
              ),
            ),
          ),
          const Spacer(),
          _CodeSnippet(
            'final debouncedText = useDebouncedValue(\n'
            '  rawText,                 // updates every keystroke\n'
            '  duration: 600.ms,\n'
            ');\n'
            '\n'
            '// Preview only re-renders after 600ms of silence',
          ),
        ],
      ),
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(76)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
                fontSize: 26, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _CodeSnippet extends StatelessWidget {
  final String code;

  const _CodeSnippet(this.code);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
      ),
      child: Text(
        code,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          color: isDark ? Colors.grey[300] : Colors.grey[800],
          height: 1.5,
        ),
      ),
    );
  }
}
