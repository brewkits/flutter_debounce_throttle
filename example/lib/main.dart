import 'package:flutter/material.dart';
import 'package:flutter_debounce_throttle/flutter_debounce_throttle.dart';

void main() {
  // Configure global defaults
  DebounceThrottleConfig.init(
    defaultDebounceDuration: const Duration(milliseconds: 500),
    defaultThrottleDuration: const Duration(milliseconds: 500),
    enableDebugLog: true,
  );

  runApp(const DemoApp());
}

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Debounce Throttle Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    ThrottleDemo(),
    DebounceDemo(),
    SearchDemo(),
    ButtonDemo(),
    AdvancedDemo(),
  ];

  final List<NavigationDestination> _destinations = const [
    NavigationDestination(
      icon: Icon(Icons.speed_outlined),
      selectedIcon: Icon(Icons.speed),
      label: 'Throttle',
    ),
    NavigationDestination(
      icon: Icon(Icons.timer_outlined),
      selectedIcon: Icon(Icons.timer),
      label: 'Debounce',
    ),
    NavigationDestination(
      icon: Icon(Icons.search_outlined),
      selectedIcon: Icon(Icons.search),
      label: 'Search',
    ),
    NavigationDestination(
      icon: Icon(Icons.touch_app_outlined),
      selectedIcon: Icon(Icons.touch_app),
      label: 'Buttons',
    ),
    NavigationDestination(
      icon: Icon(Icons.tune_outlined),
      selectedIcon: Icon(Icons.tune),
      label: 'Advanced',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Debounce Throttle'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: _destinations,
      ),
    );
  }
}

// ============================================================================
// THROTTLE DEMO
// ============================================================================
class ThrottleDemo extends StatefulWidget {
  const ThrottleDemo({super.key});

  @override
  State<ThrottleDemo> createState() => _ThrottleDemoState();
}

class _ThrottleDemoState extends State<ThrottleDemo> {
  int _rawClicks = 0;
  int _throttledClicks = 0;
  final List<String> _logs = [];
  final _scrollController = ScrollController();

  late final Throttler _throttler;

  @override
  void initState() {
    super.initState();
    _throttler = Throttler(
      duration: const Duration(milliseconds: 500),
      debugMode: true,
      name: 'click-throttler',
    );
  }

