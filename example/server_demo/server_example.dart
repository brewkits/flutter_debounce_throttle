// Pure Dart Server Example - Demonstrating Core Package Usage
// This file shows that the core package works in server environment (no Flutter)

// ignore_for_file: avoid_print

import 'dart:async';

import 'package:flutter_debounce_throttle_core/flutter_debounce_throttle_core.dart';

/// Simulates a server-side log batching service
/// Groups multiple log entries and writes to DB in batches to reduce load
class LogBatchingService {
  final _debouncer = Debouncer(
    duration: const Duration(seconds: 1),
    debugMode: true,
    name: 'log-batcher',
  );

  final List<String> _pendingLogs = [];

  void log(String message) {
    _pendingLogs.add('[${DateTime.now()}] $message');
    print('📝 Log queued: $message (Total pending: ${_pendingLogs.length})');

    // Wait 1s after last log, then write all logs to DB at once
    _debouncer.call(() {
      print('\n💾 Writing ${_pendingLogs.length} logs to Database...');
      _simulateDatabaseWrite(_pendingLogs);
      _pendingLogs.clear();
      print('✅ Batch write completed!\n');
    });
  }

  void _simulateDatabaseWrite(List<String> logs) {
    // Simulate DB write delay
    for (final log in logs) {
      print('  → $log');
    }
  }

  void dispose() {
    _debouncer.dispose();
  }
}

/// Simulates a rate limiter for external API calls
/// Prevents excessive API calls to third-party services (Google Maps, OpenAI, etc.)
class ApiRateLimiter {
  final _throttler = Throttler(
    duration: const Duration(seconds: 2),
    debugMode: true,
    name: 'api-limiter',
  );

  int _apiCallCount = 0;

  void callExternalApi(String endpoint) {
    _throttler.call(() {
      _apiCallCount++;
      print('🌐 API Call #$_apiCallCount to $endpoint');
      print('   Rate limited: Only 1 call per 2 seconds');
    });
  }

  void dispose() {
    _throttler.dispose();
  }
}

/// Simulates async batching for database operations
/// Groups multiple save operations and executes them together
class AsyncBatchProcessor {
  final _asyncDebouncer = AsyncDebouncer(
    duration: const Duration(milliseconds: 500),
    debugMode: true,
    name: 'batch-processor',
  );

  final List<Map<String, dynamic>> _pendingRecords = [];

  Future<void> saveRecord(Map<String, dynamic> record) async {
    _pendingRecords.add(record);
    print('📦 Record queued: ${record['id']} (Total: ${_pendingRecords.length})');

    // Group records and save in batch after 500ms
    await _asyncDebouncer.call(() async {
      print('\n💾 Batch saving ${_pendingRecords.length} records...');
      await _simulateAsyncDatabaseSave(_pendingRecords);
      _pendingRecords.clear();
      print('✅ Batch save completed!\n');
    });
  }

  Future<void> _simulateAsyncDatabaseSave(List<Map<String, dynamic>> records) async {
    await Future.delayed(const Duration(milliseconds: 100));
    for (final record in records) {
      print('  → Saved: ${record['id']}');
    }
  }

  void dispose() {
    _asyncDebouncer.dispose();
  }
}

void main() async {
  print('========================================');
  print('🖥️  DART SERVER DEMO');
  print('Pure Dart Core - No Flutter Dependencies');
  print('========================================\n');

  // Configure global settings
  DebounceThrottleConfig.init(
    enableDebugLog: true,
    logLevel: LogLevel.debug,
  );

  // Demo 1: Log Batching
  print('\n📋 Demo 1: Log Batching Service');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  final logService = LogBatchingService();

  // Simulate rapid logging
  logService.log('User login: john@example.com');
  await Future.delayed(const Duration(milliseconds: 100));
  logService.log('User viewed dashboard');
  await Future.delayed(const Duration(milliseconds: 100));
  logService.log('User clicked export button');
  await Future.delayed(const Duration(milliseconds: 100));
  logService.log('Export completed');

  // Wait for debounce to execute
  await Future.delayed(const Duration(milliseconds: 1500));
  logService.dispose();

  // Demo 2: API Rate Limiting
  print('\n🌐 Demo 2: External API Rate Limiting');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  final apiLimiter = ApiRateLimiter();

  // Simulate rapid API calls - only first one executes immediately
  print('Attempting 5 rapid API calls...\n');
  apiLimiter.callExternalApi('/geocode/address');
  await Future.delayed(const Duration(milliseconds: 200));
  apiLimiter.callExternalApi('/geocode/address');
  await Future.delayed(const Duration(milliseconds: 200));
  apiLimiter.callExternalApi('/geocode/address');
  await Future.delayed(const Duration(milliseconds: 200));
  apiLimiter.callExternalApi('/geocode/address');
  await Future.delayed(const Duration(milliseconds: 200));
  apiLimiter.callExternalApi('/geocode/address');

  print('\n⏳ Waiting 2.5s for rate limit to reset...\n');
  await Future.delayed(const Duration(milliseconds: 2500));

  print('Attempting another call after rate limit reset:\n');
  apiLimiter.callExternalApi('/geocode/address');

  await Future.delayed(const Duration(milliseconds: 500));
  apiLimiter.dispose();

  // Demo 3: Async Batch Processing
  print('\n🔄 Demo 3: Async Batch Processor');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  final batchProcessor = AsyncBatchProcessor();

  // Simulate rapid record saves
  print('Queueing 5 records for batch save...\n');
  await batchProcessor.saveRecord({'id': 'user_001', 'name': 'John'});
  await Future.delayed(const Duration(milliseconds: 50));
  await batchProcessor.saveRecord({'id': 'user_002', 'name': 'Jane'});
  await Future.delayed(const Duration(milliseconds: 50));
  await batchProcessor.saveRecord({'id': 'user_003', 'name': 'Bob'});
  await Future.delayed(const Duration(milliseconds: 50));
  await batchProcessor.saveRecord({'id': 'user_004', 'name': 'Alice'});
  await Future.delayed(const Duration(milliseconds: 50));
  await batchProcessor.saveRecord({'id': 'user_005', 'name': 'Charlie'});

  // Wait for batch processing
  await Future.delayed(const Duration(milliseconds: 1000));
  batchProcessor.dispose();

  print('\n========================================');
  print('✅ All demos completed successfully!');
  print('========================================\n');

  print('💡 Key Takeaways:');
  print('  • Core package is 100% Pure Dart');
  print('  • Works in server environments (Serverpod, Dart Frog)');
  print('  • No Flutter dependencies required');
  print('  • Perfect for backend rate limiting & batching\n');
}
