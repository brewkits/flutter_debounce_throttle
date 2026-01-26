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

  void _addEvent(String event) {
    setState(() {
      _events.insert(0, '[${DateTime.now().second}s] $event');
      if (_events.length > 10) {
        _events.removeLast();
      }
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
                continuousDuration: const Duration(milliseconds: 16),
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
                Text('• Drag - Throttled at 16ms (60fps)'),
                Text('• Pinch to Scale - Throttled at 16ms (60fps)'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