  @override
  void dispose() {
    _throttler.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleTap() {
    setState(() {
      _rawClicks++;
      _logs.add('Raw click #$_rawClicks at ${_formatTime()}');
    });

    _throttler.call(() {
      setState(() {
        _throttledClicks++;
        _logs.add('Throttled callback #$_throttledClicks');
      });
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime() {
    final now = DateTime.now();
    return '${now.second}.${now.millisecond.toString().padLeft(3, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final blocked = _rawClicks - _throttledClicks;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.speed,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Throttle Demo',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Throttle executes immediately, then blocks for 500ms.\nTap rapidly to see how many clicks are blocked!',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Raw Clicks',
                  value: _rawClicks.toString(),
                  color: theme.colorScheme.tertiary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Throttled',
                  value: _throttledClicks.toString(),
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Blocked',
                  value: blocked.toString(),
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _handleTap,
            icon: const Icon(Icons.touch_app),
            label: const Text('TAP RAPIDLY!'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Text('Event Log', style: theme.textTheme.titleSmall),
                        const Spacer(),
                        TextButton(
                          onPressed: () => setState(() => _logs.clear()),
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(12),
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        final isThrottled = _logs[index].startsWith('Throttled');
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            _logs[index],
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: isThrottled
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                              fontWeight:
                                  isThrottled ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// DEBOUNCE DEMO
// ============================================================================
class DebounceDemo extends StatefulWidget {
  const DebounceDemo({super.key});

  @override
  State<DebounceDemo> createState() => _DebounceDemoState();
}

class _DebounceDemoState extends State<DebounceDemo> {
  String _inputText = '';
  String _debouncedText = '';
  int _keystrokes = 0;
  int _callbacks = 0;
  bool _isPending = false;

  late final Debouncer _debouncer;
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _debouncer = Debouncer(
      duration: const Duration(milliseconds: 500),
      debugMode: true,
      name: 'input-debouncer',
    );
  }

  @override
  void dispose() {
    _debouncer.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _onTextChanged(String value) {
    setState(() {
      _inputText = value;
      _keystrokes++;
      _isPending = true;
    });

    _debouncer.call(() {
      setState(() {
        _debouncedText = value;
        _callbacks++;
        _isPending = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final saved = _keystrokes - _callbacks;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.timer,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Debounce Demo',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Debounce waits until you stop typing for 500ms.\nPerfect for search inputs!',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Keystrokes',
                  value: _keystrokes.toString(),
                  color: theme.colorScheme.tertiary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Callbacks',
                  value: _callbacks.toString(),
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'API Saved',
                  value: saved.toString(),
                  color: theme.colorScheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _textController,
            onChanged: _onTextChanged,
            decoration: InputDecoration(
              labelText: 'Type something...',
              hintText: 'Start typing rapidly',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.edit),
              suffixIcon: _isPending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : _inputText.isNotEmpty
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
            ),
          ),
          const SizedBox(height: 24),
          Card(
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.api,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Debounced Output (API Call)',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _debouncedText.isEmpty ? '(waiting for input...)' : _debouncedText,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: _debouncedText.isEmpty
                            ? theme.colorScheme.onSurfaceVariant
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {
              _textController.clear();
              setState(() {
                _inputText = '';
                _debouncedText = '';
                _keystrokes = 0;
                _callbacks = 0;
              });
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SEARCH DEMO
// ============================================================================
class SearchDemo extends StatefulWidget {
  const SearchDemo({super.key});

  @override
  State<SearchDemo> createState() => _SearchDemoState();
}

class _SearchDemoState extends State<SearchDemo> {
  late final AsyncDebouncedTextController<List<String>> _searchController;
  List<String> _results = [];
  bool _isLoading = false;
  String? _error;

  final List<String> _mockDatabase = [
    'Apple', 'Banana', 'Cherry', 'Date', 'Elderberry',
    'Fig', 'Grape', 'Honeydew', 'Kiwi', 'Lemon',
    'Mango', 'Nectarine', 'Orange', 'Papaya', 'Quince',
    'Raspberry', 'Strawberry', 'Tangerine', 'Watermelon',
  ];

  @override
  void initState() {
    super.initState();
    _searchController = AsyncDebouncedTextController<List<String>>(
      duration: const Duration(milliseconds: 400),
      onChanged: _performSearch,
      onSuccess: (results) => setState(() => _results = results),
      onError: (error, _) => setState(() => _error = error.toString()),
      onLoadingChanged: (loading) => setState(() => _isLoading = loading),
    );
  }

  Future<List<String>> _performSearch(String query) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    if (query.isEmpty) return [];

    return _mockDatabase
        .where((item) => item.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.search,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Async Search Demo',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'AsyncDebouncedTextController automatically\nhandles debouncing, cancellation, and loading state.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController.textController,
            decoration: InputDecoration(
              labelText: 'Search fruits',
              hintText: 'Try "apple" or "berry"',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _results = []);
                          },
                        )
                      : null,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              child: _error != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline,
                              size: 48, color: theme.colorScheme.error),
                          const SizedBox(height: 8),
                          Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
                        ],
                      ),
                    )
                  : _results.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.local_florist,
                                size: 64,
                                color: theme.colorScheme.outlineVariant,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchController.text.isEmpty
                                    ? 'Start typing to search'
                                    : 'No results found',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _results.length,
                          padding: const EdgeInsets.all(8),
                          itemBuilder: (context, index) {
                            final item = _results[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: theme.colorScheme.primaryContainer,
                                child: Text(
                                  item[0],
                                  style: TextStyle(
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                              title: Text(item),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// BUTTON DEMO
// ============================================================================
class ButtonDemo extends StatefulWidget {
  const ButtonDemo({super.key});

  @override
  State<ButtonDemo> createState() => _ButtonDemoState();
}

class _ButtonDemoState extends State<ButtonDemo> {
  int _submitCount = 0;
  bool _isSubmitting = false;
  final List<String> _submissions = [];

  Future<void> _handleSubmit() async {
    setState(() => _isSubmitting = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _submitCount++;
      _isSubmitting = false;
      _submissions.add('Submission #$_submitCount at ${_formatTime()}');
    });
  }

  String _formatTime() {
    final now = DateTime.now();
    return '${now.hour}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.touch_app,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Async Button Demo',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'AsyncThrottledBuilder prevents double-submissions\nby locking during async operations.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          AsyncThrottledBuilder(
            maxDuration: const Duration(seconds: 10),
            builder: (context, throttle) {
              return FilledButton.icon(
                onPressed: throttle(_handleSubmit),
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(_isSubmitting ? 'Submitting...' : 'Submit Form'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Text(
            'Try clicking rapidly while submitting!',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.check_circle,
                      color: theme.colorScheme.primary, size: 32),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Successful Submissions',
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(
                        '$_submitCount',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text('Submission Log', style: theme.textTheme.titleSmall),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: _submissions.isEmpty
                        ? Center(
                            child: Text(
                              'No submissions yet',
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _submissions.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check,
                                      size: 16,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _submissions[index],
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ADVANCED DEMO
// ============================================================================
class AdvancedDemo extends StatefulWidget {
  const AdvancedDemo({super.key});

  @override
  State<AdvancedDemo> createState() => _AdvancedDemoState();
}

class _AdvancedDemoState extends State<AdvancedDemo> {
  ConcurrencyMode _mode = ConcurrencyMode.drop;
  int _operationCount = 0;
  int _completedCount = 0;
  final List<String> _log = [];

  String get _modeDescription {
    switch (_mode) {
      case ConcurrencyMode.drop:
        return 'Ignores new calls while busy';
      case ConcurrencyMode.enqueue:
        return 'Queues calls and executes in order';
      case ConcurrencyMode.replace:
        return 'Cancels current, starts new';
      case ConcurrencyMode.keepLatest:
        return 'Keeps only the latest pending call';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.tune,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Concurrency Modes',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ConcurrentAsyncThrottler supports 4 different modes\nfor handling concurrent operations.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Select Mode', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ConcurrencyMode.values.map((mode) {
                      final isSelected = mode == _mode;
                      return ChoiceChip(
                        label: Text(mode.name),
                        selected: isSelected,
                        onSelected: (_) => setState(() => _mode = mode),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _modeDescription,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ConcurrentAsyncThrottledBuilder(
            mode: _mode,
            maxDuration: const Duration(seconds: 10),
            onPressed: () async {
              final opNum = _operationCount + 1;
              setState(() {
                _operationCount++;
                _log.add('#$opNum Started');
              });

              await Future.delayed(const Duration(seconds: 2));

              setState(() {
                _completedCount++;
                _log.add('#$opNum Completed');
              });
            },
            builder: (context, callback, isLoading, pendingCount) {
              return FilledButton.icon(
                onPressed: callback,
                icon: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(
                  isLoading
                      ? 'Processing... ($pendingCount pending)'
                      : 'Start Operation',
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Started',
                  value: _operationCount.toString(),
                  color: theme.colorScheme.tertiary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Completed',
                  value: _completedCount.toString(),
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Text('Operation Log', style: theme.textTheme.titleSmall),
                        const Spacer(),
                        TextButton(
                          onPressed: () => setState(() {
                            _log.clear();
                            _operationCount = 0;
                            _completedCount = 0;
                          }),
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _log.length,
                      itemBuilder: (context, index) {
                        final entry = _log[index];
                        final isCompleted = entry.contains('Completed');
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Icon(
                                isCompleted ? Icons.check_circle : Icons.play_circle,
                                size: 16,
                                color: isCompleted
                                    ? Colors.green
                                    : theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                entry,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SHARED WIDGETS
// ============================================================================
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
