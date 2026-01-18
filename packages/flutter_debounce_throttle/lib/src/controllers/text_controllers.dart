// TextField controllers with debounce support.

import 'package:flutter/material.dart';
import 'package:dart_debounce_throttle/dart_debounce_throttle.dart';

/// TextField controller with debounce (default 300ms).
///
/// **Example:**
/// ```dart
/// class _State extends State {
///   final _controller = DebouncedTextController(
///     onChanged: (text) => searchApi(text),
///   );
///
///   @override
///   void dispose() {
///     _controller.dispose();
///     super.dispose();
///   }
///
///   @override
///   Widget build(context) => TextField(controller: _controller.textController);
/// }
/// ```
class DebouncedTextController {
  final TextEditingController textController;
  final void Function(String value) onChanged;
  final Duration? duration;
  final bool _isExternalController;

  late final Debouncer _debouncer;
  String _previousValue = '';
  bool _shouldForceNextTrigger = false;

  DebouncedTextController({
    required this.onChanged,
    this.duration,
    TextEditingController? controller,
    String? initialValue,
  })  : assert(
          controller == null || initialValue == null,
          'Cannot provide both controller and initialValue.',
        ),
        textController =
            controller ?? TextEditingController(text: initialValue),
        _isExternalController = controller != null {
    _previousValue = textController.text;
    _debouncer = Debouncer(duration: duration);
    textController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final currentValue = textController.text;
    if (_shouldForceNextTrigger || currentValue != _previousValue) {
      _shouldForceNextTrigger = false;
      _debouncer.call(() {
        onChanged(currentValue);
        _previousValue = currentValue;
      });
    }
  }

  String get text => textController.text;

  /// Sets text. [triggerCallback] forces onChanged even if value unchanged.
  void setText(String value, {bool triggerCallback = false}) {
    if (triggerCallback) {
      _shouldForceNextTrigger = true;
    }
    _previousValue = value;
    textController.text = value;
  }

  void clear({bool triggerCallback = true}) {
    setText('', triggerCallback: triggerCallback);
  }

  void cancel() {
    _debouncer.cancel();
  }

  void flush() {
    _debouncer.flush(() => onChanged(textController.text));
  }

  void dispose() {
    textController.removeListener(_onTextChanged);
    if (!_isExternalController) {
      textController.dispose();
    }
    _debouncer.dispose();
  }
}

/// Enhanced debounced text controller with loading/error state for async operations.
///
/// **Example:**
/// ```dart
/// class _State extends State {
///   late final _controller = AsyncDebouncedTextController<List<User>>(
///     onChanged: (text) async => await searchApi(text),
///     onSuccess: (results) {
///       if (!mounted) return;
///       setState(() => _searchResults = results);
///     },
///     onError: (error, stack) {
///       if (!mounted) return;
///       showSnackBar('Error: $error');
///     },
///     onLoadingChanged: (isLoading) {
///       if (!mounted) return;
///       setState(() => _isSearching = isLoading);
///     },
///   );
///
///   @override
///   void dispose() {
///     _controller.dispose();
///     super.dispose();
///   }
///
///   @override
///   Widget build(context) => TextField(
///     controller: _controller.textController,
///     decoration: InputDecoration(
///       suffixIcon: _isSearching ? CircularProgressIndicator() : Icon(Icons.search),
///     ),
///   );
/// }
/// ```
class AsyncDebouncedTextController<T> {
  final TextEditingController textController;
  final Future<T> Function(String value) onChanged;
  final void Function(T result)? onSuccess;
  final void Function(Object error, StackTrace stackTrace)? onError;
  final void Function(bool isLoading)? onLoadingChanged;
  final Duration? duration;
  final bool _isExternalController;

  late final AsyncDebouncer _debouncer;
  String _previousValue = '';
  bool _shouldForceNextTrigger = false;
  bool _isLoading = false;

  AsyncDebouncedTextController({
    required this.onChanged,
    this.onSuccess,
    this.onError,
    this.onLoadingChanged,
    this.duration,
    TextEditingController? controller,
    String? initialValue,
  })  : assert(
          controller == null || initialValue == null,
          'Cannot provide both controller and initialValue.',
        ),
        textController =
            controller ?? TextEditingController(text: initialValue),
        _isExternalController = controller != null {
    _previousValue = textController.text;
    _debouncer = AsyncDebouncer(duration: duration);
    textController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final currentValue = textController.text;
    if (_shouldForceNextTrigger || currentValue != _previousValue) {
      _shouldForceNextTrigger = false;
      _executeAsync(currentValue);
    }
  }

  Future<void> _executeAsync(String value) async {
    _setLoadingState(true);

    try {
      // ignore: deprecated_member_use_from_same_package
      final result = await _debouncer.call(() async {
        return await onChanged(value);
      });

      if (result != null) {
        _setLoadingState(false);
        onSuccess?.call(result);
        _previousValue = value;
      }
    } catch (error, stackTrace) {
      _setLoadingState(false);
      onError?.call(error, stackTrace);
    }
  }

  void _setLoadingState(bool isLoading) {
    if (_isLoading != isLoading) {
      _isLoading = isLoading;
      onLoadingChanged?.call(isLoading);
    }
  }

  String get text => textController.text;
  bool get isLoading => _isLoading;

  void setText(String value, {bool triggerCallback = false}) {
    if (triggerCallback) {
      _shouldForceNextTrigger = true;
    }
    _previousValue = value;
    textController.text = value;
  }

  void clear({bool triggerCallback = true}) {
    setText('', triggerCallback: triggerCallback);
  }

  void cancel() {
    _debouncer.cancel();
    _setLoadingState(false);
  }

  void dispose() {
    textController.removeListener(_onTextChanged);
    if (!_isExternalController) {
      textController.dispose();
    }
    _debouncer.dispose();
  }
}
