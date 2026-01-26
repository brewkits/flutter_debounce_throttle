// Flutter widget for throttled gesture detection.
//
// Provides a drop-in replacement for GestureDetector with built-in throttling.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:dart_debounce_throttle/dart_debounce_throttle.dart';

/// Throttled gesture detector with full GestureDetector API support.
///
/// This widget wraps Flutter's [GestureDetector] and automatically throttles
/// all gesture callbacks to prevent rapid-fire events and improve UX.
///
/// **Key features:**
/// - Throttles discrete events (tap, long press, double tap) with configurable duration
/// - Throttles continuous events (pan, scale, drag) at 60fps by default for smooth animations
/// - Drop-in replacement for [GestureDetector] with identical API
/// - Automatic cleanup on dispose
/// - Separate throttling for different event types
///
/// **Event categories:**
/// 1. **Discrete events** (throttled with [discreteDuration]):
///    - onTap, onTapDown, onTapUp, onTapCancel
///    - onDoubleTap, onDoubleTapDown, onDoubleTapCancel
///    - onLongPress, onLongPressStart, onLongPressEnd, onLongPressCancel, etc.
///    - onSecondaryTap, onTertiaryTap
///
/// 2. **Continuous events** (throttled with [continuousDuration] at ~60fps):
///    - onPanUpdate, onScaleUpdate
///    - onHorizontalDragUpdate, onVerticalDragUpdate
///    - This prevents UI lag during fast gestures
///
/// **Example (Basic usage):**
/// ```dart
/// ThrottledGestureDetector(
///   onTap: () => print('Tapped!'),
///   onLongPress: () => showMenu(),
///   child: Container(
///     width: 200,
///     height: 100,
///     color: Colors.blue,
///     child: Center(child: Text('Tap me')),
///   ),
/// )
/// ```
///
/// **Example (Custom throttle durations):**
/// ```dart
/// ThrottledGestureDetector(
///   discreteDuration: Duration(milliseconds: 300),
///   continuousDuration: Duration(milliseconds: 32), // ~30fps
///   onTap: () => handleTap(),
///   onPanUpdate: (details) => updatePosition(details.delta),
///   child: MyWidget(),
/// )
/// ```
///
/// **Example (All gesture types):**
/// ```dart
/// ThrottledGestureDetector(
///   // Tap gestures
///   onTap: () => print('Tap'),
///   onTapDown: (details) => print('Tap down at ${details.localPosition}'),
///   onTapUp: (details) => print('Tap up'),
///   onTapCancel: () => print('Tap cancelled'),
///
///   // Double tap
///   onDoubleTap: () => print('Double tap'),
///
///   // Long press
///   onLongPress: () => print('Long press'),
///   onLongPressStart: (details) => print('Long press started'),
///   onLongPressEnd: (details) => print('Long press ended'),
///
///   // Pan gestures (drag in any direction)
///   onPanStart: (details) => print('Pan started'),
///   onPanUpdate: (details) => updatePosition(details.delta),
///   onPanEnd: (details) => print('Pan ended'),
///
///   // Scale gestures (pinch to zoom)
///   onScaleStart: (details) => print('Scale started'),
///   onScaleUpdate: (details) => updateScale(details.scale),
///   onScaleEnd: (details) => print('Scale ended'),
///
///   child: MyWidget(),
/// )
/// ```
///
/// **Important notes:**
/// - Continuous events (pan, scale, drag updates) use [HighFrequencyThrottler] for smooth 60fps
/// - If you need custom behavior, wrap individual callbacks with [ThrottledBuilder] instead
/// - This widget is safe to use with [ListView], [GridView], etc.
class ThrottledGestureDetector extends StatefulWidget {
  /// Throttle duration for discrete events (tap, long press, etc).
  ///
  /// Default: 500ms to prevent accidental double-taps.
  final Duration discreteDuration;

  /// Throttle duration for continuous events (pan, scale, drag).
  ///
  /// Default: 16ms (~60fps) for smooth animations.
  final Duration continuousDuration;

  /// The widget below this widget in the tree.
  final Widget child;

  /// Behavior for hit testing.
  final HitTestBehavior? behavior;

  /// Whether to exclude these gestures from the semantics tree.
  final bool excludeFromSemantics;

  /// Determines the way that drag start behavior is handled.
  final DragStartBehavior dragStartBehavior;

  // ========== TAP GESTURES ==========

  /// A tap has occurred.
  final VoidCallback? onTap;

  /// A pointer has contacted the screen at a particular location.
  final GestureTapDownCallback? onTapDown;

  /// A pointer that will trigger a tap has stopped contacting the screen.
  final GestureTapUpCallback? onTapUp;

  /// The pointer that previously triggered [onTapDown] will not end up causing a tap.
  final VoidCallback? onTapCancel;

