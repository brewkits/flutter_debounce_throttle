import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_debounce_throttle_riverpod/flutter_debounce_throttle_riverpod.dart';

// ============================================================================
// ENTRY POINT
// ============================================================================

void main() {
  runApp(const ProviderScope(child: RiverpodDemoApp()));
}

class RiverpodDemoApp extends StatelessWidget {
  const RiverpodDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Riverpod Debounce Throttle Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const _HomePage(),
    );
  }
}

class _HomePage extends StatefulWidget {
  const _HomePage();

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riverpod Debounce & Throttle'),
        centerTitle: true,
        elevation: 0,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          _SearchTab(),
          _SubmitTab(),
          _AutoDisposeTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.payment_outlined),
            selectedIcon: Icon(Icons.payment),
            label: 'Submit',
          ),
          NavigationDestination(
            icon: Icon(Icons.delete_sweep_outlined),
            selectedIcon: Icon(Icons.delete_sweep),
            label: 'Auto-Dispose',
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// TAB 1: DEBOUNCED SEARCH
// ============================================================================

class SearchState {
  final List<String> results;
  final int apiCalls;
  final bool loading;

  const SearchState({
    required this.results,
    required this.apiCalls,
    required this.loading,
  });

  factory SearchState.initial() => const SearchState(
        results: [],
        apiCalls: 0,
        loading: false,
      );

  SearchState copyWith({
    List<String>? results,
    int? apiCalls,
    bool? loading,
  }) {
    return SearchState(
      results: results ?? this.results,
      apiCalls: apiCalls ?? this.apiCalls,
      loading: loading ?? this.loading,
    );
  }
}

class SearchNotifier extends Notifier<SearchState> {
  late final EventLimiterController _limiter;

  @override
  SearchState build() {
    _limiter = ref.eventLimiter();
    return SearchState.initial();
  }

  void search(String query) {
    if (query.isEmpty) {
      state = state.copyWith(results: [], loading: false);
      return;
    }

    _limiter.debounce(
      'search',
      () async {
        state = state.copyWith(loading: true);
        await Future.delayed(const Duration(milliseconds: 600));
        final results = [
          '$query · result 1',
          '$query · result 2',
          '$query · result 3',
          '$query · result 4',
        ];
        state = state.copyWith(
          results: results,
          loading: false,
          apiCalls: state.apiCalls + 1,
        );
      },
      duration: const Duration(milliseconds: 400),
    );
  }
}

final searchNotifierProvider =
    NotifierProvider<SearchNotifier, SearchState>(SearchNotifier.new);

class _SearchTab extends ConsumerStatefulWidget {
  const _SearchTab();

  @override
  ConsumerState<_SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends ConsumerState<_SearchTab> {
  int _keystrokes = 0;
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final searchState = ref.watch(searchNotifierProvider);
    final notifier = ref.read(searchNotifierProvider.notifier);
    final saved =
        _keystrokes - searchState.apiCalls > 0 ? _keystrokes - searchState.apiCalls : 0;

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
                  Icon(Icons.search, size: 44, color: theme.colorScheme.primary),
                  const SizedBox(height: 8),
                  Text(
                    'Debounced Search',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Type quickly — debounce (400ms) waits until you pause before calling the API.',
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
                  label: 'API Calls',
                  value: searchState.apiCalls.toString(),
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Saved',
                  value: saved.toString(),
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _textController,
            onChanged: (value) {
              setState(() => _keystrokes++);
              notifier.search(value);
            },
            decoration: InputDecoration(
              labelText: 'Search anything...',
              hintText: 'Type to trigger debounce',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchState.loading
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
          const SizedBox(height: 16),
          if (searchState.results.isNotEmpty)
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Text(
                      'Results (${searchState.results.length})',
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  const Divider(height: 1),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: searchState.results.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = searchState.results[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              theme.colorScheme.primaryContainer,
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        title: Text(item),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      );
                    },
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          _CodeSnippet('''// Notifier with auto-disposing limiter
class SearchNotifier extends Notifier<SearchState> {
  late final EventLimiterController _limiter;

  @override
  SearchState build() {
    _limiter = ref.eventLimiter(); // auto-disposes
    return SearchState.initial();
  }

  void search(String query) {
    _limiter.debounce('search', () async {
      state = state.copyWith(loading: true);
      final results = await api.search(query);
      state = state.copyWith(results: results);
    }, duration: Duration(milliseconds: 400));
  }
}'''),
        ],
      ),
    );
  }
}

// ============================================================================
// TAB 2: SUBMIT PROTECTION (THROTTLE)
// ============================================================================

