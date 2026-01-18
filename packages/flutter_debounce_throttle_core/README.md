# ⚠️ DISCONTINUED - Use `dart_debounce_throttle` Instead

This package has been **renamed** to follow Dart naming conventions.

## 🔄 Migration Required

**Old package (discontinued):**
```yaml
dependencies:
  flutter_debounce_throttle_core: ^1.1.0  # ❌ Don't use
```

**New package (active):**
```yaml
dependencies:
  dart_debounce_throttle: ^2.0.0  # ✅ Use this
```

## Why the rename?

Pure Dart packages should not have the `flutter_` prefix. This package has **zero Flutter dependencies** and works in any Dart environment (server, CLI, web, mobile).

The new name `dart_debounce_throttle` better reflects this.

## Migration Guide

### 1. Update pubspec.yaml

```yaml
# Before
dependencies:
  flutter_debounce_throttle_core: ^1.1.0

# After
dependencies:
  dart_debounce_throttle: ^2.0.0
```

### 2. Update imports

```dart
// Before
import 'package:flutter_debounce_throttle_core/flutter_debounce_throttle_core.dart';

// After
import 'package:dart_debounce_throttle/dart_debounce_throttle.dart';
```

### 3. Run pub get

```bash
dart pub get  # or flutter pub get
```

## No API Changes

All classes, methods, and functionality are **exactly the same**. Only the package name and import path have changed.

## Links

- **New Package:** https://pub.dev/packages/dart_debounce_throttle
- **GitHub:** https://github.com/brewkits/flutter_debounce_throttle
- **Migration Guide:** https://github.com/brewkits/flutter_debounce_throttle/blob/main/packages/dart_debounce_throttle/CHANGELOG.md#200

---

**This package will not receive further updates. Please migrate to `dart_debounce_throttle`.**