  /// A secondary tap has occurred (e.g., right-click).
  final VoidCallback? onSecondaryTap;

  /// A pointer has contacted the screen for a secondary tap.
  final GestureTapDownCallback? onSecondaryTapDown;

  /// A pointer for a secondary tap has stopped contacting the screen.
  final GestureTapUpCallback? onSecondaryTapUp;

  /// A secondary tap cancelled.
  final VoidCallback? onSecondaryTapCancel;

  /// A tertiary tap has occurred (e.g., middle-click).
  final GestureTapDownCallback? onTertiaryTapDown;

  /// A pointer has contacted the screen for a tertiary tap.
  final GestureTapUpCallback? onTertiaryTapUp;

  /// A tertiary tap cancelled.
  final VoidCallback? onTertiaryTapCancel;

  // ========== DOUBLE TAP GESTURES ==========

  /// The user has tapped the screen twice in quick succession.
  final VoidCallback? onDoubleTap;

  /// A pointer has contacted the screen for a double tap.
  final GestureTapDownCallback? onDoubleTapDown;

  /// The pointer that previously triggered [onDoubleTapDown] was cancelled.
  final VoidCallback? onDoubleTapCancel;

  // ========== LONG PRESS GESTURES ==========

  /// A long press has occurred.
  final VoidCallback? onLongPress;

  /// A long press has started.
  final GestureLongPressStartCallback? onLongPressStart;

  /// A pointer is moving after the long press.
  final GestureLongPressMoveUpdateCallback? onLongPressMoveUpdate;

  /// The pointer is no longer in contact with the screen.
  final GestureLongPressUpCallback? onLongPressUp;

  /// A long press has ended.
  final GestureLongPressEndCallback? onLongPressEnd;

  /// The pointer that previously triggered [onLongPressStart] was cancelled.
  final VoidCallback? onLongPressCancel;

  /// A secondary long press has occurred.
  final VoidCallback? onSecondaryLongPress;

  /// A secondary long press has started.
  final GestureLongPressStartCallback? onSecondaryLongPressStart;

  /// A pointer is moving after the secondary long press.
  final GestureLongPressMoveUpdateCallback? onSecondaryLongPressMoveUpdate;

  /// The pointer for a secondary long press is no longer in contact with the screen.
  final GestureLongPressUpCallback? onSecondaryLongPressUp;

  /// A secondary long press has ended.
  final GestureLongPressEndCallback? onSecondaryLongPressEnd;

  /// A secondary long press cancelled.
  final VoidCallback? onSecondaryLongPressCancel;

  // ========== VERTICAL DRAG GESTURES ==========

  /// A pointer has contacted the screen and might begin to move vertically.
  final GestureDragDownCallback? onVerticalDragDown;

  /// A pointer has contacted the screen and has begun to move vertically.
  final GestureDragStartCallback? onVerticalDragStart;

  /// A pointer is moving vertically.
  final GestureDragUpdateCallback? onVerticalDragUpdate;

  /// A pointer is no longer in contact with the screen (vertical drag ended).
  final GestureDragEndCallback? onVerticalDragEnd;

  /// The pointer that previously triggered [onVerticalDragStart] was cancelled.
  final VoidCallback? onVerticalDragCancel;

  // ========== HORIZONTAL DRAG GESTURES ==========

  /// A pointer has contacted the screen and might begin to move horizontally.
  final GestureDragDownCallback? onHorizontalDragDown;

  /// A pointer has contacted the screen and has begun to move horizontally.
  final GestureDragStartCallback? onHorizontalDragStart;

  /// A pointer is moving horizontally.
  final GestureDragUpdateCallback? onHorizontalDragUpdate;

  /// A pointer is no longer in contact with the screen (horizontal drag ended).
  final GestureDragEndCallback? onHorizontalDragEnd;

  /// The pointer that previously triggered [onHorizontalDragStart] was cancelled.
  final VoidCallback? onHorizontalDragCancel;

  // ========== PAN GESTURES ==========

  /// A pointer has contacted the screen and might begin to move.
  final GestureDragDownCallback? onPanDown;

  /// A pointer has contacted the screen and has begun to move.
  final GestureDragStartCallback? onPanStart;

  /// A pointer is moving.
  final GestureDragUpdateCallback? onPanUpdate;

  /// A pointer is no longer in contact with the screen (pan ended).
  final GestureDragEndCallback? onPanEnd;

  /// The pointer that previously triggered [onPanStart] was cancelled.
  final VoidCallback? onPanCancel;

  // ========== SCALE GESTURES ==========

  /// The pointers in contact with the screen have established a focal point and initial scale.
  final GestureScaleStartCallback? onScaleStart;

  /// The pointers in contact with the screen have changed scale/rotation.
  final GestureScaleUpdateCallback? onScaleUpdate;

