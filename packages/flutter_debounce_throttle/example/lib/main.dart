import 'package:flutter/material.dart';
import 'package:flutter_debounce_throttle/flutter_debounce_throttle.dart';

void main() => runApp(const DemoApp());

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flutter_debounce_throttle Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: const DemoHome(),
    );
  }
}

class DemoHome extends StatelessWidget {
  const DemoHome({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('flutter_debounce_throttle'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.touch_app), text: 'Anti-Spam'),
              Tab(icon: Icon(Icons.search), text: 'Search'),
              Tab(icon: Icon(Icons.upload_rounded), text: 'Async Form'),
              Tab(icon: Icon(Icons.layers), text: 'Concurrency'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _AntiSpamTab(),
            _SearchTab(),
            _AsyncFormTab(),
            _ConcurrencyTab(),
          ],
        ),
      ),
    );
  }
}

// ─── Tab 1: Anti-Spam Button (Throttle) ───────────────────────────────────────

class _AntiSpamTab extends StatefulWidget {
  const _AntiSpamTab();

  @override
  State<_AntiSpamTab> createState() => _AntiSpamTabState();
}

class _AntiSpamTabState extends State<_AntiSpamTab> {
  int _taps = 0;
  int _executed = 0;
  late final Throttler _throttler;

  @override
  void initState() {
    super.initState();
    _throttler = Throttler(duration: 2.seconds);
  }

  @override
  void dispose() {
    _throttler.dispose();
    super.dispose();
  }

  void _handleTap() {
    setState(() => _taps++);
    _throttler(() => setState(() => _executed++));
  }

  @override
  Widget build(BuildContext context) {
    final blocked = _taps - _executed;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Tap as fast as you can!',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          const Text('Only 1 payment fires per 2 seconds.',
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 36),
          GestureDetector(
            onTap: _handleTap,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withAlpha(76),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: const Text('Pay \$99',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 36),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatCard(label: 'Taps', value: '$_taps', color: Colors.orange),
              _StatCard(
                  label: 'Payments',
                  value: '$_executed',
                  color: Colors.green),
              _StatCard(
                  label: 'Blocked', value: '$blocked', color: Colors.red),
            ],
          ),
          const SizedBox(height: 32),
          _CodeSnippet(
              'Throttler(duration: 2.seconds)\n'
              '// 1 execution per 2 seconds — rest are dropped'),
        ],
      ),
    );
  }
}

// ─── Tab 2: Debounced Search ───────────────────────────────────────────────────

class _SearchTab extends StatefulWidget {
  const _SearchTab();

  @override
  State<_SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<_SearchTab> {
  List<String> _results = [];
  int _totalKeystrokes = 0;
  int _apiCalls = 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 8),
          DebouncedQueryBuilder<List<String>>(
            duration: 500.ms,
            onQuery: (text) async {
              setState(() => _apiCalls++);
              await Future.delayed(const Duration(milliseconds: 600));
              return List.generate(
                  4, (i) => '${text.isNotEmpty ? text : "flutter"} result ${i + 1}');
            },
            onResult: (results) {
              if (mounted) setState(() => _results = results);
            },
            builder: (context, search, isSearching) => TextField(
              onChanged: (text) {
                setState(() => _totalKeystrokes++);
                search?.call(text); // search is nullable — called only after debounce
              },
              decoration: InputDecoration(
                hintText: 'Type to search...',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatCard(
                  label: 'Keystrokes',
                  value: '$_totalKeystrokes',
                  color: Colors.orange),
              _StatCard(
                  label: 'API Calls', value: '$_apiCalls', color: Colors.blue),
              _StatCard(
                  label: 'Saved',
                  value: '${(_totalKeystrokes - _apiCalls).clamp(0, 9999)}',
                  color: Colors.green),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _results.isEmpty
                ? const Center(
                    child: Text('Start typing to search',
                        style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (_, i) => ListTile(
                      leading: const Icon(Icons.article_outlined),
                      title: Text(_results[i]),
                    ),
                  ),
          ),
          _CodeSnippet(
              'DebouncedQueryBuilder(\n'
              '  duration: 500.ms,\n'
              '  onQuery: (text) async => await api.search(text),\n'
              '  onResult: (results) => setState(() => _results = results),\n'
              ')'),
        ],
      ),
    );
  }
}

// ─── Tab 3: Async Form (ConcurrentAsyncThrottledBuilder — drop mode) ──────────

class _AsyncFormTab extends StatefulWidget {
  const _AsyncFormTab();

  @override
  State<_AsyncFormTab> createState() => _AsyncFormTabState();
}

