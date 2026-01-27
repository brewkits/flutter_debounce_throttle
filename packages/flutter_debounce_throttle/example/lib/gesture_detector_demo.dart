// Demo for ThrottledGestureDetector - New in v2.4.0

import 'package:flutter/material.dart';
import 'package:flutter_debounce_throttle/flutter_debounce_throttle.dart';

class GestureDetectorDemo extends StatefulWidget {
  const GestureDetectorDemo({super.key});

  @override
  State<GestureDetectorDemo> createState() => _GestureDetectorDemoState();
}

class _GestureDetectorDemoState extends State<GestureDetectorDemo> {
  final List<String> _events = [];
  Offset _position = const Offset(100, 100);
  double _scale = 1.0;
  Duration _continuousDuration = ThrottleDuration.standard; // 16ms (60fps)
  String _selectedMode = 'Standard (60fps)';

  void _addEvent(String event) {
    setState(() {
      _events.insert(0, '[${DateTime.now().second}s] $event');
      if (_events.length > 10) {
        _events.removeLast();
      }
    });
  }

  void _setThrottleMode(String mode, Duration duration) {
    setState(() {
      _selectedMode = mode;
      _continuousDuration = duration;
      _addEvent('Switched to $mode');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ThrottledGestureDetector Demo'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          // Event Log
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[200],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Event Log (throttled)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ..._events.map((e) => Text(e, style: const TextStyle(fontSize: 12))),
              ],
            ),
          ),

          // Interactive Area
          Expanded(
            child: Center(
              child: ThrottledGestureDetector(
                discreteDuration: const Duration(milliseconds: 500),
                continuousDuration: _continuousDuration,
                onTap: () => _addEvent('Tap'),
                onLongPress: () => _addEvent('Long Press'),
                onDoubleTap: () => _addEvent('Double Tap'),
                onPanUpdate: (details) {
                  setState(() {
                    _position += details.delta;
                  });
                  _addEvent('Pan Update (${details.delta.dx.toStringAsFixed(1)}, ${details.delta.dy.toStringAsFixed(1)})');
                },
                onScaleUpdate: (details) {
                  setState(() {
                    _scale *= details.scale;
                    _scale = _scale.clamp(0.5, 3.0);
                  });
                  _addEvent('Scale Update (${details.scale.toStringAsFixed(2)})');
                },
                child: Transform.translate(
                  offset: _position,
                  child: Transform.scale(
                    scale: _scale,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.deepPurple,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'Drag & Scale\nMe!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Throttle Mode Selector
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.amber[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Continuous Throttle Mode:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Ultra Smooth (120Hz)'),
                      selected: _selectedMode == 'Ultra Smooth (120Hz)',
                      onSelected: (selected) {
                        if (selected) {
                          _setThrottleMode('Ultra Smooth (120Hz)', ThrottleDuration.ultraSmooth);
                        }
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Standard (60fps)'),
                      selected: _selectedMode == 'Standard (60fps)',
                      onSelected: (selected) {
                        if (selected) {
                          _setThrottleMode('Standard (60fps)', ThrottleDuration.standard);
                        }
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Conservative (30fps)'),
                      selected: _selectedMode == 'Conservative (30fps)',
                      onSelected: (selected) {
                        if (selected) {
                          _setThrottleMode('Conservative (30fps)', ThrottleDuration.conservative);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Current: $_selectedMode (${_continuousDuration.inMilliseconds}ms)',
                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),

          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Try these gestures:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('• Tap - Throttled at 500ms'),
                Text('• Long Press - Throttled at 500ms'),
                Text('• Double Tap - Throttled at 500ms'),
                Text('• Drag - Dynamic throttle (see mode above)'),
                Text('• Pinch to Scale - Dynamic throttle (see mode above)'),
                SizedBox(height: 8),
                Text(
                  '💡 Try Ultra Smooth (8ms) on iPad Pro or 120Hz phones!',
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