  /// The pointers in contact with the screen are no longer in contact with the screen.
  final GestureScaleEndCallback? onScaleEnd;

  // ========== FORCE PRESS GESTURES ==========

  /// A pointer has pressed with sufficient force to initiate a force press.
  final GestureForcePressStartCallback? onForcePressStart;

  /// A pointer is in contact with the screen and pressing with sufficient force.
  final GestureForcePressPeakCallback? onForcePressPeak;

  /// A pointer's force level has changed while in contact with the screen.
  final GestureForcePressUpdateCallback? onForcePressUpdate;

  /// The pointer is no longer in contact with the screen.
  final GestureForcePressEndCallback? onForcePressEnd;

  const ThrottledGestureDetector({
    super.key,
    required this.child,
    this.discreteDuration = const Duration(milliseconds: 500),
    this.continuousDuration = const Duration(milliseconds: 16),
    this.behavior,
    this.excludeFromSemantics = false,
    this.dragStartBehavior = DragStartBehavior.start,
    // Tap gestures
    this.onTap,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
    this.onSecondaryTap,
    this.onSecondaryTapDown,
    this.onSecondaryTapUp,
    this.onSecondaryTapCancel,
    this.onTertiaryTapDown,
    this.onTertiaryTapUp,
    this.onTertiaryTapCancel,
    // Double tap
    this.onDoubleTap,
    this.onDoubleTapDown,
    this.onDoubleTapCancel,
    // Long press
    this.onLongPress,
    this.onLongPressStart,
    this.onLongPressMoveUpdate,
    this.onLongPressUp,
    this.onLongPressEnd,
    this.onLongPressCancel,
    this.onSecondaryLongPress,
    this.onSecondaryLongPressStart,
    this.onSecondaryLongPressMoveUpdate,
    this.onSecondaryLongPressUp,
    this.onSecondaryLongPressEnd,
    this.onSecondaryLongPressCancel,
    // Vertical drag
    this.onVerticalDragDown,
    this.onVerticalDragStart,
    this.onVerticalDragUpdate,
    this.onVerticalDragEnd,
    this.onVerticalDragCancel,
    // Horizontal drag
    this.onHorizontalDragDown,
    this.onHorizontalDragStart,
    this.onHorizontalDragUpdate,
    this.onHorizontalDragEnd,
    this.onHorizontalDragCancel,
    // Pan
    this.onPanDown,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
    this.onPanCancel,
    // Scale
    this.onScaleStart,
    this.onScaleUpdate,
    this.onScaleEnd,
    // Force press
    this.onForcePressStart,
    this.onForcePressPeak,
    this.onForcePressUpdate,
    this.onForcePressEnd,
  });

  @override
  State<ThrottledGestureDetector> createState() =>
      _ThrottledGestureDetectorState();
}

class _ThrottledGestureDetectorState extends State<ThrottledGestureDetector> {
  /// Throttler for discrete events (tap, long press, etc).
  late final Throttler _discreteThrottler;

  /// High-frequency throttler for continuous events (pan, scale, drag).
  late final HighFrequencyThrottler _continuousThrottler;

  @override
  void initState() {
    super.initState();
    _discreteThrottler = Throttler(duration: widget.discreteDuration);
    _continuousThrottler =
        HighFrequencyThrottler(duration: widget.continuousDuration);
  }

  @override
  void didUpdateWidget(ThrottledGestureDetector oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Recreate throttlers if durations changed
    if (oldWidget.discreteDuration != widget.discreteDuration) {
      _discreteThrottler.dispose();
      _discreteThrottler = Throttler(duration: widget.discreteDuration);
    }

    if (oldWidget.continuousDuration != widget.continuousDuration) {
      _continuousThrottler.dispose();
      _continuousThrottler =
          HighFrequencyThrottler(duration: widget.continuousDuration);
    }
  }

  @override
  void dispose() {
    _discreteThrottler.dispose();
    _continuousThrottler.dispose();
    super.dispose();
  }

  /// Wrap discrete event callbacks (tap, long press, etc).
  T? _wrapDiscrete<T>(T? callback) {
    if (callback == null) return null;

    // Handle VoidCallback
    if (callback is VoidCallback) {
      return (() => _discreteThrottler.call(callback)) as T;
    }

    // Handle callbacks with parameters (TapDown, TapUp, etc)
    if (callback is Function) {
      return ((dynamic details) =>
          _discreteThrottler.call(() => Function.apply(callback, [details])))
          as T;
    }

    return callback;
  }

  /// Wrap continuous event callbacks (pan update, scale update, drag update).
  T? _wrapContinuous<T>(T? callback) {
    if (callback == null) return null;

    // All continuous callbacks take details parameter
    if (callback is Function) {
      return ((dynamic details) => _continuousThrottler
          .call(() => Function.apply(callback, [details]))) as T;
    }

    return callback;
  }