class _AsyncFormTabState extends State<_AsyncFormTab> {
  int _attempts = 0;
  int _submitted = 0;
  String _lastStatus = '';

  @override
  Widget build(BuildContext context) {
    final blocked = _attempts - _submitted;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Async Form Submit', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          const Text('Duplicate taps are dropped while submitting.',
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 36),
          ConcurrentAsyncThrottledBuilder(
            mode: ConcurrencyMode.drop,
            onPressed: () async {
              setState(() {
                _attempts++;
                _lastStatus = 'Submitting...';
              });
              await Future.delayed(const Duration(seconds: 2));
              if (mounted) {
                setState(() {
                  _submitted++;
                  _lastStatus = 'Submitted!';
                });
              }
            },
            builder: (context, callback, isLoading, _) => SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: callback, // null when busy — button auto-disabled
                icon: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: Text(isLoading ? 'Submitting...' : 'Submit Form'),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_lastStatus.isNotEmpty)
            Text(_lastStatus,
                style: TextStyle(
                    color: _lastStatus.contains('!')
                        ? Colors.green
                        : Colors.orange)),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatCard(
                  label: 'Attempts', value: '$_attempts', color: Colors.orange),
              _StatCard(
                  label: 'Submitted', value: '$_submitted', color: Colors.green),
              _StatCard(
                  label: 'Blocked', value: '$blocked', color: Colors.red),
            ],
          ),
          const SizedBox(height: 32),
          _CodeSnippet(
              'ConcurrentAsyncThrottledBuilder(\n'
              '  mode: ConcurrencyMode.drop,\n'
              '  onPressed: () async => await submitForm(),\n'
              '  builder: (ctx, callback, isLoading, _) =>\n'
              '    FilledButton(onPressed: callback, ...),\n'
              ')'),
        ],
      ),
    );
  }
}

// ─── Tab 4: Concurrency — Replace Mode ────────────────────────────────────────

class _ConcurrencyTab extends StatefulWidget {
  const _ConcurrencyTab();

  @override
  State<_ConcurrencyTab> createState() => _ConcurrencyTabState();
}

class _ConcurrencyTabState extends State<_ConcurrencyTab> {
  late final ConcurrentAsyncThrottler _throttler;
  final List<_RequestLog> _log = [];
  int _requestId = 0;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _throttler = ConcurrentAsyncThrottler(mode: ConcurrencyMode.replace);
  }

  @override
  void dispose() {
    _throttler.dispose();
    super.dispose();
  }

  void _addLog(String message, {bool done = false}) {
    if (!mounted) return;
    setState(() {
      _log.insert(0, _RequestLog(message, done: done));
      if (_log.length > 8) _log.removeLast();
    });
  }

  Future<void> _handleSearch(String text) async {
    if (text.isEmpty) return;
    final id = ++_requestId;
    _addLog('Request #$id started: "$text"');
    setState(() => _isRunning = true);

    await _throttler(() async {
      await Future.delayed(const Duration(milliseconds: 800));
      _addLog('Request #$id completed ✓', done: true);
    });

    if (mounted) setState(() => _isRunning = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Text('ConcurrencyMode.replace',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          const Text(
              'Each new search cancels the previous in-flight request.\n'
              'Only the latest result is used.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 16),
          TextField(
            onChanged: _handleSearch,
            decoration: InputDecoration(
              hintText: 'Type quickly to see cancellation in action...',
              border: const OutlineInputBorder(),
              prefixIcon: _isRunning
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : const Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _log.isEmpty
                ? const Center(
                    child: Text('Request log will appear here',
                        style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    itemCount: _log.length,
                    itemBuilder: (_, i) {
                      final entry = _log[i];
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          entry.done
                              ? Icons.check_circle_outline
                              : Icons.pending_outlined,
                          color: entry.done ? Colors.green : Colors.orange,
                          size: 18,
                        ),
                        title: Text(entry.message,
                            style: const TextStyle(fontSize: 13)),
                      );
                    },
                  ),
          ),
          _CodeSnippet(
              'ConcurrentAsyncThrottler(\n'
              '  mode: ConcurrencyMode.replace,\n'
              ')\n'
              '// New search cancels the previous one automatically'),
        ],
      ),
    );
  }
}

class _RequestLog {
  final String message;
  final bool done;
  _RequestLog(this.message, {this.done = false});
}

// ─── Shared Widgets ────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(76)),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Text(
        code,
        style: TextStyle(
            fontFamily: 'monospace', fontSize: 12, color: Colors.grey[800]),
      ),
    );
  }
}
