// Pure Dart - no Flutter dependencies.
//
// Token Bucket rate limiter for burst-capable rate limiting.

import 'dart:math' as math;

import 'logger.dart';
import 'throttler.dart';

/// Token Bucket rate limiter for burst-capable rate limiting.
///
/// Unlike [Throttler] which blocks all calls after the first one for a duration,
/// [RateLimiter] allows a burst of calls up to [maxTokens], then limits to a
/// sustained rate defined by [refillRate] tokens per [refillInterval].
///
/// **Use cases:**
/// - API rate limiting: Allow 10 requests/second with burst of 20
/// - Game input: Allow burst actions then cooldown
/// - Server-side: Protect against sudden traffic spikes
/// - UI spam protection: Allow quick double-tap but prevent 100 taps
///
/// **Example:**
/// ```dart
/// final limiter = RateLimiter(
///   maxTokens: 10,           // Burst capacity
///   refillRate: 2,           // 2 tokens per interval
///   refillInterval: Duration(seconds: 1),
///   debugMode: true,
///   name: 'api-limiter',
/// );
///
/// // Check before calling
/// if (limiter.tryAcquire()) {
///   await api.call();
/// } else {
///   showRateLimitError();
/// }
///
/// // Or use with callback (only executes if token available)
/// limiter.call(() => api.submit());
///
/// // Check status
/// print('Available: ${limiter.availableTokens}');
/// print('Time until next: ${limiter.timeUntilNextToken}');
///
/// limiter.dispose();
/// ```
///
/// **Server-side example:**
/// ```dart
/// final apiLimiter = RateLimiter(
///   maxTokens: 100,          // Allow burst of 100 requests
///   refillRate: 10,          // Refill 10 tokens per second
///   refillInterval: Duration(seconds: 1),
///   name: 'api-rate-limiter',
/// );
///
/// Future<Response> handleRequest(Request request) async {
///   if (!apiLimiter.tryAcquire()) {
///     return Response.tooManyRequests(
///       retryAfter: apiLimiter.timeUntilNextToken,
///     );
///   }
///   return await processRequest(request);
/// }
/// ```
class RateLimiter with EventLimiterLogging {
  /// Maximum tokens in the bucket (burst capacity).
  final int maxTokens;

  /// Number of tokens to add per [refillInterval].
  final int refillRate;

  /// How often tokens are refilled.
  final Duration refillInterval;

  /// Whether rate limiting is enabled. If false, all calls succeed.
  final bool enabled;

  @override
  final bool debugMode;

  @override
  final String? name;

  /// Callback for metrics tracking.
  final void Function(int tokensRemaining, bool acquired)? onMetrics;

  double _tokens;
  DateTime _lastRefill;

  /// Creates a new [RateLimiter] with Token Bucket algorithm.
  ///
  /// - [maxTokens]: Maximum tokens (burst capacity). Must be > 0.
  /// - [refillRate]: Tokens added per interval. Defaults to 1.
  /// - [refillInterval]: How often tokens refill. Defaults to 1 second.
  /// - [enabled]: If false, all calls succeed without consuming tokens.
  /// - [debugMode]: Enable debug logging.
  /// - [name]: Optional name for logging.
  /// - [onMetrics]: Callback fired on each acquire attempt.
  RateLimiter({
    required this.maxTokens,
    this.refillRate = 1,
    this.refillInterval = const Duration(seconds: 1),
    this.enabled = true,
    this.debugMode = false,
    this.name,
    this.onMetrics,
  })  : assert(maxTokens > 0, 'maxTokens must be positive'),
        assert(refillRate > 0, 'refillRate must be positive'),
        _tokens = maxTokens.toDouble(),
        _lastRefill = DateTime.now();

  /// Refills tokens based on elapsed time since last refill.
  void _refillTokens() {
    final now = DateTime.now();
    final elapsed = now.difference(_lastRefill);
    final intervalsElapsed =
        elapsed.inMicroseconds / refillInterval.inMicroseconds;
    final tokensToAdd = intervalsElapsed * refillRate;

    if (tokensToAdd > 0) {
      _tokens = math.min(maxTokens.toDouble(), _tokens + tokensToAdd);
      _lastRefill = now;
      debugLog('Refilled ${tokensToAdd.toStringAsFixed(2)} tokens, '
          'now at ${_tokens.toStringAsFixed(2)}');
    }
  }

  /// Try to acquire [tokens] tokens. Returns true if successful.
  ///
  /// If [enabled] is false, always returns true without consuming tokens.
  bool tryAcquire([int tokens = 1]) {
    if (!enabled) {
      debugLog('Rate limiting disabled, allowing acquire');
      onMetrics?.call(availableTokens, true);
      return true;
    }

    _refillTokens();

    if (_tokens >= tokens) {
      _tokens -= tokens;
      debugLog(
          'Acquired $tokens token(s), ${_tokens.toStringAsFixed(2)} remaining');
      onMetrics?.call(availableTokens, true);
      return true;
    }

    debugLog('Failed to acquire $tokens token(s), '
        'only ${_tokens.toStringAsFixed(2)} available');
    onMetrics?.call(availableTokens, false);
    return false;
  }

  /// Execute [callback] if token is available, otherwise do nothing.
  ///
  /// Returns true if [callback] was executed, false if rate limited.
  bool call(VoidCallback callback, [int tokens = 1]) {
    if (tryAcquire(tokens)) {
      callback();
      return true;
    }
    return false;
  }

  /// Execute async [callback] if token is available.
  ///
  /// Returns result or null if rate limited.
  Future<T?> callAsync<T>(Future<T> Function() callback,
      [int tokens = 1]) async {
    if (tryAcquire(tokens)) {
      return await callback();
    }
    return null;
  }

  /// Current available tokens (rounded down).
  int get availableTokens {
    _refillTokens();
    return _tokens.floor();
  }

  /// Whether at least one token is available.
  bool get canAcquire {
    _refillTokens();
    return _tokens >= 1;
  }

  /// Time until next token is available.
  ///
  /// Returns [Duration.zero] if tokens are already available.
  Duration get timeUntilNextToken {
    _refillTokens();

    if (_tokens >= 1) {
      return Duration.zero;
    }

    // Calculate time needed to refill to 1 token
    final tokensNeeded = 1 - _tokens;
    final intervalsNeeded = tokensNeeded / refillRate;
    final microseconds =
        (intervalsNeeded * refillInterval.inMicroseconds).ceil();

    return Duration(microseconds: microseconds);
  }

  /// Reset to full capacity.
  void reset() {
    _tokens = maxTokens.toDouble();
    _lastRefill = DateTime.now();
    debugLog('Reset to full capacity ($maxTokens tokens)');
  }

  /// Dispose resources. No cleanup needed for this implementation.
  void dispose() {
    debugLog('Disposed');
  }
}