  /// Don't throttle start/end callbacks - only update callbacks.
  T? _noThrottle<T>(T? callback) => callback;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior,
      excludeFromSemantics: widget.excludeFromSemantics,
      dragStartBehavior: widget.dragStartBehavior,
      // Tap gestures (throttle all)
      onTap: _wrapDiscrete(widget.onTap),
      onTapDown: _wrapDiscrete(widget.onTapDown),
      onTapUp: _wrapDiscrete(widget.onTapUp),
      onTapCancel: _wrapDiscrete(widget.onTapCancel),
      onSecondaryTap: _wrapDiscrete(widget.onSecondaryTap),
      onSecondaryTapDown: _wrapDiscrete(widget.onSecondaryTapDown),
      onSecondaryTapUp: _wrapDiscrete(widget.onSecondaryTapUp),
      onSecondaryTapCancel: _wrapDiscrete(widget.onSecondaryTapCancel),
      onTertiaryTapDown: _wrapDiscrete(widget.onTertiaryTapDown),
      onTertiaryTapUp: _wrapDiscrete(widget.onTertiaryTapUp),
      onTertiaryTapCancel: _wrapDiscrete(widget.onTertiaryTapCancel),
      // Double tap (throttle all)
      onDoubleTap: _wrapDiscrete(widget.onDoubleTap),
      onDoubleTapDown: _wrapDiscrete(widget.onDoubleTapDown),
      onDoubleTapCancel: _wrapDiscrete(widget.onDoubleTapCancel),
      // Long press (throttle discrete, no throttle for move update)
      onLongPress: _wrapDiscrete(widget.onLongPress),
      onLongPressStart: _wrapDiscrete(widget.onLongPressStart),
      onLongPressMoveUpdate: _wrapContinuous(widget.onLongPressMoveUpdate),
      onLongPressUp: _wrapDiscrete(widget.onLongPressUp),
      onLongPressEnd: _wrapDiscrete(widget.onLongPressEnd),
      onLongPressCancel: _wrapDiscrete(widget.onLongPressCancel),
      onSecondaryLongPress: _wrapDiscrete(widget.onSecondaryLongPress),
      onSecondaryLongPressStart:
          _wrapDiscrete(widget.onSecondaryLongPressStart),
      onSecondaryLongPressMoveUpdate:
          _wrapContinuous(widget.onSecondaryLongPressMoveUpdate),
      onSecondaryLongPressUp: _wrapDiscrete(widget.onSecondaryLongPressUp),
      onSecondaryLongPressEnd: _wrapDiscrete(widget.onSecondaryLongPressEnd),
      onSecondaryLongPressCancel:
          _wrapDiscrete(widget.onSecondaryLongPressCancel),
      // Vertical drag (no throttle start/end, throttle update)
      onVerticalDragDown: _noThrottle(widget.onVerticalDragDown),
      onVerticalDragStart: _noThrottle(widget.onVerticalDragStart),
      onVerticalDragUpdate: _wrapContinuous(widget.onVerticalDragUpdate),
      onVerticalDragEnd: _noThrottle(widget.onVerticalDragEnd),
      onVerticalDragCancel: _noThrottle(widget.onVerticalDragCancel),
      // Horizontal drag (no throttle start/end, throttle update)
      onHorizontalDragDown: _noThrottle(widget.onHorizontalDragDown),
      onHorizontalDragStart: _noThrottle(widget.onHorizontalDragStart),
      onHorizontalDragUpdate: _wrapContinuous(widget.onHorizontalDragUpdate),
      onHorizontalDragEnd: _noThrottle(widget.onHorizontalDragEnd),
      onHorizontalDragCancel: _noThrottle(widget.onHorizontalDragCancel),
      // Pan (no throttle start/end, throttle update)
      onPanDown: _noThrottle(widget.onPanDown),
      onPanStart: _noThrottle(widget.onPanStart),
      onPanUpdate: _wrapContinuous(widget.onPanUpdate),
      onPanEnd: _noThrottle(widget.onPanEnd),
      onPanCancel: _noThrottle(widget.onPanCancel),
      // Scale (no throttle start/end, throttle update)
      onScaleStart: _noThrottle(widget.onScaleStart),
      onScaleUpdate: _wrapContinuous(widget.onScaleUpdate),
      onScaleEnd: _noThrottle(widget.onScaleEnd),
      // Force press (throttle all)
      onForcePressStart: _wrapDiscrete(widget.onForcePressStart),
      onForcePressPeak: _wrapDiscrete(widget.onForcePressPeak),
      onForcePressUpdate: _wrapContinuous(widget.onForcePressUpdate),
      onForcePressEnd: _wrapDiscrete(widget.onForcePressEnd),
      child: widget.child,
    );
  }
}