enum SubmitStatus { idle, submitting, done }

class SubmitState {
  final SubmitStatus status;
  final int attempts;
  final int submitted;

  const SubmitState({
    required this.status,
    required this.attempts,
    required this.submitted,
  });

  factory SubmitState.initial() => const SubmitState(
        status: SubmitStatus.idle,
        attempts: 0,
        submitted: 0,
      );

  SubmitState copyWith({
    SubmitStatus? status,
    int? attempts,
    int? submitted,
  }) {
    return SubmitState(
      status: status ?? this.status,
      attempts: attempts ?? this.attempts,
      submitted: submitted ?? this.submitted,
    );
  }
}

class SubmitNotifier extends Notifier<SubmitState> {
  late final EventLimiterController _limiter;

  @override
  SubmitState build() {
    _limiter = ref.eventLimiter();
    return SubmitState.initial();
  }

  void submit() {
    final newAttempts = state.attempts + 1;
    state = state.copyWith(attempts: newAttempts);

    _limiter.throttle(
      'submit',
      () async {
        state = state.copyWith(status: SubmitStatus.submitting);
        await Future.delayed(const Duration(seconds: 2));
        state = state.copyWith(
          status: SubmitStatus.done,
          submitted: state.submitted + 1,
        );
        await Future.delayed(const Duration(seconds: 1));
        state = state.copyWith(status: SubmitStatus.idle);
      },
      duration: const Duration(seconds: 3),
    );
  }
}

final submitNotifierProvider =
    NotifierProvider<SubmitNotifier, SubmitState>(SubmitNotifier.new);

class _SubmitTab extends ConsumerWidget {
  const _SubmitTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final submitState = ref.watch(submitNotifierProvider);
    final notifier = ref.read(submitNotifierProvider.notifier);
    final blocked = submitState.attempts - submitState.submitted;

    final isSubmitting = submitState.status == SubmitStatus.submitting;
    final isDone = submitState.status == SubmitStatus.done;

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
                  Icon(Icons.payment, size: 44, color: theme.colorScheme.primary),
                  const SizedBox(height: 8),
                  Text(
                    'Submit Protection',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Throttle (3s) prevents accidental double-payments. Tap rapidly — only one fires.',
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
                  label: 'Taps',
                  value: submitState.attempts.toString(),
                  color: theme.colorScheme.tertiary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Payments',
                  value: submitState.submitted.toString(),
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Blocked',
                  value: blocked > 0 ? blocked.toString() : '0',
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 64,
            child: FilledButton.icon(
              onPressed: isSubmitting ? null : notifier.submit,
              icon: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : isDone
                      ? const Icon(Icons.check_circle_outline)
                      : const Icon(Icons.payment),
              label: Text(
                isSubmitting
                    ? 'Processing...'
                    : isDone
                        ? 'Submitted!'
                        : 'Pay \$99',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isSubmitting
                ? 'Payment in progress — extra taps are blocked'
                : isDone
                    ? 'Payment complete! Throttle resets in ~1s'
                    : 'Tap rapidly to test throttle protection',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isSubmitting
                  ? theme.colorScheme.primary
                  : isDone
                      ? Colors.green
                      : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          _CodeSnippet('''// Throttle with 3-second lock window
class SubmitNotifier extends Notifier<SubmitState> {
  late final EventLimiterController _limiter;

  @override
  SubmitState build() {
    _limiter = ref.eventLimiter();
    return SubmitState.initial();
  }

  void submit() {
    state = state.copyWith(attempts: state.attempts + 1);

    _limiter.throttle('submit', () async {
      state = state.copyWith(status: SubmitStatus.submitting);
      await api.processPayment();
      state = state.copyWith(status: SubmitStatus.done);
    }, duration: Duration(seconds: 3));
  }
}'''),
        ],
      ),
    );
  }
}

// ============================================================================
// TAB 3: AUTO-DISPOSE DEMO
// ============================================================================

class LogNotifier extends Notifier<List<String>> {
  @override
  List<String> build() {
    return const [];
  }

  void addLog(String message) {
    state = [...state, message];
  }

  void clear() {
    state = const [];
  }
}

final logNotifierProvider =
    NotifierProvider<LogNotifier, List<String>>(LogNotifier.new);

class AutoDisposeSearchNotifier extends Notifier<SearchState> {
  late final EventLimiterController _limiter;

  @override
  SearchState build() {
    _limiter = ref.eventLimiter();

    ref.onDispose(() {
      ref.read(logNotifierProvider.notifier).addLog(
            'Provider reset — debounce CANCELLED',
          );
    });

    return SearchState.initial();
  }

