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
    EnterpriseDemo(),
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
    NavigationDestination(
      icon: Icon(Icons.rocket_launch_outlined),
      selectedIcon: Icon(Icons.rocket_launch),
      label: 'Enterprise',
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
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
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
                  Icon(Icons.speed, size: 48, color: theme.colorScheme.primary),
                  const SizedBox(height: 12),
                  Text('Throttle Demo', style: theme.textTheme.headlineSmall),
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
                        final isThrottled = _logs[index].startsWith(
                          'Throttled',
                        );
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
                              fontWeight: isThrottled
                                  ? FontWeight.bold
                                  : FontWeight.normal,
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
                  Icon(Icons.timer, size: 48, color: theme.colorScheme.primary),
                  const SizedBox(height: 12),
                  Text('Debounce Demo', style: theme.textTheme.headlineSmall),
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
                      _debouncedText.isEmpty
                          ? '(waiting for input...)'
                          : _debouncedText,
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
    'Apple',
    'Banana',
    'Cherry',
    'Date',
    'Elderberry',
    'Fig',
    'Grape',
    'Honeydew',
    'Kiwi',
    'Lemon',
    'Mango',
    'Nectarine',
    'Orange',
    'Papaya',
    'Quince',
    'Raspberry',
    'Strawberry',
    'Tangerine',
    'Watermelon',
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
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _error!,
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
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
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
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
                  Icon(
                    Icons.check_circle,
                    color: theme.colorScheme.primary,
                    size: 32,
                  ),
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
                    child: Text(
                      'Submission Log',
                      style: theme.textTheme.titleSmall,
                    ),
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
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
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
                  Icon(Icons.tune, size: 48, color: theme.colorScheme.primary),
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
                        Text(
                          'Operation Log',
                          style: theme.textTheme.titleSmall,
                        ),
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
                                isCompleted
                                    ? Icons.check_circle
                                    : Icons.play_circle,
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

// ============================================================================
// ENTERPRISE DEMO
// ============================================================================
class EnterpriseDemo extends StatefulWidget {
  const EnterpriseDemo({super.key});

  @override
  State<EnterpriseDemo> createState() => _EnterpriseDemoState();
}

class _EnterpriseDemoState extends State<EnterpriseDemo> {
  int _selectedFeature = 0;

  final List<String> _features = [
    'RateLimiter',
    'Extensions',
    'Leading/Trailing',
    'BatchThrottler',
    'Queue Limit',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Feature selector
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: List.generate(_features.length, (index) {
              final isSelected = index == _selectedFeature;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(_features[index]),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedFeature = index),
                ),
              );
            }),
          ),
        ),
        // Feature demo
        Expanded(
          child: IndexedStack(
            index: _selectedFeature,
            children: const [
              _RateLimiterDemo(),
              _ExtensionsDemo(),
              _LeadingTrailingDemo(),
              _BatchThrottlerDemo(),
              _QueueLimitDemo(),
            ],
          ),
        ),
      ],
    );
  }
}

// ----------------------------------------------------------------------------
// 1. RateLimiter Demo - Token Bucket Algorithm
// ----------------------------------------------------------------------------
class _RateLimiterDemo extends StatefulWidget {
  const _RateLimiterDemo();

  @override
  State<_RateLimiterDemo> createState() => _RateLimiterDemoState();
}

class _RateLimiterDemoState extends State<_RateLimiterDemo> {
  late final RateLimiter _rateLimiter;
  int _attempts = 0;
  int _allowed = 0;
  int _blocked = 0;
  final List<String> _log = [];

  @override
  void initState() {
    super.initState();
    // Allow burst of 3 requests, then 1 per second
    _rateLimiter = RateLimiter(
      maxTokens: 3,
      refillInterval: 1.seconds, // Using Duration extension!
      debugMode: true,
      name: 'api-limiter',
    );
  }

  @override
  void dispose() {
    _rateLimiter.dispose();
    super.dispose();
  }

  void _makeRequest() {
    setState(() => _attempts++);

    final allowed = _rateLimiter.call(() {
      setState(() {
        _allowed++;
        _log.add(
          '[${_formatTime()}] Request #$_attempts - ALLOWED (tokens: ${_rateLimiter.availableTokens})',
        );
      });
    });

    if (!allowed) {
      setState(() {
        _blocked++;
        _log.add(
          '[${_formatTime()}] Request #$_attempts - BLOCKED (wait: ${_rateLimiter.timeUntilNextToken.inMilliseconds}ms)',
        );
      });
    }
  }

