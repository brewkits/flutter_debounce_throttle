// Demo: Memory Cleanup with EventLimiterMixin
//
// This demonstrates the 3 strategies to prevent memory leaks with dynamic IDs.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_debounce_throttle/flutter_debounce_throttle.dart';

void main() {
  // AUTO-CLEANUP IS NOW ENABLED BY DEFAULT! (10 minutes, 100 limiters)
  // This demo customizes the settings for faster demonstration
  DebounceThrottleConfig.init(
    limiterAutoCleanupTTL: const Duration(
      seconds: 10,
    ), // Faster for demo (default: 10 minutes)
    limiterAutoCleanupThreshold: 50, // More aggressive for demo (default: 100)
    enableDebugLog: true, // Enable debug logs to see cleanup in action
  );

  runApp(const MemoryCleanupDemoApp());
}

class MemoryCleanupDemoApp extends StatelessWidget {
  const MemoryCleanupDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memory Cleanup Demo',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const MemoryCleanupDemo(),
    );
  }
}

class MemoryCleanupDemo extends StatefulWidget {
  const MemoryCleanupDemo({super.key});

  @override
  State<MemoryCleanupDemo> createState() => _MemoryCleanupDemoState();
}

class _MemoryCleanupDemoState extends State<MemoryCleanupDemo>
    with EventLimiterMixin {
  int _dynamicLimiterCount = 0;
  int _likeCount = 0;
  Timer? _periodicCleanupTimer;
  Timer? _spamTimer;

  @override
  void initState() {
    super.initState();

    // Strategy 2: Periodic manual cleanup (optional, in addition to auto-cleanup)
    _periodicCleanupTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      final removed = cleanupInactive();
      if (removed > 0) {
        debugPrint('🧹 Periodic cleanup removed $removed inactive limiters');
      }
    });
  }

  @override
  void dispose() {
    _periodicCleanupTimer?.cancel();
    _spamTimer?.cancel();
    cancelAll(); // IMPORTANT: Always cleanup on dispose
    super.dispose();
  }

  void _updateLimiterCount() {
    setState(() {
      _dynamicLimiterCount = totalLimitersCount;
    });
  }

  // Simulate infinite scroll with dynamic post IDs
  void _simulateInfiniteScroll() {
    setState(() => _likeCount = 0);
    _spamTimer?.cancel();

    int postId = 0;
    _spamTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      // Simulate liking posts with dynamic IDs
      final currentPostId = postId++;

      // This creates a new limiter for each post ID
      debounce('like_post_$currentPostId', () {
        setState(() => _likeCount++);
        debugPrint('❤️ Liked post #$currentPostId');
      }, duration: const Duration(milliseconds: 300));

      _updateLimiterCount();

      // Stop after 100 posts (simulating infinite scroll)
      if (postId >= 100) {
        _spamTimer?.cancel();
        debugPrint('🛑 Stopped at 100 posts');
        debugPrint('📊 Current limiter count: $_dynamicLimiterCount');

        // Auto-cleanup will kick in when threshold (50) is exceeded
        // Wait a bit and trigger another action to see auto-cleanup
        Future.delayed(const Duration(seconds: 12), () {
          debugPrint('⏰ 12 seconds passed, triggering auto-cleanup...');
          debounce('trigger_cleanup', () {
            debugPrint('✅ Trigger action executed');
          });
          _updateLimiterCount();
        });
      }
    });
  }

  void _manualCleanupInactive() {
    final removed = cleanupInactive();
    debugPrint('🧹 Manual cleanup: removed $removed inactive limiters');
    _updateLimiterCount();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Removed $removed inactive limiters')),
    );
  }

  void _manualCleanupUnused() {
    final removed = cleanupUnused(const Duration(seconds: 5));
    debugPrint('🧹 Manual cleanup: removed $removed limiters unused for 5s');
    _updateLimiterCount();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Removed $removed limiters unused for 5s')),
    );
  }

  void _clearAll() {
    _spamTimer?.cancel();
    cancelAll();
    setState(() {
      _dynamicLimiterCount = 0;
      _likeCount = 0;
    });
    debugPrint('🗑️ All limiters cleared');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory Cleanup Demo'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info Card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📊 Memory Status',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Active Limiters: $_dynamicLimiterCount',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: _dynamicLimiterCount > 50
                                ? Colors.red
                                : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text('Likes Processed: $_likeCount'),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      '⚙️ Config:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Text('• TTL: 10 seconds'),
                    const Text('• Threshold: 50 limiters'),
                    const Text('• Auto-cleanup: Enabled'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Demo Actions
            Text(
              '🧪 Demonstrations',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),

            ElevatedButton.icon(
              onPressed: _simulateInfiniteScroll,
              icon: const Icon(Icons.rocket_launch),
              label: const Text('Simulate Infinite Scroll (100 posts)'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 8),

            const Text(
              'This creates 100 dynamic limiters. Watch auto-cleanup kick in after 12s!',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),

            const SizedBox(height: 24),

            // Manual Cleanup Options
            Text(
              '🛠️ Manual Cleanup',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),

            ElevatedButton.icon(
              onPressed: _manualCleanupInactive,
              icon: const Icon(Icons.cleaning_services),
              label: const Text('Cleanup Inactive Limiters'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            ),
            const SizedBox(height: 8),

            ElevatedButton.icon(
              onPressed: _manualCleanupUnused,
              icon: const Icon(Icons.timer_off),
              label: const Text('Cleanup Unused (>5s)'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            ),
            const SizedBox(height: 8),

            ElevatedButton.icon(
              onPressed: _clearAll,
              icon: const Icon(Icons.delete_forever),
              label: const Text('Clear All'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),

            const Spacer(),

            // Instructions
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '💡 How to Test:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text('1. Tap "Simulate Infinite Scroll"'),
                    const Text('2. Watch limiter count grow to 100'),
                    const Text('3. Wait 12 seconds'),
                    const Text('4. Auto-cleanup removes old limiters!'),
                    const Text('5. Check console for debug logs'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
