/// Riverpod integration for flutter_debounce_throttle.
///
/// Provides [EventLimiterController] — debounce/throttle tied to Riverpod's
/// [Ref] lifecycle. Zero boilerplate, auto-cleanup on provider dispose.
///
/// ```dart
/// class SearchNotifier extends Notifier<SearchState> {
///   late final EventLimiterController _limiter;
///
///   @override
///   SearchState build() {
///     _limiter = ref.eventLimiter();
///     return SearchState.initial();
///   }
///
///   void onSearch(String query) {
///     _limiter.debounce('search', () async {
///       state = SearchState.data(await api.search(query));
///     });
///   }
/// }
/// ```
library flutter_debounce_throttle_riverpod;

export 'package:dart_debounce_throttle/dart_debounce_throttle.dart'
    show
        DebounceResult,
        ThrottlerResult,
        Debouncer,
        Throttler,
        AsyncDebouncer,
        AsyncThrottler;

export 'src/event_limiter_controller.dart';