  String _formatTime() {
    final now = DateTime.now();
    return '${now.second}.${now.millisecond.toString().padLeft(3, '0')}';
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
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.token, size: 40, color: theme.colorScheme.primary),
                  const SizedBox(height: 8),
                  Text(
                    'Token Bucket Rate Limiter',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Burst: 3 tokens | Refill: 1 token/second',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Token gauge
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Available Tokens: ',
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        _rateLimiter.availableTokens.toStringAsFixed(1),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(' / 3', style: theme.textTheme.bodyMedium),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _rateLimiter.availableTokens / 3,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Attempts',
                  value: '$_attempts',
                  color: theme.colorScheme.tertiary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  label: 'Allowed',
                  value: '$_allowed',
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  label: 'Blocked',
                  value: '$_blocked',
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _makeRequest,
            icon: const Icon(Icons.send),
            label: const Text('Make API Request'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => setState(() {
              _log.clear();
              _attempts = 0;
              _allowed = 0;
              _blocked = 0;
            }),
            icon: const Icon(Icons.refresh),
            label: const Text('Reset'),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Card(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _log.length,
                itemBuilder: (context, index) {
                  final entry = _log[_log.length - 1 - index];
                  final isAllowed = entry.contains('ALLOWED');
                  return Text(
                    entry,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: isAllowed ? Colors.green : theme.colorScheme.error,
                    ),
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

// ----------------------------------------------------------------------------
// 2. Extensions Demo - Duration & Callback
// ----------------------------------------------------------------------------
class _ExtensionsDemo extends StatefulWidget {
  const _ExtensionsDemo();

  @override
  State<_ExtensionsDemo> createState() => _ExtensionsDemoState();
}

class _ExtensionsDemoState extends State<_ExtensionsDemo> {
  int _rawClicks = 0;
  int _debouncedClicks = 0;
  int _throttledClicks = 0;

  // Using callback extensions!
  late final void Function() _debouncedIncrement;
  late final void Function() _throttledIncrement;

  @override
  void initState() {
    super.initState();
    // Create debounced callback using extension
    _debouncedIncrement = (() {
      setState(() => _debouncedClicks++);
    }).debounced(500.ms); // Using Duration extension!

    // Create throttled callback using extension
    _throttledIncrement = (() {
      setState(() => _throttledClicks++);
    }).throttled(500.ms); // Using Duration extension!
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.extension,
                    size: 40,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Duration & Callback Extensions',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Duration Extensions:',
                          style: theme.textTheme.labelMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '300.ms  500.ms\n2.seconds  5.minutes  1.hours',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                        const Divider(height: 16),
                        Text(
                          'Callback Extensions:',
                          style: theme.textTheme.labelMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'myFunc.debounced(300.ms)\nmyFunc.throttled(500.ms)',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
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
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Raw Clicks',
                  value: '$_rawClicks',
                  color: theme.colorScheme.tertiary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  label: 'Debounced',
                  value: '$_debouncedClicks',
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  label: 'Throttled',
                  value: '$_throttledClicks',
                  color: theme.colorScheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              setState(() => _rawClicks++);
              _debouncedIncrement();
              _throttledIncrement();
            },
            icon: const Icon(Icons.touch_app),
            label: const Text('Tap Rapidly!'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Debounce waits 500ms after last tap\nThrottle allows 1 tap per 500ms',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => setState(() {
              _rawClicks = 0;
              _debouncedClicks = 0;
              _throttledClicks = 0;
            }),
            icon: const Icon(Icons.refresh),
            label: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------------------
// 3. Leading/Trailing Edge Demo
// ----------------------------------------------------------------------------
class _LeadingTrailingDemo extends StatefulWidget {
  const _LeadingTrailingDemo();

  @override
  State<_LeadingTrailingDemo> createState() => _LeadingTrailingDemoState();
}

class _LeadingTrailingDemoState extends State<_LeadingTrailingDemo> {
  bool _leading = true;
  bool _trailing = true;
  int _clicks = 0;
  int _executions = 0;
  final List<String> _log = [];
  final _scrollController = ScrollController();

  Debouncer? _debouncer;

  @override
  void initState() {
    super.initState();
    _createDebouncer();
  }

  void _createDebouncer() {
    _debouncer?.dispose();
    _debouncer = Debouncer(
      duration: 1.seconds,
      leading: _leading,
      trailing: _trailing,
      debugMode: true,
      name: 'edge-demo',
    );
  }

  @override
  void dispose() {
    _debouncer?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleClick() {
    final clickNum = _clicks + 1;
    setState(() {
      _clicks++;
      _log.add('[${_formatTime()}] Click #$clickNum');
    });

    _debouncer?.call(() {
      setState(() {
        _executions++;
        _log.add('[${_formatTime()}] >>> EXECUTED #$_executions');
      });
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: 200.ms,
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

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.swap_horiz,
                    size: 40,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Leading/Trailing Edge',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Debounce duration: 1 second',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: CheckboxListTile(
                      title: const Text('Leading'),
                      subtitle: const Text('Execute on first call'),
                      value: _leading,
                      dense: true,
                      onChanged: (v) {
                        setState(() => _leading = v ?? true);
                        _createDebouncer();
                      },
                    ),
                  ),
                  Expanded(
                    child: CheckboxListTile(
                      title: const Text('Trailing'),
                      subtitle: const Text('Execute after pause'),
                      value: _trailing,
                      dense: true,
                      onChanged: (v) {
                        setState(() => _trailing = v ?? true);
                        _createDebouncer();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Clicks',
                  value: '$_clicks',
                  color: theme.colorScheme.tertiary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  label: 'Executions',
                  value: '$_executions',
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _handleClick,
            icon: const Icon(Icons.touch_app),
            label: const Text('Click Rapidly!'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => setState(() {
              _clicks = 0;
              _executions = 0;
              _log.clear();
            }),
            icon: const Icon(Icons.refresh),
            label: const Text('Reset'),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Card(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(8),
                itemCount: _log.length,
                itemBuilder: (context, index) {
                  final entry = _log[index];
                  final isExecution = entry.contains('EXECUTED');
                  return Text(
                    entry,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: isExecution
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: isExecution
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
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

// ----------------------------------------------------------------------------
// 4. BatchThrottler Demo with maxBatchSize
// ----------------------------------------------------------------------------
class _BatchThrottlerDemo extends StatefulWidget {
  const _BatchThrottlerDemo();

  @override
  State<_BatchThrottlerDemo> createState() => _BatchThrottlerDemoState();
}

class _BatchThrottlerDemoState extends State<_BatchThrottlerDemo> {
  BatchOverflowStrategy _strategy = BatchOverflowStrategy.dropOldest;
  int _addedCount = 0;
  int _batchCount = 0;
  final List<String> _log = [];

  BatchThrottler? _batcher;

  @override
  void initState() {
    super.initState();
    _createBatcher();
  }

  void _createBatcher() {
    _batcher?.dispose();
    _batcher = BatchThrottler(
      duration: 2.seconds,
      maxBatchSize: 3, // Only allow 3 items in batch
      overflowStrategy: _strategy,
      onBatchExecute: (actions) {
        // Execute all batched actions
        for (final action in actions) {
          action();
        }
        setState(() {
          _batchCount++;
          _log.add(
            '[${_formatTime()}] >>> BATCH #$_batchCount executed (${actions.length} items)!',
          );
        });
      },
      debugMode: true,
      name: 'batch-demo',
    );
  }

  @override
  void dispose() {
    _batcher?.dispose();
    super.dispose();
  }

  void _addItem() {
    final itemNum = _addedCount + 1;
    setState(() {
      _addedCount++;
      _log.add(
        '[${_formatTime()}] Added item #$itemNum (pending: ${(_batcher?.pendingCount ?? 0) + 1})',
      );
    });

    // Add action to batch - will execute with other batched items via onBatchExecute
    _batcher?.call(() {
      // This action just logs that this item was processed
      debugPrint('Item #$itemNum processed in batch');
    });
  }

  String _formatTime() {
    final now = DateTime.now();
    return '${now.second}.${now.millisecond.toString().padLeft(3, '0')}';
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
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.inventory_2,
                    size: 40,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'BatchThrottler with maxBatchSize',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Max batch: 3 items | Duration: 2 seconds',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overflow Strategy:',
                    style: theme.textTheme.labelMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: BatchOverflowStrategy.values.map((s) {
                      return ChoiceChip(
                        label: Text(s.name),
                        selected: _strategy == s,
                        onSelected: (_) {
                          setState(() => _strategy = s);
                          _createBatcher();
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Added',
                  value: '$_addedCount',
                  color: theme.colorScheme.tertiary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  label: 'Pending',
                  value: '${_batcher?.pendingCount ?? 0}',
                  color: theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  label: 'Batches',
                  value: '$_batchCount',
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
            label: const Text('Add Item to Batch'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _addedCount = 0;
                _batchCount = 0;
                _log.clear();
              });
              _createBatcher();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reset'),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Card(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _log.length,
                itemBuilder: (context, index) {
                  final entry = _log[_log.length - 1 - index];
                  final isBatch = entry.contains('BATCH');
                  return Text(
                    entry,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: isBatch
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: isBatch ? FontWeight.bold : FontWeight.normal,
                    ),
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

// ----------------------------------------------------------------------------
// 5. ConcurrentAsyncThrottler with maxQueueSize
// ----------------------------------------------------------------------------
class _QueueLimitDemo extends StatefulWidget {
  const _QueueLimitDemo();

  @override
  State<_QueueLimitDemo> createState() => _QueueLimitDemoState();
}

class _QueueLimitDemoState extends State<_QueueLimitDemo> {
  QueueOverflowStrategy _strategy = QueueOverflowStrategy.dropNewest;
  int _requestCount = 0;
  int _completedCount = 0;
  int _droppedCount = 0;
  final List<String> _log = [];

  ConcurrentAsyncThrottler? _throttler;

  @override
  void initState() {
    super.initState();
    _createThrottler();
  }

  void _createThrottler() {
    _throttler?.dispose();
    _throttler = ConcurrentAsyncThrottler(
      mode: ConcurrencyMode.enqueue,
      maxQueueSize: 2, // Only allow 2 items in queue
      queueOverflowStrategy: _strategy,
      maxDuration: 10.seconds,
      debugMode: true,
      name: 'queue-demo',
    );
  }

  @override
  void dispose() {
    _throttler?.dispose();
    super.dispose();
  }

  void _makeRequest() {
    final requestNum = _requestCount + 1;
    final queueBefore = _throttler?.pendingCount ?? 0;

    setState(() {
      _requestCount++;
      _log.add(
        '[${_formatTime()}] Request #$requestNum queued (queue: $queueBefore)',
      );
    });

    // Note: ConcurrentAsyncThrottler.call() returns Future<void>
    // We track completion inside the callback
    _throttler?.call(() async {
      await Future.delayed(2.seconds); // Simulate slow API
      if (mounted) {
        setState(() {
          _completedCount++;
          _log.add('[${_formatTime()}] >>> Request #$requestNum COMPLETED');
        });
      }
    });

    // Check if request was dropped (queue didn't increase as expected)
    Future.delayed(const Duration(milliseconds: 50), () {
      // If queue size is at max and we're in dropNewest mode, request may be dropped
      if (_strategy == QueueOverflowStrategy.dropNewest &&
          queueBefore >= 2 &&
          mounted) {
        // Request was likely dropped
        setState(() {
          _droppedCount++;
          _log.add(
            '[${_formatTime()}] Request #$requestNum DROPPED (queue full)',
          );
        });
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

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.queue, size: 40, color: theme.colorScheme.primary),
                  const SizedBox(height: 8),
                  Text(
                    'ConcurrentAsyncThrottler Queue Limit',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mode: enqueue | Max queue: 2 | Task: 2s',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Queue Overflow Strategy:',
                    style: theme.textTheme.labelMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: QueueOverflowStrategy.values.map((s) {
                      return ChoiceChip(
                        label: Text(s.name),
                        selected: _strategy == s,
                        onSelected: (_) {
                          setState(() => _strategy = s);
                          _createThrottler();
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Requests',
                  value: '$_requestCount',
                  color: theme.colorScheme.tertiary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  label: 'Completed',
                  value: '$_completedCount',
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  label: 'Dropped',
                  value: '$_droppedCount',
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _makeRequest,
            icon: const Icon(Icons.send),
            label: Text(
              'Make Request (queue: ${_throttler?.pendingCount ?? 0})',
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _requestCount = 0;
                _completedCount = 0;
                _droppedCount = 0;
                _log.clear();
              });
              _createThrottler();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reset'),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Card(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _log.length,
                itemBuilder: (context, index) {
                  final entry = _log[_log.length - 1 - index];
                  final isCompleted = entry.contains('COMPLETED');
                  final isDropped = entry.contains('DROPPED');
                  return Text(
                    entry,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: isCompleted
                          ? Colors.green
                          : isDropped
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: (isCompleted || isDropped)
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
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