  void search(String query, {required void Function() onStarted}) {
    if (query.isEmpty) {
      state = state.copyWith(results: [], loading: false);
      return;
    }

    onStarted();

    _limiter.debounce(
      'auto-search',
      () async {
        ref
            .read(logNotifierProvider.notifier)
            .addLog('Debounce fired — API called');
        state = state.copyWith(loading: true);
        await Future.delayed(const Duration(milliseconds: 600));
        final results = [
          '$query · result 1',
          '$query · result 2',
          '$query · result 3',
          '$query · result 4',
        ];
        state = state.copyWith(
          results: results,
          loading: false,
          apiCalls: state.apiCalls + 1,
        );
      },
      duration: const Duration(milliseconds: 800),
    );
  }
}

final autoDisposeSearchProvider =
    NotifierProvider<AutoDisposeSearchNotifier, SearchState>(
        AutoDisposeSearchNotifier.new);

class _AutoDisposeTab extends ConsumerStatefulWidget {
  const _AutoDisposeTab();

  @override
  ConsumerState<_AutoDisposeTab> createState() => _AutoDisposeTabState();
}

class _AutoDisposeTabState extends ConsumerState<_AutoDisposeTab> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final logs = ref.watch(logNotifierProvider);
    final searchNotifier = ref.read(autoDisposeSearchProvider.notifier);

    ref.listen(logNotifierProvider, (_, __) => _scrollToBottom());

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
                  Icon(Icons.delete_sweep, size: 44, color: theme.colorScheme.primary),
                  const SizedBox(height: 8),
                  Text(
                    'Auto-Dispose Demo',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Type → then tap "Reset Provider" before the debounce fires. The pending debounce is CANCELLED.',
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
            controller: _textController,
            onChanged: (value) {
              searchNotifier.search(
                value,
                onStarted: () {
                  ref.read(logNotifierProvider.notifier).addLog(
                        'Started debouncing... (800ms window)',
                      );
                },
              );
            },
            decoration: const InputDecoration(
              labelText: 'Type to start debouncing...',
              hintText: 'Then hit Reset before it fires!',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.keyboard),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ref.invalidate(autoDisposeSearchProvider);
                    _textController.clear();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset Provider'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    side: BorderSide(color: theme.colorScheme.error),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ref.read(logNotifierProvider.notifier).clear();
                  },
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Clear Log'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'Event Log',
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: logs.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.receipt_long_outlined,
                                  size: 48,
                                  color: theme.colorScheme.outlineVariant,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Start typing to see events...',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(8),
                            itemCount: logs.length,
                            itemBuilder: (context, index) {
                              return _LogTile(message: logs[index]);
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _CodeSnippet('''// ref.onDispose fires when provider is invalidated
class AutoDisposeSearchNotifier extends Notifier<SearchState> {
  late final EventLimiterController _limiter;

  @override
  SearchState build() {
    _limiter = ref.eventLimiter(); // bound to lifecycle

    ref.onDispose(() {
      // _limiter.dispose() is called automatically —
      // any pending debounce timer is CANCELLED here
      log.add("Provider reset — debounce CANCELLED");
    });

    return SearchState.initial();
  }
}

// In widget:
// ref.invalidate(autoDisposeSearchProvider);
// → provider rebuilds → old limiter disposed → timer cancelled'''),
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
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CodeSnippet extends StatelessWidget {
  final String code;

  const _CodeSnippet(this.code);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF44475A) : const Color(0xFFE0E0E0),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Text(
          code,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 11.5,
            height: 1.6,
            color: isDark ? const Color(0xFFCDD6F4) : const Color(0xFF37474F),
          ),
        ),
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  final String message;

  const _LogTile({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCancelled = message.contains('CANCELLED');
    final isFired = message.contains('API called');
    final isStarted = message.contains('Started debouncing');

    Color textColor;
    IconData iconData;

    if (isCancelled) {
      textColor = theme.colorScheme.error;
      iconData = Icons.cancel_outlined;
    } else if (isFired) {
      textColor = Colors.green;
      iconData = Icons.check_circle_outline;
    } else if (isStarted) {
      textColor = theme.colorScheme.primary;
      iconData = Icons.timer_outlined;
    } else {
      textColor = theme.colorScheme.onSurface;
      iconData = Icons.circle_outlined;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(iconData, size: 16, color: textColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                height: 1.5,
                color: textColor,
                fontWeight:
                    (isCancelled || isFired) ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
